output "id" {
  description = "Database resource ID."
  value       = azurerm_postgresql_flexible_server_database.main.id
}

output "name" {
  description = "Primary database name."
  value       = azurerm_postgresql_flexible_server_database.main.name
}

output "additional_database_names" {
  description = "Names of extra databases created (additional_database_names input, excluding duplicate of primary)."
  value       = [for k in sort(keys(azurerm_postgresql_flexible_server_database.additional)) : k]
}
