# actionpit

**Reusable GitHub Actions in one place — free to use, transparent, and ready to drop into your workflows.**

**actionpit** is a public collection of ready-made Action steps you can use in any repository — from side projects to team-owned products. You don’t have to reinvent every small integration: add them to your workflow, pass the documented inputs, and focus on what matters.

---

## Why use it?

- **Faster CI/CD** — less trial and error, fewer detours like “how do I send a Discord message from bash again?”
- **Open and free** — the code is here: read it, fork it, adapt it. This project is licensed under **Apache 2.0**.
- **Composable building blocks** — not a closed platform: wire them into your pipelines with a plain `uses:` reference.
- **Community-friendly** — when something proves useful, others benefit too; if something’s missing, ideas and PRs are welcome.

---

## Who is it for?

Developers and teams who care about DevOps and want to:

- **standardize** notifications, deploy signals, and other repetitive tasks,
- **avoid** maintaining every little helper as a separate npm package or private repo,
- and value solutions that are **clear** and **easy to adopt**.

---

## Actions

- **[discord-deploy-notification](github/action/discord-deploy-notification/)** · [Documentation](docs/discord-deploy-notification.md) — Composite action: [`action.yml`](github/action/discord-deploy-notification/action.yml) defines inputs and env; [`send.sh`](github/action/discord-deploy-notification/send.sh) builds the Discord JSON and posts it with `curl`.

---

## Getting started

1. Browse [`github/action/`](github/action/) — each action lives in its own subdirectory: at minimum `action.yml`; some also ship helper scripts (e.g. [`send.sh`](github/action/discord-deploy-notification/send.sh) for **discord-deploy-notification**).
2. In your workflow, reference this repository and path (tag, branch, or SHA), for example:  
   `uses: kovacszsolt/actionpit/github/action/<action-name>@<ref>` — or use a relative path from the same repo.
3. Provide the documented **inputs** (webhook, text, etc.) and run the workflow.

Per-action parameters and examples live in [`docs/`](docs/) (e.g. [`discord-deploy-notification.md`](docs/discord-deploy-notification.md)). This file is only the **project pitch** and **usage overview**.

---

## Philosophy

actionpit is not a monolith for every problem: **small, focused** Actions you can combine with your own automation. If you like the direction — star the repo, share it with your team, or build something on top. **Happy builds and smooth deploys.**
