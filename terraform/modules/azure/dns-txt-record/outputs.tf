output "txt_record_ids" {
  description = "IDs of created azurerm_dns_txt_record resources."
  value       = [for r in azurerm_dns_txt_record.main : r.id]
}
