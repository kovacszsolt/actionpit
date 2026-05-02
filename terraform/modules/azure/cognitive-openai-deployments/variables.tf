variable "cognitive_account_id" {
  description = "Resource ID of the Cognitive Services account (e.g. AIServices / Foundry account)."
  type        = string
}

variable "deployments" {
  description = <<-EOT
    Map of logical keys to deployment settings. If null, defaults to GPT-5.2 and GPT-5.4 (Microsoft Learn model versions).
    Override entirely if you need different models or SKU names (e.g. Standard vs GlobalStandard for your region).
  EOT
  type = map(object({
    deployment_name            = string
    model_name                 = string
    model_version              = string
    sku_name                   = string
    capacity                   = optional(number, 1)
    version_upgrade_option     = optional(string)
    dynamic_throttling_enabled = optional(bool)
    rai_policy_name            = optional(string)
  }))
  default = null
}
