output "id" {
  description = "Communication Service resource ID."
  value       = azurerm_communication_service.main.id
}

output "name" {
  value = azurerm_communication_service.main.name
}

output "hostname" {
  description = "Service hostname."
  value       = azurerm_communication_service.main.hostname
}

output "primary_connection_string" {
  description = "Primary connection string (e.g. SMS, voice; also used when linking email domains)."
  value       = azurerm_communication_service.main.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  value     = azurerm_communication_service.main.secondary_connection_string
  sensitive = true
}

output "primary_key" {
  value     = azurerm_communication_service.main.primary_key
  sensitive = true
}

output "secondary_key" {
  value     = azurerm_communication_service.main.secondary_key
  sensitive = true
}

output "email_domain_association_id" {
  description = "Association resource ID when an email domain is linked."
  value       = try(azurerm_communication_service_email_domain_association.main[0].id, null)
}
