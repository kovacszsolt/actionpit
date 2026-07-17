# actionpit

**Reusable building blocks for CI/CD and infrastructure — open, small pieces you can copy or reference.**

**actionpit** ships GitHub Actions and Terraform modules (Azure + AWS) so you spend less time on wiring and more on product work. Code is **Apache 2.0**; read, fork, adapt.

---

## Why use it?

- **Less friction** — common CI/CD and infra patterns already thought through.
- **Composable** — Actions via `uses:`; Terraform via `module` blocks pointing at this repo or a fork.
- **Transparent** — everything lives here; no hidden platform.
- **Multi-cloud** — Azure (`azurerm`) and AWS (`hashicorp/aws`) under the same layout.

---

## What’s in the repo

| Area | Source | Docs |
|------|--------|------|
| **GitHub Actions** | [`github/action/`](github/action/) | [docs/github-action/README.md](docs/github-action/README.md) |
| **Terraform (Azure)** | [`terraform/modules/azure/`](terraform/modules/azure/) | [docs/terraform/azure/README.md](docs/terraform/azure/README.md) |
| **Terraform (AWS)** | [`terraform/modules/aws/`](terraform/modules/aws/) | [docs/terraform/aws/README.md](docs/terraform/aws/README.md) |

### GitHub Actions

| Name | Purpose |
|------|---------|
| `azure-docker-build-push` | Bump semver, build and push a Docker image to Azure Container Registry (metadata tags + layer cache). |
| `discord-deploy-notification` | Post a Discord webhook message (content + embed: repo, branch, actor, commit). |
| `version-number` | Read, bump, and persist a semver (`X.Y.Z`) in a GitHub Environment variable. |

### Terraform (Azure)

| Name | Purpose |
|------|---------|
| `action-group` | Azure Monitor Action Group (email, Azure app push). |
| `ai-foundry` | Azure AI Services (`AIServices`) with diagnostic settings. |
| `cae-postgres-vnet` | VNet with CAE-delegated subnet and PostgreSQL Flexible Server subnet. |
| `cognitive-openai-deployments` | Azure OpenAI model deployments on an existing cognitive account. |
| `communication-service` | Azure Communication Services (SMS, voice; optional email domain). |
| `container-app` | Single Container App (image, ingress, secrets, optional custom domain). |
| `container-app-alerts` | Metric alerts for an existing Container App. |
| `container-app-environment` | Container Apps Environment with Log Analytics. |
| `container-app-environment-storage` | Mount Azure Files on the environment. |
| `container-app-job` | Container Apps Job (cron Schedule or on-demand Manual). |
| `container-app-with-alerts` | Container App plus built-in alerts. |
| `container-registry` | Azure Container Registry (SKU, optional admin). |
| `container-registry-principal-access` | Grant a service principal ACR pull/push. |
| `dns-cname-record` | Single CNAME in an Azure DNS zone. |
| `dns-records` | Multiple TXT and CNAME records via maps. |
| `dns-txt-record` | Single TXT record (e.g. domain validation). |
| `dns-zone` | Azure DNS zone. |
| `documentdb-mongocluster` | Cosmos DB for MongoDB vCore (DocumentDB Mongo cluster). |
| `email-communication-service` | Email Communication Service. |
| `email-communication-service-domain` | Custom sender domain for email. |
| `key-vault` | Key Vault (network ACLs, access policies / RBAC, optional external secrets SP). |
| `linux-vm` | Linux VM with NIC, disk, SSH or password. |
| `log-analytics-workspace` | Log Analytics workspace. |
| `managed-identity-deployment-rbac` | Grant a managed identity Contributor on an RG and AcrPush on ACR. |
| `portal-dashboard` | Portal dashboard with Container App metrics. |
| `postgresql-flexible-database` | Database on an existing Flexible Server. |
| `postgresql-flexible-server` | PostgreSQL Flexible Server. |
| `postgresql-flexible-user` | Application user on PostgreSQL. |
| `redis` | Azure Cache for Redis. |
| `resource-group` | Resource group. |
| `service-bus` | Service Bus namespace (queues/topics). |
| `service-principal-rbac` | App registration + SP + RBAC (e.g. GitHub `AZURE_CREDENTIALS`). |
| `static-web-app` | Azure Static Web Apps. |
| `static-web-app-apex-dns` | Apex domain + DNS TXT for Static Web App. |
| `static-web-app-custom-domain` | Attach a hostname to Static Web App. |
| `storage-account` | Storage account. |
| `user-assigned-identity` | User-assigned managed identity. |
| `web-pubsub` | Azure Web PubSub. |
| `workbook` | Application Insights workbook scoped by Container App. |

### Terraform (AWS)

| Name | Purpose |
|------|---------|
| `account` | AWS Organizations member account (email, OU, access role, billing). |
| `acm` | ACM certificate in `us-east-1` with optional Route53 DNS validation (CloudFront-ready). |
| `azure-container-app-dns` | Route53 CNAME + asuid TXT for an Azure Container Apps custom domain. |
| `cloudfront` | CloudFront distribution in front of an S3 origin (OAC, SPA/static rewrite modes). |
| `identity-center-account-assignment` | Assign an IAM Identity Center user/group + permission set to a member account. |
| `route53` | Hosted zone (create or reuse) plus alias / CNAME / TXT / MX records. |
| `s3` | S3 bucket with encryption, versioning, public-access block, optional CloudFront OAC policy. |
| `s3-cloudfront-oac-policy` | Attach a CloudFront OAC read policy to an existing bucket. |
| `static-website` | Composite S3 + ACM + CloudFront + Route53 alias, plus GitHub Actions deploy IAM user. |

---

## Getting started

1. Pick the area above and open its docs catalogue.
2. Reference the Action or Terraform module from your workflow / stack (`uses:` / `module` `source`).

---

## Philosophy

Small, focused building blocks — not a monolith. **Happy builds and smooth deploys.**
