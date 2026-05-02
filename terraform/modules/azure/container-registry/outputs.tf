output "id" {
  description = "The ID of the Container Registry."
  value       = azurerm_container_registry.main.id
}

output "name" {
  description = "The name of the Container Registry."
  value       = azurerm_container_registry.main.name
}

output "resource_group_name" {
  description = "The name of the resource group containing the Container Registry."
  value       = azurerm_container_registry.main.resource_group_name
}

output "location" {
  description = "The Azure location of the Container Registry."
  value       = azurerm_container_registry.main.location
}

output "login_server" {
  description = "The URL that can be used to log into the container registry."
  value       = azurerm_container_registry.main.login_server
}

output "admin_username" {
  description = "The Username associated with the Container Registry Admin account."
  value       = var.admin_enabled ? azurerm_container_registry.main.admin_username : null
  sensitive   = false
}

output "admin_password" {
  description = "The Password associated with the Container Registry Admin account."
  value       = var.admin_enabled ? azurerm_container_registry.main.admin_password : null
  sensitive   = true
}

output "identity" {
  description = "An identity block containing the Managed Service Identity information for this Container Registry."
  value       = azurerm_container_registry.main.identity
}
