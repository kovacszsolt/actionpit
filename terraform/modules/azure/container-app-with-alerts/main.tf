locals {
  alerts_enabled = try(var.alerts.enabled, false)

  alert_tags = merge(var.tags, try(var.alerts.tags, {}))

  alert_name_prefix = coalesce(try(var.alerts.name_prefix, null), var.app_name)
}

module "app" {
  source = "../container-app"

  app_name                     = var.app_name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode

  external_ingress_enabled   = var.external_ingress_enabled
  target_port                = var.target_port
  ingress_transport          = var.ingress_transport
  allow_insecure_connections = var.allow_insecure_connections

  min_replicas = var.min_replicas
  max_replicas = var.max_replicas

  container_name  = var.container_name
  container_image = var.container_image
  cpu             = var.cpu
  memory          = var.memory

  container_env     = var.container_env
  container_secrets = var.container_secrets
  secrets           = var.secrets
  tags              = var.tags

  cooldown_period  = var.cooldown_period
  polling_interval = var.polling_interval

  inline_secrets                = var.inline_secrets
  key_vault_secrets             = var.key_vault_secrets
  key_vault_secrets_identity_id = var.key_vault_secrets_identity_id
  user_assigned_identity_ids    = var.user_assigned_identity_ids

  http_concurrent_requests = var.http_concurrent_requests
  memory_scale_utilization = var.memory_scale_utilization
  cpu_scale_utilization    = var.cpu_scale_utilization

  registry_server               = var.registry_server
  registry_identity_id          = var.registry_identity_id
  registry_username             = var.registry_username
  registry_password_secret_name = var.registry_password_secret_name

  health_check    = var.health_check
  liveness_probe  = var.liveness_probe
  readiness_probe = var.readiness_probe
  startup_probe   = var.startup_probe

  azure_file_volumes = var.azure_file_volumes
  custom_domain      = var.custom_domain
}

module "alerts" {
  count  = local.alerts_enabled ? 1 : 0
  source = "../container-app-alerts"

  depends_on = [module.app]

  name_prefix         = local.alert_name_prefix
  resource_group_name = var.resource_group_name
  scopes              = [module.app.app_id]

  action_group_ids = try(var.alerts.action_group_ids, [])

  cpu_threshold           = try(var.alerts.cpu_threshold, null)
  cpu_aggregation         = try(var.alerts.cpu_aggregation, "Maximum")
  memory_threshold        = try(var.alerts.memory_threshold, null)
  memory_aggregation      = try(var.alerts.memory_aggregation, "Maximum")
  replica_count_threshold = try(var.alerts.replica_count_threshold, null)
  replica_aggregation     = try(var.alerts.replica_aggregation, "Maximum")

  evaluation_frequency = try(var.alerts.evaluation_frequency, "PT1M")
  window_size          = try(var.alerts.window_size, "PT5M")
  severity             = try(var.alerts.severity, 2)
  tags                 = local.alert_tags
}
