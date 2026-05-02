output "identity_id" {
  description = "User Assigned Identity Principal ID (object id); use for AcrPull and other RBAC principal_id"
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "principal_id" {
  description = "Same as identity_id (Azure AD object id of the identity)"
  value       = azurerm_user_assigned_identity.main.principal_id
}

output "identity_client_id" {
  description = "User Assigned Identity Client ID"
  value       = azurerm_user_assigned_identity.main.client_id
}

output "identity_name" {
  description = "User Assigned Identity name"
  value       = azurerm_user_assigned_identity.main.name
}

output "identity_resource_id" {
  description = "User Assigned Identity Resource ID"
  value       = azurerm_user_assigned_identity.main.id
}

output "location" {
  description = "Identity location"
  value       = azurerm_user_assigned_identity.main.location
}
