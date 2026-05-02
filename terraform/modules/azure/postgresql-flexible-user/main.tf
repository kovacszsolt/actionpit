provider "postgresql" {
  host            = var.server_fqdn
  port            = var.server_port
  database        = var.admin_database
  username        = var.admin_username
  password        = var.admin_password
  sslmode         = var.sslmode
  connect_timeout = 15
  superuser       = false
}

resource "random_password" "user_password" {
  count = var.password == null ? 1 : 0

  length           = var.password_length
  special          = true
  override_special = var.password_override_special
}

locals {
  resolved_password = coalesce(var.password, try(random_password.user_password[0].result, null))
}

resource "postgresql_role" "app_user" {
  name            = var.username
  login           = true
  password        = local.resolved_password
  create_database = false
  create_role     = false
  inherit         = true
}

resource "postgresql_grant" "database_grant" {
  database    = var.database_name
  role        = postgresql_role.app_user.name
  object_type = "database"
  privileges  = var.database_privileges
}

resource "postgresql_grant" "schema_grant" {
  database    = var.database_name
  schema      = var.schema_name
  role        = postgresql_role.app_user.name
  object_type = "schema"
  privileges  = var.schema_privileges
}

resource "postgresql_grant" "table_grant" {
  count = length(var.table_privileges) > 0 ? 1 : 0

  database    = var.database_name
  schema      = var.schema_name
  role        = postgresql_role.app_user.name
  object_type = "table"
  privileges  = var.table_privileges
}

resource "postgresql_grant" "sequence_grant" {
  count = length(var.sequence_privileges) > 0 ? 1 : 0

  database    = var.database_name
  schema      = var.schema_name
  role        = postgresql_role.app_user.name
  object_type = "sequence"
  privileges  = var.sequence_privileges
}

resource "postgresql_grant" "function_grant" {
  count = length(var.function_privileges) > 0 ? 1 : 0

  database    = var.database_name
  schema      = var.schema_name
  role        = postgresql_role.app_user.name
  object_type = "function"
  privileges  = var.function_privileges
}
