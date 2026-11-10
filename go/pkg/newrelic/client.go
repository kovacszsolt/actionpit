package newrelic

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"strings"
)

// Client posts log entries to the New Relic Log API.
type Client struct {
	cfg        Config
	httpClient *http.Client
}

// NewClient builds a Log API client. An empty license key disables posting (ErrDisabled).
func NewClient(cfg Config) *Client {
	timeout := cfg.Timeout
	if timeout <= 0 {
		timeout = defaultHTTPTimeout
	}
	return &Client{
		cfg: cfg,
		httpClient: &http.Client{
			Timeout: timeout,
		},
	}
}

// Enabled reports whether Log API requests will be sent.
func (c *Client) Enabled() bool {
	return c != nil && strings.TrimSpace(c.cfg.LicenseKey) != ""
}

// AppName returns the service label embedded in log payloads.
func (c *Client) AppName() string {
	if c == nil {
		return ""
	}
	return c.cfg.AppName
}

// Post sends one or more log entries to the Log API.
func (c *Client) Post(ctx context.Context, entries []map[string]any) error {
	if c == nil {
		return ErrDisabled{}
	}
	if strings.TrimSpace(c.cfg.LicenseKey) == "" {
		return ErrDisabled{}
	}
	if ctx == nil {
		ctx = context.Background()
	}
	ctx, cancel := context.WithTimeout(ctx, c.httpClient.Timeout)
	defer cancel()

	body, err := json.Marshal(entries)
	if err != nil {
		return fmt.Errorf("new relic log api: encode body: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.cfg.LogEndpoint, bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("new relic log api: build request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Api-Key", c.cfg.LicenseKey)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("new relic log api: request: %w", err)
	}
	defer func() { _ = resp.Body.Close() }()

	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("new relic log api: unexpected status %s", resp.Status)
	}
	return nil
}
