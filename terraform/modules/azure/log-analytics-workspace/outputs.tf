output "workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}

output "workspace_name" {
  description = "Log Analytics Workspace name"
  value       = azurerm_log_analytics_workspace.main.name
}

output "workspace_primary_shared_key" {
  description = "Primary shared key (sensitive)"
  value       = azurerm_log_analytics_workspace.main.primary_shared_key
  sensitive   = true
}

output "workspace_secondary_shared_key" {
  description = "Secondary shared key (sensitive)"
  value       = azurerm_log_analytics_workspace.main.secondary_shared_key
  sensitive   = true
}

output "workspace_workspace_id" {
  description = "Workspace (Customer) ID"
  value       = azurerm_log_analytics_workspace.main.workspace_id
}

