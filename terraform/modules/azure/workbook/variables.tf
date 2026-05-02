variable "workbook_template_path" {
  description = "Absolute path to the workbook JSON template (e.g. from get_terragrunt_dir() + \"/workbook.json.tftpl\")."
  type        = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "workbook_display_name" {
  type = string
}

variable "container_app_resource_id" {
  type = string
}

# Optional: use when a deterministic workbook resource name is required (update-friendly)
variable "workbook_name" {
  type    = string
  default = null
}
