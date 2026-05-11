output "resource_group_contributor_assignment_id" {
  description = "Role assignment id for Contributor on the deployment resource group."
  value       = azurerm_role_assignment.resource_group_contributor.id
}

output "acr_push_assignment_id" {
  description = "Role assignment id for AcrPush on the container registry."
  value       = azurerm_role_assignment.acr_push.id
}

output "container_registry_id" {
  value = data.azurerm_container_registry.target.id
}
