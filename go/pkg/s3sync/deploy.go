package s3sync

import (
	"context"
	"fmt"
	"log"
	"os"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/cloudfront"
	cftypes "github.com/aws/aws-sdk-go-v2/service/cloudfront/types"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// Config is the S3/CloudFront sync target.
type Config struct {
	Bucket                   string
	Prefix                   string
	Region                   string
	CloudfrontDistributionID string
	AccessKeyID              string
	SecretAccessKey          string
	// UploadWorkers caps parallel PutObject calls (0 = defaultUploadWorkers).
	UploadWorkers int
	// CacheControl selects Cache-Control per relative path; nil uses DefaultStaticSiteCacheControl.
	CacheControl CacheControlFunc
}

// Result summarizes a sync run.
type Result struct {
	Bucket                   string
	Prefix                   string
	ObjectsUploaded          int
	ObjectsSkipped           int
	ObjectsDeleted           int
	CloudfrontInvalidationID string
	CFPathsInvalidated       int
}

// ValidateConfig ensures required S3 credentials are present.
func ValidateConfig(c Config) error {
	if strings.TrimSpace(c.Bucket) == "" {
		return fmt.Errorf("bucket is required")
	}
	if strings.TrimSpace(c.AccessKeyID) == "" {
		return fmt.Errorf("access_key_id is required")
	}
	if strings.TrimSpace(c.SecretAccessKey) == "" {
		return fmt.Errorf("secret_access_key is required")
	}
	return nil
}

// Deployer syncs a local directory to S3 and optionally invalidates CloudFront.
type Deployer struct {
	S3         *s3.Client
	CloudFront *cloudfront.Client
	Config     Config
}

// NewDeployer builds an AWS-backed deployer.
func NewDeployer(cfg Config) (*Deployer, error) {
	if err := ValidateConfig(cfg); err != nil {
		return nil, err
	}
	if strings.TrimSpace(cfg.Region) == "" {
		cfg.Region = DefaultRegion
	}
	creds := credentials.NewStaticCredentialsProvider(cfg.AccessKeyID, cfg.SecretAccessKey, "")
	awsCfg := aws.Config{
		Region:      cfg.Region,
		Credentials: creds,
	}
	return &Deployer{
		S3:         s3.NewFromConfig(awsCfg),
		CloudFront: cloudfront.NewFromConfig(awsCfg),
		Config:     cfg,
	}, nil
}

// Deploy syncs sourceDir to the destination prefix (upload changed, delete orphans),
// then invalidates CloudFront for changed paths when configured.
func (d *Deployer) Deploy(ctx context.Context, sourceDir string) (Result, error) {
	if err := ValidateConfig(d.Config); err != nil {
		return Result{}, err
	}
	st, err := os.Stat(sourceDir)
	if err != nil || !st.IsDir() {
		return Result{}, fmt.Errorf("missing source directory: %s", sourceDir)
	}

	result := Result{
		Bucket: d.Config.Bucket,
		Prefix: d.Config.Prefix,
	}

	log.Printf("s3sync: scanning local tree %s", sourceDir)
	locals, err := listLocalFiles(sourceDir, d.Config.Prefix)
	if err != nil {
		return result, err
	}
	log.Printf("s3sync: local files=%d", len(locals))

	log.Printf("s3sync: listing s3://%s/%s", d.Config.Bucket, d.Config.Prefix)
	remote, err := d.listRemoteObjects(ctx)
	if err != nil {
		return result, err
	}
	log.Printf("s3sync: remote objects=%d", len(remote))

	toUpload, skipped, orphans, err := planSync(locals, remote)
	if err != nil {
		return result, err
	}

	log.Printf(
		"s3sync: plan upload=%d skip=%d delete=%d workers=%d",
		len(toUpload), skipped, len(orphans), d.uploadWorkers(),
	)

	uploaded, err := d.uploadFiles(ctx, toUpload)
	if err != nil {
		return result, err
	}
	result.ObjectsUploaded = uploaded
	result.ObjectsSkipped = skipped
	log.Printf("s3sync: uploaded=%d skipped=%d", uploaded, skipped)

	deleted, err := d.deleteKeys(ctx, orphans)
	if err != nil {
		return result, err
	}
	result.ObjectsDeleted = deleted
	if deleted > 0 {
		log.Printf("s3sync: deleted orphans=%d", deleted)
	}

	if d.Config.CloudfrontDistributionID == "" {
		log.Printf("s3sync: cloudfront skipped (no distribution id)")
		return result, nil
	}
	if uploaded == 0 && deleted == 0 {
		log.Printf("s3sync: cloudfront skipped (no changes)")
		return result, nil
	}

	paths := invalidationPaths(toUpload, orphans)
	log.Printf(
		"s3sync: invalidating cloudfront distribution=%s paths=%d",
		d.Config.CloudfrontDistributionID, len(paths),
	)
	id, n, err := d.invalidatePaths(ctx, paths)
	if err != nil {
		return result, err
	}
	result.CloudfrontInvalidationID = id
	result.CFPathsInvalidated = n
	log.Printf("s3sync: cloudfront invalidation_id=%s paths=%d", id, n)
	return result, nil
}

func (d *Deployer) uploadWorkers() int {
	if d.Config.UploadWorkers > 0 {
		return d.Config.UploadWorkers
	}
	return defaultUploadWorkers
}

func (d *Deployer) invalidatePaths(ctx context.Context, paths []string) (id string, pathCount int, err error) {
	items := paths
	if len(items) == 0 {
		return "", 0, nil
	}
	if len(items) > maxInvalidationPaths {
		log.Printf(
			"s3sync: cloudfront path count %d exceeds %d; falling back to /*",
			len(items), maxInvalidationPaths,
		)
		items = []string{"/*"}
	}
	out, err := d.CloudFront.CreateInvalidation(ctx, &cloudfront.CreateInvalidationInput{
		DistributionId: aws.String(d.Config.CloudfrontDistributionID),
		InvalidationBatch: &cftypes.InvalidationBatch{
			CallerReference: aws.String(fmt.Sprintf("s3sync-%d", time.Now().UnixNano())),
			Paths: &cftypes.Paths{
				Quantity: aws.Int32(int32(len(items))),
				Items:    items,
			},
		},
	})
	if err != nil {
		return "", 0, fmt.Errorf("cloudfront invalidation: %w", err)
	}
	if out.Invalidation == nil || out.Invalidation.Id == nil {
		return "", len(items), nil
	}
	return *out.Invalidation.Id, len(items), nil
}
