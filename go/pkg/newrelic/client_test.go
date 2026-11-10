package newrelic_test

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/kovacszsolt/actionpit/go/pkg/newrelic"
)

func TestClientPostDisabled(t *testing.T) {
	c := newrelic.NewClient(newrelic.Config{})
	err := c.Post(context.Background(), []map[string]any{{"message": "x"}})
	var disabled newrelic.ErrDisabled
	if !errors.As(err, &disabled) {
		t.Fatalf("want ErrDisabled, got %v", err)
	}
}

func TestClientPostSendsApiKey(t *testing.T) {
	var gotKey string
	var gotBody []byte
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotKey = r.Header.Get("Api-Key")
		body, _ := io.ReadAll(r.Body)
		gotBody = body
		w.WriteHeader(http.StatusOK)
	}))
	defer srv.Close()

	c := newrelic.NewClient(newrelic.Config{
		LicenseKey:  "lic-test",
		LogEndpoint: srv.URL,
		AppName:     "test-app",
	})
	if err := c.Post(context.Background(), []map[string]any{
		{"message": "hello", "level": "info", "service": "test-app"},
	}); err != nil {
		t.Fatalf("Post: %v", err)
	}
	if gotKey != "lic-test" {
		t.Fatalf("Api-Key = %q", gotKey)
	}
	var entries []map[string]any
	if err := json.Unmarshal(gotBody, &entries); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if entries[0]["message"] != "hello" {
		t.Fatalf("message = %v", entries[0]["message"])
	}
}

func TestPublishProcessStarted(t *testing.T) {
	var gotBody []byte
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotBody, _ = io.ReadAll(r.Body)
		w.WriteHeader(http.StatusOK)
	}))
	defer srv.Close()

	c := newrelic.NewClient(newrelic.Config{
		LicenseKey:  "k",
		LogEndpoint: srv.URL,
		AppName:     "my-svc",
	})
	if err := c.PublishProcessStarted(context.Background(), "import CLI"); err != nil {
		t.Fatalf("PublishProcessStarted: %v", err)
	}
	var entries []map[string]any
	if err := json.Unmarshal(gotBody, &entries); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	if entries[0]["message"] != "import CLI process started" {
		t.Fatalf("message = %v", entries[0]["message"])
	}
	if entries[0]["service"] != "my-svc" {
		t.Fatalf("service = %v", entries[0]["service"])
	}
}
