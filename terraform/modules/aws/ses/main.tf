data "aws_region" "current" {}

locals {
  mail_from_domain = "${var.mail_from_subdomain}.${var.domain_name}"

  configuration_set_name = coalesce(
    var.configuration_set_name,
    replace(var.domain_name, ".", "-"),
  )

  smtp_user_name = coalesce(
    var.smtp_user_name,
    "ses-smtp-${replace(var.domain_name, ".", "-")}",
  )

  smtp_endpoint = "email-smtp.${data.aws_region.current.name}.amazonaws.com"
}

resource "aws_sesv2_configuration_set" "main" {
  configuration_set_name = local.configuration_set_name

  tags = var.tags
}

resource "aws_sesv2_email_identity" "domain" {
  email_identity         = var.domain_name
  configuration_set_name = aws_sesv2_configuration_set.main.configuration_set_name

  dkim_signing_attributes {
    next_signing_key_length = "RSA_2048_BIT"
  }

  tags = var.tags
}

resource "aws_sesv2_email_identity_mail_from_attributes" "domain" {
  email_identity = aws_sesv2_email_identity.domain.email_identity

  behavior_on_mx_failure = "USE_DEFAULT_VALUE"
  mail_from_domain       = local.mail_from_domain
}

resource "aws_route53_record" "dkim" {
  count = 3

  zone_id = var.zone_id
  name    = "${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}._domainkey.${var.domain_name}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_sesv2_email_identity.domain.dkim_signing_attributes[0].tokens[count.index]}.dkim.amazonses.com"]
}

resource "aws_route53_record" "mail_from_mx" {
  zone_id = var.zone_id
  name    = local.mail_from_domain
  type    = "MX"
  ttl     = 600
  records = ["10 feedback-smtp.${data.aws_region.current.name}.amazonses.com"]
}

resource "aws_route53_record" "mail_from_spf" {
  zone_id = var.zone_id
  name    = local.mail_from_domain
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}

resource "aws_route53_record" "spf" {
  zone_id = var.zone_id
  name    = var.domain_name
  type    = "TXT"
  ttl     = 600
  records = ["v=spf1 include:amazonses.com ~all"]
}

resource "aws_route53_record" "dmarc" {
  zone_id = var.zone_id
  name    = "_dmarc.${var.domain_name}"
  type    = "TXT"
  ttl     = 600
  records = ["v=DMARC1; p=${var.dmarc_policy};"]
}

data "aws_iam_policy_document" "smtp_send" {
  count = var.create_smtp_user ? 1 : 0

  # SES SMTP commonly requires Resource "*"; identity ARNs alone break SendRawEmail over SMTP.
  statement {
    sid    = "SesSend"
    effect = "Allow"

    actions = [
      "ses:SendEmail",
      "ses:SendRawEmail",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_user" "smtp" {
  count = var.create_smtp_user ? 1 : 0

  name = local.smtp_user_name
  path = "/"

  tags = merge(var.tags, { Purpose = "ses-smtp" })
}

resource "aws_iam_user_policy" "smtp" {
  count = var.create_smtp_user ? 1 : 0

  name   = "${local.smtp_user_name}-send"
  user   = aws_iam_user.smtp[0].name
  policy = data.aws_iam_policy_document.smtp_send[0].json
}

resource "aws_iam_access_key" "smtp" {
  count = var.create_smtp_user ? 1 : 0

  user = aws_iam_user.smtp[0].name
}
