output "role_assignment_id" {
  description = "The role assignment resource ID"
  value       = azurerm_role_assignment.registry.id
}

output "container_registry_id" {
  description = "Target container registry resource ID"
  value       = data.azurerm_container_registry.target.id
}
