# Go packages (`go/pkg`)

Reusable Go modules under [`go/pkg/`](../../go/pkg/). Each package is its own module (`go.mod`) so consumers can depend on only what they need.

Import path prefix:

```text
github.com/kovacszsolt/actionpit/go/pkg/<package>
```

Prefer a **tagged release** (or commit SHA) over a floating branch for production services.

## How to use

```bash
go get github.com/kovacszsolt/actionpit/go/pkg/openobserve@<ref>
go get github.com/kovacszsolt/actionpit/go/pkg/oolifecycle@<ref>
go get github.com/kovacszsolt/actionpit/go/pkg/ooai@<ref>
```

Local development against a checkout (optional `replace`):

```go
// go.mod
replace github.com/kovacszsolt/actionpit/go/pkg/openobserve => ../actionpit/go/pkg/openobserve
```

## Quick catalogue

| Package | Module path | Purpose |
|---------|-------------|---------|
| **openobserve** | [`go/pkg/openobserve/`](../../go/pkg/openobserve/) | HTTP `_json` ingest client, env/meta loading, nil-safe structured `Publisher` |
| **oolifecycle** | [`go/pkg/oolifecycle/`](../../go/pkg/oolifecycle/) | App lifecycle helpers: `app.started`, `app.stopped`, `pipeline.failed` |
| **ooai** | [`go/pkg/ooai/`](../../go/pkg/ooai/) | AI call cost calculation and `{service}.ai.call` events |

Dependency flow:

```text
ooai ────────┐
oolifecycle ─┼──► openobserve
```

---

## Conventions

- **One concern per module** — keep ingest transport in `openobserve`; domain event shapes in thin helpers (`oolifecycle`, `ooai`).
- **Best-effort publish** — `Publisher.Publish` logs failures and does not fail the caller; 8s timeout per publish.
- **Nil-safe** — `nil` publisher / client is a no-op.
- **Event names** — `{SERVICE_NAME}.{domain}.{action}` (e.g. `my-cron.app.started`, `my-cron.ai.call`).
- **Levels** — `info`, `warn`, `error`. Never log secrets, passwords, JWTs, or full raw credentials.
- **Go version** — modules target Go `1.23.0+`.

---

## Packages

### `openobserve`

Core OpenObserve integration: `_json` HTTP client, process meta from env, and a structured event publisher.

#### Types

| Type | Role |
|------|------|
| `Client` | POST to `/api/{org}/{stream}/_json` |
| `Config` | Base URL, org, stream, `Authorization` header, optional timeout |
| `Meta` | `ServiceName`, `ServiceVersion`, `ContainerAppRevision` on every envelope |
| `Env` | Parsed env + validation for console / openobserve output |
| `Publisher` | Builds envelope rows and calls `Client.Ingest` |
| `Output` | Bitmask: `console`, `openobserve`, or both |

#### Environment

| Variable | Required when | Notes |
|----------|---------------|-------|
| `LOG_EVENT_OUTPUT` | — | `console`, `openobserve`, `console,openobserve`, `both` / `all`, or empty (no destinations) |
| `LOG_EVENT_OPENOBSERVE_STREAM` | output includes `openobserve` | Stream name in the ingest URL |
| `OPENOBSERVE_BASE_URL` | output includes `openobserve` | Base URL without trailing slash |
| `OPENOBSERVE_ORG` | output includes `openobserve` | Default: `default` |
| `OPENOBSERVE_AUTHORIZATION` | output includes `openobserve` | Full `Authorization` header value |
| `SERVICE_NAME` | — | Default: `service` (used in event names) |
| `VERSION_NUMBER` | — | Default: `dev` |
| `CONTAINER_APP_REVISION` | — | Default: `local` |

`LoadEnv(defaultOutput)` validates that OpenObserve credentials are present when the output includes `openobserve`.

#### Envelope fields

Each published row includes:

| Field | Source |
|-------|--------|
| `_timestamp` | Unix microseconds at publish time |
| `event_name` | Caller event name |
| `service_name` / `service_version` / `container_app_revision` | `Meta` |
| `session_id` | Process-level correlation id passed to `NewPublisher` |
| `level` | `info` / `warn` / `error` |
| `message` | Caller map; sets `event.name` and `session_id` if missing |

