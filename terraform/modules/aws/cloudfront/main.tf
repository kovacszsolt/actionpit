locals {
  origin_id              = "s3-${var.name}"
  comment                = coalesce(var.comment, "CloudFront distribution for ${var.name}")
  static_index_fn_suffix = substr(replace(replace(var.name, ".", "-"), "_", "-"), 0, 40)

  use_static_directory_rewrite = var.site_mode == "static_directory" || (var.site_mode == "plain" && var.static_site_index_rewrite)
  use_react_spa_rewrite        = var.site_mode == "react_spa"
  use_viewer_request_rewrite   = local.use_static_directory_rewrite || local.use_react_spa_rewrite
  use_spa_fallback             = var.spa_fallback && var.site_mode != "react_spa"

  viewer_request_rewrite_code = (
    local.use_react_spa_rewrite ?
    file("${path.module}/functions/react_spa_rewrite.js") :
    file("${path.module}/functions/static_site_index_rewrite.js")
  )

  viewer_request_rewrite_comment = (
    local.use_react_spa_rewrite ?
    "Rewrite SPA client routes to /index.html for ${var.name}" :
    "Rewrite extensionless paths to directory index.html for ${var.name}"
  )
}

# Single function resource: site_mode changes update code in place (avoids delete-while-in-use on mode switch).
resource "aws_cloudfront_function" "viewer_request_rewrite" {
  count   = local.use_viewer_request_rewrite ? 1 : 0
  name    = "${local.static_index_fn_suffix}-static-index"
  runtime = "cloudfront-js-2.0"
  comment = local.viewer_request_rewrite_comment
  publish = true
  code    = local.viewer_request_rewrite_code
}

moved {
  from = aws_cloudfront_function.static_site_index_rewrite[0]
  to   = aws_cloudfront_function.viewer_request_rewrite[0]
}

removed {
  from = aws_cloudfront_function.react_spa_rewrite

  lifecycle {
    destroy = true
  }
}

resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.name}-oac"
  description                       = "OAC for ${local.origin_id}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = var.enabled
  is_ipv6_enabled     = var.is_ipv6_enabled
  comment             = local.comment
  default_root_object = var.default_root_object
  price_class         = var.price_class
  aliases             = var.aliases
  tags                = var.tags

  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  default_cache_behavior {
    target_origin_id         = local.origin_id
    viewer_protocol_policy   = var.viewer_protocol_policy
    allowed_methods          = ["GET", "HEAD", "OPTIONS"]
    cached_methods           = ["GET", "HEAD"]
    compress                 = var.compress
    cache_policy_id          = var.cache_policy_id
    origin_request_policy_id = var.origin_request_policy_id

    dynamic "function_association" {
      for_each = local.use_viewer_request_rewrite ? [1] : []

      content {
        event_type   = "viewer-request"
        function_arn = aws_cloudfront_function.viewer_request_rewrite[0].arn
      }
    }
  }

  dynamic "custom_error_response" {
    for_each = local.use_spa_fallback ? toset(["403", "404"]) : []

    content {
      error_code            = tonumber(custom_error_response.value)
      response_code         = 200
      response_page_path    = "/${var.default_root_object}"
      error_caching_min_ttl = 10
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = length(var.aliases) == 0
    acm_certificate_arn            = length(var.aliases) > 0 ? var.acm_certificate_arn : null
    ssl_support_method             = length(var.aliases) > 0 ? "sni-only" : null
    minimum_protocol_version       = length(var.aliases) > 0 ? "TLSv1.2_2021" : null
  }

  lifecycle {
    precondition {
      condition     = length(var.aliases) == 0 || var.acm_certificate_arn != null
      error_message = "acm_certificate_arn is required when aliases is non-empty."
    }
  }
}
