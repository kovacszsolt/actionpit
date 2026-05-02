output "app_id" {
  description = "Container App ID"
  value       = azurerm_container_app.main.id
}

output "app_name" {
  description = "Container App name"
  value       = azurerm_container_app.main.name
}

output "app_fqdn" {
  description = "Fully qualified domain name (FQDN)"
  value       = azurerm_container_app.main.latest_revision_fqdn
}

output "ingress_fqdn" {
  description = "Ingress FQDN (stable app hostname for CNAME targets)"
  value       = try(azurerm_container_app.main.ingress[0].fqdn, null)
}

output "app_url" {
  description = "Application URL (default *.azurecontainerapps.io hostname)"
  value       = "https://${azurerm_container_app.main.latest_revision_fqdn}"
}

output "custom_domain_url" {
  description = "HTTPS URL on the custom hostname when custom_domain is configured"
  value       = var.custom_domain != null ? "https://${var.custom_domain.hostname}" : null
}

output "latest_revision_name" {
  description = "Latest revision name"
  value       = azurerm_container_app.main.latest_revision_name
}

output "identity_principal_id" {
  description = "System Assigned Identity Principal ID (if exists)"
  value       = try(azurerm_container_app.main.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "System Assigned Identity Tenant ID (if exists)"
  value       = try(azurerm_container_app.main.identity[0].tenant_id, null)
}
