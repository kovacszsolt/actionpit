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

## Behaviour

- **ErrDisabled** — empty license key; `Post` and lifecycle helpers return this sentinel (no HTTP).
- **stdlib only** — no Cobra dependency; callers pass command path and invocation.
- **FormatErrorReport** — optional `AppendDiagnostics` hook for HTTP or domain-specific detail.

## Tests

```bash
cd go/pkg/newrelic
go test ./...
```
