data "azapi_resource" "swa" {
  type        = "Microsoft.Web/staticSites@2023-01-01"
  resource_id = var.static_web_app_id

  response_export_values = ["properties"]
}

locals {
  # Portal "JSON view": properties.stableInboundIP - used for apex A record (see SWA apex domain docs).
  stable_ip = coalesce(
    var.apex_inbound_ipv4,
    try(data.azapi_resource.swa.output.properties.stableInboundIP, null),
    try(data.azapi_resource.swa.output.properties.stableInboundIp, null),
  )

  # After validation, Azure often returns an empty validation_token on read. azurerm_dns_txt_record
  # requires record.value length 1–4096, so refresh/plan/destroy must never see an empty string.
  apex_validation_txt = trimspace(azurerm_static_web_app_custom_domain.apex.validation_token)
}

resource "azurerm_static_web_app_custom_domain" "apex" {
  static_web_app_id = var.static_web_app_id
  domain_name       = var.domain_name
  validation_type   = "dns-txt-token"
}

resource "azurerm_dns_txt_record" "apex_validation" {
  name                = "_dnsauth"
  zone_name           = var.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = var.ttl

  record {
    value = length(local.apex_validation_txt) > 0 ? local.apex_validation_txt : "swa-validation-token-placeholder"
  }

  lifecycle {
    ignore_changes = [record]
  }
}

resource "azurerm_dns_a_record" "apex" {
  name                = "@"
  zone_name           = var.zone_name
  resource_group_name = var.resource_group_name
  ttl                 = var.ttl
  records             = [local.stable_ip]

  lifecycle {
    precondition {
      condition     = local.stable_ip != null && local.stable_ip != ""
      error_message = "Apex A record needs an IPv4 address. Set variable apex_inbound_ipv4 to the Static Web App stableInboundIP (Azure Portal -> SWA -> JSON view -> properties.stableInboundIP) if ARM does not return it."
    }
  }
}
