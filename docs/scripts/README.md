# Scripts (`scripts/`)

Reusable shell utilities under [`scripts/`](../../scripts/). Each script is standalone, parameterized, and has no hard-coded environment-specific defaults.

Common conventions:

- `set -euo pipefail` — fail fast on errors
- `--dry-run` — print actions without executing anything
- `--help` / `-h` / `help` — usage text
- Required values fallback to env variables (documented per script)
- Stderr for status/progress, stdout for machine-readable output where relevant

---

## Quick catalogue

| Script | Cloud | Purpose |
|--------|-------|---------|
| [`aws-s3-state.sh`](#aws-s3-statesh) | AWS | Create an S3 bucket for Terraform / Terragrunt remote state |
| [`azure-certificate-create.sh`](#azure-certificate-createsh) | Azure | Issue a managed certificate for an Azure Container Apps environment |
| [`clear-terragrunt-cache.sh`](#clear-terragrunt-cachesh) | — | Remove `.terragrunt-cache` directories and optionally `.terraform.lock.hcl` files |

---

## Scripts

### `aws-s3-state.sh`

Creates an S3 bucket suitable for Terraform / Terragrunt remote state with versioning, AES256 encryption, public access block, and `BucketOwnerEnforced` ownership.

**Requirements:** AWS CLI authenticated.

**Generated bucket name (when `--bucket` is not set):**

```text
terraform-state-<ACCOUNT_ID>-<REGION>[-SUFFIX]
```

**Usage:**

```bash
./aws-s3-state.sh [--region REGION] [--suffix SUFFIX] [--bucket BUCKET_NAME] [--dry-run]
```

| Option | Required | Notes |
|--------|:--------:|-------|
| `--region REGION` | no | Fallback: `AWS_REGION` env or AWS CLI default region |
| `--suffix SUFFIX` | no | Appended to the generated bucket name |
| `--bucket NAME` | no | Full bucket name (overrides generated name) |
| `--dry-run` | no | Print planned actions without creating anything |

**Environment:**

| Variable | Used when |
|----------|-----------|
| `AWS_REGION` | `--region` is not provided |

**Bucket settings applied:**

- Versioning: Enabled
- Encryption: AES256 (SSE-S3)
- Public access: blocked
- Object ownership: BucketOwnerEnforced
- Namespace: `account-regional` (when name matches generated pattern)

**Examples:**

```bash
./aws-s3-state.sh
./aws-s3-state.sh --region eu-north-1 --suffix shared
AWS_REGION=eu-central-1 ./aws-s3-state.sh --dry-run
./aws-s3-state.sh --bucket my-custom-state-bucket --region us-east-1
```

**`root.hcl` snippet (printed after creation):**

```hcl
locals {
  remote_state_config = {
    bucket = "terraform-state-<ACCOUNT_ID>-<REGION>"
    region = "<REGION>"
  }
}
```

---

### `azure-certificate-create.sh`

Issues a managed TLS certificate for an Azure Container Apps custom domain via `az containerapp env certificate create`.

**Requirements:** Azure CLI authenticated.

**Usage:**

```bash
./azure-certificate-create.sh \
  --resource-group RESOURCE_GROUP \
  --environment ENVIRONMENT \
  --hostname HOSTNAME \
  [--validation-method CNAME|TXT] \
  [--subscription SUBSCRIPTION_ID] \
  [--dry-run]
```

| Option | Required | Default | Notes |
|--------|:--------:|---------|-------|
| `--resource-group NAME` | yes* | — | Azure resource group |
| `--environment NAME` | yes* | — | Container Apps environment name; alias: `--env` |
| `--hostname HOSTNAME` | yes* | — | Custom domain; alias: `--domain` |
| `--validation-method VALUE` | no | `CNAME` | Domain validation method (`CNAME` or `TXT`) |
| `--subscription ID` | no | current CLI context | Azure subscription ID or name |
| `--dry-run` | no | — | Print the `az` command without running it |

*Required unless the corresponding env variable is set.

**Environment:**

| Variable | Used when |
|----------|-----------|
| `AZURE_RESOURCE_GROUP` | `--resource-group` is not provided |
| `CONTAINER_APP_ENVIRONMENT` | `--environment` is not provided |
| `CERT_HOSTNAME` | `--hostname` is not provided |
| `AZURE_SUBSCRIPTION_ID` | `--subscription` is not provided |

**Examples:**

```bash
./azure-certificate-create.sh \
  --resource-group rg-myapp-prod \
  --environment cae-myapp-prod \
  --hostname app.example.com

./azure-certificate-create.sh \
  --resource-group rg-myapp-prod \
  --environment cae-myapp-prod \
  --hostname app.example.com \
  --validation-method TXT \
  --dry-run
```

---

### `clear-terragrunt-cache.sh`

Removes `.terragrunt-cache` directories recursively under a path. Optionally also removes `.terraform.lock.hcl` files.

**Usage:**

```bash
./clear-terragrunt-cache.sh [--path PATH] [--include-lock-files] [--dry-run]
```

| Option | Required | Default | Notes |
|--------|:--------:|---------|-------|
| `--path PATH` | no | current working directory | Root to search; alias: `--root` |
| `--include-lock-files` | no | off | Also remove `.terraform.lock.hcl` files |
| `--dry-run` | no | — | Print matched paths without deleting |

**Environment:**

| Variable | Used when |
|----------|-----------|
| `TERRAGRUNT_CLEAR_PATH` | `--path` is not provided |

**Examples:**

```bash
./clear-terragrunt-cache.sh
./clear-terragrunt-cache.sh --path ./infrastructure
./clear-terragrunt-cache.sh --path . --include-lock-files
./clear-terragrunt-cache.sh --path ./infrastructure --dry-run
```

---

## Related

| Path | Notes |
|------|-------|
| [`docs/go/README.md`](../go/README.md) | Go packages catalogue |
| [`docs/github-action/README.md`](../github-action/README.md) | GitHub Actions catalogue |
| [`docs/terraform/aws/README.md`](../terraform/aws/README.md) | Terraform AWS modules |
| [`docs/terraform/azure/README.md`](../terraform/azure/README.md) | Terraform Azure modules |
