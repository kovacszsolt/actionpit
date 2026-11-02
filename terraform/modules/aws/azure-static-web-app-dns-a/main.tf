locals {
  # "@" is the route53 module's apex marker; trimsuffix alone returns the full
  # hostname when hostname == zone_name.
  subdomain_label = var.hostname == var.zone_name ? "@" : trimsuffix(var.hostname, ".${var.zone_name}")
}

module "dns" {
  source = "../route53"

  zone_name   = var.zone_name
  create_zone = false
  zone_id     = var.zone_id

  a_records = {
    (local.subdomain_label) = {
      ttl     = var.ttl
      records = [var.a_target]
    }
  }

  tags = var.tags
}
