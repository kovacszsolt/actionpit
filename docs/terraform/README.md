# Terraform modules – detailed documentation

This directory holds **user-facing documentation** for the reusable modules under [`terraform/modules/azure/`](../terraform/modules/azure/). Code conventions (region format, tags, variable naming) are documented in [`terraform/README.md`](../terraform/README.md).

## Quick catalogue

All modules in one table: **[terraform-modules.md](../terraform-modules.md)**.

## Modules by category

### Foundation and resource group

- **`resource-group`** – Baseline **resource group**; most modules expect `resource_group_name` and `location`.
- **`user-assigned-identity`** – **User-assigned managed identity** – commonly paired with Container Apps, Key Vault policies, and ACR access.

### Container Apps and containers

- **`container-app-environment`** – **Container Apps Environment**: shared logical runtime; prerequisite for multiple Container Apps and logging.
- **`container-app-environment-storage`** – Attach **Azure Files** shares so containers get persistent volumes.
- **`container-app`** – Defines one **Container App**: image, CPU/memory, ingress, secrets (Key Vault or inline), optional custom domain.
- **`container-app-with-alerts`** – Same scope as `container-app` plus **built-in Azure Monitor alerts** (less manual wiring).
- **`container-app-alerts`** – **Alerts only** for an existing Container App’s metrics (when the app is created elsewhere).

### Container registry

- **`container-registry`** – Create **ACR** (SKU, optional admin user).
- **`container-registry-principal-access`** – Grant a **service principal** rights on ACR (e.g. CI/CD pull/push).

### Networking and DNS

- **`cae-postgres-vnet`** – **Virtual network** with two subnets: one **delegated to Container Apps Environment**, one for **PostgreSQL Flexible Server** private access; connects CAE and PostgreSQL over VNet.
- **`dns-zone`** – Azure **DNS zone**.
- **`dns-cname-record`**, **`dns-txt-record`** – One record per module type.
- **`dns-records`** – **Multiple TXT and CNAME** records in one zone via a variable map.

### Databases

- **`postgresql-flexible-server`** – **PostgreSQL Flexible Server** (version, SKU, backup, VNet integration, password or random password).
- **`postgresql-flexible-database`** – **Database** on the server (server usually created by another module).
- **`postgresql-flexible-user`** – Create an **application user** on the server (provider uses admin credentials).
- **`documentdb-mongocluster`** – **Cosmos DB for MongoDB vCore** (Azure DocumentDB Mongo API); cluster, firewall, and users via the ARM API resource.

### Cache and messaging

- **`redis`** – **Azure Cache for Redis**.
- **`service-bus`** – **Service Bus** namespace (queues and topics).

### Identity and secrets

- **`key-vault`** – **Key Vault** with network rules, access policies or RBAC; optional external secret-sync **service principal** object ID (`external_secrets_object_id`).
- **`service-principal-rbac`** – **App registration**, client secret, service principal, and **RBAC** assignments on a scope (e.g. resource group). Outputs suitable for GitHub Actions `AZURE_CREDENTIALS`.

### AI and cognitive services

- **`ai-foundry`** – **Azure AI Services** account (`AIServices`) with diagnostic settings – AI Foundry–style projects.
- **`cognitive-openai-deployments`** – **Azure OpenAI deployments** (models, versions) on an existing cognitive account.

### Communication and email

- **`communication-service`** – **Azure Communication Services** (SMS, voice); optional **email domain association**.
- **`email-communication-service`** – **Email Communication Service** as its own resource (transactional email).
- **`email-communication-service-domain`** – **Custom domain** and verification for sending email.

### Static web

- **`static-web-app`** – **Azure Static Web Apps**.
- **`static-web-app-custom-domain`** – Attach a **hostname** (CNAME or TXT validation).
- **`static-web-app-apex-dns`** – **Root domain** DNS plus SWA (TXT token).

### Observability and operations

- **`log-analytics-workspace`** – **Log Analytics** – ingest logs from Container Apps Environment and other resources.
- **`action-group`** – **Action Group** – alert targets (email, Azure app).
- **`portal-dashboard`** – **Azure Portal dashboard** template with Container App metrics.
- **`workbook`** – **Application Insights workbook** from JSON template, keyed by Container App resource ID.

### Other compute and integration

- **`linux-vm`** – **Linux VM** with NIC, disk, SSH key or password.
- **`storage-account`** – **Storage account** (blob/file scenarios).
- **`web-pubsub`** – **Azure Web PubSub** for real-time connections.

## Template for new module READMEs

When authoring a module-level `README`, use [`terraform/docs/MODULE_README.template.md`](../terraform/docs/MODULE_README.template.md).

## Related files

| File | Contents |
|------|----------|
| [terraform-modules.md](../terraform-modules.md) | Full module list as a table |
| [terraform/README.md](../terraform/README.md) | `location`, `tags`, variable conventions, breaking changes |
| [terraform/docs/MODULE_README.template.md](../terraform/docs/MODULE_README.template.md) | Module README template |
