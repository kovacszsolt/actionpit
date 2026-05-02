output "id" {
  description = "Resource ID of the DocumentDB Mongo cluster."
  value       = azapi_resource.mongo_cluster.id
}

output "name" {
  description = "Name of the cluster."
  value       = azapi_resource.mongo_cluster.name
}

output "resource_id" {
  description = "Azure resource ID (same as id)."
  value       = azapi_resource.mongo_cluster.id
}

output "location" {
  description = "Azure region of the cluster."
  value       = azapi_resource.mongo_cluster.location
}

# Connection endpoint pattern: <cluster-name>.mongocluster.cosmos.azure.com (use with listMongoClusterConnectionStrings or portal for full connection string)
output "connection_host" {
  description = "MongoDB connection host (cluster FQDN). Use with administrator credentials; full connection string from portal or list connection strings API."
  value       = "${azapi_resource.mongo_cluster.name}.mongocluster.cosmos.azure.com"
}

output "firewall_rule_ids" {
  description = "Map of firewall rule names to resource IDs."
  value       = { for k, r in azapi_resource.firewall_rule : k => r.id }
}

output "user_ids" {
  description = "Map of user names to resource IDs."
  value       = { for k, r in azapi_resource.user : k => r.id }
}
