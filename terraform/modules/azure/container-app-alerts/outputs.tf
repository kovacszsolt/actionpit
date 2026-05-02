output "cpu_alert_id" {
  description = "Resource ID of the CPU metric alert (if created)."
  value       = try(azurerm_monitor_metric_alert.cpu[0].id, null)
}

output "memory_alert_id" {
  description = "Resource ID of the Memory metric alert (if created)."
  value       = try(azurerm_monitor_metric_alert.memory[0].id, null)
}

output "replica_alert_id" {
  description = "Resource ID of the Replica count metric alert (if created)."
  value       = try(azurerm_monitor_metric_alert.replica_count[0].id, null)
}
