locals {
  custom_domain_enabled = var.custom_domain != null
  custom_domain_label   = local.custom_domain_enabled ? trimsuffix(var.custom_domain.hostname, ".${var.custom_domain.dns_zone_name}") : ""

  # HTTP health probes: optional health_check block fills liveness/readiness (and optional startup) when the
  # explicit *probe variables are null. Set health_check.enabled = false to disable defaults.
  hc_enabled = var.health_check.enabled
  hc_port    = coalesce(var.health_check.port, var.target_port)

  default_liveness_probe = local.hc_enabled && var.liveness_probe == null ? {
    transport               = "HTTP"
    port                    = local.hc_port
    path                    = var.health_check.liveness_path
    host                    = null
    initial_delay           = var.health_check.liveness_initial_delay
    interval_seconds        = var.health_check.liveness_interval_seconds
    timeout                 = var.health_check.liveness_timeout
    failure_count_threshold = var.health_check.liveness_failure_count_threshold
  } : null

  default_readiness_probe = local.hc_enabled && var.readiness_probe == null ? {
    transport               = "HTTP"
    port                    = local.hc_port
    path                    = var.health_check.readiness_path
    host                    = null
    initial_delay           = var.health_check.readiness_initial_delay
    interval_seconds        = var.health_check.readiness_interval_seconds
    timeout                 = var.health_check.readiness_timeout
    failure_count_threshold = var.health_check.readiness_failure_count_threshold
    success_count_threshold = var.health_check.readiness_success_count_threshold
  } : null

  default_startup_probe = local.hc_enabled && var.startup_probe == null && var.health_check.startup_path != null && var.health_check.startup_path != "" ? {
    transport               = "HTTP"
    port                    = local.hc_port
    path                    = var.health_check.startup_path
    host                    = null
    initial_delay           = var.health_check.startup_initial_delay
    interval_seconds        = var.health_check.startup_interval_seconds
    timeout                 = var.health_check.startup_timeout
    failure_count_threshold = var.health_check.startup_failure_count_threshold
  } : null

  # Use ternary, not coalesce: coalesce(null, null) errors when both explicit and default probes are absent.
  effective_liveness_probe  = var.liveness_probe != null ? var.liveness_probe : local.default_liveness_probe
  effective_readiness_probe = var.readiness_probe != null ? var.readiness_probe : local.default_readiness_probe
  effective_startup_probe   = var.startup_probe != null ? var.startup_probe : local.default_startup_probe
}

