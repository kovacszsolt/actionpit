variable "display_name" {
  description = "Entra ID app registration display name (visible in Microsoft Entra admin center)."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID (used in azure_credentials_json output)."
  type        = string
}

variable "client_password_display_name" {
  description = "Label for the generated client secret (password credential) on the app registration."
  type        = string
  default     = "infisical"
}

variable "grant_mode" {
  description = <<-EOT
    How to authorize this service principal on Key Vault:
    - access_policy: attach an access policy on the vault (vault must use access policies, not RBAC-only).
    - rbac: assign Azure RBAC at key_vault_id (vault must have RBAC authorization enabled).
    - none: only create the app + secret; grant Key Vault access manually.
  EOT
  type        = string
  default     = "access_policy"

  validation {
    condition     = contains(["access_policy", "rbac", "none"], var.grant_mode)
    error_message = "grant_mode must be one of: access_policy, rbac, none."
  }

  validation {
    condition = (
      var.grant_mode != "access_policy" && var.grant_mode != "rbac"
      ) || (
      try(length(var.key_vault_id), 0) > 0
    )
    error_message = "key_vault_id must be set when grant_mode is access_policy or rbac."
  }
}

variable "key_vault_id" {
  description = "Full ARM resource ID of the Key Vault (from azurerm_key_vault.main.id)."
  type        = string
  default     = ""
}

variable "rbac_role_definition_name" {
  description = "Azure RBAC role when grant_mode is rbac. Key Vault Secrets Officer allows read/write/delete secrets (typical for Infisical sync)."
  type        = string
  default     = "Key Vault Secrets Officer"
}

variable "access_policy_secret_permissions" {
  description = "Secret permissions when grant_mode is access_policy (subset of Key Vault access policies)."
  type        = list(string)
  default     = ["Get", "List", "Set", "Delete"]
}
