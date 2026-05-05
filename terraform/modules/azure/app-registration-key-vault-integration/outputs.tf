output "tenant_id" {
  description = "Microsoft Entra tenant ID — Infisical \"Tenant ID\" field."
  value       = data.azurerm_client_config.current.tenant_id
}

output "client_id" {
  description = "Application (client) ID — Infisical \"Client ID\" field."
  value       = azuread_application.this.client_id
}

output "client_secret" {
  description = "Client secret value — Infisical \"Client Secret\" field. Store securely; Terraform state is sensitive."
  value       = azuread_application_password.this.value
  sensitive   = true
}

output "service_principal_object_id" {
  description = "Entra object ID of the service principal (for diagnostics and manual RBAC/policy)."
  value       = azuread_service_principal.this.object_id
}

output "azure_credentials_json" {
  description = "Same shape as az ad sp create-for-rbac --sdk-auth (GitHub AZURE_CREDENTIALS-style)."
  value = jsonencode({
    clientId       = azuread_application.this.client_id
    clientSecret   = azuread_application_password.this.value
    subscriptionId = var.subscription_id
    tenantId       = data.azurerm_client_config.current.tenant_id
  })
  sensitive = true
}
