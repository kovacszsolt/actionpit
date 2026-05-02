
locals {
  # Workbook "name" is the Azure resource name (can be a GUID-like string).
  # If workbook_name is not set, generate a stable name from the container app ID.
  # (uuidv5: deterministic for the same input)
  effective_workbook_name = coalesce(
    var.workbook_name,
    uuidv5("6ba7b810-9dad-11d1-80b4-00c04fd430c8", var.container_app_resource_id)
  )
}

resource "azurerm_application_insights_workbook" "this" {
  name                = local.effective_workbook_name
  location            = var.location
  resource_group_name = var.resource_group_name
  display_name        = var.workbook_display_name

  # Terraform resource: data_json must be a string containing valid JSON.
  data_json = templatefile(var.workbook_template_path, {
    container_app_resource_id = var.container_app_resource_id
    workbook_display_name     = var.workbook_display_name
  })
}

output "workbook_id" {
  value = azurerm_application_insights_workbook.this.id
}
