resource "azurerm_dns_txt_record" "main" {
  for_each = var.txt_records

  name                = each.key
  resource_group_name = var.resource_group_name
  zone_name           = var.zone_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.values
    content {
      value = record.value
    }
  }
}
