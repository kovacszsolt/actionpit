output "username" {
  description = "Created PostgreSQL username."
  value       = postgresql_role.app_user.name
}

output "password" {
  description = "Created or generated PostgreSQL user password."
  value       = local.resolved_password
  sensitive   = true
}
