data "azurerm_client_config" "current" {}

resource "azuread_application" "smtp" {
  display_name = var.entra_display_name
}

resource "azuread_service_principal" "smtp" {
  client_id = azuread_application.smtp.client_id
}

resource "azuread_application_password" "smtp" {
  application_id = azuread_application.smtp.id
  display_name   = "smtp"
}

resource "azurerm_role_assignment" "email_sender" {
  scope                = var.communication_service_id
  role_definition_name = "Email Sender"
  principal_id         = azuread_service_principal.smtp.object_id
}

resource "azapi_resource" "smtp_username" {
  type      = "Microsoft.Communication/communicationServices/smtpUsernames@2025-09-01"
  name      = var.smtp_username_resource_name
  parent_id = var.communication_service_id

  body = {
    properties = {
      entraApplicationId = azuread_application.smtp.client_id
      tenantId           = data.azurerm_client_config.current.tenant_id
      username           = var.smtp_username
    }
  }

  depends_on = [azurerm_role_assignment.email_sender]
}
