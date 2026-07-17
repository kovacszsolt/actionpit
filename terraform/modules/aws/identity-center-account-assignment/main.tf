data "aws_identitystore_user" "main" {
  provider = aws.identity_center

  identity_store_id = var.identity_store_id

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = var.identity_center_username
    }
  }
}

data "aws_ssoadmin_permission_set" "main" {
  provider = aws.identity_center

  instance_arn = var.sso_instance_arn
  name         = var.permission_set_name
}

resource "aws_ssoadmin_account_assignment" "main" {
  provider = aws.identity_center

  instance_arn       = var.sso_instance_arn
  permission_set_arn = data.aws_ssoadmin_permission_set.main.arn
  principal_id       = data.aws_identitystore_user.main.user_id
  principal_type     = var.principal_type
  target_id          = var.account_id
  target_type        = "AWS_ACCOUNT"
}
