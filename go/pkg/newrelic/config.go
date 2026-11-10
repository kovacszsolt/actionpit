package newrelic

import (
	"os"
	"strings"
	"time"
)

const (
	DefaultLogEndpoint = "https://log-api.eu.newrelic.com/log/v1"
	defaultHTTPTimeout = 10 * time.Second
)

// Config holds New Relic Log API connection settings.
type Config struct {
	LicenseKey  string
	LogEndpoint string
	AppName     string
	Timeout     time.Duration
}

// ConfigFromEnv builds Config from NEW_RELIC_* env vars. defaultAppName is used when NEW_RELIC_APP_NAME is unset.
func ConfigFromEnv(defaultAppName string) Config {
	endpoint := strings.TrimSpace(os.Getenv("NEW_RELIC_LOG_ENDPOINT"))
	if endpoint == "" {
		endpoint = DefaultLogEndpoint
	}
	appName := strings.TrimSpace(os.Getenv("NEW_RELIC_APP_NAME"))
	if appName == "" {
		appName = defaultAppName
	}
	return Config{
		LicenseKey:  strings.TrimSpace(os.Getenv("NEW_RELIC_LICENSE_KEY")),
		LogEndpoint: endpoint,
		AppName:     appName,
		Timeout:     defaultHTTPTimeout,
	}
}