#### Bootstrap example

```go
env, err := openobserve.LoadEnv("console")
if err != nil {
    return err
}

var client *openobserve.Client
out, _ := openobserve.ParseLogEventOutput(env.Output)
if out.UseOpenObserve() {
    client, err = openobserve.NewClient(env.ClientConfig())
    if err != nil {
        return err
    }
}

sessionID := uuid.NewString() // or any process correlation id
pub := openobserve.NewPublisher(client, env.Meta, sessionID, nil)

pub.Publish(ctx, env.Meta.ServiceName+".job.completed", "info", map[string]any{
    "success": true,
    "items":   42,
})
```

---

### `oolifecycle`

Thin helpers on top of `openobserve.Publisher` for process / pipeline lifecycle events.

| Function | Event | Level | Typical fields |
|----------|-------|-------|----------------|
| `PublishAppStarted` | `{service}.app.started` | `info` | `pipeline`, `success` |
| `PublishAppStopped` | `{service}.app.stopped` | `info` | `pipeline`, `success`, `duration_ms`, optional `ai_calls` / `ai_total_cost_usd` |
| `PublishPipelineFailed` | `{service}.pipeline.failed` | `error` | `pipeline`, `success=false`, `duration_ms`, `error.message` |

Message builders (`AppStartedMessage`, `AppStoppedMessage`, `PipelineFailedMessage`) are exported for tests or custom publishers.

```go
start := time.Now()
oolifecycle.PublishAppStarted(pub, ctx, "humor_generate")
// ... work ...
oolifecycle.PublishAppStopped(pub, ctx, "humor_generate", true, time.Since(start), oolifecycle.RunCostStats{
    AICalls:      3,
    TotalCostUSD: 0.012,
})
```

---

### `ooai`

AI provider call observability: decimal cost math and `{service}.ai.call` publishing.

| Symbol | Role |
|--------|------|
| `AICallFields` | Tokens, model/provider, unit prices, timing, HTTP status, retries |
| `CalculateCost` | Returns `CostBreakdown` (`free` if `PricingFound` is false or total is zero; otherwise `paid`) |
| `AICallMessage` | Builds the message map (prompt/response, token costs, unit prices) |
| `PublishAICall` | Publishes `{service}.ai.call` at `info` or `error` |

Cost rules:

- Uncached input tokens × `InputUSDPer1M`
- Cached input tokens × `CachedInputUSDPer1M` (falls back to input rate)
- Output tokens × `OutputUSDPer1M`
- Rates are **USD per 1M tokens**
- Uses `shopspring/decimal` for intermediate math

```go
ooai.PublishAICall(pub, ctx, "humor_generate", ooai.AICallFields{
    Provider:       "openai",
    Model:          "gpt-4o-mini",
    InputTokens:    1200,
    OutputTokens:   400,
    CachedTokens:   200,
    PricingFound:   true,
    InputUSDPer1M:  ptr(0.15),
    OutputUSDPer1M: ptr(0.60),
}, nil)
```

---

## Suggested wiring (long-running job / cron)

1. `openobserve.LoadEnv(...)` at startup; fail fast if OpenObserve output is misconfigured.
2. Create `Client` only when output includes `openobserve`.
3. Create one `Publisher` with a session / run UUID.
4. Emit `oolifecycle.PublishAppStarted` / `PublishAppStopped` (or `PublishPipelineFailed` on hard failure).
5. After each AI provider call, emit `ooai.PublishAICall` with pricing fields when available.

---

## Related

| Path | Notes |
|------|-------|
| [`go/pkg/openobserve/`](../../go/pkg/openobserve/) | Source + tests |
| [`go/pkg/oolifecycle/`](../../go/pkg/oolifecycle/) | Source + tests |
| [`go/pkg/ooai/`](../../go/pkg/ooai/) | Source + tests |
| [`docs/github-action/README.md`](../github-action/README.md) | GitHub Actions catalogue |
| [`docs/terraform/aws/README.md`](../terraform/aws/README.md) | Terraform AWS modules |
| [`docs/terraform/azure/README.md`](../terraform/azure/README.md) | Terraform Azure modules |
