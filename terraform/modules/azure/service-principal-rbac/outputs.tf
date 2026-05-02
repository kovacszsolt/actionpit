output "application_id" {
  description = "App registration client ID (same as service principal application ID)."
  value       = azuread_application.this.client_id
}

output "tenant_id" {
  description = "Azure AD tenant ID."
  value       = data.azurerm_client_config.current.tenant_id
}

output "client_secret" {
  description = "Client secret for the application (store as GitHub secret, never commit)."
  value       = azuread_application_password.this.value
  sensitive   = true
}

# Same shape as `az ad sp create-for-rbac ... --sdk-auth` for AZURE_CREDENTIALS in GitHub Actions.
output "azure_credentials_json" {
  description = "JSON for GitHub Actions Azure/login secret AZURE_CREDENTIALS."
  value = jsonencode({
    clientId       = azuread_application.this.client_id
    clientSecret   = azuread_application_password.this.value
    subscriptionId = var.subscription_id
    tenantId       = data.azurerm_client_config.current.tenant_id
  })
  sensitive = true
}

output "service_principal_object_id" {
  description = "Object ID of the service principal (for diagnostics)."
  value       = azuread_service_principal.this.object_id
}
