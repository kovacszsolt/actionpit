package openobserve_test

import (
	"strings"
	"testing"

	"github.com/kovacszsolt/actionpit/go/pkg/openobserve"
)

func clearEnv(t *testing.T) {
	t.Helper()
	t.Setenv("LOG_EVENT_OUTPUT", "")
	t.Setenv("LOG_EVENT_OPENOBSERVE_STREAM", "")
	t.Setenv("OPENOBSERVE_BASE_URL", "")
	t.Setenv("OPENOBSERVE_ORG", "")
	t.Setenv("OPENOBSERVE_AUTHORIZATION", "")
	t.Setenv("SERVICE_NAME", "")
	t.Setenv("VERSION_NUMBER", "")
	t.Setenv("CONTAINER_APP_REVISION", "")
}

func TestLoadEnvConsoleOnlyDefaults(t *testing.T) {
	clearEnv(t)

	env, err := openobserve.LoadEnv("console")
	if err != nil {
		t.Fatalf("LoadEnv() error = %v", err)
	}
	if env.Output != "console" {
		t.Errorf("Output = %q, want console", env.Output)
	}
	if env.Meta.ServiceName != openobserve.DefaultServiceName {
		t.Errorf("ServiceName = %q", env.Meta.ServiceName)
	}
	if env.Meta.ServiceVersion != openobserve.DefaultVersionNumber {
		t.Errorf("Version = %q", env.Meta.ServiceVersion)
	}
}

func TestLoadEnvOpenObserveRequiresStream(t *testing.T) {
	clearEnv(t)
	t.Setenv("LOG_EVENT_OUTPUT", "openobserve")
	t.Setenv("OPENOBSERVE_BASE_URL", "https://oo.example.com")
	t.Setenv("OPENOBSERVE_AUTHORIZATION", "Basic dGVzdA==")

	_, err := openobserve.LoadEnv("console")
	if err == nil {
		t.Fatal("expected error for missing stream")
	}
	if !strings.Contains(err.Error(), "LOG_EVENT_OPENOBSERVE_STREAM") {
		t.Errorf("error = %v", err)
	}
}

func TestLoadEnvOpenObserveOK(t *testing.T) {
	clearEnv(t)
	t.Setenv("LOG_EVENT_OUTPUT", "console,openobserve")
	t.Setenv("LOG_EVENT_OPENOBSERVE_STREAM", "humorhello-cron")
	t.Setenv("OPENOBSERVE_BASE_URL", "https://oo.example.com/")
	t.Setenv("OPENOBSERVE_ORG", "default")
	t.Setenv("OPENOBSERVE_AUTHORIZATION", "Basic dGVzdA==")
	t.Setenv("SERVICE_NAME", "humorhello-cron")
	t.Setenv("VERSION_NUMBER", "1.2.3")
	t.Setenv("CONTAINER_APP_REVISION", "rev-1")

	env, err := openobserve.LoadEnv("console")
	if err != nil {
		t.Fatalf("LoadEnv() error = %v", err)
	}
	if env.OpenObserveBaseURL != "https://oo.example.com" {
		t.Errorf("OpenObserveBaseURL = %q", env.OpenObserveBaseURL)
	}
	if env.Meta.ServiceVersion != "1.2.3" {
		t.Errorf("Version = %q", env.Meta.ServiceVersion)
	}
	if env.Meta.ContainerAppRevision != "rev-1" {
		t.Errorf("Revision = %q", env.Meta.ContainerAppRevision)
	}
}

func TestParseLogEventOutput(t *testing.T) {
	out, err := openobserve.ParseLogEventOutput("console,openobserve")
	if err != nil {
		t.Fatalf("ParseLogEventOutput: %v", err)
	}
	if !out.UseConsole() || !out.UseOpenObserve() {
		t.Fatalf("unexpected output flags: %v", out)
	}
}
