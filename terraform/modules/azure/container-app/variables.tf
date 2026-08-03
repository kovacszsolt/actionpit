variable "app_name" {
  description = "Name of the Container App"
  type        = string
}

variable "container_app_environment_id" {
  description = "Container App Environment ID (required)"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "revision_mode" {
  description = "Revision mode (Single or Multiple)"
  type        = string
  default     = "Single"
}

variable "external_ingress_enabled" {
  description = "Enable external ingress traffic"
  type        = bool
  default     = true
}

variable "target_port" {
  description = "Target port for incoming traffic"
  type        = number
  default     = 80
}

variable "ingress_transport" {
  description = "Ingress transport protocol (auto, http, http2)"
  type        = string
  default     = "auto"
}

variable "allow_insecure_connections" {
  description = "Allow HTTP connections"
  type        = bool
  default     = false
}

variable "cors" {
  description = "Optional Container Apps ingress CORS policy (platform-level). Set null to omit."
  type = object({
    allowed_origins            = list(string)
    allow_credentials_enabled  = optional(bool, false)
    allowed_headers            = optional(list(string))
    allowed_methods            = optional(list(string))
    exposed_headers            = optional(list(string))
    max_age_in_seconds         = optional(number)
  })
  default = null
}

variable "min_replicas" {
  description = "Minimum number of replicas"
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum number of replicas"
  type        = number
  default     = 10
}

variable "container_name" {
  description = "Name of the container"
  type        = string
  default     = "main"
}

variable "container_image" {
  description = "Container image (e.g. nginx:latest)"
  type        = string
}

variable "cpu" {
  description = "CPU allocation (e.g. 0.25, 0.5, 1.0, 2.0)"
  type        = number
  default     = 0.25
}

variable "memory" {
  description = "Memory allocation (e.g. 0.5Gi, 1Gi, 2Gi)"
  type        = string
  default     = "0.5Gi"
}

variable "container_env" {
  description = "Map of environment variables (key-value pairs)"
  type        = map(string)
  default     = {}
}

variable "container_secrets" {
  description = "List of secret environment variables. Each item should have 'name' (environment variable name) and 'secretRef' (secret name) fields."
  type = list(object({
    name      = string
    secretRef = string
  }))
  default = []
}


variable "secrets" {
  description = "Map of Key Vault secret URLs (key-key_vault_url pairs). Values should be Key Vault secret URLs (e.g. https://<keyvault-name>.vault.azure.net/secrets/<secret-name>/<version>)"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}

variable "cooldown_period" {
  description = "Cooldown period in seconds for scaling down (especially to 0 replicas). Default is 300 seconds (5 minutes)."
  type        = number
  default     = 600
}

variable "polling_interval" {
  description = "Polling interval in seconds for event-driven scalers. Default is 30 seconds."
  type        = number
  default     = 30
}

variable "inline_secrets" {
  description = "Container App secret definitions with literal values (sensitive; stored in Terraform state). Reference from container_secrets via matching secretRef name. Prefer Key Vault in production."
  type = list(object({
    name  = string
    value = string
  }))
  default   = []
  sensitive = true
}

variable "key_vault_secrets" {
  description = "List of Key Vault secrets to reference. Each item should have 'name' and 'key_vault_url' (full URL to the secret in Key Vault). Requires key_vault_secrets_identity_id to be set."
  type = list(object({
    name          = string
    key_vault_url = string
  }))
  default = []
}

variable "key_vault_secrets_identity_id" {
  description = "User Assigned Managed Identity resource ID used to access Key Vault secrets (key_vault_secrets). Required when key_vault_secrets is non-empty. Must be one of the identities in user_assigned_identity_ids."
  type        = string
  default     = null
}

variable "user_assigned_identity_ids" {
  description = "List of User Assigned Managed Identity resource IDs attached to the Container App."
  type        = list(string)
  default     = []
}

variable "http_concurrent_requests" {
  description = "HTTP scaler concurrent requests threshold. The application will scale out when the average number of concurrent HTTP requests exceeds this value. Default: null (no HTTP scaler configured)."
  type        = number
  default     = null
}

variable "memory_scale_utilization" {
  description = "Memory scale rule utilization threshold (percentage). The application will scale out when memory usage exceeds this percentage relative to the container's memory limit. Default: null (no memory scaler configured). Example: 70 = scale out when memory usage exceeds 70%."
  type        = number
  default     = null
  validation {
    condition     = var.memory_scale_utilization == null || (var.memory_scale_utilization > 0 && var.memory_scale_utilization <= 100)
    error_message = "The memory_scale_utilization value must be a number between 1-100, or null."
  }
}

variable "cpu_scale_utilization" {
  description = "CPU scale rule utilization threshold (percentage). The application will scale out when CPU usage exceeds this percentage relative to the container's CPU limit. Default: null (no CPU scaler configured). Example: 80 = scale out when CPU usage exceeds 80%."
  type        = number
  default     = null
  validation {
    condition     = var.cpu_scale_utilization == null || (var.cpu_scale_utilization > 0 && var.cpu_scale_utilization <= 100)
    error_message = "The cpu_scale_utilization value must be a number between 1-100, or null."
  }
}

variable "registry_server" {
  description = "Container registry server URL (e.g., myregistry.azurecr.io). Required for private container registries. If null, public registry is assumed."
  type        = string
  default     = null

  validation {
    condition = (
      var.registry_server == null
      || var.registry_identity_id != null
      || (var.registry_username != null && var.registry_password_secret_name != null)
    )
    error_message = "When registry_server is set, you must set either registry_identity_id (managed identity auth) OR both registry_username and registry_password_secret_name (basic auth)."
  }
}

variable "registry_identity_id" {
  description = "User Assigned Managed Identity resource ID to use for authenticating to the registry (e.g., ACR)."
  type        = string
  default     = null

  validation {
    condition = !(
      var.registry_identity_id != null
      && (var.registry_username != null || var.registry_password_secret_name != null)
    )
    error_message = "registry_identity_id cannot be used together with registry_username / registry_password_secret_name."
  }
}

variable "registry_username" {
  description = "Container registry username. Optional, can be null if using managed identity or admin user."
  type        = string
  default     = null
}

variable "registry_password_secret_name" {
  description = "Name of the secret that contains the container registry password. This secret must be defined in the container_secrets or key_vault_secrets. Required if registry_server is set and not using managed identity."
  type        = string
  default     = null
}

variable "health_check" {
  description = <<-EOT
    Default HTTP probes when liveness_probe / readiness_probe / startup_probe are null.
    Uses target_port (or health_check.port) for GET liveness_path and readiness_path (default /health).
    Set enabled = false to disable these defaults (no probes unless you set liveness_probe etc. explicitly).
    startup_path: when non-empty, a startup_probe is added unless startup_probe is set explicitly.
  EOT
  type = object({
    enabled = optional(bool, true)
    port    = optional(number)

    liveness_path  = optional(string, "/health")
    readiness_path = optional(string, "/health")
    startup_path   = optional(string, null)

    liveness_initial_delay           = optional(number, 10)
    liveness_interval_seconds        = optional(number, 20)
    liveness_timeout                 = optional(number, 3)
    liveness_failure_count_threshold = optional(number, 3)

    readiness_initial_delay           = optional(number, 10)
    readiness_interval_seconds        = optional(number, 20)
    readiness_timeout                 = optional(number, 5)
    readiness_failure_count_threshold = optional(number, 3)
    readiness_success_count_threshold = optional(number, 1)

    startup_initial_delay           = optional(number, 0)
    startup_interval_seconds        = optional(number, 10)
    startup_timeout                 = optional(number, 3)
    startup_failure_count_threshold = optional(number, 18)
  })
  default = {}
}

variable "liveness_probe" {
  description = "Optional liveness probe for the main container (TCP or HTTP/HTTPS)."
  type = object({
    transport               = string
    port                    = number
    path                    = optional(string)
    host                    = optional(string)
    initial_delay           = optional(number)
    interval_seconds        = optional(number)
    timeout                 = optional(number)
    failure_count_threshold = optional(number)
  })
  default = null
}

variable "readiness_probe" {
  description = "Optional readiness probe for the main container (TCP or HTTP/HTTPS)."
  type = object({
    transport               = string
    port                    = number
    path                    = optional(string)
    host                    = optional(string)
    initial_delay           = optional(number)
    interval_seconds        = optional(number)
    timeout                 = optional(number)
    failure_count_threshold = optional(number)
    success_count_threshold = optional(number)
  })
  default = null
}

variable "startup_probe" {
  description = "Optional startup probe for the main container (TCP or HTTP/HTTPS)."
  type = object({
    transport               = string
    port                    = number
    path                    = optional(string)
    host                    = optional(string)
    initial_delay           = optional(number)
    interval_seconds        = optional(number)
    timeout                 = optional(number)
    failure_count_threshold = optional(number)
  })
  default = null
}

variable "azure_file_volumes" {
  description = "Azure Files volumes. Requires matching azurerm_container_app_environment_storage; storage_name must equal that resource's name."
  type = list(object({
    volume_name  = string
    storage_name = string
    mount_path   = string
  }))
  default = []
}

variable "custom_domain" {
  description = "Optional public hostname + Azure DNS zone to create asuid TXT, CNAME to the app, and bind managed TLS (azurerm_container_app_custom_domain)."
  type = object({
    hostname                = string
    dns_zone_name           = string
    dns_resource_group_name = string
  })
  default = null

  validation {
    condition = var.custom_domain == null || (
      endswith(var.custom_domain.hostname, var.custom_domain.dns_zone_name)
      && length(trimspace(var.custom_domain.hostname)) > length(var.custom_domain.dns_zone_name) + 1
    )
    error_message = "custom_domain.hostname must be a single label plus dns_zone_name (e.g. app.example.com with zone example.com)."
  }
}
