# newrelic

New Relic [Log API](https://docs.newrelic.com/docs/logs/log-api/introduction-log-api/) client for CLI and batch jobs: optional startup/run-finished logs and shared error-report formatting.

## Module

```text
github.com/kovacszsolt/actionpit/go/pkg/newrelic
```

```bash
go get github.com/kovacszsolt/actionpit/go/pkg/newrelic@<ref>
```

Local development:

```go
replace github.com/kovacszsolt/actionpit/go/pkg/newrelic => ../actionpit/go/pkg/newrelic
```

## Environment

| Variable | Required | Default |
|----------|----------|---------|
| `NEW_RELIC_LICENSE_KEY` | No (disabled when empty) | — |
| `NEW_RELIC_LOG_ENDPOINT` | No | `https://log-api.eu.newrelic.com/log/v1` (US: `https://log-api.newrelic.com/log/v1`) |
| `NEW_RELIC_APP_NAME` | No | constructor default in `ConfigFromEnv` |

## Usage

```go
import (
    "context"
    "errors"
    "os"
    "strings"
    "time"

    "github.com/kovacszsolt/actionpit/go/pkg/newrelic"
)

func main() {
    nr := newrelic.NewClient(newrelic.ConfigFromEnv("my-cli"))
    start := time.Now()

    _ = nr.PublishProcessStarted(context.Background(), "my CLI")

    // ... run work ...

    detail := newrelic.FormatErrorReport(newrelic.ReportParams{
        CommandPath: "my scrape",
        Invocation:  strings.Join(os.Args, " "),
        Err:         err,
    })
    _ = nr.PublishRunFinished(context.Background(), newrelic.RunFinished{
        Command:      "my scrape",
        Invocation:   strings.Join(os.Args, " "),
        ProcessLabel: "my CLI",
        Err:          err,
        Detail:       detail,
        Duration:     time.Since(start),
    })

    var skip newrelic.ErrDisabled
    if errors.As(err, &skip) {
        // no license key — skip quietly
    }
}
```

## slog (console + Log API)

HTTP services can install a default `slog` logger that prints to stdout and forwards each record to the Log API when a license key is set:

```go
lv, _ := newrelic.ParseLogLevel(os.Getenv("LOG_LEVEL"))
nr := newrelic.NewClient(newrelic.ConfigFromEnv("my-service"))
logger := newrelic.InstallDefaultLogger(newrelic.SlogOptions{
    Level:       lv,
    Format:      os.Getenv("LOG_FORMAT"), // "auto", "json", or "console"
    ServiceName: "my-service",
}, nr)
_ = logger
```

| `LOG_FORMAT` | Behaviour |
|--------------|-----------|
| `auto` or empty | **tint** (colored) when stdout is a TTY, else JSON |
| `console` | tint on stdout |
| `json` | one JSON object per line |

## Behaviour

- **ErrDisabled** — empty license key; `Post` and lifecycle helpers return this sentinel (no HTTP).
- **stdlib only** — no Cobra dependency; callers pass command path and invocation.
- **FormatErrorReport** — optional `AppendDiagnostics` hook for HTTP or domain-specific detail.

## Tests

```bash
cd go/pkg/newrelic
go test ./...
```
