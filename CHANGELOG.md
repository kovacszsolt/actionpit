# Changelog

This file mirrors the published notes on [GitHub Releases](https://github.com/kovacszsolt/actionpit/releases).
Pin a **tag or commit SHA** in workflows and Terraform module sources (`?ref=`) — avoid floating `@main`.

Newest releases appear first.

## v3.1.1 — 2026-11-20

## Highlights

- **New GitHub Action** [`azure-static-web-app-deploy`](github/action/azure-static-web-app-deploy/): upload a pre-built static folder to Azure Static Web Apps (`skip_app_build: true`), with optional `artifact_name` download and `deploy_path` validation.
- **Documentation**: [`azure-static-web-app-deploy`](github/action/azure-static-web-app-deploy/) catalogue and usage in [`docs/github-action/README.md`](docs/github-action/README.md); entry in root [`README.md`](README.md).

## GitHub Actions

### Added

| Action | Path |
|--------|------|
| Azure Static Web App deploy | [`github/action/azure-static-web-app-deploy`](github/action/azure-static-web-app-deploy/) |

Example (with dist artifact from `frontend-pnpm-build`):

```yaml
- uses: kovacszsolt/actionpit/github/action/azure-static-web-app-deploy@v3.1.1
  with:
    deploy_path: apps/admin/frontend/dist
    artifact_name: admin-frontend-dist
    azure_static_web_apps_api_token: ${{ secrets.YOUR_SWA_API_TOKEN }}
```

**Full Changelog**: https://github.com/kovacszsolt/actionpit/compare/v3.1.0...v3.1.1

## v3.1.0 — 2026-11-11

## Highlights

- **New GitHub Actions** for Azure Container Apps and Container App Jobs: Azure login, image update, and build metadata env vars (`IMAGE_GIT_SHA`, `IMAGE_BUILD_TIME`, `VERSION_NUMBER`).
- **New Go module** [`go/pkg/newrelic`](go/pkg/newrelic): New Relic Log API client for CLIs and batch jobs, plus optional `log/slog` handler (console/JSON with async Log API forwarding).
- **Documentation**: root [`README.md`](README.md) project catalogue; [`docs/go/README.md`](docs/go/README.md) updated for `newrelic`.

## GitHub Actions

### Added

| Action | Path |
|--------|------|
| Azure Container App deploy | [`github/action/azure-container-app-deploy`](github/action/azure-container-app-deploy/) |
| Azure Container App Job deploy | [`github/action/azure-container-app-job-deploy`](github/action/azure-container-app-job-deploy/) |

Example:

```yaml
- uses: kovacszsolt/actionpit/github/action/azure-container-app-deploy@v3.1.0
  with:
    azure_credentials: ${{ secrets.AZURE_CREDENTIALS }}
    azure_subscription_id: ${{ vars.AZURE_SUBSCRIPTION_ID }}
    resource_group: rg-example
    app_name: ca-api
    image: myacr.azurecr.io/backend:1.2.3
    version_number: "1.2.3"
```

## v3.0.6 — 2026-11-05

**Full Changelog**: https://github.com/kovacszsolt/actionpit/compare/v3.0.5...v3.0.6

## v3.0.5 — 2026-08-22

**Full Changelog**: https://github.com/kovacszsolt/actionpit/compare/v3.0.4...v3.0.5

## v3.0.4 — 2026-08-08

**Full Changelog**: https://github.com/kovacszsolt/actionpit/compare/v3.0.3...v3.0.4

## v3.0.3 — 2026-08-01

**Full Changelog**: https://github.com/kovacszsolt/actionpit/compare/3.0.1...v3.0.3

## v3.0.2 — 2026-07-31

**Full Changelog**: https://github.com/kovacszsolt/actionpit/compare/3.0.0...v3.0.2

## 3.0.1 — 2026-07-31

**Full Changelog**: https://github.com/kovacszsolt/actionpit/compare/3.0.0...3.0.1

## 3.0.0 — 2026-07-28

Reusable Go packages, shell scripts, AWS SES Terraform module, frontend CI actions, and expanded documentation 
### Added

#### Go packages (`go/pkg/`)

Standalone Go modules (import: `github.com/kovacszsolt/actionpit/go/pkg/<package>`):

- **`openobserve`** — OpenObserve `_json` HTTP ingest client, env/meta loading, nil-safe structured `Publisher`
- **`oolifecycle`** — App lifecycle events: `app.started`, `app.stopped`, `pipeline.failed`
- **`ooai`** — AI call cost calculation and `{service}.ai.call` event publishing
- **`auth`** — HS256 JWT verification (`iss=auth-ba`) with optional Echo Bearer middleware

Docs: [`docs/go/README.md`](docs/go/README.md)

#### Shell scripts (`scripts/`)

- **`aws-s3-state.sh`** — Create an S3 bucket for Terraform / Terragrunt remote state
- **`azure-certificate-create.sh`** — Issue a managed certificate for an Azure Container Apps environment
- **`clear-terragrunt-cache.sh`** — Remove `.terragrunt-cache` directories and optionally `.terraform.lock.hcl` files

Docs: [`docs/scripts/README.md`](docs/scripts/README.md)

#### Terraform — AWS

- **`ses`** — SESv2 domain identity (Easy DKIM), Route53 DKIM / MAIL FROM / SPF / DMARC records, configuration set, optional SMTP IAM user
- **`static-website`** — New `managed_hostnames` variable for extra CloudFront aliases and ACM SANs with in-zone Route53 DNS alias and validation records

#### GitHub Actions

- **`frontend-pnpm-build`** — Build a pnpm Vite frontend, write `dist/health.json`, upload dist artifact
- **`frontend-s3-deploy`** — Download dist artifact, sync to S3 with cache policies, optional CloudFront invalidation

### Changed

- Root **`README.md`** restructured as a catalogue with links to per-area docs (`terraform/`, `github/action/`, `go/pkg/`, `scripts/`)
- **`docs/terraform/aws/README.md`** — `ses` module added to catalogue, dependency diagram, and security notes
- **`frontend-pnpm-build`** — pnpm action version updated

### Removed

- Root **`clear-terragrunt.sh`** — replaced by `scripts/clear-terragrunt-cache.sh`

### Documentation

| Path | Status |
|------|--------|
| `docs/go/README.md` | **New** — Go package catalogue and wiring examples |
| `docs/scripts/README.md` | **New** — Shell script reference |
| `docs/terraform/aws/README.md` | **Updated** — SES module |
| `docs/terraform/azure/README.md` | Unchanged |
| `docs/github-action/README.md` | Unchanged |

### Upgrade notes

- Go packages are independent modules; pin with `go get ...@2.2.0` (or commit SHA).
- `ses` and `static-website` may store sensitive credentials in Terraform state (`smtp_password`, deploy IAM secret). Treat state access as privileged.
- New SES accounts remain in the **SES sandbox** until AWS grants production access.
- `auth` requires Go **1.25.0+**; other Go modules target **1.23.0+**.

## 2.0.0 — 2026-07-17

### Added

- AWS Terraform modules under `terraform/modules/aws/`:
  - `account` — AWS Organizations member account
  - `acm` — ACM certificate (`us-east-1`) with optional Route53 DNS validation
  - `azure-container-app-dns` — Route53 CNAME + asuid TXT for Azure Container Apps custom domains
  - `cloudfront` — CloudFront distribution for S3 origins (OAC, SPA/static rewrite modes)
  - `identity-center-account-assignment` — IAM Identity Center user/group + permission set assignment
  - `route53` — hosted zone and alias / CNAME / TXT / MX records
  - `s3` — S3 bucket (encryption, versioning, public-access block, optional CloudFront OAC policy)
  - `s3-cloudfront-oac-policy` — CloudFront OAC read policy on an existing bucket
  - `static-website` — composite S3 + ACM + CloudFront + Route53 alias, plus GitHub Actions deploy IAM user
- AWS module documentation: [`docs/terraform/aws/README.md`](docs/terraform/aws/README.md)
- Repository overview updated for Azure + AWS modules

## v1.0.3 — 2026-05-16

## What's Changed
* Add user_assigned_identity_resource_id output and variable for Azure … by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/6
* Add user_assigned_identity_resource_id output for Azure identity mana… by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/7
* Add managed identity deployment RBAC module for Azure by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/8
* Enhance README and add version-number action by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/9
* Improve version-number action error handling and verification process by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/10


**Full Changelog**: https://github.com/kovacszsolt/actionpit/compare/1.0.1...v1.0.3

## v1.0.2 — 2026-05-15

## What's Changed
* Add user_assigned_identity_resource_id output and variable for Azure … by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/6
* Add user_assigned_identity_resource_id output for Azure identity mana… by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/7
* Add managed identity deployment RBAC module for Azure by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/8
* Enhance README and add version-number action by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/9
* Improve version-number action error handling and verification process by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/10


**Full Changelog**: https://github.com/kovacszsolt/actionpit/compare/1.0.1...v1.0.2

## 1.0.2 — 2026-05-15

## What's Changed
* Add user_assigned_identity_resource_id output and variable for Azure … by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/6
* Add user_assigned_identity_resource_id output for Azure identity mana… by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/7
* Add managed identity deployment RBAC module for Azure by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/8
* Enhance README and add version-number action by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/9
* Improve version-number action error handling and verification process by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/10


**Full Changelog**: https://github.com/kovacszsolt/actionpit/compare/1.0.1...1.0.2

## 1.0.1 — 2026-05-02

## What's Changed
* Add sbeventlog package for structured JSON log event publishing by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/3
* Go package sbeventlog by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/4


**Full Changelog**: https://github.com/kovacszsolt/actionpit/compare/1.0.0...1.0.1

## 1.0.0 — 2026-05-02

## What's Changed
* Add clear-terragrunt.sh script and enhance documentation for Terrafor… by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/1
* Develop by @kovacszsolt in https://github.com/kovacszsolt/actionpit/pull/2

## New Contributors
* @kovacszsolt made their first contribution in https://github.com/kovacszsolt/actionpit/pull/1

**Full Changelog**: https://github.com/kovacszsolt/actionpit/commits/1.0.0
