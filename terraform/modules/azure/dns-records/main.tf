resource "azurerm_dns_txt_record" "main" {
  for_each = var.txt_records

  name                = each.key
  zone_name           = var.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl

  dynamic "record" {
    for_each = each.value.values
    content {
      value = record.value
    }
  }
}

resource "azurerm_dns_cname_record" "main" {
  for_each = var.cname_records

  name                = each.key
  zone_name           = var.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = each.value.ttl
  record              = each.value.record
}
