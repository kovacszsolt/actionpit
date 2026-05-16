# container-app-job

Azure **Container Apps Job** — batch / cron workloads on an existing Container Apps Environment.

Supports:

- **Schedule** (`trigger_type = "Schedule"`) — cron via `cron_expression` (UTC)
- **Manual** (`trigger_type = "Manual"`) — on-demand runs (Portal, `az containerapp job start`, API)

Registry auth, Key Vault secrets, and env vars follow the same patterns as `container-app`.

## Example — daily cron (scoutbuddy)

```hcl
module "scoutbuddy_cron" {
  source = "git::https://github.com/kovacszsolt/actionpit.git//terraform/modules/azure/container-app-job?ref=main"

  job_name                     = "caj-scoutbuddy-cron"
  resource_group_name          = "rg-scoutbuddy"
  location                     = "westeurope"
  container_app_environment_id = dependency.cae.outputs.environment_id

  trigger_type    = "Schedule"
  cron_expression = "0 6 * * *" # daily 06:00 UTC

  replica_timeout_in_seconds = 3600
  replica_retry_limit        = 1

  container_name  = "scoutbuddy"
  container_image = "acrsharedsmith.azurecr.io/scoutbuddy/cron:1.0.0"
  cpu             = 0.5
  memory          = "1Gi"

  registry_server      = "acrsharedsmith.azurecr.io"
  registry_identity_id = dependency.identity.outputs.identity_resource_id

  user_assigned_identity_ids = [dependency.identity.outputs.identity_resource_id]

  key_vault_secrets = [
    {
      name          = "service-bus-connection-string"
      key_vault_url = "https://kv-example.vault.azure.net/secrets/SB-CONN"
    },
  ]
  key_vault_secrets_identity_id = dependency.identity.outputs.identity_resource_id

  container_secrets = [
    { name = "SERVICE_BUS_CONNECTION_STRING", secretRef = "service-bus-connection-string" },
  ]

  container_env = {
    SCOUTBUDDY_CONFIG = "/app/settings/settings.app.json"
  }

  tags = { Project = "scoutbuddy" }
}
```

## Example — manual job

```hcl
  trigger_type = "Manual"
  # cron_expression omitted
```

## Notes

- `schedule_trigger_config` is **ForceNew** in the Azure provider — changing `cron_expression` replaces the job.
- Cron uses **UTC**.
- Requires `azurerm` **>= 3.103** (resource `azurerm_container_app_job`).
