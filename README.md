# actionpit

Reusable infrastructure building blocks: Terraform modules, GitHub Actions, Go packages, and shell scripts.

## Structure

| Path | Contents |
|------|----------|
| `terraform/modules/aws/` | Terraform modules for AWS |
| `terraform/modules/azure/` | Terraform modules for Azure |
| `github/action/` | Composite GitHub Actions |
| `go/pkg/` | Go modules |
| `scripts/` | Shell utilities |
| `docs/` | Documentation per area |

---

## Terraform — AWS (`terraform/modules/aws/`)

| Module | Purpose |
|--------|---------|
| `account` | AWS Organizations member account |
| `acm` | ACM certificate (us-east-1, DNS validation) |
| `azure-container-app-dns` | Route53 CNAME + TXT for Azure Container Apps custom domain |
| `cloudfront` | CloudFront distribution with S3 origin (OAC) |
| `identity-center-account-assignment` | IAM Identity Center user/permission-set assignment |
| `route53` | Hosted zone + DNS records (alias, CNAME, TXT, MX) |
| `s3` | S3 bucket (versioning, encryption, public access block) |
| `s3-cloudfront-oac-policy` | CloudFront OAC read policy on an existing bucket |
| `ses` | SES domain identity, DKIM, MAIL FROM, DMARC, optional SMTP user |
| `static-website` | S3 + ACM + CloudFront + Route53 + GitHub Actions deploy IAM user |

Docs: [`docs/terraform/aws/README.md`](docs/terraform/aws/README.md)

---

## Terraform — Azure (`terraform/modules/azure/`)

| Module | Purpose |
|--------|---------|
| `action-group` | Azure Monitor action group |
| `ai-foundry` | Azure AI Foundry hub |
| `cae-postgres-vnet` | Container Apps environment + PostgreSQL + VNet wiring |
| `cognitive-openai-deployments` | Azure OpenAI model deployments |
| `communication-service` | Azure Communication Services resource |
| `container-app` | Azure Container App |
| `container-app-alerts` | Alerts for a Container App |
| `container-app-environment` | Container Apps environment |
| `container-app-environment-storage` | Shared storage for a Container Apps environment |
| `container-app-job` | Container App Job |
| `container-app-with-alerts` | Container App + alerts composite |
| `container-registry` | Azure Container Registry |
| `container-registry-principal-access` | ACR pull/push RBAC assignment |
| `dns-cname-record` | DNS CNAME record |
| `dns-records` | Multiple DNS record types |
| `dns-txt-record` | DNS TXT record |
| `dns-zone` | Azure DNS zone |
| `documentdb-mongocluster` | DocumentDB Mongo cluster |
| `email-communication-service` | Email Communication Services resource |
| `email-communication-service-domain` | Email domain for Communication Services |
| `key-vault` | Azure Key Vault |
| `linux-vm` | Linux virtual machine |
| `log-analytics-workspace` | Log Analytics workspace |
| `managed-identity-deployment-rbac` | RBAC for deployment managed identity |
| `portal-dashboard` | Azure Portal dashboard |
| `postgresql-flexible-database` | PostgreSQL Flexible Server database |
| `postgresql-flexible-server` | PostgreSQL Flexible Server |
| `postgresql-flexible-user` | PostgreSQL user + role |
| `redis` | Azure Cache for Redis |
| `resource-group` | Resource group |
| `service-bus` | Azure Service Bus namespace |
| `service-principal-rbac` | RBAC assignment for a service principal |
| `static-web-app` | Azure Static Web App |
| `static-web-app-apex-dns` | Apex DNS for Static Web App |
| `static-web-app-custom-domain` | Custom domain for Static Web App |
| `storage-account` | Azure Storage Account |
| `user-assigned-identity` | User-assigned managed identity |
| `web-pubsub` | Azure Web PubSub |
| `workbook` | Azure Monitor workbook |

Docs: [`docs/terraform/azure/README.md`](docs/terraform/azure/README.md)

---

## GitHub Actions (`github/action/`)

Composite actions (run on caller's runner, no custom Docker image).

| Action | Purpose |
|--------|---------|
| `azure-docker-build-push` | Bump semver, build and push Docker image to Azure Container Registry |
| `discord-deploy-notification` | Post a Discord webhook message (content + deploy embed) |
| `frontend-pnpm-build` | Build a frontend project with pnpm |
| `frontend-s3-deploy` | Deploy static frontend assets to S3 |
| `version-number` | Read / bump / persist a semver in a GitHub Environment variable |

Docs: [`docs/github-action/README.md`](docs/github-action/README.md)

---

## Go packages (`go/pkg/`)

Standalone Go modules. Import path: `github.com/kovacszsolt/actionpit/go/pkg/<package>`.

| Package | Purpose |
|---------|---------|
| `openobserve` | OpenObserve HTTP `_json` ingest client, env/meta loading, structured `Publisher` |
| `oolifecycle` | App lifecycle events: `app.started`, `app.stopped`, `pipeline.failed` |
| `ooai` | AI call cost calculation (decimal math) and `{service}.ai.call` publishing |

Docs: [`docs/go/README.md`](docs/go/README.md)

---

## Scripts (`scripts/`)

| Script | Purpose |
|--------|---------|
| `aws-s3-state.sh` | Create an S3 bucket for Terraform / Terragrunt remote state |
| `azure-certificate-create.sh` | Issue a managed certificate for an Azure Container Apps environment |
| `clear-terragrunt-cache.sh` | Remove `.terragrunt-cache` directories and optionally `.terraform.lock.hcl` files |

Docs: [`docs/scripts/README.md`](docs/scripts/README.md)
