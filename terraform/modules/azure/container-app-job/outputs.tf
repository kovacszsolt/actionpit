output "job_id" {
  description = "Container Apps Job resource ID."
  value       = azurerm_container_app_job.main.id
}

output "job_name" {
  description = "Container Apps Job name."
  value       = azurerm_container_app_job.main.name
}

output "event_stream_endpoint" {
  description = "Event stream endpoint for job execution telemetry."
  value       = azurerm_container_app_job.main.event_stream_endpoint
}

output "outbound_ip_addresses" {
  description = "Outbound IP addresses used by the job."
  value       = azurerm_container_app_job.main.outbound_ip_addresses
}
