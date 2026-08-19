locals {
  route53_record_name = var.hostname == var.zone_name ? "@" : trimsuffix(var.hostname, ".${var.zone_name}")

  managed_route53_record_names = {
    for h in var.managed_hostnames :
    h => h == var.zone_name ? "@" : trimsuffix(h, ".${var.zone_name}")
  }

  cloudfront_aliases = distinct(concat([var.hostname], var.managed_hostnames, var.additional_hostnames))

  alias_records = {
    for name in distinct(concat([local.route53_record_name], values(local.managed_route53_record_names))) :
    name => {
      type                   = "A"
      dns_name               = module.cloudfront.domain_name
      hosted_zone_id         = module.cloudfront.hosted_zone_id
      evaluate_target_health = false
    }
  }
}

module "s3" {
  source = "../s3"

  bucket_name        = var.bucket_name
  versioning_enabled = var.versioning_enabled
  force_destroy      = var.force_destroy
  tags               = var.tags
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

module "cloudfront" {
  source = "../cloudfront"

  name                            = var.bucket_name
  comment                         = "CloudFront for ${var.hostname}"
  s3_bucket_regional_domain_name  = module.s3.bucket_domain_name
  default_root_object             = var.default_root_object
  site_mode                       = var.site_mode
  spa_fallback                    = var.spa_fallback
  static_site_index_rewrite       = var.static_site_index_rewrite
  price_class                     = var.price_class
  aliases                         = local.cloudfront_aliases
  acm_certificate_arn             = module.acm.certificate_arn
  tags                            = var.tags
}

module "s3_cloudfront_oac" {
  source = "../s3-cloudfront-oac-policy"

  bucket_name                  = module.s3.id
  cloudfront_distribution_arns = [module.cloudfront.arn]
}

module "dns" {
  source = "../route53"

  zone_name   = var.zone_name
  create_zone = false
  zone_id     = var.zone_id
  alias_records = local.alias_records
  tags          = var.tags
}
