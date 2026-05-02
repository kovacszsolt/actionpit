resource "azurerm_static_web_app" "main" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location

  sku_tier = var.sku_tier
  sku_size = var.sku_size

  preview_environments_enabled       = var.preview_environments_enabled
  configuration_file_changes_enabled = var.configuration_file_changes_enabled
  public_network_access_enabled      = var.public_network_access_enabled

  dynamic "basic_auth" {
    for_each = var.basic_auth_password != null ? [1] : []
    content {
      password     = var.basic_auth_password
      environments = var.basic_auth_environments
    }
  }

  tags = var.tags
}
