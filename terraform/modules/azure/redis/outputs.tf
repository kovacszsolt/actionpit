output "id" {
  description = "The ID of the Redis cache."
  value       = azurerm_redis_cache.main.id
}

output "name" {
  description = "The name of the Redis cache."
  value       = azurerm_redis_cache.main.name
}

output "hostname" {
  description = "The hostname of the Redis cache."
  value       = azurerm_redis_cache.main.hostname
}

output "port" {
  description = "The non-SSL port of the Redis cache."
  value       = azurerm_redis_cache.main.port
}

output "ssl_port" {
  description = "The SSL port of the Redis cache."
  value       = azurerm_redis_cache.main.ssl_port
}

output "primary_access_key" {
  description = "The primary access key for the Redis cache."
  value       = azurerm_redis_cache.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "The secondary access key for the Redis cache."
  value       = azurerm_redis_cache.main.secondary_access_key
  sensitive   = true
}

output "resource_group_name" {
  description = "The resource group name of the Redis cache."
  value       = azurerm_redis_cache.main.resource_group_name
}
