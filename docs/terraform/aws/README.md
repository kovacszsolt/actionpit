# Terraform AWS modules

User-facing documentation for reusable modules under [`terraform/modules/aws/`](../../../terraform/modules/aws/).

Azure modules: **[azure/README.md](../azure/README.md)**. Conventions shared across clouds (English `description` strings, tagging) follow the same spirit as [`terraform/README.md`](../../../terraform/README.md).

## Requirements

| Name | Version |
|------|---------|
| Terraform | `>= 1.5.0` |
| `hashicorp/aws` | `>= 5.0` |

### Provider aliases

Some modules expect a **named AWS provider** from the caller:

| Alias | Used by | Why |
|-------|---------|-----|
| `aws.us_east_1` | `acm` (and composite stacks that issue CloudFront certs) | ACM certificates for CloudFront must live in `us-east-1`. |
| `aws.identity_center` | `identity-center-account-assignment` | IAM Identity Center APIs are called via a dedicated provider configuration (typically the management / SSO home region). |

Pass aliases with `providers = { aws.us_east_1 = aws.us_east_1, ... }` on the `module` block.

### Tags

Where supported, pass `tags` as `map(string)`. Align with your organisation’s tagging policy (`Environment`, `ManagedBy`, `CostCenter`, `Workload`, …). Required keys are not enforced in module code.

---

## Quick catalogue

| Module | Description |
|--------|-------------|
| `account` | Create an **AWS Organizations member account** (email, OU parent, access role, billing access). |
| `acm` | **ACM certificate** in `us-east-1` with optional Route53 DNS validation (CloudFront-ready). |
| `azure-container-app-dns` | Route53 **CNAME + asuid TXT** for an Azure Container Apps custom domain. |
| `cloudfront` | **CloudFront distribution** in front of an S3 origin (OAC, SPA/static rewrite modes). |
| `identity-center-account-assignment` | Assign an IAM Identity Center **user** (or group) + permission set to a member account. |
| `route53` | **Hosted zone** (create or reuse) plus alias / CNAME / TXT / MX records. |
| `s3` | **S3 bucket** with encryption, versioning, public-access block, optional CloudFront OAC policy. |
| `s3-cloudfront-oac-policy` | Attach a **CloudFront OAC read policy** to an existing bucket. |
| `static-website` | Composite: **S3 + ACM + CloudFront + Route53 alias** and a GitHub Actions deploy IAM user. |

---

## Modules by category

### Organizations and identity

- **`account`** – Provisions `aws_organizations_account`. Use from the **management account**. Outputs `account_id`, `arn`, and the cross-account `role_name` (default `OrganizationAccountAccessRole`). Deletion closes the account (`close_on_deletion = true`).
- **`identity-center-account-assignment`** – Looks up an existing Identity Center user by `UserName` and a permission set by name (default `AdministratorAccess`), then creates an account assignment on `account_id`. Requires `sso_instance_arn`, `identity_store_id`, and the `aws.identity_center` provider.

### DNS and certificates

- **`route53`** – Create a hosted zone (`create_zone = true`) or attach records to an existing `zone_id`. Supports map-driven `alias_records`, `cname_records`, `txt_records`, and `mx_records` (relative names; `@` for apex).
- **`acm`** – Requests a DNS-validated certificate via `aws.us_east_1`. Optionally writes validation records into `zone_id` for domains listed in `dns_validation_domains` (defaults to the primary `domain_name` so extra SANs can be validated elsewhere). Set `wait_for_validation` to wait for full issuance.
- **`azure-container-app-dns`** – Cross-cloud helper: for `hostname` under `zone_name`, creates the Container App **CNAME** to `cname_target` and the **`asuid.<label>` TXT** with `asuid_verification_id`. Composes the `route53` module.

### Storage and CDN

- **`s3`** – Private-by-default bucket (`block_public_access`, `BucketOwnerEnforced`). Optional versioning, AES256/`aws:kms` SSE, lifecycle rules, and inline CloudFront OAC read policy when `cloudfront_distribution_arns` is set.
- **`s3-cloudfront-oac-policy`** – Same OAC read policy for a **pre-existing** bucket (use when the bucket and distribution are created in separate steps).
- **`cloudfront`** – S3 REST origin with Origin Access Control. Routing modes via `site_mode`:
  - `plain` – no rewrite (optional `spa_fallback` / `static_site_index_rewrite` flags still apply)
  - `static_directory` – extensionless URIs → per-directory `index.html` (Astro / SSG)
  - `react_spa` – client-side routes rewrite to `index.html`
  Custom domains need `aliases` + `acm_certificate_arn` (us-east-1).

### Composite websites

- **`static-website`** – Opinionated stack for a public static site: S3 assets bucket, ACM cert, CloudFront, Route53 alias for `hostname`, optional `additional_hostnames` (SANs / aliases whose DNS may live outside this stack), and an IAM user + access key for GitHub Actions (S3 sync + CloudFront invalidation). Sensitive output: `github_deploy_secret_access_key` (also in Terraform state — rotate/copy carefully).

---

## Typical composition

```text
account ──► identity-center-account-assignment
                │
route53 (zone) ─┬─► acm (us-east-1 validation)
                ├─► static-website  ──► s3 + cloudfront + acm + route53 + IAM deploy
                └─► azure-container-app-dns  ──► route53 CNAME + asuid TXT

s3 ──► cloudfront ──► s3-cloudfront-oac-policy   (split apply / existing bucket)
```

Minimal **static website** sketch:

```hcl
provider "aws" {
  region = "eu-central-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "website" {
  source = "../../modules/aws/static-website"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1 # if required by nested acm
  }

  bucket_name = "example-www-assets"
  hostname    = "www.example.com"
  zone_name   = "example.com"
  zone_id     = module.dns.zone_id
  site_mode   = "react_spa"

  tags = {
    Environment = "prod"
    ManagedBy   = "terraform"
  }
}
```

Wire provider aliases exactly as each module’s `versions.tf` / nested modules declare them.

---

## Security notes

- Prefer **private S3 + CloudFront OAC**; do not open buckets publicly for static hosting.
- ACM for CloudFront is always **`us-east-1`**.
- `static-website` stores the deploy **secret access key** in state (`sensitive = true`). Prefer short-lived credentials or OIDC where possible; if using the generated key, copy once to GitHub Secrets and treat state access as privileged.
- Organizations **account email** must be globally unique and is hard to change after create.

---

## Module README template

When adding a per-module `README.md` under `terraform/modules/aws/<module>/`, use [`terraform/docs/MODULE_README.template.md`](../../../terraform/docs/MODULE_README.template.md) (adapt Azure examples to AWS providers and variables).

## Related files

| File | Contents |
|------|----------|
| [docs/terraform/README.md](../README.md) | Index of Azure + AWS docs |
| [docs/terraform/azure/README.md](../azure/README.md) | Azure module catalogue |
| [docs/terraform-modules.md](../../terraform-modules.md) | Azure quick-reference table |
| [terraform/README.md](../../../terraform/README.md) | Shared Terraform conventions (Azure-focused historically) |
| [terraform/modules/aws/](../../../terraform/modules/aws/) | Module source |
