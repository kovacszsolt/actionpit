# CloudFront flat-rate plans require a CLOUDFRONT-scope web ACL. Managed rule groups
# are not eligible for plans; keep a single IP rate-limit rule (within Free's 5-rule cap).

resource "aws_wafv2_web_acl" "pricing_plan" {
  count    = local.use_flat_rate_plan ? 1 : 0
  provider = aws.us_east_1

  name        = "${var.bucket_name}-cf-plan"
  description = "WAF for CloudFront ${var.pricing_plan} plan on ${var.hostname}"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "RateLimitByIP"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitByIP"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.bucket_name}-cf-plan"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}
