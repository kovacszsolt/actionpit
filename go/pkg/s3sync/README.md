# s3sync

Sync a local directory to an S3 prefix (upload changed objects, delete orphans) and optionally invalidate CloudFront.

## Module

```
github.com/kovacszsolt/actionpit/go/pkg/s3sync
```

## Usage

```go
import "github.com/kovacszsolt/actionpit/go/pkg/s3sync"

cfg := s3sync.Config{
    Bucket:          "my-bucket",
    Prefix:          s3sync.NormalizePrefix("staging"),
    Region:          s3sync.NormalizeRegion(region, s3sync.DefaultRegion),
    AccessKeyID:     accessKey,
    SecretAccessKey: secret,
    UploadWorkers:   s3sync.ParseUploadWorkers(os.Getenv("S3_UPLOAD_WORKERS")),
}
deployer, err := s3sync.NewDeployer(cfg)
if err != nil {
    return err
}
result, err := deployer.Deploy(ctx, "./public")
```

## Local development

```go
require github.com/kovacszsolt/actionpit/go/pkg/s3sync v0.0.0

replace github.com/kovacszsolt/actionpit/go/pkg/s3sync => ../path/to/actionpit/go/pkg/s3sync
```
