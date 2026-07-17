# GitHub Actions (`github/action`)

Reusable **composite** GitHub Actions under [`github/action/`](../../github/action/). Each action is its own folder with `action.yml` (and optional scripts). They run on the **caller’s runner** — no custom Docker image for the action itself.

Per-action deep dives (where present) live next to this catalogue under [`docs/`](../).

## How to use

Reference an action from another repository:

```yaml
uses: <owner>/actionpit/github/action/<action-name>@<ref>
```

Pass documented **inputs** via `with:`. Prefer a tag or commit SHA over a floating branch for production workflows.

Examples:

```yaml
- uses: kovacszsolt/actionpit/github/action/discord-deploy-notification@main
  with:
    webhook-url: ${{ secrets.DISCORD_WEBHOOK_URL }}
    content: "Deploy finished"

- uses: kovacszsolt/actionpit/github/action/version-number@main
  with:
    environment_name: main
    variable_name: APP_VERSION
    write_token: ${{ secrets.GH_VARIABLES_TOKEN }}
    bump: patch
```

## Quick catalogue

| Action | Path | Docs | Purpose |
|--------|------|------|---------|
| **discord-deploy-notification** | [`github/action/discord-deploy-notification/`](../../github/action/discord-deploy-notification/) | [discord-deploy-notification.md](../discord-deploy-notification.md) | Post a Discord webhook message (content + embed: repo, branch, actor, commit). |
| **version-number** | [`github/action/version-number/`](../../github/action/version-number/) | [version-number.md](../version-number.md) | Read / bump / persist a semver (`X.Y.Z`) in a GitHub Environment variable. |
| **azure-docker-build-push** | [`github/action/azure-docker-build-push/`](../../github/action/azure-docker-build-push/) | _(this page)_ | Bump semver, build & push a Docker image to **Azure Container Registry** with metadata tags and layer cache. |

---

## Conventions

- **Composite only** — `runs.using: composite`; shell steps use `bash`.
- **Secrets as inputs** — never hardcode webhook URLs, registry passwords, or PATs; pass `secrets.*` into inputs.
- **English** `name` / `description` / input docs in `action.yml` for marketplace-style clarity.
- **Folder layout** — one action per directory under `github/action/<name>/`; keep scripts next to `action.yml` when needed (e.g. `send.sh`).

### Runner tools

| Action | Needs on PATH / available |
|--------|---------------------------|
| `discord-deploy-notification` | `bash`, `jq`, `curl` (default on GitHub-hosted Ubuntu/macOS) |
| `version-number` | `bash`, `curl`, `jq`, `npx` (semver via `npx --yes semver`) |
| `azure-docker-build-push` | Docker / Buildx (via `docker/setup-buildx-action`); network to ACR and GitHub API |

---

## Actions

### `discord-deploy-notification`

Posts one Discord Incoming Webhook message: a plain-text **content** line plus an **embed** (repository, branch, actor, commit message/URL).

| Input | Required | Notes |
|-------|:--------:|-------|
| `webhook-url` | yes | Discord webhook URL (secret). |
| `content` | yes | Message body above the embed. |
| `embed-title` | no | Default: `GitHub Actions notification`. |

Full details: [docs/discord-deploy-notification.md](../discord-deploy-notification.md).

### `version-number`

Increments a semantic version stored as a **GitHub Environment variable** and writes it back. Outputs `version_number` (or `0.0.0-unknown` on missing/invalid value or failed update).

| Input | Required | Default | Notes |
|-------|:--------:|---------|-------|
| `environment_name` | yes | — | Environment that owns the variable. |
| `variable_name` | yes | — | Variable key (`X.Y.Z`). |
| `write_token` | yes | — | Token with Variables read/write on the repo. |
| `bump` | no | `patch` | `major` / `minor` / `patch`. |
| `repository_name` | no | current repo | `owner/name`. |

Full details: [docs/version-number.md](../version-number.md).

### `azure-docker-build-push`

Orchestrates a common ACR publish path:

1. Stamp `IMAGE_BUILD_TIME` (UTC).
2. Call **`version-number`** to bump the environment semver.
3. Set up Buildx, log in to ACR, compute metadata tags (branch + version).
4. Build/push with GHA + registry `buildcache`, passing build-args (`IMAGE_BUILD_TIME`, `IMAGE_GIT_SHA`, `VERSION_NUMBER`, `SERVICE_NAME`).

| Input | Required | Default | Notes |
|-------|:--------:|---------|-------|
| `registry` | yes | — | ACR host (no image path), e.g. `myregistry.azurecr.io`. |
| `image_name` | yes | — | Image repo path inside the registry; also GHA cache scope. |
| `acr_username` / `acr_password` | yes | — | ACR credentials (secrets). |
| `environment_name` / `variable_name` / `write_token` | yes | — | Passed through to `version-number`. |
| `repository_name` | no | current repo | For the version variable API. |
| `bump` | no | `patch` | Semver segment. |
| `docker_context` | no | `.` | Build context. |
| `dockerfile` | no | `./Dockerfile` | Dockerfile path. |

| Output | Description |
|--------|-------------|
| `version_number` | Bumped semver. |
| `image_tags` | Newline-separated tags from metadata-action. |
| `deploy_image` | `${registry}/${image_name}:${version_number}`. |
| `t` | UTC build timestamp (`IMAGE_BUILD_TIME`). |

Example:

```yaml
- id: image
  uses: kovacszsolt/actionpit/github/action/azure-docker-build-push@main
  with:
    registry: myregistry.azurecr.io
    image_name: my-service
    acr_username: ${{ secrets.ACR_USERNAME }}
    acr_password: ${{ secrets.ACR_PASSWORD }}
    environment_name: main
    variable_name: MY_SERVICE_VERSION
    write_token: ${{ secrets.GH_VARIABLES_TOKEN }}
    bump: patch
    dockerfile: ./Dockerfile

- run: echo "Deploy ${{ steps.image.outputs.deploy_image }}"
```

---

## Related files

| Path | Contents |
|------|----------|
| [`github/action/`](../../github/action/) | Action source |
| [docs/discord-deploy-notification.md](../discord-deploy-notification.md) | Discord action deep dive |
| [docs/version-number.md](../version-number.md) | Semver action deep dive |
| [README.md](../../README.md) | Repository overview |
