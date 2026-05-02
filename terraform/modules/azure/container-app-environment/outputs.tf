output "environment_id" {
  description = "Container App Environment ID"
  value       = azurerm_container_app_environment.main.id
}

output "environment_name" {
  description = "Container App Environment name"
  value       = azurerm_container_app_environment.main.name
}

output "default_domain" {
  description = "Default FQDN"
  value       = azurerm_container_app_environment.main.default_domain
}

output "static_ip_address" {
  description = "Static IP address"
  value       = azurerm_container_app_environment.main.static_ip_address
}

output "location" {
  description = "Environment location"
  value       = azurerm_container_app_environment.main.location
}
