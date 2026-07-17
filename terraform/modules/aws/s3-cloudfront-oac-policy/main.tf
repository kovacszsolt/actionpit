data "aws_s3_bucket" "main" {
  bucket = var.bucket_name
}

data "aws_iam_policy_document" "cloudfront_read" {
  statement {
    sid    = "AllowCloudFrontServicePrincipalReadOnly"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "${data.aws_s3_bucket.main.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = var.cloudfront_distribution_arns
    }
  }
}

resource "aws_s3_bucket_policy" "cloudfront_read" {
  bucket = data.aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.cloudfront_read.json
}
