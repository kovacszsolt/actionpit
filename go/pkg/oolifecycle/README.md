# oolifecycle

Vékony segédcsomag az [`openobserve`](../openobserve/) `Publisher` fölött: egységes **alkalmazás- és pipeline-életciklus** események OpenObserve-be (strukturált log / ingest).

## Modul

```text
github.com/kovacszsolt/actionpit/go/pkg/oolifecycle
```

```bash
go get github.com/kovacszsolt/actionpit/go/pkg/oolifecycle@<ref>
```

Helyi fejlesztéshez (opcionális `replace`):

```go
// go.mod
require github.com/kovacszsolt/actionpit/go/pkg/oolifecycle v0.0.0

replace github.com/kovacszsolt/actionpit/go/pkg/oolifecycle => ../actionpit/go/pkg/oolifecycle
```

A csomag közvetlenül függ az `openobserve` modultól; a publisher és környezet beállítását ott kell megoldani (lásd [`docs/go/README.md`](../../../docs/go/README.md)).

## Mit csinál?

Cronok, workerök és egyfolyamatú pipeline-ok tipikus mintája:

1. indulás → `app.started`
2. sikeres leállás → `app.stopped` (időtartam, opcionális AI költség)
3. kemény hiba → `pipeline.failed` (`error` szint)

Az eseménynevek a publisher `ServiceName()` értékéből épülnek: `{service}.app.started`, `{service}.app.stopped`, `{service}.pipeline.failed`.

| Funkció | Esemény | Szint | Mezők (üzenetben) |
|---------|---------|-------|-------------------|
| `PublishAppStarted` | `{service}.app.started` | `info` | `event.name`, `pipeline`, `success=true` |
| `PublishAppStopped` | `{service}.app.stopped` | `info` | `pipeline`, `success`, `duration_ms`, opcionálisan `ai_calls`, `ai_total_cost_usd` |
| `PublishPipelineFailed` | `{service}.pipeline.failed` | `error` | `pipeline`, `success=false`, `duration_ms`, `error.message` |

Az üzenetépítők (`AppStartedMessage`, `AppStoppedMessage`, `PipelineFailedMessage`) exportáltak — tesztekhez vagy saját publisherhez.

## Használat

Előfeltétel: működő `*openobserve.Publisher` (pl. `openobserve.NewPublisher(...)`).

```go
import (
    "context"
    "time"

    "github.com/kovacszsolt/actionpit/go/pkg/oolifecycle"
    "github.com/kovacszsolt/actionpit/go/pkg/openobserve"
)

func run(ctx context.Context, pub *openobserve.Publisher) {
    pipeline := "humor_generate"
    start := time.Now()

    oolifecycle.PublishAppStarted(pub, ctx, pipeline)

    // ... munka ...

    if err != nil {
        oolifecycle.PublishPipelineFailed(pub, ctx, pipeline, err, time.Since(start))
        return
    }

    oolifecycle.PublishAppStopped(pub, ctx, pipeline, true, time.Since(start), oolifecycle.RunCostStats{
        AICalls:      3,
        TotalCostUSD: 0.012,
    })
}
```

### `RunCostStats`

Opcionális összefoglaló az `app.stopped` eseményhez. Ha megadod, az első elem kerül az üzenetbe (`ai_calls`, `ai_total_cost_usd`). Egyéni AI hívásokhoz használd az [`ooai`](../ooai/) csomagot.

## Viselkedés

- **Nil-safe** — `nil` publisher esetén a `Publish*` függvények csendben visszatérnek (ugyanaz a konvenció, mint az `openobserve`-ben).
- **Best-effort** — a tényleges küldés az `openobserve.Publisher.Publish` szabályait követi (hiba nem dobódik a hívó stackre).
- **Eseményelnevezés** — a `event.name` mező mindig megegyezik a publisholt eseménynévvel.

## Tesztek

```bash
cd go/pkg/oolifecycle
go test ./...
```

## Kapcsolódó dokumentáció

- Összes Go csomag: [`docs/go/README.md`](../../../docs/go/README.md)
- Ingest / meta / publisher: [`go/pkg/openobserve`](../openobserve/)
