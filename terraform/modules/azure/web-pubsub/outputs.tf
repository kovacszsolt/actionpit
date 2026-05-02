output "id" {
  description = "Web PubSub Azure resource ID."
  value       = azurerm_web_pubsub.main.id
}

output "name" {
  description = "Web PubSub service name."
  value       = azurerm_web_pubsub.main.name
}

output "hostname" {
  description = "FQDN of the Web PubSub service (connection string / endpoint hostname)."
  value       = azurerm_web_pubsub.main.hostname
}

output "external_ip" {
  description = "Public IP address of the service (Azure attribute)."
  value       = azurerm_web_pubsub.main.external_ip
}

output "public_port" {
  description = "Public port for browser/client use."
  value       = azurerm_web_pubsub.main.public_port
}

output "server_port" {
  description = "Public port for server-side use."
  value       = azurerm_web_pubsub.main.server_port
}

output "primary_connection_string" {
  description = "Primary connection string (WEBPUBSUB_CONNECTION_STRING in apps)."
  value       = azurerm_web_pubsub.main.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "Secondary connection string."
  value       = azurerm_web_pubsub.main.secondary_connection_string
  sensitive   = true
}

output "primary_access_key" {
  description = "Primary access key."
  value       = azurerm_web_pubsub.main.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "Secondary access key."
  value       = azurerm_web_pubsub.main.secondary_access_key
  sensitive   = true
}

output "hub_ids" {
  description = "Map hub name => hub resource ID (only hubs created by this module)."
  value       = { for k, h in azurerm_web_pubsub_hub.hub : k => h.id }
}
