output "virtual_network_id" {
  description = "Virtual network resource ID."
  value       = azurerm_virtual_network.main.id
}

output "virtual_network_name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.main.name
}

output "cae_subnet_id" {
  description = "Subnet ID for azurerm_container_app_environment.infrastructure_subnet_id."
  value       = azurerm_subnet.cae.id
}

output "postgresql_subnet_id" {
  description = "Delegated subnet ID for azurerm_postgresql_flexible_server.delegated_subnet_id."
  value       = azurerm_subnet.postgresql.id
}

output "postgresql_private_dns_zone_id" {
  description = "Private DNS zone ID for azurerm_postgresql_flexible_server.private_dns_zone_id."
  value       = azurerm_private_dns_zone.postgresql.id
}

output "jump_subnet_id" {
  description = "Non-delegated subnet ID for jump VM (SSH tunnel to private resources). Null if jump subnet not created."
  value       = length(var.jump_subnet_address_prefixes) > 0 ? azurerm_subnet.jump[0].id : null
}
