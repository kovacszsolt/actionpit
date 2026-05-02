resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.database_name
  server_id = var.server_id
  charset   = var.charset
  collation = var.collation
}

resource "azurerm_postgresql_flexible_server_database" "additional" {
  for_each = toset([for n in var.additional_database_names : n if n != var.database_name])

  name      = each.key
  server_id = var.server_id
  charset   = var.charset
  collation = var.collation
}
