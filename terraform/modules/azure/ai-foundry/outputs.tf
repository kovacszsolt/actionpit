output "cognitive_account_id" {
  description = "Resource ID of the Azure AI Services (Foundry) account."
  value       = azurerm_cognitive_account.main.id
}

output "name" {
  description = "Cognitive account name."
  value       = azurerm_cognitive_account.main.name
}

output "endpoint" {
  description = "HTTPS endpoint for the Cognitive Services account."
  value       = azurerm_cognitive_account.main.endpoint
}

output "custom_subdomain_name" {
  description = "Custom subdomain when configured."
  value       = azurerm_cognitive_account.main.custom_subdomain_name
}

output "identity_principal_id" {
  description = "Principal ID when SystemAssigned or UserAssigned identity is used on the account."
  value       = try(azurerm_cognitive_account.main.identity[0].principal_id, null)
}

output "identity_tenant_id" {
  description = "Tenant ID for the account managed identity."
  value       = try(azurerm_cognitive_account.main.identity[0].tenant_id, null)
}

output "primary_access_key" {
  description = "Primary API key (only when local_auth_enabled is true)."
  value       = azurerm_cognitive_account.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Secondary API key (only when local_auth_enabled is true)."
  value       = azurerm_cognitive_account.main.secondary_access_key
  sensitive   = true
}

output "project_id" {
  description = "Foundry project resource ID when create_project is true."
  value       = try(azurerm_cognitive_account_project.main[0].id, null)
}

output "project_endpoints" {
  description = "Map of project endpoint names to URLs when a project exists."
  value       = try(azurerm_cognitive_account_project.main[0].endpoints, null)
}

output "project_identity_principal_id" {
  description = "Principal ID of the Foundry project managed identity."
  value       = try(azurerm_cognitive_account_project.main[0].identity[0].principal_id, null)
}

output "diagnostic_setting_id" {
  description = "Monitor diagnostic setting ID when diagnostic_log_analytics_workspace_id is set."
  value       = try(azurerm_monitor_diagnostic_setting.cognitive[0].id, null)
}
