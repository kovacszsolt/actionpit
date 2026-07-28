# Go auth

Shared Go library for validating HS256 access tokens (`iss=auth-ba`). Provides a
core verifier plus an optional Echo middleware.

## Module

```
github.com/kovacszsolt/actionpit/go/pkg/auth
```

## JWT contract

| Item | Value |
|------|-------|
| Algorithm | HS256 |
| Default issuer | `auth-ba` |
| Claims | `user_id`, `tenant_id`, `email`, `name`, `domain` |

## Environment variables

| Variable | Required | Default | Notes |
|----------|----------|---------|-------|
| `JWT_AUTH_ENABLED` | no | `true` | When `false`, secret/domain are not required |
| `JWT_SECRET` | yes (if enabled) | — | At least 32 characters; must match auth tenant `jwt_secret` |
| `JWT_ISSUER` | no | `auth-ba` | Must match token `iss` |
| `JWT_DOMAIN` | yes (if enabled) | — | Must match token `domain` claim |
| `JWT_TENANT_ID` | no | `0` | When `> 0`, enforces token `tenant_id` |

## Usage

### Core verifier

```go
import "github.com/kovacszsolt/actionpit/go/pkg/auth"

cfg, err := auth.LoadJWTAuth()
if err != nil {
    log.Fatal(err)
}
var verifier *auth.Verifier
if cfg.Enabled {
    verifier = auth.NewVerifier(cfg)
}
claims, err := verifier.Verify(rawToken)
```

### Echo middleware

```go
import (
    "github.com/kovacszsolt/actionpit/go/pkg/auth"
    authecho "github.com/kovacszsolt/actionpit/go/pkg/auth/echo"
    echov4 "github.com/labstack/echo/v4"
)

e.Use(authecho.RequireBearerJWT(verifier, authecho.JWTAuthOptions{
    Enabled:          cfg.Enabled,
    PlaygroundPublic: playgroundEnabled,
    // Optional: wire structured logging on 401
    OnUnauthorized: func(c echov4.Context, detail map[string]any) {
        // e.g. eventlog.MergeRequestErrorDetail(c, detail)
    },
}))
```

Public paths (no JWT): `/`, `/health*`, `/healthz*`, `OPTIONS`, and optionally
`GET /graphql` when `PlaygroundPublic` is true.

When `Enabled` is false, requests pass through with a fake dev context
(`dev@local`, `tenant_id=1`).

### Local replace (before tagging)

```go
// go.mod
require github.com/kovacszsolt/actionpit/go/pkg/auth v0.0.0

replace github.com/kovacszsolt/actionpit/go/pkg/auth => ../path/to/actionpit/go/pkg/auth
```

## Error codes

Stable codes returned in `401` JSON (`{ "error": { "code", "message", "details" } }`):

- `JWT_REQUIRED`
- `JWT_MISSING`
- `JWT_EXPIRED`
- `JWT_INVALID_SIGNATURE`
- `JWT_ISSUER_MISMATCH`
- `JWT_DOMAIN_MISMATCH`
- `JWT_TENANT_MISMATCH`
- `JWT_INVALID_CLAIMS`
- `JWT_MALFORMED`
