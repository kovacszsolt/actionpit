output "id" {
  description = "The ID of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.id
}

output "name" {
  description = "The name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.name
}

output "fqdn" {
  description = "The FQDN of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "resource_group_name" {
  description = "The resource group name of the server."
  value       = azurerm_postgresql_flexible_server.main.resource_group_name
}

output "administrator_login" {
  description = "The administrator login name."
  value       = var.administrator_login
}

output "administrator_password" {
  description = "The administrator password (set or auto-generated). Retrieve with: terraform output -raw administrator_password"
  value       = local.administrator_password
  sensitive   = true
}
