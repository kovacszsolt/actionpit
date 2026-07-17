locals {
  subdomain_label   = trimsuffix(var.hostname, ".${var.zone_name}")
  asuid_record_name = "asuid.${local.subdomain_label}"
}
