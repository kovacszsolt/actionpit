output "custom_domain_id" {
  description = "azurerm_static_web_app_custom_domain.apex id"
  value       = azurerm_static_web_app_custom_domain.apex.id
}

output "stable_inbound_ip" {
  description = "IPv4 used for the apex A record (from override or ARM)."
  value       = local.stable_ip
}
