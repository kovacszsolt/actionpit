output "id" {
  description = "Email Communication Service domain resource ID."
  value       = azurerm_email_communication_service_domain.main.id
}

output "name" {
  description = "Configured custom domain."
  value       = azurerm_email_communication_service_domain.main.name
}

output "mail_from_sender_domain" {
  description = "Suggested sender domain for ACS email sending."
  value       = azurerm_email_communication_service_domain.main.mail_from_sender_domain
}

output "from_sender_domain" {
  description = "Alternative sender domain value from provider."
  value       = azurerm_email_communication_service_domain.main.from_sender_domain
}

output "verification_records" {
  description = "DNS verification payloads from Azure (domain / SPF / DKIM blocks); use for CustomerManaged DNS."
  value       = azurerm_email_communication_service_domain.main.verification_records
}
