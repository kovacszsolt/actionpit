# discord-deploy-notification

Composite GitHub Action that posts a single message to a [Discord Incoming Webhook](https://support.discord.com/hc/en-us/articles/228383668-Intro-to-Webhooks). It sends:

1. A plain-text **content** line (the usual Discord message body above embeds).
2. One **embed** titled by `embed-title`, with structured fields for repository, branch, triggering user, commit message, and commit URL.

The action runs entirely on the **caller’s runner** (no Docker image). It uses `bash`, `jq`, and `curl`, which are available on GitHub-hosted `ubuntu-*` and `macos-*` runners.

### Layout in this repository

| File | Purpose |
|------|---------|
| [`action.yml`](../github/action/discord-deploy-notification/action.yml) | Composite definition: inputs, `env` mapping from inputs and `github.*`, single step that runs `bash "${{ github.action_path }}/send.sh"`. |
| [`send.sh`](../github/action/discord-deploy-notification/send.sh) | Shell: commit fallbacks, `jq` payload, `curl` POST to the webhook URL. |

---

## When to use it

- Notify a Discord channel when a deployment pipeline finishes (success or failure can be reflected in the `content` you pass).
- Share a consistent, readable summary: who ran the workflow, on which branch, for which repo, and which commit.

---

## Prerequisites

| Requirement | Notes |
|-------------|--------|
| Discord webhook | Create under **Server Settings → Integrations → Webhooks**, copy the webhook URL. |
| GitHub secret | Store the URL as a secret (e.g. `DISCORD_WEBHOOK_URL`) and pass it to `webhook-url`. **Do not** commit the raw URL. |
| Runner tools | `jq` and `curl` must be on `PATH` (default on GitHub-hosted Ubuntu/macOS). |

---

## Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `webhook-url` | **Yes** | — | Discord Incoming Webhook URL. Use `secrets.YOUR_SECRET_NAME`. |
| `content` | **Yes** | — | First line of the Discord message (the `content` field). Use this for a short status line, e.g. “Deploy succeeded on production”. |
| `embed-title` | No | `GitHub Actions notification` | Title of the single embed. |

All values are passed through the action into the script as environment variables and embedded in JSON with `jq` (properly escaped for Discord’s API).

---

## GitHub context used

The action reads these **automatically** from the workflow run (you do not pass them as inputs):

| Data | Source | Embed field |
|------|--------|----------------|
| Repository | `github.repository` | **Repository** |
| Branch / ref name | `github.ref_name` | **Branch** |
| Who triggered the run | `github.actor` | **User** |
| Commit message | `github.event.head_commit.message` | **Commit message** |
| Commit URL | `github.event.head_commit.url` | **Commit link** (value shown as link text in the field) |

### Push vs other events

- For **`push`** events, `head_commit` is usually populated, so the real commit message and URL are shown.
- For **`workflow_dispatch`**, **manual re-runs**, or other events without `head_commit`, the action **falls back**:
  - **Commit message:** an em dash (`—`) if missing.
  - **Commit link:** `${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}` so there is still a valid link for the commit that was checked out.

---

## Usage examples

### From another repository (pin by tag or branch)

```yaml
jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - uses: kovacszsolt/actionpit/github/action/discord-deploy-notification@v1
        with:
          webhook-url: ${{ secrets.DISCORD_WEBHOOK_URL }}
          content: "Production deploy finished successfully."
          embed-title: "Deploy notification"
```

Replace `v1` with the tag or branch you trust (e.g. `main`).

### Same repository (relative path)

```yaml
- uses: ./github/action/discord-deploy-notification
  with:
    webhook-url: ${{ secrets.DISCORD_WEBHOOK_URL }}
    content: "CI passed for ${{ github.ref_name }}."
```

---

## Payload shape (reference)

The action builds a JSON body like:

- `content`: your `content` input.
- `embeds[0].title`: your `embed-title` (or default).
- `embeds[0].fields`: **Repository**, **Branch**, **User** (inline), **Commit message**, **Commit link** (full width).

Discord may apply its own limits (message length, embed size). Keep `content` reasonably short; very long commit messages are passed as-is and could hit API limits in edge cases.

---

## Security notes

- Treat `webhook-url` as a **secret**. Anyone with the URL can post to that channel (within Discord’s permissions).
- The action does not log the webhook URL; it only passes it to `curl` as the POST target.

---

## Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| `jq: command not found` | Runner without `jq` (e.g. minimal container). Install `jq` in an earlier step or use a runner image that includes it. |
| Empty or “—” commit message | Workflow not triggered by a `push`, or `head_commit` absent — expected; see [Push vs other events](#push-vs-other-events). |
| Discord `400` / message rejected | Invalid webhook URL, revoked webhook, or payload too large. Check the webhook in Discord and shorten `content` / commit message if needed. |

---

## Related

- Root overview: [README](../README.md)
- [`action.yml`](../github/action/discord-deploy-notification/action.yml), [`send.sh`](../github/action/discord-deploy-notification/send.sh)
