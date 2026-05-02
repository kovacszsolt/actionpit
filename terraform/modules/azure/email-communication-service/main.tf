# Azure Email Communication Service (mail service resource).
# Communication Service, managed domain, and domain association are handled in separate modules/steps.

resource "azurerm_email_communication_service" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  data_location       = var.data_location

  tags = var.tags
}
