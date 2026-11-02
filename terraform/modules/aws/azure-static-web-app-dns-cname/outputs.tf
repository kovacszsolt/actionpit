output "zone_id" {
  description = "Route53 hosted zone ID."
  value       = module.dns.zone_id
}

output "subdomain_label" {
  description = "Relative DNS label for the CNAME record (e.g. api)."
  value       = local.subdomain_label
}

output "cname_fqdn" {
  description = "FQDN of the CNAME record pointing to the Container App ingress."
  value       = module.dns.cname_record_fqdns[local.subdomain_label]
}

