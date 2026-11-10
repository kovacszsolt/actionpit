# actionpit

Reusable building blocks for shipping apps on **GitHub Actions**, **Terraform** (AWS & Azure), and **Go**.

Pin a **tag or commit SHA** in production — avoid floating `@main` / `@latest` for workflows and modules you depend on.

## What’s in here

| Area | Path | Docs |
|------|------|------|
| Composite GitHub Actions | [`github/action/`](github/action/) | [docs/github-action](docs/github-action/README.md) |
| Terraform modules (AWS) | [`terraform/modules/aws/`](terraform/modules/aws/) | [docs/terraform/aws](docs/terraform/aws/README.md) |
| Terraform modules (Azure) | [`terraform/modules/azure/`](terraform/modules/azure/) | [docs/terraform/azure](docs/terraform/azure/README.md) |
| Go packages | [`go/pkg/`](go/pkg/) | [docs/go](docs/go/README.md) |
| Shell scripts | [`scripts/`](scripts/) | [docs/scripts](docs/scripts/README.md) |

---

## GitHub Actions

```yaml
uses: kovacszsolt/actionpit/github/action/<action-name>@<ref>
```

| Action | Purpose |
|--------|---------|
| [`version-number`](github/action/version-number/) | Read / bump / persist a semver in a GitHub Environment variable |
| [`azure-docker-build-push`](github/action/azure-docker-build-push/) | Bump semver, build & push an image to Azure Container Registry |
| [`azure-container-app-deploy`](github/action/azure-container-app-deploy/) | Update a Container App image (+ build metadata env vars) |
| [`azure-container-app-job-deploy`](github/action/azure-container-app-job-deploy/) | Update a Container App Job image (+ build metadata env vars) |
| [`frontend-pnpm-build`](github/action/frontend-pnpm-build/) | Install & build a pnpm Vite frontend, upload `dist` artifact |
| [`frontend-s3-deploy`](github/action/frontend-s3-deploy/) | Sync a `dist` artifact to S3 and optionally invalidate CloudFront |
| [`discord-deploy-notification`](github/action/discord-deploy-notification/) | Post a Discord webhook with repo / branch / actor / commit |

Example:

```yaml
- uses: kovacszsolt/actionpit/github/action/discord-deploy-notification@v1
  with:
    webhook-url: ${{ secrets.DISCORD_WEBHOOK_URL }}
    content: "Deploy finished"
```

Full catalogue and inputs: **[docs/github-action/README.md](docs/github-action/README.md)**.

---

## Terraform

Source a module from git (or a local checkout):

```hcl
module "rg" {
  source = "git::https://github.com/kovacszsolt/actionpit.git//terraform/modules/azure/resource-group?ref=<tag>"

  resource_group_name = "rg-example"
  location            = "westeurope"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

### AWS highlights

Organizations account, ACM (CloudFront / `us-east-1`), Route53, S3 + CloudFront + OAC, SES, static website stack, and Route53 helpers for Azure Container Apps / Static Web Apps DNS.

→ **[docs/terraform/aws/README.md](docs/terraform/aws/README.md)**

### Azure highlights

Resource groups, Container Apps / Jobs / Environment, ACR, Key Vault, PostgreSQL Flexible Server, Redis, Service Bus, Static Web Apps, DNS, Communication Services, AI Foundry / OpenAI deployments, and monitoring (action groups, dashboards, workbooks).

→ **[docs/terraform/azure/README.md](docs/terraform/azure/README.md)**

---

## Go packages

Each package is its own module:

```text
github.com/kovacszsolt/actionpit/go/pkg/<package>
```

```bash
go get github.com/kovacszsolt/actionpit/go/pkg/openobserve@<ref>
go get github.com/kovacszsolt/actionpit/go/pkg/auth@<ref>
```

| Package | Purpose |
|---------|---------|
| [`openobserve`](go/pkg/openobserve/) | HTTP `_json` ingest client + nil-safe structured event `Publisher` |
| [`oolifecycle`](go/pkg/oolifecycle/) | `app.started` / `app.stopped` / `pipeline.failed` helpers |
| [`ooai`](go/pkg/ooai/) | AI call cost calculation and `{service}.ai.call` events |
| [`auth`](go/pkg/auth/) | HS256 JWT verification + optional Echo Bearer middleware |
| [`s3sync`](go/pkg/s3sync/) | Sync a local directory to S3 (optional CloudFront invalidation) |
| [`templatedmail`](go/pkg/templatedmail/) | Handlebars templates + SMTP send (STARTTLS / 465) |

Full catalogue and wiring notes: **[docs/go/README.md](docs/go/README.md)**.

---

## Scripts

Standalone bash utilities (`--help`, `--dry-run` where useful):

| Script | Purpose |
|--------|---------|
| [`aws-s3-state.sh`](scripts/aws-s3-state.sh) | Create an S3 bucket for Terraform / Terragrunt remote state |
| [`azure-certificate-create.sh`](scripts/azure-certificate-create.sh) | Issue a managed certificate on a Container Apps environment |
| [`clear-terragrunt-cache.sh`](scripts/clear-terragrunt-cache.sh) | Remove `.terragrunt-cache` (optional lock files) |

Details: **[docs/scripts/README.md](docs/scripts/README.md)**.

---

## Layout

```text
actionpit/
├── github/action/          # composite actions
├── terraform/modules/
│   ├── aws/
│   └── azure/
├── go/pkg/                 # one Go module per package
├── scripts/
└── docs/                   # catalogues & deeper guides
```

## License

[Apache License 2.0](LICENSE)
