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

output "secret_resource_ids" {
  description = "Map of initialized secret names to Azure resource IDs (secret values are never output)."
  value = {
    for i, name in local.secret_keys_sorted : name => azurerm_key_vault_secret.this[i].id
  }
}