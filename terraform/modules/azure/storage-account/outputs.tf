output "id" {
  description = "The ID of the Storage Account."
  value       = azurerm_storage_account.main.id
}

output "name" {
  description = "The name of the Storage Account."
  value       = azurerm_storage_account.main.name
}

output "primary_blob_endpoint" {
  description = "The primary Blob endpoint."
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "primary_blob_host" {
  description = "The primary Blob host."
  value       = azurerm_storage_account.main.primary_blob_host
}

output "primary_connection_string" {
  description = "The primary connection string."
  value       = azurerm_storage_account.main.primary_connection_string
  sensitive   = true
}

output "primary_access_key" {
  description = "The primary access key."
  value       = azurerm_storage_account.main.primary_access_key
  sensitive   = true
}

output "file_share_ids" {
  description = "IDs of the Azure File Shares created in this storage account."
  value       = { for k, v in azurerm_storage_share.shares : k => v.id }
}

output "file_share_names" {
  description = "Names of the Azure File Shares created in this storage account."
  value       = keys(azurerm_storage_share.shares)
}

output "blob_container_ids" {
  description = "IDs of blob containers created in this storage account."
  value       = { for k, v in azurerm_storage_container.blobs : k => v.id }
}

output "blob_container_names" {
  description = "Names of blob containers created in this storage account."
  value       = keys(azurerm_storage_container.blobs)
}

