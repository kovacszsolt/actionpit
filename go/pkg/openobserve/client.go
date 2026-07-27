package openobserve

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"
)

const defaultTimeout = 8 * time.Second

// Client posts structured log rows to OpenObserve _json ingest.
type Client struct {
	baseURL    string
	org        string
	stream     string
	authHeader string
	httpClient *http.Client
}

// Config is the constructor input for Client.
type Config struct {
	BaseURL    string
	Org        string
	Stream     string
	AuthHeader string
	Timeout    time.Duration
}

// NewClient builds an OpenObserve ingest client.
func NewClient(cfg Config) (*Client, error) {
	base := strings.TrimRight(strings.TrimSpace(cfg.BaseURL), "/")
	org := strings.TrimSpace(cfg.Org)
	stream := strings.TrimSpace(cfg.Stream)
	auth := strings.TrimSpace(cfg.AuthHeader)
	if base == "" {
		return nil, fmt.Errorf("openobserve base URL is required")
	}
	if org == "" {
		return nil, fmt.Errorf("openobserve org is required")
	}
	if stream == "" {
		return nil, fmt.Errorf("openobserve stream is required")
	}
	if auth == "" {
		return nil, fmt.Errorf("openobserve authorization is required")
	}
	timeout := cfg.Timeout
	if timeout <= 0 {
		timeout = defaultTimeout
	}
	return &Client{
		baseURL:    base,
		org:        org,
		stream:     stream,
		authHeader: auth,
		httpClient: &http.Client{Timeout: timeout},
	}, nil
}

// IngestURL builds POST /api/{org}/{stream}/_json.
func (c *Client) IngestURL() string {
	return IngestURL(c.baseURL, c.org, c.stream)
}

// IngestURL builds the OpenObserve _json ingest URL.
func IngestURL(baseURL, org, stream string) string {
	base := strings.TrimRight(strings.TrimSpace(baseURL), "/")
	return fmt.Sprintf("%s/api/%s/%s/_json",
		base,
		url.PathEscape(strings.TrimSpace(org)),
		url.PathEscape(strings.TrimSpace(stream)),
	)
}

// Ingest posts one or more JSON objects as a _json array payload.
func (c *Client) Ingest(ctx context.Context, rows []map[string]any) error {
	if len(rows) == 0 {
		return fmt.Errorf("openobserve ingest: empty payload")
	}
	body, err := json.Marshal(rows)
	if err != nil {
		return fmt.Errorf("openobserve ingest marshal: %w", err)
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.IngestURL(), bytes.NewReader(body))
	if err != nil {
		return fmt.Errorf("openobserve ingest request: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", c.authHeader)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("openobserve ingest: %w", err)
	}
	defer resp.Body.Close()
	_, _ = io.Copy(io.Discard, io.LimitReader(resp.Body, 4096))
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		return fmt.Errorf("openobserve ingest: status %d", resp.StatusCode)
	}
	return nil
}
