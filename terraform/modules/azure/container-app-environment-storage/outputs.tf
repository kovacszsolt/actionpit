output "name" {
  description = "Storage mount name (use as template.volume.storage_name)."
  value       = azurerm_container_app_environment_storage.main.name
}

output "id" {
  description = "Resource ID of the CAE storage binding."
  value       = azurerm_container_app_environment_storage.main.id
}