resource "azurerm_container_app" "main" {
  name                         = var.app_name
  container_app_environment_id = var.container_app_environment_id
  resource_group_name          = var.resource_group_name
  revision_mode                = var.revision_mode

  dynamic "identity" {
    for_each = length(var.user_assigned_identity_ids) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.user_assigned_identity_ids
    }
  }
  # Ingress configuration
  ingress {
    external_enabled           = var.external_ingress_enabled
    target_port                = var.target_port
    transport                  = var.ingress_transport
    allow_insecure_connections = var.allow_insecure_connections

    dynamic "cors" {
      for_each = var.cors != null ? [var.cors] : []
      content {
        allowed_origins           = cors.value.allowed_origins
        allow_credentials_enabled = cors.value.allow_credentials_enabled
        allowed_headers           = cors.value.allowed_headers
        allowed_methods           = cors.value.allowed_methods
        exposed_headers           = cors.value.exposed_headers
        max_age_in_seconds        = cors.value.max_age_in_seconds
      }
    }

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  # Template - container configuration
  template {
    min_replicas                = var.min_replicas
    max_replicas                = var.max_replicas
    cooldown_period_in_seconds  = var.cooldown_period
    polling_interval_in_seconds = var.polling_interval

    dynamic "volume" {
      for_each = var.azure_file_volumes
      content {
        name         = volume.value.volume_name
        storage_type = "AzureFile"
        storage_name = volume.value.storage_name
      }
    }

    # HTTP scale rules - concurrent requests
    dynamic "http_scale_rule" {
      for_each = var.http_concurrent_requests != null ? [1] : []
      content {
        name                = "http-concurrent-requests"
        concurrent_requests = tostring(var.http_concurrent_requests)
      }
    }

    # Custom scale rules - memory utilization
    dynamic "custom_scale_rule" {
      for_each = var.memory_scale_utilization != null ? [1] : []
      content {
        name             = "memory-utilization-rule"
        custom_rule_type = "memory"
        metadata = {
          type  = "Utilization"
          value = tostring(var.memory_scale_utilization)
        }
      }
    }

    # Custom scale rules - CPU utilization
    dynamic "custom_scale_rule" {
      for_each = var.cpu_scale_utilization != null ? [1] : []
      content {
        name             = "cpu-utilization-rule"
        custom_rule_type = "cpu"
        metadata = {
          type  = "Utilization"
          value = tostring(var.cpu_scale_utilization)
        }
      }
    }

    container {
      name   = var.container_name
      image  = var.container_image
      cpu    = var.cpu
      memory = var.memory

      # Environment variables
      dynamic "env" {
        for_each = var.container_env
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secret environment variables
      dynamic "env" {
        for_each = var.container_secrets
        content {
          name        = env.value.name
          secret_name = env.value.secretRef
        }
      }

      dynamic "liveness_probe" {
        for_each = local.effective_liveness_probe != null ? [local.effective_liveness_probe] : []
        content {
          transport               = liveness_probe.value.transport
          port                    = liveness_probe.value.port
          path                    = liveness_probe.value.path
          host                    = liveness_probe.value.host
          initial_delay           = liveness_probe.value.initial_delay
          interval_seconds        = liveness_probe.value.interval_seconds
          timeout                 = liveness_probe.value.timeout
          failure_count_threshold = liveness_probe.value.failure_count_threshold
        }
      }

      dynamic "readiness_probe" {
        for_each = local.effective_readiness_probe != null ? [local.effective_readiness_probe] : []
        content {
          transport               = readiness_probe.value.transport
          port                    = readiness_probe.value.port
          path                    = readiness_probe.value.path
          host                    = readiness_probe.value.host
          initial_delay           = readiness_probe.value.initial_delay
          interval_seconds        = readiness_probe.value.interval_seconds
          timeout                 = readiness_probe.value.timeout
          failure_count_threshold = readiness_probe.value.failure_count_threshold
          success_count_threshold = readiness_probe.value.success_count_threshold
        }
      }

      dynamic "startup_probe" {
        for_each = local.effective_startup_probe != null ? [local.effective_startup_probe] : []
        content {
          transport               = startup_probe.value.transport
          port                    = startup_probe.value.port
          path                    = startup_probe.value.path
          host                    = startup_probe.value.host
          initial_delay           = startup_probe.value.initial_delay
          interval_seconds        = startup_probe.value.interval_seconds
          timeout                 = startup_probe.value.timeout
          failure_count_threshold = startup_probe.value.failure_count_threshold
        }
      }

      dynamic "volume_mounts" {
        for_each = var.azure_file_volumes
        content {
          name = volume_mounts.value.volume_name
          path = volume_mounts.value.mount_path
        }
      }
    }
  }

  # Registry configuration for private container registries
  # Must be at the resource level, not inside template
  dynamic "registry" {
    for_each = var.registry_server != null ? [1] : []
    content {
      server               = var.registry_server
      identity             = var.registry_identity_id
      username             = var.registry_identity_id == null ? var.registry_username : null
      password_secret_name = var.registry_identity_id == null ? var.registry_password_secret_name : null
    }
  }

  # Secrets - literal values (Container App secret store)
  dynamic "secret" {
    for_each = var.inline_secrets
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }

  # Secret configuration - Key Vault URL references
  dynamic "secret" {
    for_each = var.key_vault_secrets
    content {
      name                = secret.value.name
      key_vault_secret_id = secret.value.key_vault_url
      identity            = var.key_vault_secrets_identity_id
    }
  }


  tags = var.tags
}

# Azure Container Apps custom hostname + managed certificate (DNS must exist first; see HashiCorp docs).
resource "azurerm_dns_txt_record" "custom_domain_verification" {
  count = local.custom_domain_enabled ? 1 : 0

  name                = "asuid.${local.custom_domain_label}"
  zone_name           = var.custom_domain.dns_zone_name
  resource_group_name = var.custom_domain.dns_resource_group_name
  ttl                 = 300

  record {
    value = azurerm_container_app.main.custom_domain_verification_id
  }
}

resource "azurerm_dns_cname_record" "custom_domain" {
  count = local.custom_domain_enabled ? 1 : 0

  name                = local.custom_domain_label
  zone_name           = var.custom_domain.dns_zone_name
  resource_group_name = var.custom_domain.dns_resource_group_name
  ttl                 = 300
  record              = azurerm_container_app.main.ingress[0].fqdn
}

resource "azurerm_container_app_custom_domain" "main" {
  count = local.custom_domain_enabled ? 1 : 0

  name             = var.custom_domain.hostname
  container_app_id = azurerm_container_app.main.id

  depends_on = [
    azurerm_dns_txt_record.custom_domain_verification,
    azurerm_dns_cname_record.custom_domain,
  ]

  lifecycle {
    ignore_changes = [
      certificate_binding_type,
      container_app_environment_certificate_id,
    ]
  }
}
