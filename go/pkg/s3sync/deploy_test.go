package s3sync

import (
	"crypto/md5"
	"encoding/hex"
	"os"
	"path/filepath"
	"testing"
)

func TestValidateConfig(t *testing.T) {
	t.Parallel()
	if err := ValidateConfig(Config{}); err == nil {
		t.Fatal("expected error for empty config")
	}
	if err := ValidateConfig(Config{Bucket: "b", AccessKeyID: "k"}); err == nil {
		t.Fatal("expected error when secret missing")
	}
	if err := ValidateConfig(Config{Bucket: "b", AccessKeyID: "k", SecretAccessKey: "s"}); err != nil {
		t.Fatalf("unexpected: %v", err)
	}
}

func TestNormalizePrefixAndRegion(t *testing.T) {
	t.Parallel()
	if got := NormalizePrefix("staging"); got != "staging/" {
		t.Fatalf("prefix = %q", got)
	}
	if got := NormalizeRegion(`"eu-central-1"`, DefaultRegion); got != "eu-central-1" {
		t.Fatalf("region = %q", got)
	}
	if got := NormalizeRegion("", ""); got != DefaultRegion {
		t.Fatalf("default region = %q", got)
	}
	if got := NormalizeRegion("", "us-east-1"); got != "us-east-1" {
		t.Fatalf("fallback region = %q", got)
	}
}

func TestDefaultStaticSiteCacheControl(t *testing.T) {
	t.Parallel()
	if got := DefaultStaticSiteCacheControl("css/main.css"); got != cacheLong {
		t.Fatalf("css: %q", got)
	}
	if got := DefaultStaticSiteCacheControl("pagefind/entry.json"); got != cacheMedium {
		t.Fatalf("pagefind: %q", got)
	}
	if got := DefaultStaticSiteCacheControl("index.html"); got != cacheShort {
		t.Fatalf("html: %q", got)
	}
}

func TestPlanSyncSkipsSameSizeAndDeletesOrphans(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	sameContent := []byte("same-bytes")
	changedContent := []byte("changed!!")
	newContent := []byte("new")

	samePath := filepath.Join(dir, "a.html")
	changedPath := filepath.Join(dir, "b.css")
	newPath := filepath.Join(dir, "new.js")
	for _, pair := range []struct {
		path string
		body []byte
	}{
		{samePath, sameContent},
		{changedPath, changedContent},
		{newPath, newContent},
	} {
		if err := os.WriteFile(pair.path, pair.body, 0o644); err != nil {
			t.Fatal(err)
		}
	}

	sameMD5 := md5Hex(sameContent)
	locals := []localFile{
		{Path: samePath, Key: "p/a.html", Size: int64(len(sameContent))},
		{Path: changedPath, Key: "p/b.css", Size: int64(len(changedContent))},
		{Path: newPath, Key: "p/new.js", Size: int64(len(newContent))},
	}
	remote := map[string]remoteObject{
		"p/a.html": {Size: int64(len(sameContent)), ETag: sameMD5},
		"p/b.css":  {Size: int64(len(changedContent)), ETag: "deadbeef"},
		"p/old.md": {Size: 1, ETag: "abc"},
	}
	upload, skipped, orphans, err := planSync(locals, remote)
	if err != nil {
		t.Fatal(err)
	}
	if skipped != 1 {
		t.Fatalf("skipped=%d", skipped)
	}
	if len(upload) != 2 {
		t.Fatalf("upload=%d %#v", len(upload), upload)
	}
	keys := map[string]bool{}
	for _, f := range upload {
		keys[f.Key] = true
	}
	if !keys["p/b.css"] || !keys["p/new.js"] {
		t.Fatalf("upload keys=%v", keys)
	}
	if len(orphans) != 1 || orphans[0] != "p/old.md" {
		t.Fatalf("orphans=%v", orphans)
	}
}

func TestPlanSyncMultipartETagForcesUpload(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	path := filepath.Join(dir, "big.bin")
	body := []byte("hello")
	if err := os.WriteFile(path, body, 0o644); err != nil {
		t.Fatal(err)
	}
	locals := []localFile{{Path: path, Key: "p/big.bin", Size: int64(len(body))}}
	remote := map[string]remoteObject{
		"p/big.bin": {Size: int64(len(body)), ETag: "abc123-2"},
	}
	upload, skipped, orphans, err := planSync(locals, remote)
	if err != nil {
		t.Fatal(err)
	}
	if skipped != 0 || len(upload) != 1 || len(orphans) != 0 {
		t.Fatalf("upload=%d skipped=%d orphans=%d", len(upload), skipped, len(orphans))
	}
}

func TestListLocalFiles(t *testing.T) {
	t.Parallel()
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "index.html"), []byte("hi"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(dir, "css"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "css", "main.css"), []byte("body{}"), 0o644); err != nil {
		t.Fatal(err)
	}
	files, err := listLocalFiles(dir, "staging/")
	if err != nil {
		t.Fatal(err)
	}
	if len(files) != 2 {
		t.Fatalf("files=%d", len(files))
	}
	byRel := map[string]localFile{}
	for _, f := range files {
		byRel[f.Rel] = f
	}
	if byRel["index.html"].Key != "staging/index.html" {
		t.Fatalf("index key=%q", byRel["index.html"].Key)
	}
	if byRel["css/main.css"].Size != 6 {
		t.Fatalf("css size=%d", byRel["css/main.css"].Size)
	}
}

func TestInvalidationPaths(t *testing.T) {
	t.Parallel()
	uploaded := []localFile{{Key: "staging/index.html"}, {Key: "/staging/a.css"}}
	orphans := []string{"staging/old.html", "staging/index.html"}
	paths := invalidationPaths(uploaded, orphans)
	if len(paths) != 3 {
		t.Fatalf("paths=%v", paths)
	}
	for _, p := range paths {
		if p[0] != '/' {
			t.Fatalf("path must start with /: %q", p)
		}
	}
}

func TestParseUploadWorkers(t *testing.T) {
	t.Parallel()
	if got := ParseUploadWorkers(""); got != 0 {
		t.Fatalf("empty=%d", got)
	}
	if got := ParseUploadWorkers("64"); got != 64 {
		t.Fatalf("64=%d", got)
	}
	if got := ParseUploadWorkers("-1"); got != 0 {
		t.Fatalf("negative=%d", got)
	}
	if got := ParseUploadWorkers("abc"); got != 0 {
		t.Fatalf("bad=%d", got)
	}
}

func TestNormalizeETag(t *testing.T) {
	t.Parallel()
	if got := normalizeETag(`"abc"`); got != "abc" {
		t.Fatalf("got %q", got)
	}
}

func md5Hex(b []byte) string {
	sum := md5.Sum(b)
	return hex.EncodeToString(sum[:])
}
