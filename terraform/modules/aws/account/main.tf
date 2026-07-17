resource "aws_organizations_account" "main" {
  name                       = var.name
  email                      = var.email
  parent_id                  = var.parent_id
  role_name                  = var.role_name
  iam_user_access_to_billing = var.iam_user_access_to_billing
  close_on_deletion          = true
  tags                       = var.tags

  timeouts {
    create = "60m"
  }
}
