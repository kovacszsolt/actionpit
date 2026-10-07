locals {
  function_name = var.create_lambda ? module.lambda[0].lambda_function_name : var.function_name
  origin_id     = "lambda-${local.function_name}"

  route53_record_name = var.hostname == var.zone_name ? "@" : trimsuffix(var.hostname, ".${var.zone_name}")

  managed_route53_record_names = {
    for hostname in var.managed_hostnames :
    hostname => hostname == var.zone_name ? "@" : trimsuffix(hostname, ".${var.zone_name}")
  }

  cloudfront_aliases = distinct(concat([var.hostname], var.managed_hostnames, var.additional_hostnames))

  alias_records = {
    for name in distinct(concat([local.route53_record_name], values(local.managed_route53_record_names))) :
    name => {
      type                   = "A"
      dns_name               = aws_cloudfront_distribution.main.domain_name
      hosted_zone_id         = aws_cloudfront_distribution.main.hosted_zone_id
      evaluate_target_health = false
    }
  }

  # Managed CloudFront cache / origin request policies for dynamic Lambda HTTP APIs.
  cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
  origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac" # AllViewerExceptHostHeader
}

module "lambda" {
  count  = var.create_lambda ? 1 : 0
  source = "../lambda"

  function_name                  = var.function_name
  description                    = var.description
  package_type                   = var.package_type
  runtime                        = var.runtime
  handler                        = var.handler
  architecture                   = var.architecture
  memory_size                    = var.memory_size
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions
  ephemeral_storage_size         = var.ephemeral_storage_size
  environment_variables          = var.environment_variables
  filename                       = var.filename
  source_code_hash               = var.source_code_hash
  s3_bucket                      = var.s3_bucket
  s3_key                         = var.s3_key
  s3_object_version              = var.s3_object_version
  image_uri                      = var.image_uri
  create_log_group               = var.create_log_group
  log_retention_in_days          = var.log_retention_in_days
  create_execution_role          = var.create_execution_role
  execution_role_arn             = var.execution_role_arn
  execution_role_name            = var.execution_role_name
  managed_policy_arns            = var.managed_policy_arns
  subnet_ids                     = var.subnet_ids
  security_group_ids             = var.security_group_ids
  tags                           = var.tags
}

resource "aws_lambda_function_url" "main" {
  function_name      = local.function_name
  qualifier          = var.function_url_qualifier
  authorization_type = "AWS_IAM"
  invoke_mode        = var.invoke_mode

  dynamic "cors" {
    for_each = var.cors != null ? [var.cors] : []

    content {
      allow_credentials = cors.value.allow_credentials
      allow_headers     = cors.value.allow_headers
      allow_methods     = cors.value.allow_methods
      allow_origins     = cors.value.allow_origins
      expose_headers    = cors.value.expose_headers
      max_age           = cors.value.max_age
    }
  }
}

locals {
  function_url_domain = trimprefix(trimsuffix(aws_lambda_function_url.main.function_url, "/"), "https://")
}

resource "aws_cloudfront_origin_access_control" "main" {
  name                              = "${local.function_name}-lambda-url-oac"
  description                       = "OAC for Lambda function URL ${local.function_name}"
  origin_access_control_origin_type = "lambda"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = coalesce(var.comment, "HTTPS endpoint for ${var.hostname}")
  price_class     = var.price_class
  aliases         = local.cloudfront_aliases
  tags            = var.tags

  origin {
    domain_name              = local.function_url_domain
    origin_id                = local.origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.main.id

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    target_origin_id       = local.origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true
    cache_policy_id          = local.cache_policy_id
    origin_request_policy_id = local.origin_request_policy_id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = module.acm.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

# CloudFront OAC requires both permissions on Function URLs (dual auth, post-Oct 2025).
resource "aws_lambda_permission" "cloudfront_invoke_function_url" {
  statement_id  = "AllowCloudFrontInvokeFunctionUrl"
  action        = "lambda:InvokeFunctionUrl"
  function_name = local.function_name
  qualifier     = var.function_url_qualifier
  principal     = "cloudfront.amazonaws.com"
  source_arn    = aws_cloudfront_distribution.main.arn
}

resource "aws_lambda_permission" "cloudfront_invoke_function" {
  statement_id  = "AllowCloudFrontInvokeFunction"
  action        = "lambda:InvokeFunction"
  function_name = local.function_name
  qualifier     = var.function_url_qualifier
  principal     = "cloudfront.amazonaws.com"
  source_arn    = aws_cloudfront_distribution.main.arn
}

module "acm" {
  source = "../acm"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  domain_name               = var.hostname
  subject_alternative_names = distinct(concat(var.managed_hostnames, var.additional_hostnames))
  zone_id                   = var.zone_id
  dns_validation_domains    = distinct(concat([var.hostname], var.managed_hostnames))
  tags                      = var.tags
}

module "dns" {
  source = "../route53"

  zone_name     = var.zone_name
  create_zone   = false
  zone_id       = var.zone_id
  alias_records = local.alias_records
  tags          = var.tags
}
