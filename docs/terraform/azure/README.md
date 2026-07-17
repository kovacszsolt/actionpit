# Terraform Azure modules

User-facing documentation for reusable modules under [`terraform/modules/azure/`](../../../terraform/modules/azure/).

AWS modules: **[aws/README.md](../aws/README.md)**. Code conventions (`location`, tags, variable naming, breaking changes) live in [`terraform/README.md`](../../../terraform/README.md).

## Requirements

| Name | Version |
|------|---------|
| Terraform | typically `>= 1.2` / `>= 1.3` (see each module’s `versions.tf`) |
| `hashicorp/azurerm` | see each module’s `versions.tf` |
| Extra providers | some modules also need `azuread`, `random`, or `azapi` |

### Region (`location`)

Use **Azure Resource Manager location identifiers**: lowercase, no spaces (e.g. `westeurope`, `northeurope`). Do **not** use display names such as `West Europe`.

Modules that define a default region use `westeurope` unless documented otherwise.

### Tags

Where supported, pass `tags` as `map(string)`. Align with your organisation’s tagging policy (`Environment`, `ManagedBy`, `CostCenter`, `Workload`, …). Required keys are not enforced in module code.

### Variable naming

| Pattern | When to use |
|--------|-------------|
| `resource_group_name` | Target resource group for the primary resource. |
| `<resource>_name` | Primary Azure resource name when the module owns one main resource (e.g. `key_vault_name`). |
| `name` | Allowed for single-resource modules only; prefer explicit `<resource>_name` in larger catalogues. |
| `location` | Always ARM region ID. |
| `tags` | Resource tags (`map(string)`). |

---

## Quick catalogue

Full table also in **[terraform-modules.md](../../terraform-modules.md)** (may lag new modules — this README is authoritative for the tree under `modules/azure/`).

| Module | Description |
|--------|-------------|
| `action-group` | Azure Monitor **Action Group** (email, Azure app push). |
| `ai-foundry` | **Azure AI Services** (`AIServices`) with diagnostic settings. |
| `cae-postgres-vnet` | **VNet** with CAE-delegated subnet + PostgreSQL Flexible Server subnet. |
| `cognitive-openai-deployments` | **Azure OpenAI** model deployments on an existing cognitive account. |
| `communication-service` | **Azure Communication Services** (SMS, voice; optional email domain). |
| `container-app` | Single **Container App** (image, ingress, secrets, optional custom domain). |
| `container-app-alerts` | **Metric alerts** for an existing Container App. |
| `container-app-environment` | **Container Apps Environment** with Log Analytics. |
| `container-app-environment-storage` | Mount **Azure Files** on the environment. |
| `container-app-job` | **Container Apps Job** (cron `Schedule` or on-demand `Manual`). |
| `container-app-with-alerts` | Container App plus **built-in alerts**. |
| `container-registry` | **Azure Container Registry** (SKU, optional admin). |
| `container-registry-principal-access` | Grant a **service principal** ACR pull/push. |
| `dns-cname-record` | Single **CNAME** in an Azure DNS zone. |
| `dns-records` | **Multiple TXT and CNAME** records via maps. |
| `dns-txt-record` | Single **TXT** record (e.g. domain validation). |
| `dns-zone` | Azure **DNS zone**. |
| `documentdb-mongocluster` | **Cosmos DB for MongoDB vCore** (DocumentDB Mongo cluster). |
| `email-communication-service` | **Email Communication Service**. |
| `email-communication-service-domain` | **Custom sender domain** for email. |
| `key-vault` | **Key Vault** (network ACLs, access policies / RBAC, optional external secrets SP). |
| `linux-vm` | **Linux VM** with NIC, disk, SSH or password. |
| `log-analytics-workspace` | **Log Analytics** workspace. |
| `managed-identity-deployment-rbac` | Grant a managed identity **Contributor** on an RG + **AcrPush** on ACR. |
| `portal-dashboard` | **Portal dashboard** with Container App metrics. |
| `postgresql-flexible-database` | **Database** on an existing Flexible Server. |
| `postgresql-flexible-server` | **PostgreSQL Flexible Server**. |
| `postgresql-flexible-user` | **Application user** on PostgreSQL. |
| `redis` | **Azure Cache for Redis**. |
| `resource-group` | **Resource group**. |
| `service-bus` | **Service Bus** namespace (queues/topics). |
| `service-principal-rbac` | App registration + SP + **RBAC** (e.g. GitHub `AZURE_CREDENTIALS`). |
| `static-web-app` | **Azure Static Web Apps**. |
| `static-web-app-apex-dns` | **Apex domain** + DNS TXT for SWA. |
| `static-web-app-custom-domain` | Attach a **hostname** to SWA. |
| `storage-account` | **Storage account**. |
| `user-assigned-identity` | **User-assigned managed identity**. |
| `web-pubsub` | **Azure Web PubSub**. |
| `workbook` | **Application Insights workbook** scoped by Container App. |

---

## Modules by category

### Foundation and resource group

- **`resource-group`** – Baseline resource group; most modules expect `resource_group_name` and `location`.
- **`user-assigned-identity`** – User-assigned managed identity (Container Apps, Key Vault, ACR).
- **`managed-identity-deployment-rbac`** – RBAC for a deploy identity: `Contributor` on a resource group and `AcrPush` on an existing ACR. Pair with `user-assigned-identity` and optional Entra federated credentials for GitHub OIDC.

