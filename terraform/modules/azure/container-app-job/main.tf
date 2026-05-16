resource "azurerm_container_app_job" "main" {
  name                         = var.job_name
  location                     = var.location
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id

  replica_timeout_in_seconds = var.replica_timeout_in_seconds
  replica_retry_limit        = var.replica_retry_limit
  workload_profile_name      = var.workload_profile_name

  dynamic "identity" {
    for_each = length(var.user_assigned_identity_ids) > 0 ? [1] : []
    content {
      type         = "UserAssigned"
      identity_ids = var.user_assigned_identity_ids
    }
  }

  dynamic "schedule_trigger_config" {
    for_each = var.trigger_type == "Schedule" ? [1] : []
    content {
      cron_expression          = var.cron_expression
      parallelism              = var.schedule_parallelism
      replica_completion_count = var.schedule_replica_completion_count
    }
  }

  dynamic "manual_trigger_config" {
    for_each = var.trigger_type == "Manual" ? [1] : []
    content {
      parallelism              = var.manual_parallelism
      replica_completion_count = var.manual_replica_completion_count
    }
  }

  template {
    dynamic "volume" {
      for_each = var.azure_file_volumes
      content {
        name         = volume.value.volume_name
        storage_type = "AzureFile"
        storage_name = volume.value.storage_name
      }
    }

    container {
      name   = var.container_name
      image  = var.container_image
      cpu    = var.cpu
      memory = var.memory

      dynamic "env" {
        for_each = var.container_env
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = var.container_secrets
        content {
          name        = env.value.name
          secret_name = env.value.secretRef
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

  dynamic "registry" {
    for_each = var.registry_server != null ? [1] : []
    content {
      server               = var.registry_server
      identity             = var.registry_identity_id
      username             = var.registry_identity_id == null ? var.registry_username : null
      password_secret_name = var.registry_identity_id == null ? var.registry_password_secret_name : null
    }
  }

  dynamic "secret" {
    for_each = var.inline_secrets
    content {
      name  = secret.value.name
      value = secret.value.value
    }
  }

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
