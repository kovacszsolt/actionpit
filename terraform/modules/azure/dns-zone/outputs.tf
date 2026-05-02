output "id" {
  description = "DNS zone resource ID."
  value       = azurerm_dns_zone.main.id
}

output "name" {
  description = "DNS zone name."
  value       = azurerm_dns_zone.main.name
}

output "name_servers" {
  description = "Azure-assigned name servers for delegation at the registrar."
  value       = azurerm_dns_zone.main.name_servers
}

output "resource_group_name" {
  description = "Resource group containing the zone."
  value       = azurerm_dns_zone.main.resource_group_name
}
