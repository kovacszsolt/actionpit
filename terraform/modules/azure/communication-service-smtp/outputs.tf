output "smtp_host" {
  description = "ACS SMTP host."
  value       = "smtp.azurecomm.net"
}

output "smtp_port" {
  description = "ACS SMTP port (STARTTLS)."
  value       = 587
}

output "smtp_username" {
  description = "SMTP AUTH username."
  value       = var.smtp_username
}

output "smtp_password" {
  description = "SMTP AUTH password (Entra application client secret)."
  value       = azuread_application_password.smtp.value
  sensitive   = true
}

output "entra_application_id" {
  description = "Entra application (client) ID linked to the SMTP username."
  value       = azuread_application.smtp.client_id
}

output "tenant_id" {
  description = "Entra tenant ID."
  value       = data.azurerm_client_config.current.tenant_id
}

output "smtp_username_resource_id" {
  description = "SmtpUsername ARM resource ID."
  value       = azapi_resource.smtp_username.id
}

output "dotted_smtp_username" {
  description = "Alternate ACS username form: <acsName>.<appId>.<tenantId>."
  value       = "${element(split("/", var.communication_service_id), length(split("/", var.communication_service_id)) - 1)}.${azuread_application.smtp.client_id}.${data.azurerm_client_config.current.tenant_id}"
}
