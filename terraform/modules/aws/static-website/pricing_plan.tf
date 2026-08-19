# Pricing Plan Manager is not in the Terraform AWS provider yet; subscribe via AWS CLI.

resource "terraform_data" "pricing_plan" {
  count = local.use_flat_rate_plan ? 1 : 0

  input = {
    plan_tier        = var.pricing_plan
    distribution_arn = module.cloudfront.arn
    web_acl_arn      = aws_wafv2_web_acl.pricing_plan[0].arn
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      "${path.module}/scripts/ensure_cloudfront_pricing_plan.sh" apply \
        "${var.pricing_plan}" \
        "${module.cloudfront.arn}" \
        "${aws_wafv2_web_acl.pricing_plan[0].arn}"
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      "${path.module}/scripts/ensure_cloudfront_pricing_plan.sh" destroy \
        "${self.input.distribution_arn}"
    EOT
  }
}
