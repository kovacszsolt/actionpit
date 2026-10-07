locals {
  subdomain_label   = trimsuffix(var.hostname, ".${var.zone_name}")
  asuid_record_name = "asuid.${local.subdomain_label}"
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

  txt_records = {
    (local.asuid_record_name) = {
      ttl     = var.ttl
      records = [var.asuid_verification_id]
    }
  }

  tags = var.tags
}
