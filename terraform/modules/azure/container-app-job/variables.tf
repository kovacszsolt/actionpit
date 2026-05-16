variable "job_name" {
  description = "Name of the Container Apps Job."
  type        = string
}

variable "container_app_environment_id" {
  description = "Container App Environment ID."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region (ARM id), e.g. westeurope."
  type        = string
}

variable "trigger_type" {
  description = "Schedule = cron job; Manual = on-demand runs (Azure Portal, CLI, or API)."
  type        = string
  default     = "Schedule"

  validation {
    condition     = contains(["Schedule", "Manual"], var.trigger_type)
    error_message = "trigger_type must be Schedule or Manual."
  }
}

variable "cron_expression" {
  description = "Cron expression when trigger_type = Schedule (UTC). Example: \"0 6 * * *\" (daily 06:00)."
  type        = string
  default     = null

  validation {
    condition = (
      var.trigger_type != "Schedule"
      || (var.cron_expression != null && trimspace(var.cron_expression) != "")
    )
    error_message = "cron_expression is required when trigger_type is Schedule."
  }
}

variable "schedule_parallelism" {
  description = "Parallel replicas per scheduled execution."
  type        = number
  default     = 1
}

variable "schedule_replica_completion_count" {
  description = "Replicas that must complete successfully per scheduled execution."
  type        = number
  default     = 1
}

variable "manual_parallelism" {
  description = "Parallel replicas when trigger_type = Manual."
  type        = number
  default     = 1
}

variable "manual_replica_completion_count" {
  description = "Replicas that must complete successfully per manual execution."
  type        = number
  default     = 1
}

variable "replica_timeout_in_seconds" {
  description = "Maximum duration of a single replica run (seconds)."
  type        = number
}

variable "replica_retry_limit" {
  description = "Retries after a replica fails."
  type        = number
  default     = 0
}

variable "workload_profile_name" {
  description = "Optional workload profile on the Container Apps Environment."
  type        = string
  default     = null
}

variable "container_name" {
  description = "Container name in the job template."
  type        = string
  default     = "main"
}

variable "container_image" {
  description = "Container image (e.g. myregistry.azurecr.io/app:1.0.0)."
  type        = string
}

variable "cpu" {
  description = "CPU cores per replica (e.g. 0.25, 0.5, 1.0)."
  type        = number
  default     = 0.25
}

variable "memory" {
  description = "Memory per replica (e.g. 0.5Gi, 1Gi)."
  type        = string
  default     = "0.5Gi"
}

variable "container_env" {
  description = "Plain environment variables (name -> value)."
  type        = map(string)
  default     = {}
}

variable "container_secrets" {
  description = "Secret env vars: name = env var name, secretRef = secret store name."
  type = list(object({
    name      = string
    secretRef = string
  }))
  default = []
}

variable "inline_secrets" {
  description = "Job secret definitions with literal values (sensitive)."
  type = list(object({
    name  = string
    value = string
  }))
  default   = []
  sensitive = true
}

variable "key_vault_secrets" {
  description = "Key Vault secret references. Requires key_vault_secrets_identity_id."
  type = list(object({
    name          = string
    key_vault_url = string
  }))
  default = []
}

variable "key_vault_secrets_identity_id" {
  description = "User-assigned identity ARM id for Key Vault secret references."
  type        = string
  default     = null
}

variable "user_assigned_identity_ids" {
  description = "User-assigned identity ARM ids attached to the job."
  type        = list(string)
  default     = []
}

variable "registry_server" {
  description = "Registry host (e.g. myregistry.azurecr.io). Null = public images only."
  type        = string
  default     = null

  validation {
    condition = (
      var.registry_server == null
      || var.registry_identity_id != null
      || (var.registry_username != null && var.registry_password_secret_name != null)
    )
    error_message = "When registry_server is set, set registry_identity_id OR registry_username + registry_password_secret_name."
  }
}

variable "registry_identity_id" {
  description = "Managed identity ARM id for ACR pull."
  type        = string
  default     = null

  validation {
    condition = !(
      var.registry_identity_id != null
      && (var.registry_username != null || var.registry_password_secret_name != null)
    )
    error_message = "registry_identity_id cannot be used with registry_username / registry_password_secret_name."
  }
}

variable "registry_username" {
  type    = string
  default = null
}

variable "registry_password_secret_name" {
  type    = string
  default = null
}

variable "azure_file_volumes" {
  description = "Azure Files volumes (requires matching environment storage)."
  type = list(object({
    volume_name  = string
    storage_name = string
    mount_path   = string
  }))
  default = []
}

variable "tags" {
  description = "Resource tags."
  type        = map(string)
  default     = {}
}
