package openobserve

import (
	"fmt"
	"os"
	"strings"
)

const (
	DefaultServiceName          = "service"
	DefaultVersionNumber        = "dev"
	DefaultContainerAppRevision = "local"
	DefaultOpenObserveOrg       = "default"
)

// Meta is fixed process-level context added to every envelope.
type Meta struct {
	ServiceName          string
	ServiceVersion       string
	ContainerAppRevision string
}

// Env holds process meta and OpenObserve client configuration.
type Env struct {
	Output             string
	OpenObserveStream  string
	OpenObserveBaseURL string
	OpenObserveOrg     string
	OpenObserveAuth    string
	Meta               Meta
}

// MetaFromEnv loads service metadata with sensible defaults.
func MetaFromEnv() Meta {
	return Meta{
		ServiceName:          envOr("SERVICE_NAME", DefaultServiceName),
		ServiceVersion:       envOr("VERSION_NUMBER", DefaultVersionNumber),
		ContainerAppRevision: envOr("CONTAINER_APP_REVISION", DefaultContainerAppRevision),
	}
}

// LoadEnv reads OpenObserve-related environment variables.
func LoadEnv(defaultOutput string) (Env, error) {
	if strings.TrimSpace(defaultOutput) == "" {
		defaultOutput = "console"
	}
	env := Env{
		Output:             envOr("LOG_EVENT_OUTPUT", defaultOutput),
		OpenObserveStream:  strings.TrimSpace(os.Getenv("LOG_EVENT_OPENOBSERVE_STREAM")),
		OpenObserveBaseURL: strings.TrimRight(strings.TrimSpace(os.Getenv("OPENOBSERVE_BASE_URL")), "/"),
		OpenObserveOrg:     envOr("OPENOBSERVE_ORG", DefaultOpenObserveOrg),
		OpenObserveAuth:    strings.TrimSpace(os.Getenv("OPENOBSERVE_AUTHORIZATION")),
		Meta:               MetaFromEnv(),
	}
	if err := env.Validate(); err != nil {
		return Env{}, err
	}
	return env, nil
}

// Validate checks the output and required fields.
func (e Env) Validate() error {
	out, err := ParseLogEventOutput(e.Output)
	if err != nil {
		return err
	}
	if !out.UseOpenObserve() {
		return nil
	}
	if e.OpenObserveStream == "" {
		return fmt.Errorf("LOG_EVENT_OPENOBSERVE_STREAM is required when LOG_EVENT_OUTPUT includes openobserve")
	}
	if e.OpenObserveBaseURL == "" {
		return fmt.Errorf("OPENOBSERVE_BASE_URL is required when LOG_EVENT_OUTPUT includes openobserve")
	}
	if e.OpenObserveAuth == "" {
		return fmt.Errorf("OPENOBSERVE_AUTHORIZATION is required when LOG_EVENT_OUTPUT includes openobserve")
	}
	if e.OpenObserveOrg == "" {
		return fmt.Errorf("OPENOBSERVE_ORG is required when LOG_EVENT_OUTPUT includes openobserve")
	}
	return nil
}

// ClientConfig returns the HTTP ingest config for NewClient.
func (e Env) ClientConfig() Config {
	return Config{
		BaseURL:    e.OpenObserveBaseURL,
		Org:        e.OpenObserveOrg,
		Stream:     e.OpenObserveStream,
		AuthHeader: e.OpenObserveAuth,
	}
}

func envOr(name, fallback string) string {
	value := strings.TrimSpace(os.Getenv(name))
	if value != "" {
		return value
	}
	return fallback
}
