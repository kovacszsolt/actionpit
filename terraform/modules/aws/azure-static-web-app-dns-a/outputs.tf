output "zone_id" {
  description = "Route53 hosted zone ID."
  value       = module.dns.zone_id
}

output "subdomain_label" {
  description = "Relative DNS label for the A record (e.g. api, or @ for the zone apex)."
  value       = local.subdomain_label
}

output "a_fqdn" {
  description = "FQDN of the A record pointing at a_target."
  value       = module.dns.a_record_fqdns[local.subdomain_label]
}

