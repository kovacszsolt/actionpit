locals {
  route53_record_name = trimsuffix(var.hostname, ".${var.zone_name}")
  managed_route53_record_names = {
    for h in var.managed_hostnames :
    h => trimsuffix(h, ".${var.zone_name}")
  }
}
