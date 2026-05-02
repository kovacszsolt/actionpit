# Terraform modules (Azure)

Reusable root modules under `modules/azure/<module-name>/`. Each module follows the standard layout: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf`.

## Conventions

### Region (`location`)

Use **Azure Resource Manager location identifiers**: lowercase, no spaces (e.g. `westeurope`, `northeurope`). Do **not** use display names such as `West Europe` in Terraform arguments.

Modules that define a default region use `westeurope` unless documented otherwise. Override per environment via tfvars or CI variables.

### Tags (`tags`)

Pass a `map(string)` where supported. Align with your organisation’s tagging policy (for example `Environment`, `ManagedBy`, `CostCenter`, `Workload`). Required keys are not enforced in code; enforce via policy or review.

### Language

Module `description` strings are **English** for consistency and tooling (terraform-docs, linters).

---

## Variable naming taxonomy

| Pattern | When to use |
|--------|-------------|
| `resource_group_name` | Target resource group for the primary resource. |
| `<resource>_name` | Primary Azure resource name when the module owns one main resource (e.g. `key_vault_name`). |
| `name` | Allowed for single-resource modules only; prefer explicit `<resource>_name` for clarity in larger catalogues. |
| `location` | Always ARM region ID (see above). |
| `tags` | Resource tags (`map(string)`). |

### Known inconsistencies (future alignment)

Some modules predate this catalogue and use different patterns for the same idea. Planned harmonisation (breaking for callers unless using `moved` or new module version):

| Module | Current | Target |
|--------|---------|--------|
| `container-app` | `app_name` | `container_app_name` (optional rename) |
| `postgresql-flexible-server` | `name` | `postgresql_server_name` or keep `name` if documented as single-resource convention |

Do not rename casually; coordinate with consumers and use Terraform `moved` blocks or semantic versioning if modules are published.

---

## Directory and module names

- Prefer **kebab-case** folder names matching the Azure resource family (e.g. `postgresql-flexible-server`, `container-app-environment`).
- Abbreviations (e.g. `cae-postgres-vnet`) are acceptable if listed and explained here:
  - **`cae-postgres-vnet`**: Container Apps Environment–oriented VNet integration for PostgreSQL private connectivity.

---

## Module documentation

- Use **[docs/MODULE_README.template.md](docs/MODULE_README.template.md)** when adding or rewriting a module `README.md`.
- Each module README should include purpose, required variables table, minimal `module` example, notable outputs, and a **Breaking changes** subsection when the module API changes.

---

## Breaking changes (changelog)

| Change | Migration |
|--------|-----------|
| Key Vault: `doppler_object_id` renamed to `external_secrets_object_id` | Replace the argument name when calling the module. Behaviour unchanged. |
| Default `location` where previously `West Europe` | Defaults are now `westeurope`. Explicit `location = "West Europe"` in callers may break Azure provider validation; use `westeurope`. |

---

## Optional tooling

These are **not** required to use the modules but match common enterprise repo practice.

### terraform-docs

Generate variable/output tables into module READMEs:

```bash
terraform-docs markdown table --output-file README.md --output-mode inject /path/to/modules/azure/<module>
```

Install: [terraform-docs](https://terraform-docs.io/).

### tflint

Lint Terraform with Azure rules where applicable:

```bash
tflint --init   # once, with .tflint.hcl
tflint
```

Install: [tflint](https://github.com/terraform-linters/tflint).

### pre-commit

Run format/lint/docs before commit. Example `.pre-commit-config.yaml` hooks:

- `terraform_fmt`
- `terraform_validate` (with backend/init considerations in CI)
- `terraform-docs-go` or shell wrapper calling `terraform-docs`

Install: [pre-commit](https://pre-commit.com/).

---

## Variable descriptions

For public variables, prefer:

1. One line: what the variable controls.
2. Whether it is optional and what the default is.
3. For sensitive or state-heavy values: note state or Key Vault preference.
4. For non-obvious SKUs or APIs: link to Microsoft Learn.
