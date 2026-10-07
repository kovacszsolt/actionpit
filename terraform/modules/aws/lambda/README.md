# aws/lambda

Generic, reusable Terraform module for an AWS Lambda function.
It contains no application-, environment-, region- or account-specific
configuration; everything is driven by input variables and the provider
configuration inherited from the caller.

## Requirements

| Name | Version |
| --- | --- |
| Terraform | >= 1.9.0 |
| hashicorp/aws provider | >= 6.0 (Lambda functions use the provider 6 `function_name` argument) |

## What it creates

| Resource | Always? | Notes |
| --- | --- | --- |
| `aws_lambda_function` | yes | Zip (`filename` or `s3_bucket`/`s3_key`) or container image deployment |
| `aws_iam_role` + logging policy | by default | Skip with `create_execution_role = false` + `execution_role_arn`; extra policies via `managed_policy_arns` |
| `aws_cloudwatch_log_group` | by default | Named `/aws/lambda/<function_name>` with configurable retention; skip with `create_log_group = false` |

## Usage

### ZIP-based function (created role)

```hcl
module "lambda_example" {
  source = "../../terraform/modules/aws/lambda" # adjust path

  function_name = "example-worker"
  description   = "Example worker function"

  package_type = "Zip"
  runtime      = "nodejs20.x"
  handler      = "index.handler"
  filename     = "${path.module}/dist/function.zip"
  source_code_hash = filebase64sha256("${path.module}/dist/function.zip")

  architecture             = "arm64"
  memory_size              = 512
  timeout                  = 60
  reserved_concurrent_executions = -1

  environment_variables = {
    LOG_LEVEL = "info"
  }

  log_retention_in_days = 30

  managed_policy_arns = [] # e.g. custom S3/SQS access policies

  tags = {
    Project = "example"
  }
}
```

### Container image function

```hcl
module "lambda_image" {
  source = "../../terraform/modules/aws/lambda"

  function_name = "example-image"

  package_type = "Image"
  image_uri    = "123456789012.dkr.ecr.eu-west-1.amazonaws.com/example:1.0.0"

  architecture = "x86_64"
  memory_size  = 1024
  timeout      = 300
}
```

### VPC-attached function with a pre-existing role

```hcl
module "lambda_vpc" {
  source = "../../terraform/modules/aws/lambda"

  function_name = "example-vpc"

  package_type = "Zip"
  runtime      = "python3.12"
  handler      = "main.handler"
  filename     = "${path.module}/dist/function.zip"

  subnet_ids         = ["subnet-0123456789abcdef0", "subnet-0123456789abcdef1"]
  security_group_ids = ["sg-0123456789abcdef0"]

  create_execution_role = false
  execution_role_arn    = aws_iam_role.existing.arn # role must allow lambda.amazonaws.com
}
```

## Notable inputs

| Variable | Default | Purpose |
| --- | --- | --- |
| `function_name` | required | Function name (no auto-prefixing; add your own) |
| `package_type` | `"Zip"` | `"Zip"` or `"Image"` |
| `runtime` / `handler` | `null` | Required for Zip |
| `image_uri` | `null` | Required for Image |
| `architecture` | `"arm64"` | `arm64` or `x86_64` |
| `memory_size` | `512` | 128–10240 MB |
| `timeout` | `60` | 1–900 s |
| `reserved_concurrent_executions` | `-1` | `-1` = unrestricted |
| `ephemeral_storage_size` | `512` | 512–10240 MiB |
| `environment_variables` | `{}` | Plain `map(string)` |
| `log_retention_in_days` | `14` | CloudWatch log retention |
| `create_execution_role` | `true` | Set `false` to bring your own role |
| `managed_policy_arns` | `[]` | Extra managed policies for the created role |
| `subnet_ids` / `security_group_ids` | `[]` | Provide both to enable VPC config |
| `tags` | `{}` | Applied to all taggable resources |

## Notes & constraints

- VPC-attached functions need `ec2:CreateNetworkInterface` etc. on their role:
  pass `arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole`
  in `managed_policy_arns` (created role) or include it on your existing role.
- Container images must already exist in ECR in the same region/account as the
  provider (build/push is out of scope for this module).
- For Zip packages, set `source_code_hash` (e.g. `filebase64sha256(...)`) so
  code changes trigger a redeployment.
- The created role grants only scoped CloudWatch Logs permissions plus whatever
  you attach via `managed_policy_arns` (least privilege).