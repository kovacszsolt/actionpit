locals {
  # Microsoft Learn model IDs/versions (Azure OpenAI / Foundry).
  default_deployments = {
    gpt_52 = {
      deployment_name            = "gpt-52"
      model_name                 = "gpt-5.2"
      model_version              = "2025-12-11"
      sku_name                   = "GlobalStandard"
      capacity                   = 1
      version_upgrade_option     = null
      dynamic_throttling_enabled = null
      rai_policy_name            = null
    }
    gpt_54 = {
      deployment_name            = "gpt-54"
      model_name                 = "gpt-5.4"
      model_version              = "2026-03-05"
      sku_name                   = "GlobalStandard"
      capacity                   = 1
      version_upgrade_option     = null
      dynamic_throttling_enabled = null
      rai_policy_name            = null
    }
  }

  deployments = coalesce(var.deployments, local.default_deployments)
}

resource "azurerm_cognitive_deployment" "main" {
  for_each = local.deployments

  name                 = each.value.deployment_name
  cognitive_account_id = var.cognitive_account_id

  model {
    format  = "OpenAI"
    name    = each.value.model_name
    version = each.value.model_version
  }

  sku {
    name     = each.value.sku_name
    capacity = each.value.capacity
  }

  # try(): Terragrunt/custom maps may omit optional keys; avoid "Missing map element" on plan.
  dynamic_throttling_enabled = try(each.value.dynamic_throttling_enabled, null)
  rai_policy_name            = try(each.value.rai_policy_name, null)
  version_upgrade_option     = try(each.value.version_upgrade_option, null)
}
