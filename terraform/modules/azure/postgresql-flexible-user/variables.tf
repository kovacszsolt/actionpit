variable "server_fqdn" {
  description = "PostgreSQL Flexible Server FQDN."
  type        = string
}

variable "server_port" {
  description = "PostgreSQL server port."
  type        = number
  default     = 5432
}

variable "admin_username" {
  description = "Admin username used for provider connection."
  type        = string
}

variable "admin_password" {
  description = "Admin password used for provider connection."
  type        = string
  sensitive   = true
}

variable "admin_database" {
  description = "Database used for the admin connection."
  type        = string
  default     = "postgres"
}

variable "sslmode" {
  description = "SSL mode for PostgreSQL connection."
  type        = string
  default     = "require"
}

variable "database_name" {
  description = "Database name where access is granted."
  type        = string
}

variable "username" {
  description = "Application username to create."
  type        = string
}

variable "password" {
  description = "Application password. If null, a random one is generated."
  type        = string
  default     = null
  sensitive   = true
}

variable "password_length" {
  description = "Generated password length when password is null."
  type        = number
  default     = 32
}

variable "password_override_special" {
  description = "Allowed special chars for generated password."
  type        = string
  default     = "!#$%&*()-_=+[]{}<>:?"
}

variable "database_privileges" {
  description = "Privileges granted on the target database."
  type        = list(string)
  default     = ["CONNECT", "TEMPORARY"]
}

variable "schema_name" {
  description = "Schema name where schema privileges are granted."
  type        = string
  default     = "public"
}

variable "schema_privileges" {
  description = "Privileges granted on the target schema."
  type        = list(string)
  default     = ["USAGE"]
}

variable "table_privileges" {
  description = "Privileges granted on all tables in the target schema."
  type        = list(string)
  default     = []
}

variable "sequence_privileges" {
  description = "Privileges granted on all sequences in the target schema."
  type        = list(string)
  default     = []
}

variable "function_privileges" {
  description = "Privileges granted on all functions in the target schema."
  type        = list(string)
  default     = []
}
