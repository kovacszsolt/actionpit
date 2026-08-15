# templatedmail

Send emails using Handlebars templates ([aymerick/raymond](https://github.com/aymerick/raymond)) and SMTP (AUTH LOGIN, STARTTLS / port 465).

The package does **not** store template files. Callers pass template **strings** (typically via `go:embed`).

## One-shot send

```go
err := templatedmail.Send(templatedmail.SendInput{
    To: "ops@example.com",
    SMTP: templatedmail.SMTP{
        Endpoint:  "smtp.example.com",
        Port:      587,
        Username:  "user",
        Password:  "pass",
        FromEmail: "noreply@example.com",
        FromName:  "App",
        UseTLS:    true,
    },
    Templates: templatedmail.Templates{
        Subject: "[{{tenantName}}] Summary",
        Text:    "Hello {{tenantName}}",
    },
    Data: map[string]any{"tenantName": "Acme"},
})
```

## Embed + compile once

```go
//go:embed templates/subject.hbs templates/body.hbs
var templateFS embed.FS

func mustRead(name string) string {
    b, err := templateFS.ReadFile(name)
    if err != nil {
        panic(err)
    }
    return string(b)
}

var compiled = mustCompile()

func mustCompile() *templatedmail.Compiled {
    c, err := templatedmail.CompileTemplates(templatedmail.Templates{
        Subject: mustRead("templates/subject.hbs"),
        Text:    mustRead("templates/body.hbs"),
    })
    if err != nil {
        panic(err)
    }
    return c
}

err := compiled.Send(to, smtp, data)
```

## MIME

- Text only → `text/plain`
- HTML only → `text/html`
- Both → `multipart/alternative`