### Container Apps and containers

- **`container-app-environment`** – Shared Container Apps Environment; prerequisite for apps/jobs and logging.
- **`container-app-environment-storage`** – Azure Files shares as persistent volumes.
- **`container-app`** – One Container App: image, CPU/memory, ingress, secrets (Key Vault or inline), optional custom domain.
- **`container-app-job`** – Container Apps Job: `Schedule` (cron UTC) or `Manual` (on-demand). Registry auth / Key Vault patterns align with `container-app`.
- **`container-app-with-alerts`** – Container App plus built-in Azure Monitor alerts.
- **`container-app-alerts`** – Alerts only for an existing Container App.

### Container registry

- **`container-registry`** – ACR (SKU, optional admin user).
- **`container-registry-principal-access`** – Grant a service principal ACR access for CI/CD.

### Networking and DNS

- **`cae-postgres-vnet`** – VNet with a subnet delegated to Container Apps Environment and a subnet for PostgreSQL Flexible Server private access.
- **`dns-zone`** – Azure DNS zone.
- **`dns-cname-record`**, **`dns-txt-record`** – One record per module.
- **`dns-records`** – Multiple TXT and CNAME records via variable maps.

### Databases

- **`postgresql-flexible-server`** – PostgreSQL Flexible Server (version, SKU, backup, VNet, password or random).
- **`postgresql-flexible-database`** – Database on an existing server.
- **`postgresql-flexible-user`** – Application user (provider uses admin credentials).
- **`documentdb-mongocluster`** – Cosmos DB for MongoDB vCore (cluster, firewall, users via ARM API).

### Cache and messaging

- **`redis`** – Azure Cache for Redis.
- **`service-bus`** – Service Bus namespace (queues and topics).

### Identity and secrets

- **`key-vault`** – Key Vault with network rules, access policies or RBAC; optional `external_secrets_object_id` for secret-sync principals.
- **`service-principal-rbac`** – App registration, client secret, service principal, and RBAC on a scope. Outputs suitable for GitHub Actions `AZURE_CREDENTIALS`.

### AI and cognitive services

- **`ai-foundry`** – Azure AI Services account (`AIServices`) with diagnostic settings.
- **`cognitive-openai-deployments`** – Azure OpenAI deployments on an existing cognitive account.

### Communication and email

- **`communication-service`** – Azure Communication Services; optional email domain association.
- **`email-communication-service`** – Email Communication Service resource.
- **`email-communication-service-domain`** – Custom domain and verification for sending.

### Static web

- **`static-web-app`** – Azure Static Web Apps.
- **`static-web-app-custom-domain`** – Attach a hostname (CNAME or TXT validation).
- **`static-web-app-apex-dns`** – Root domain DNS plus SWA TXT token.

### Observability and operations

- **`log-analytics-workspace`** – Log Analytics for Container Apps Environment and other resources.
- **`action-group`** – Alert targets (email, Azure app).
- **`portal-dashboard`** – Portal dashboard template with Container App metrics.
- **`workbook`** – Application Insights workbook from JSON, keyed by Container App resource ID.

### Other compute and integration

- **`linux-vm`** – Linux VM with NIC, disk, SSH key or password.
- **`storage-account`** – Storage account (blob/file scenarios).
- **`web-pubsub`** – Azure Web PubSub for real-time connections.

---

## Typical composition

```text
resource-group
    │
    ├─► log-analytics-workspace ──► container-app-environment
    │                                      │
    │                                      ├─► container-app / container-app-job
    │                                      └─► container-app-environment-storage
    │
    ├─► user-assigned-identity ──► managed-identity-deployment-rbac
    │                                      │
    │                                      └─► container-registry (AcrPush)
    │
    ├─► key-vault
    ├─► postgresql-flexible-server ──► database + user
    │         ▲
    │         └── cae-postgres-vnet (private connectivity)
    │
    ├─► redis / service-bus / storage-account
    └─► static-web-app ──► custom-domain / apex-dns
```

Minimal **resource group** sketch:

```hcl
module "rg" {
  source = "../../modules/azure/resource-group"

  resource_group_name = "rg-example"
  location            = "westeurope"

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
```

---

## Breaking changes (selected)

| Change | Migration |
|--------|-----------|
| Key Vault: `doppler_object_id` → `external_secrets_object_id` | Rename the argument; behaviour unchanged. |
| Default `location` previously `West Europe` | Use ARM IDs such as `westeurope`. |

Full conventions and tooling notes: [`terraform/README.md`](../../../terraform/README.md).

---

## Module README template

When adding a per-module `README.md` under `terraform/modules/azure/<module>/`, use [`terraform/docs/MODULE_README.template.md`](../../../terraform/docs/MODULE_README.template.md).

## Related files

| File | Contents |
|------|----------|
| [docs/terraform/README.md](../README.md) | Index of Azure + AWS docs |
| [docs/terraform/aws/README.md](../aws/README.md) | AWS module catalogue |
| [docs/terraform-modules.md](../../terraform-modules.md) | Azure quick-reference table |
| [terraform/README.md](../../../terraform/README.md) | `location`, tags, variable conventions, tooling |
| [terraform/modules/azure/](../../../terraform/modules/azure/) | Module source |
