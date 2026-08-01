data "aws_caller_identity" "current" {
  count = var.enable_inbound ? 1 : 0
}

locals {
  inbound_recipients = coalesce(var.inbound_recipients, [var.domain_name])

  inbound_rule_set_name = coalesce(
    var.inbound_rule_set_name,
    "inbound-${replace(var.domain_name, ".", "-")}",
  )
}

resource "aws_s3_bucket" "inbound" {
  count = var.enable_inbound ? 1 : 0

  bucket = var.inbound_bucket_name

  tags = merge(var.tags, { Purpose = "ses-inbound" })

  lifecycle {
    precondition {
      condition     = var.inbound_bucket_name != null && var.inbound_bucket_name != ""
      error_message = "inbound_bucket_name is required when enable_inbound is true."
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "inbound" {
  count = var.enable_inbound ? 1 : 0

  bucket = aws_s3_bucket.inbound[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_ownership_controls" "inbound" {
  count = var.enable_inbound ? 1 : 0

  bucket = aws_s3_bucket.inbound[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "inbound" {
  count = var.enable_inbound ? 1 : 0

  bucket = aws_s3_bucket.inbound[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "inbound" {
  count = var.enable_inbound && var.inbound_expiration_days != null ? 1 : 0

  bucket = aws_s3_bucket.inbound[0].id

  rule {
    id     = "expire-inbound-mail"
    status = "Enabled"

    filter {
      prefix = var.inbound_object_key_prefix
    }

    expiration {
      days = var.inbound_expiration_days
    }
  }
}

data "aws_iam_policy_document" "inbound_ses_put" {
  count = var.enable_inbound ? 1 : 0

  statement {
    sid    = "AllowSESPuts"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.inbound[0].arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:Referer"
      values   = [data.aws_caller_identity.current[0].account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "inbound" {
  count = var.enable_inbound ? 1 : 0

  bucket = aws_s3_bucket.inbound[0].id
  policy = data.aws_iam_policy_document.inbound_ses_put[0].json

  depends_on = [
    aws_s3_bucket_public_access_block.inbound,
    aws_s3_bucket_ownership_controls.inbound,
  ]
}

resource "aws_ses_receipt_rule_set" "inbound" {
  count = var.enable_inbound ? 1 : 0

  rule_set_name = local.inbound_rule_set_name
}

resource "aws_ses_active_receipt_rule_set" "inbound" {
  count = var.enable_inbound ? 1 : 0

  rule_set_name = aws_ses_receipt_rule_set.inbound[0].rule_set_name
}

resource "aws_ses_receipt_rule" "store_to_s3" {
  count = var.enable_inbound ? 1 : 0

  name          = var.inbound_rule_name
  rule_set_name = aws_ses_receipt_rule_set.inbound[0].rule_set_name
  recipients    = local.inbound_recipients
  enabled       = true
  scan_enabled  = true

  s3_action {
    bucket_name       = aws_s3_bucket.inbound[0].id
    object_key_prefix = var.inbound_object_key_prefix
    position          = 1
  }

  depends_on = [
    aws_s3_bucket_policy.inbound,
    aws_ses_active_receipt_rule_set.inbound,
  ]
}

resource "aws_route53_record" "inbound_mx" {
  count = var.enable_inbound ? 1 : 0

  zone_id = var.zone_id
  name    = var.domain_name
  type    = "MX"
  ttl     = 600
  records = ["10 inbound-smtp.${data.aws_region.current.name}.amazonaws.com"]
}
