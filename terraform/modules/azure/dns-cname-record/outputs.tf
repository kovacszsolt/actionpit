output "id" {
  description = "CNAME record resource ID."
  value       = azurerm_dns_cname_record.main.id
}

output "fqdn" {
  description = "Full host name (name.zone_name)."
  value       = "${azurerm_dns_cname_record.main.name}.${var.zone_name}"
}
