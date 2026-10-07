locals {
  create_zip   = var.package_type == "Zip"
  create_image = var.package_type == "Image"

  # Deployment package attributes, only meaningful for the selected package type.
  filename          = local.create_zip ? var.filename : null
  source_code_hash  = local.create_zip ? var.source_code_hash : null
  s3_bucket         = local.create_zip ? var.s3_bucket : null
  s3_key            = local.create_zip ? var.s3_key : null
  s3_object_version = local.create_zip ? var.s3_object_version : null
  image_uri         = local.create_image ? var.image_uri : null

  create_vpc_config = length(var.subnet_ids) > 0 && length(var.security_group_ids) > 0

  # Log group ARN used by the least-privilege logging policy attached to the
  # created role. Partition-safe (aws / aws-cn / aws-us-gov).
  log_group_name = "/aws/lambda/${var.function_name}"
  log_group_arn  = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:${local.log_group_name}"
}

data "aws_partition" "current" {}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# IAM execution role
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "assume_role" {
  count = var.create_execution_role ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = var.trusted_service_principals
    }
  }
}

resource "aws_iam_role" "main" {
  count = var.create_execution_role ? 1 : 0

  name               = coalesce(var.execution_role_name, "lambda-${var.function_name}-execution")
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json

  tags = var.tags
}

# Basic CloudWatch Logs permissions (scoped to this function's log group).
data "aws_iam_policy_document" "logging" {
  count = var.create_execution_role ? 1 : 0

  statement {
    sid    = "CloudWatchLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = [
      local.log_group_arn,
      "${local.log_group_arn}:*",
    ]
  }
}

resource "aws_iam_role_policy" "logging" {
  count = var.create_execution_role ? 1 : 0

  name   = "lambda-${var.function_name}-logging"
  role   = aws_iam_role.main[0].id
  policy = data.aws_iam_policy_document.logging[0].json
}

# Additional managed policies supplied by the caller
# (e.g. AWSLambdaVPCAccessExecutionRole, ReadOnlyAccess, custom policy ARNs).
resource "aws_iam_role_policy_attachment" "managed" {
  for_each = var.create_execution_role ? toset(var.managed_policy_arns) : toset([])

  role       = aws_iam_role.main[0].name
  policy_arn = each.value
}

# ---------------------------------------------------------------------------
# CloudWatch log group
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_log_group" "main" {
  count = var.create_log_group ? 1 : 0

  name              = local.log_group_name
  retention_in_days = var.log_retention_in_days

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Lambda function
# ---------------------------------------------------------------------------

resource "aws_lambda_function" "main" {
  function_name                  = var.function_name
  description                    = var.description
  package_type                   = var.package_type
  architectures                  = [var.architecture]
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions

  runtime = local.create_zip ? var.runtime : null
  handler = local.create_zip ? var.handler : null

  filename          = local.filename
  source_code_hash  = local.source_code_hash
  s3_bucket         = local.s3_bucket
  s3_key            = local.s3_key
  s3_object_version = local.s3_object_version

  image_uri = local.image_uri

  role = var.create_execution_role ? aws_iam_role.main[0].arn : var.execution_role_arn

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []

    content {
      variables = var.environment_variables
    }
  }

  dynamic "vpc_config" {
    for_each = local.create_vpc_config ? [1] : []

    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size != 512 ? [1] : []

    content {
      size = var.ephemeral_storage_size
    }
  }

  tags = var.tags

  depends_on = [
    aws_cloudwatch_log_group.main,
    aws_iam_role_policy.logging,
    aws_iam_role_policy_attachment.managed,
  ]
}
