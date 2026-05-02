variable "server_id" {
  description = "Azure PostgreSQL Flexible Server resource ID (azurerm_postgresql_flexible_server.id)."
  type        = string
}

variable "database_name" {
  description = "Primary database name to create on the server."
  type        = string
}

variable "additional_database_names" {
  description = "Extra databases to create on the same server (same charset/collation as the primary)."
  type        = list(string)
  default     = []
}

variable "charset" {
  description = "PostgreSQL charset (Azure is typically UTF8)."
  type        = string
  default     = "UTF8"
}

variable "collation" {
  description = "PostgreSQL collation."
  type        = string
  default     = "en_US.utf8"
}
