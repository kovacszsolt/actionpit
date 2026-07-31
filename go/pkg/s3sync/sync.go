package s3sync

import (
	"context"
	"crypto/md5"
	"encoding/hex"
	"fmt"
	"io"
	"io/fs"
	"log"
	"mime"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
)

type localFile struct {
	Path   string
	Rel    string
	Key    string
	Size   int64
	MD5Hex string // filled only when needed for size-match compare
}

type remoteObject struct {
	Size int64
	ETag string // quotes stripped; multipart ETags contain "-"
}

// planSync decides uploads (content change or missing), skips (size+MD5 match), and orphan deletes.
func planSync(locals []localFile, remote map[string]remoteObject) (upload []localFile, skipped int, orphans []string, err error) {
	upload = make([]localFile, 0, len(locals))
	localKeys := make(map[string]struct{}, len(locals))
	for _, f := range locals {
		localKeys[f.Key] = struct{}{}
		rem, ok := remote[f.Key]
		if !ok {
			upload = append(upload, f)
			continue
		}
		if rem.Size != f.Size {
			upload = append(upload, f)
			continue
		}
		etag := rem.ETag
		if etag == "" || strings.Contains(etag, "-") {
			upload = append(upload, f)
			continue
		}
		md5hex, hashErr := fileMD5Hex(f.Path)
		if hashErr != nil {
			return nil, 0, nil, fmt.Errorf("md5 %s: %w", f.Path, hashErr)
		}
		f.MD5Hex = md5hex
		if strings.EqualFold(md5hex, etag) {
			skipped++
			continue
		}
		upload = append(upload, f)
	}
	orphans = make([]string, 0)
	for key := range remote {
		if _, ok := localKeys[key]; !ok {
			orphans = append(orphans, key)
		}
	}
	return upload, skipped, orphans, nil
}

func fileMD5Hex(path string) (string, error) {
	f, err := os.Open(path)
	if err != nil {
		return "", err
	}
	defer f.Close()
	h := md5.New()
	if _, err := io.Copy(h, f); err != nil {
		return "", err
	}
	return hex.EncodeToString(h.Sum(nil)), nil
}

func normalizeETag(raw string) string {
	return strings.Trim(strings.TrimSpace(raw), `"`)
}

func listLocalFiles(sourceDir, prefix string) ([]localFile, error) {
	var out []localFile
	err := filepath.WalkDir(sourceDir, func(path string, entry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if entry.IsDir() {
			return nil
		}
		info, err := entry.Info()
		if err != nil {
			return err
		}
		rel, err := filepath.Rel(sourceDir, path)
		if err != nil {
			return err
		}
		rel = filepath.ToSlash(rel)
		out = append(out, localFile{
			Path: path,
			Rel:  rel,
			Key:  prefix + rel,
			Size: info.Size(),
		})
		return nil
	})
	return out, err
}

func (d *Deployer) listRemoteObjects(ctx context.Context) (map[string]remoteObject, error) {
	out := make(map[string]remoteObject)
	var token *string
	for {
		listOut, err := d.S3.ListObjectsV2(ctx, &s3.ListObjectsV2Input{
			Bucket:            aws.String(d.Config.Bucket),
			Prefix:            aws.String(d.Config.Prefix),
			ContinuationToken: token,
		})
		if err != nil {
			return nil, fmt.Errorf("list s3 objects: %w", err)
		}
		for _, obj := range listOut.Contents {
			if obj.Key == nil {
				continue
			}
			var size int64
			if obj.Size != nil {
				size = *obj.Size
			}
			etag := ""
			if obj.ETag != nil {
				etag = normalizeETag(*obj.ETag)
			}
			out[*obj.Key] = remoteObject{Size: size, ETag: etag}
		}
		if !aws.ToBool(listOut.IsTruncated) {
			break
		}
		token = listOut.NextContinuationToken
	}
	return out, nil
}

func (d *Deployer) uploadFiles(ctx context.Context, files []localFile) (int, error) {
	if len(files) == 0 {
		return 0, nil
	}
	workers := d.uploadWorkers()
	sem := make(chan struct{}, workers)
	var (
		wg       sync.WaitGroup
		uploaded atomic.Int64
		errOnce  sync.Once
		firstErr error
	)
	setErr := func(err error) {
		errOnce.Do(func() { firstErr = err })
	}

	for _, f := range files {
		if ctx.Err() != nil {
			setErr(ctx.Err())
			break
		}
		if firstErr != nil {
			break
		}
		wg.Add(1)
		sem <- struct{}{}
		go func(f localFile) {
			defer wg.Done()
			defer func() { <-sem }()
			if err := d.putFile(ctx, f); err != nil {
				setErr(err)
				return
			}
			n := uploaded.Add(1)
			if n%100 == 0 {
				log.Printf("s3sync: upload progress %d/%d", n, len(files))
			}
		}(f)
	}
	wg.Wait()
	if firstErr != nil {
		return int(uploaded.Load()), firstErr
	}
	return int(uploaded.Load()), nil
}

func (d *Deployer) putFile(ctx context.Context, f localFile) error {
	body, err := os.Open(f.Path)
	if err != nil {
		return fmt.Errorf("open %s: %w", f.Path, err)
	}
	defer body.Close()

	contentType := mime.TypeByExtension(filepath.Ext(f.Path))
	if contentType == "" {
		contentType = "application/octet-stream"
	}
	_, err = d.S3.PutObject(ctx, &s3.PutObjectInput{
		Bucket:       aws.String(d.Config.Bucket),
		Key:          aws.String(f.Key),
		Body:         body,
		ContentType:  aws.String(contentType),
		CacheControl: aws.String(d.Config.cacheControl()(f.Rel)),
	})
	if err != nil {
		return fmt.Errorf("upload %s: %w", f.Key, err)
	}
	return nil
}

func (d *Deployer) deleteKeys(ctx context.Context, keys []string) (int, error) {
	deleted := 0
	for i := 0; i < len(keys); i += deleteBatchSize {
		end := i + deleteBatchSize
		if end > len(keys) {
			end = len(keys)
		}
		batch := keys[i:end]
		objs := make([]types.ObjectIdentifier, 0, len(batch))
		for _, key := range batch {
			objs = append(objs, types.ObjectIdentifier{Key: aws.String(key)})
		}
		_, err := d.S3.DeleteObjects(ctx, &s3.DeleteObjectsInput{
			Bucket: aws.String(d.Config.Bucket),
			Delete: &types.Delete{Objects: objs, Quiet: aws.Bool(true)},
		})
		if err != nil {
			return deleted, fmt.Errorf("delete s3 objects: %w", err)
		}
		deleted += len(objs)
	}
	return deleted, nil
}

func invalidationPaths(uploaded []localFile, orphans []string) []string {
	seen := make(map[string]struct{}, len(uploaded)+len(orphans))
	out := make([]string, 0, len(uploaded)+len(orphans))
	add := func(key string) {
		p := "/" + strings.TrimLeft(key, "/")
		if _, ok := seen[p]; ok {
			return
		}
		seen[p] = struct{}{}
		out = append(out, p)
	}
	for _, f := range uploaded {
		add(f.Key)
	}
	for _, key := range orphans {
		add(key)
	}
	return out
}
