output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_resource_id" {
  description = "The Resource ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "secret_names" {
  description = "Names of secrets managed in this Key Vault"
  value       = keys(azurerm_key_vault_secret.main)
}

output "secret_ids" {
  description = "Azure resource IDs of managed secrets, keyed by secret name"
  value       = { for name, secret in azurerm_key_vault_secret.main : name => secret.id }
}

output "secret_uris" {
  description = "Full Key Vault secret URIs for Container App key_vault_secrets references"
  value       = { for name, secret in azurerm_key_vault_secret.main : name => secret.versionless_id }
}