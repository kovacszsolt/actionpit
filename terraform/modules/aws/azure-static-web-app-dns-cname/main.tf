locals {
  subdomain_label = trimsuffix(var.hostname, ".${var.zone_name}")
}

module "dns" {
  source = "../route53"

  zone_name   = var.zone_name
  create_zone = false
  zone_id     = var.zone_id

  cname_records = {
    (local.subdomain_label) = {
      ttl    = var.ttl
      record = var.cname_target
    }
  }

  tags = var.tags
}
