locals {
  route53_record_name = trimsuffix(var.hostname, ".${var.zone_name}")
}
