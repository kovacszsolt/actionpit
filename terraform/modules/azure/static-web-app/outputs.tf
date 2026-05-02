output "id" {
  description = "Static Web App resource ID"
  value       = azurerm_static_web_app.main.id
}

output "name" {
  description = "Static Web App name"
  value       = azurerm_static_web_app.main.name
}

output "default_host_name" {
  description = "Default host name of the Static Web App"
  value       = azurerm_static_web_app.main.default_host_name
}

output "api_key" {
  description = "API key for deployment (e.g. GitHub Actions)"
  value       = azurerm_static_web_app.main.api_key
  sensitive   = true
}
