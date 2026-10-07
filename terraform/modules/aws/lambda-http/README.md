# aws/lambda-http

Reusable Terraform module for a **public HTTPS API** backed by AWS Lambda.

It composes:

| Piece | Module / resource | Role |
| --- | --- | --- |
| Lambda function | `../lambda` (optional) | Compute |
| Function URL | `aws_lambda_function_url` | HTTP runtime entry (`AWS_IAM`) |
| CloudFront + OAC | `aws_cloudfront_distribution` | Custom domain, TLS, hides direct URL |
| ACM | `../acm` | Certificate for the custom hostname(s) |
| Route53 | `../route53` | Alias record(s) to CloudFront |

Designed for Go handlers using `github.com/aws/aws-lambda-go/lambdaurl` (`invoke_mode = RESPONSE_STREAM` by default).

## Requirements

| Name | Version |
| --- | --- |
| Terraform | >= 1.9.0 |
| hashicorp/aws provider | >= 6.0 |

The caller must configure a default `aws` provider (Lambda / Route53 region) **and** an `aws.us_east_1` alias (ACM + CloudFront certificate).

```hcl
provider "aws" {
  region = "eu-north-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
```

## Usage

### New Lambda + custom domain

```hcl
module "scanner_api" {
  source = "../../terraform/modules/aws/lambda-http"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  function_name = "dolgozatmester-scanner-lambda"
  description   = "Exam scanner HTTP API"

  package_type     = "Zip"
  runtime          = "provided.al2023"
  handler          = "bootstrap"
  filename         = "${path.module}/dist/scanner-lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/dist/scanner-lambda.zip")

  architecture          = "arm64"
  memory_size           = 512
  timeout               = 60
  log_retention_in_days = 30
  invoke_mode           = "RESPONSE_STREAM"

  hostname  = "api.scanner.dolgozatmester.online"
  zone_name = "dolgozatmester.online"
  zone_id   = dependency.route53.outputs.zone_id

  cors = {
    allow_origins = ["https://scanner.dolgozatmester.online"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["content-type", "authorization"]
  }

  tags = {
    Project = "dolgozatmester"
  }
}
```

After apply:

```bash
curl https://api.scanner.dolgozatmester.online/
```

### Existing Lambda (HTTP layer only)

When the function is already managed elsewhere (e.g. a separate `aws/lambda` stack), set `create_lambda = false`:

```hcl
module "scanner_api" {
  source = "../../terraform/modules/aws/lambda-http"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  create_lambda = false
  function_name = "dolgozatmester-scanner-lambda"
  invoke_mode   = "RESPONSE_STREAM"

  hostname  = "api.scanner.dolgozatmester.online"
  zone_name = "dolgozatmester.online"
  zone_id   = var.zone_id
}
```

## What it creates

| Resource | Always? | Notes |
| --- | --- | --- |
| `aws_lambda_function` | optional | Via `../lambda` when `create_lambda = true` |
| `aws_lambda_function_url` | yes | `authorization_type = AWS_IAM`, not publicly callable |
| `aws_cloudfront_distribution` | yes | Custom domain, caching disabled |
| `aws_cloudfront_origin_access_control` | yes | Lambda URL origin (SigV4) |
| `aws_lambda_permission` (×2) | yes | `InvokeFunctionUrl` + `InvokeFunction` for CloudFront OAC |
| ACM certificate + validation | yes | us-east-1 |
| Route53 alias record(s) | yes | Primary hostname + `managed_hostnames` |

## Notable inputs

| Variable | Default | Purpose |
| --- | --- | --- |
| `hostname` | required | Public FQDN (e.g. `api.scanner.example.com`) |
| `zone_name` / `zone_id` | required | Route53 zone for DNS + ACM validation |
| `create_lambda` | `true` | Set `false` to attach HTTP layer to an existing function |
| `function_name` | required | Lambda name (created or existing) |
| `invoke_mode` | `RESPONSE_STREAM` | Use for `lambdaurl.Start` in Go |
| `cors` | `null` | Optional Function URL CORS block |
| `additional_hostnames` | `[]` | Extra CloudFront aliases / SANs (DNS managed outside) |
| `managed_hostnames` | `[]` | Extra aliases with Route53 records in `zone_id` |

All `../lambda` deployment variables (`package_type`, `runtime`, `handler`, `filename`, …) apply when `create_lambda = true`.

## Notes & constraints

- The direct Function URL is **not** meant for public use; clients call the custom domain via CloudFront.
- CloudFront uses managed policies **CachingDisabled** and **AllViewerExceptHostHeader** (API-friendly defaults).
- Function URLs created after October 2025 require **both** `lambda:InvokeFunctionUrl` and `lambda:InvokeFunction` for CloudFront OAC; this module grants both.
- Build the deployment ZIP before `plan`/`apply` when using Zip packages (`source_code_hash` is evaluated at parse time in Terragrunt call sites).
- For VPC-attached Lambdas, pass `subnet_ids`, `security_group_ids`, and attach `AWSLambdaVPCAccessExecutionRole` via `managed_policy_arns`.
