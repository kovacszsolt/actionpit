output "namespace_id" {
  description = "Azure resource ID of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.main.id
}

output "namespace_name" {
  description = "Name of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.main.name
}

output "endpoint" {
  description = "HTTPS endpoint URL for the namespace (as returned by Azure)."
  value       = azurerm_servicebus_namespace.main.endpoint
}

output "default_primary_connection_string" {
  description = "Primary namespace-level connection string (RootManageSharedAccessKey)."
  value       = azurerm_servicebus_namespace.main.default_primary_connection_string
  sensitive   = true
}

output "default_secondary_connection_string" {
  description = "Secondary namespace-level connection string."
  value       = azurerm_servicebus_namespace.main.default_secondary_connection_string
  sensitive   = true
}

output "default_primary_key" {
  description = "Primary shared access key for the default RootManageSharedAccessKey rule."
  value       = azurerm_servicebus_namespace.main.default_primary_key
  sensitive   = true
}

output "queue_ids" {
  description = "Map of queue name => Azure resource ID."
  value       = { for k, q in azurerm_servicebus_queue.queues : k => q.id }
}

output "topic_ids" {
  description = "Map of topic name => Azure resource ID."
  value       = { for k, t in azurerm_servicebus_topic.topics : k => t.id }
}
