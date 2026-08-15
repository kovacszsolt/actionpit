package templatedmail

import (
	"encoding/base64"
	"strings"
	"testing"
)

func TestCompileAndRenderSubjectAndText(t *testing.T) {
	c, err := CompileTemplates(Templates{
		Subject: "[{{tenantName}}] Cron — {{newCount}} új",
		Text: `Tenant: {{tenantName}}{{#if publicSiteURL}} ({{publicSiteURL}}){{/if}}

{{#if newJokes}}Új viccek ({{newCount}}):
{{#each newJokes}}  {{n}}. {{title}}
{{/each}}{{else}}Nem készült új vicc ebben a futásban.
{{/if}}
Összes vicc: {{totalJokes}}
`,
	})
	if err != nil {
		t.Fatalf("CompileTemplates: %v", err)
	}

	out, err := c.render(map[string]any{
		"tenantName":    "HumorHello",
		"publicSiteURL": "https://humorhello.online",
		"newCount":      2,
		"totalJokes":    10,
		"newJokes": []map[string]any{
			{"n": 1, "title": "Első", "slug": "elso"},
			{"n": 2, "title": "Második", "slug": "masodik"},
		},
	})
	if err != nil {
		t.Fatalf("render: %v", err)
	}
	if out.Subject != "[HumorHello] Cron — 2 új" {
		t.Fatalf("subject = %q", out.Subject)
	}
	if !strings.Contains(out.Text, "Tenant: HumorHello (https://humorhello.online)") {
		t.Fatalf("text missing tenant line: %q", out.Text)
	}
	if !strings.Contains(out.Text, "1. Első") || !strings.Contains(out.Text, "2. Második") {
		t.Fatalf("text missing jokes: %q", out.Text)
	}
	if !strings.Contains(out.Text, "Összes vicc: 10") {
		t.Fatalf("text missing total: %q", out.Text)
	}
}

func TestCompileRequiresSubjectAndBody(t *testing.T) {
	if _, err := CompileTemplates(Templates{Text: "hi"}); err == nil {
		t.Fatal("expected subject required error")
	}
	if _, err := CompileTemplates(Templates{Subject: "hi"}); err == nil {
		t.Fatal("expected body required error")
	}
}

func TestRenderEmptyJokes(t *testing.T) {
	c, err := CompileTemplates(Templates{
		Subject: "s",
		Text: `{{#if newJokes}}has{{else}}Nem készült új vicc ebben a futásban.
{{/if}}`,
	})
	if err != nil {
		t.Fatalf("CompileTemplates: %v", err)
	}
	out, err := c.render(map[string]any{"newJokes": []map[string]any{}})
	if err != nil {
		t.Fatalf("render: %v", err)
	}
	if !strings.Contains(out.Text, "Nem készült új vicc") {
		t.Fatalf("text = %q", out.Text)
	}
}

func TestBuildMIMEPlain(t *testing.T) {
	msg, err := buildMIMEMessage("From <a@b.c>", "to@x.y", "Subj", "plain body", "")
	if err != nil {
		t.Fatalf("buildMIMEMessage: %v", err)
	}
	s := string(msg)
	if !strings.Contains(s, "Content-Type: text/plain") {
		t.Fatalf("expected plain content type: %s", s)
	}
	if !strings.Contains(s, "plain body") {
		t.Fatalf("missing body: %s", s)
	}
}

func TestBuildMIMEMultipart(t *testing.T) {
	msg, err := buildMIMEMessage("From <a@b.c>", "to@x.y", "Subj", "plain", "<p>html</p>")
	if err != nil {
		t.Fatalf("buildMIMEMessage: %v", err)
	}
	s := string(msg)
	if !strings.Contains(s, "multipart/alternative") {
		t.Fatalf("expected multipart: %s", s)
	}
	if !strings.Contains(s, "plain") || !strings.Contains(s, "<p>html</p>") {
		t.Fatalf("missing parts: %s", s)
	}
}

func TestValidateSMTP(t *testing.T) {
	if err := validateSMTP("", SMTP{Endpoint: "x", FromEmail: "a@b.c"}); err == nil {
		t.Fatal("expected to required")
	}
	if err := validateSMTP("a@b.c", SMTP{FromEmail: "a@b.c"}); err == nil {
		t.Fatal("expected endpoint required")
	}
	if err := validateSMTP("a@b.c", SMTP{Endpoint: "smtp.example.com"}); err == nil {
		t.Fatal("expected from required")
	}
}

func TestLoginAuthStart(t *testing.T) {
	auth := newLoginAuth("user@example.com", "secret")
	mech, initial, err := auth.Start(nil)
	if err != nil {
		t.Fatalf("Start: %v", err)
	}
	if mech != "LOGIN" {
		t.Fatalf("mech = %q, want LOGIN", mech)
	}
	if initial != nil {
		t.Fatalf("initial = %v, want nil", initial)
	}
}

func TestLoginAuthNextUsernamePassword(t *testing.T) {
	auth := newLoginAuth("user@example.com", "secret")

	userResp, err := auth.Next([]byte("Username:"), true)
	if err != nil {
		t.Fatalf("username challenge: %v", err)
	}
	if string(userResp) != "user@example.com" {
		t.Fatalf("username = %q", userResp)
	}

	passResp, err := auth.Next([]byte("Password:"), true)
	if err != nil {
		t.Fatalf("password challenge: %v", err)
	}
	if string(passResp) != "secret" {
		t.Fatalf("password = %q", passResp)
	}
}

func TestLoginAuthNextBase64Challenges(t *testing.T) {
	auth := newLoginAuth("user@example.com", "secret")

	userChallenge := base64.StdEncoding.EncodeToString([]byte("Username:"))
	userResp, err := auth.Next([]byte(userChallenge), true)
	if err != nil {
		t.Fatalf("username challenge: %v", err)
	}
	if string(userResp) != "user@example.com" {
		t.Fatalf("username = %q", userResp)
	}

	passChallenge := base64.StdEncoding.EncodeToString([]byte("Password:"))
	passResp, err := auth.Next([]byte(passChallenge), true)
	if err != nil {
		t.Fatalf("password challenge: %v", err)
	}
	if string(passResp) != "secret" {
		t.Fatalf("password = %q", passResp)
	}
}
