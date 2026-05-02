# Terraform modules – quick reference

Source code: [`terraform/modules/azure/<module>`](../terraform/modules/azure/).

| Module | Description |
|--------|-------------|
| `action-group` | Azure Monitor **Action Group**: route alerts to email and Azure mobile app push notifications. |
| `ai-foundry` | **Azure AI Services** (`AIServices`) cognitive account with diagnostic settings – AI Foundry / project-style AI workloads. |
| `cae-postgres-vnet` | **Virtual network** with a subnet delegated to Container Apps Environment and a subnet for PostgreSQL Flexible Server (foundation for private connectivity). |
| `cognitive-openai-deployments` | **Azure OpenAI** model deployments (models and capacity) within an existing cognitive account. |
| `communication-service` | **Azure Communication Services** resource (SMS, voice; optional email domain association). |
| `container-app` | **Azure Container App**: single app with ingress, scaling, container image, and secrets management. |
| `container-app-alerts` | **Metric alerts** for Container App CPU, memory, and requests (Azure Monitor). |
| `container-app-environment` | **Container Apps Environment**: shared runtime with Log Analytics integration. |
| `container-app-environment-storage` | Mount **Azure Files** storage to the environment (persistent volumes for containers). |
| `container-app-with-alerts` | **Container App plus built-in alerts** in one module (pre-wired monitoring). |
| `container-registry` | **Azure Container Registry** (SKU, optional admin user). |
| `container-registry-principal-access` | Grant a **service principal** access to ACR (pull/push for CI/CD). |
| `dns-cname-record` | A single **CNAME record** in an Azure DNS zone. |
| `dns-records` | **Multiple TXT and CNAME records** in one zone (map-driven `for_each`). |
| `dns-txt-record` | A single **TXT record** in an Azure DNS zone (e.g. domain validation). |
| `dns-zone` | Create an Azure **DNS zone**. |
| `documentdb-mongocluster` | **Cosmos DB for MongoDB vCore** (DocumentDB Mongo cluster) – cluster and related resources via the Azure API. |
| `email-communication-service` | **Azure Email Communication Service** – transactional email resource. |
| `email-communication-service-domain` | **Custom sender domain** for Email Communication Service (verification, DNS records). |
| `key-vault` | **Azure Key Vault** with network ACLs, access policies or RBAC, optional external secret-sync service principal. |
| `linux-vm` | **Linux virtual machine** with disk, NIC, SSH key or password-based admin. |
| `log-analytics-workspace` | **Log Analytics workspace** for logs and metrics. |
| `portal-dashboard` | **Azure Portal dashboard** with Container App metrics (CPU, memory, requests, logs). |
| `postgresql-flexible-database` | Create a **database** on an existing PostgreSQL Flexible Server. |
| `postgresql-flexible-server` | **Azure Database for PostgreSQL – Flexible Server** (SKU, backup, networking, authentication). |
| `postgresql-flexible-user` | Create an **application user** and password on PostgreSQL (optional random password). |
| `redis` | **Azure Cache for Redis** instance (SKU, capacity, TLS). |
| `resource-group` | **Resource group** with region and tags. |
| `service-bus` | **Azure Service Bus** namespace (SKU; queues and topics). |
| `service-principal-rbac` | **App registration**, client secret, service principal, and **RBAC** role assignments on resource group(s). |
| `static-web-app` | **Azure Static Web Apps** (SKU, optional basic authentication). |
| `static-web-app-apex-dns` | **Apex (root) domain** for Static Web App: custom domain plus DNS TXT validation. |
| `static-web-app-custom-domain` | Attach a **subdomain or hostname** to a Static Web App (CNAME or TXT validation). |
| `storage-account` | **Azure Storage account** (tier, redundancy, encryption settings). |
| `user-assigned-identity` | **User-assigned managed identity** with tags. |
| `web-pubsub` | **Azure Web PubSub** for real-time WebSocket traffic. |
| `workbook` | **Application Insights workbook** with metric views scoped by Container App resource ID. |

More detail: [docs/terraform/README.md](terraform/README.md). Conventions and variable naming: [terraform/README.md](../terraform/README.md).
