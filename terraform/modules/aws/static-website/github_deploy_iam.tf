locals {
  github_deploy_iam_user_name = coalesce(var.github_deploy_iam_user_name, "github-${var.bucket_name}-deploy")
}

resource "aws_iam_user" "github_deploy" {
  name = local.github_deploy_iam_user_name
  path = "/"

  tags = merge(var.tags, { Purpose = "github-actions-deploy" })
}

data "aws_iam_policy_document" "github_deploy" {
  statement {
    sid    = "S3Deploy"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      module.s3.arn,
      "${module.s3.arn}/*",
    ]
  }

  statement {
    sid    = "CloudFrontInvalidate"
    effect = "Allow"

    actions = [
      "cloudfront:CreateInvalidation",
    ]

    resources = [
      module.cloudfront.arn,
    ]
  }
}

resource "aws_iam_policy" "github_deploy" {
  name        = "${local.github_deploy_iam_user_name}-policy"
  description = "GitHub Actions deploy to ${var.bucket_name} and CloudFront invalidation."
  policy      = data.aws_iam_policy_document.github_deploy.json

  tags = var.tags
}

resource "aws_iam_user_policy_attachment" "github_deploy" {
  user       = aws_iam_user.github_deploy.name
  policy_arn = aws_iam_policy.github_deploy.arn
}

resource "aws_iam_access_key" "github_deploy" {
  user = aws_iam_user.github_deploy.name
}
