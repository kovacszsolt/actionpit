output "app_id" {
  description = "Container App ID"
  value       = module.app.app_id
}

output "app_name" {
  description = "Container App name"
  value       = module.app.app_name
}

output "app_fqdn" {
  description = "Fully qualified domain name (FQDN)"
  value       = module.app.app_fqdn
}

output "ingress_fqdn" {
  description = "Ingress FQDN (stable app hostname for CNAME targets)"
  value       = module.app.ingress_fqdn
}

output "app_url" {
  description = "Application URL (default *.azurecontainerapps.io hostname)"
  value       = module.app.app_url
}

output "custom_domain_url" {
  description = "HTTPS URL on the custom hostname when custom_domain is configured"
  value       = module.app.custom_domain_url
}

output "latest_revision_name" {
  description = "Latest revision name"
  value       = module.app.latest_revision_name
}

output "identity_principal_id" {
  description = "System Assigned Identity Principal ID (if exists)"
  value       = module.app.identity_principal_id
}

output "identity_tenant_id" {
  description = "System Assigned Identity Tenant ID (if exists)"
  value       = module.app.identity_tenant_id
}

output "cpu_alert_id" {
  description = "Resource ID of the CPU metric alert when alerts are enabled."
  value       = length(module.alerts) > 0 ? module.alerts[0].cpu_alert_id : null
}

output "memory_alert_id" {
  description = "Resource ID of the Memory metric alert when alerts are enabled."
  value       = length(module.alerts) > 0 ? module.alerts[0].memory_alert_id : null
}

output "replica_alert_id" {
  description = "Resource ID of the replica count metric alert when alerts are enabled."
  value       = length(module.alerts) > 0 ? module.alerts[0].replica_alert_id : null
}
