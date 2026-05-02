output "deployment_ids" {
  description = "Map of logical keys (e.g. gpt_52) to Cognitive deployment resource IDs."
  value       = { for k, v in azurerm_cognitive_deployment.main : k => v.id }
}

output "deployment_resource_names" {
  description = "Map of logical keys to deployment names (used in OpenAI REST URLs under /deployments/{name}/)."
  value       = { for k, v in azurerm_cognitive_deployment.main : k => v.name }
}
