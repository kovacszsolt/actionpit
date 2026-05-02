resource "azurerm_email_communication_service_domain" "main" {
  name              = var.domain_name
  email_service_id  = var.email_service_id
  domain_management = "CustomerManaged"

  tags = var.tags
}
