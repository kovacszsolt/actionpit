resource "azurerm_container_app_environment_storage" "main" {
  name                         = var.name
  container_app_environment_id = var.container_app_environment_id
  account_name                 = var.storage_account_name
  access_key                   = var.storage_account_access_key
  share_name                   = var.file_share_name
  access_mode                  = var.access_mode
}
