output "zone_id" {
  description = "Route53 hosted zone ID."
  value       = local.zone_id
}

output "zone_name" {
  description = "Route53 hosted zone name."
  value       = var.zone_name
}

output "name_servers" {
  description = "Delegation name servers for a newly created hosted zone."
  value       = var.create_zone ? aws_route53_zone.main[0].name_servers : null
}

output "alias_record_fqdns" {
  description = "FQDNs of alias records created in the zone."
  value       = { for name, record in aws_route53_record.alias : name => record.fqdn }
}

output "cname_record_fqdns" {
  description = "FQDNs of CNAME records created in the zone."
  value       = { for name, record in aws_route53_record.cname : name => record.fqdn }
}
