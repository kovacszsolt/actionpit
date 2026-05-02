output "id" {
  description = "Static Web App custom domain resource ID."
  value       = azurerm_static_web_app_custom_domain.main.id
}

output "validation_token" {
  description = "Set only for dns-txt-token until validation completes; empty for cname-delegation."
  value       = azurerm_static_web_app_custom_domain.main.validation_token
  sensitive   = true
}
