resource "azurerm_communication_service" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  data_location       = var.data_location

  tags = var.tags
}

resource "azurerm_communication_service_email_domain_association" "main" {
  count = var.email_service_domain_id != null ? 1 : 0

  communication_service_id = azurerm_communication_service.main.id
  email_service_domain_id  = var.email_service_domain_id
}
