# actionpit

**Reusable GitHub Actions and Azure Terraform modules — open, small pieces you can copy or reference.**

**actionpit** ships ready-made workflow steps and Terraform modules so you spend less time wiring integrations and more on product work. Code is **Apache 2.0**; read, fork, adapt.

---

## Why use it?

- **Less CI/CD friction** — common patterns (notifications, infra modules) already thought through.
- **Composable** — Actions via `uses:`; Terraform via `module` blocks pointing at this repo or a fork.
- **Transparent** — everything lives here; no hidden platform.

---

## GitHub Actions

Composite and scripted steps under [`github/action/`](github/action/) and [`.github/actions/`](.github/actions/). Each action is its own folder (`action.yml` + optional scripts).

| Action | Docs |
|--------|------|
| [discord-deploy-notification](github/action/discord-deploy-notification/) | [docs/discord-deploy-notification.md](docs/discord-deploy-notification.md) |
| [version-number](.github/actions/version-number/) | [docs/version-number.md](docs/version-number.md) |

**Use in a workflow:** `uses: <owner>/actionpit/<action-path>@<ref>` and pass the documented **inputs**.
Examples:
- `uses: <owner>/actionpit/github/action/discord-deploy-notification@<ref>`
- `uses: <owner>/actionpit/.github/actions/version-number@<ref>`

---

## Terraform modules (Azure)

Reusable modules under [`terraform/modules/azure/`](terraform/modules/azure/).

| Doc | What |
|-----|------|
| [docs/terraform-modules.md](docs/terraform-modules.md) | One-page **module index** (table) |
| [docs/terraform/README.md](docs/terraform/README.md) | **Grouped** descriptions |
| [terraform/README.md](terraform/README.md) | **Conventions** (`location`, tags, naming, breaking changes) |

---

## Getting started

1. **Actions** — Pick a folder under [`github/action/`](github/action/) or [`.github/actions/`](.github/actions/), read the matching file in [`docs/`](docs/), reference the action in your workflow.
2. **Terraform** — Point `module { source = "..." }` at this repo (or vendor the path); follow [`terraform/README.md`](terraform/README.md) for region and tags.

---

## Philosophy

Small, focused building blocks — not a monolith. **Happy builds and smooth deploys.**
