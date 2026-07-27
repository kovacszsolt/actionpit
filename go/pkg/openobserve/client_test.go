package openobserve_test

import (
	"context"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/kovacszsolt/actionpit/go/pkg/openobserve"
)

func TestIngestURL(t *testing.T) {
	got := openobserve.IngestURL("https://oo.example.com/", "default", "humorhello-cron")
	want := "https://oo.example.com/api/default/humorhello-cron/_json"
	if got != want {
		t.Errorf("IngestURL() = %q, want %q", got, want)
	}
}

func TestNewClientRequiresFields(t *testing.T) {
	_, err := openobserve.NewClient(openobserve.Config{
		BaseURL: "https://oo.example.com",
		Org:     "default",
		Stream:  "humorhello-cron",
	})
	if err == nil {
		t.Fatal("expected error for missing auth")
	}
}

func TestClientIngest(t *testing.T) {
	var gotAuth string
	var gotBody []byte
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		gotAuth = r.Header.Get("Authorization")
		if r.URL.Path != "/api/default/humorhello-cron/_json" {
			t.Errorf("path = %q", r.URL.Path)
		}
		if r.Method != http.MethodPost {
			t.Errorf("method = %q", r.Method)
		}
		body, err := io.ReadAll(r.Body)
		if err != nil {
			t.Errorf("read body: %v", err)
		}
		gotBody = body
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"code":200}`))
	}))
	defer srv.Close()

	client, err := openobserve.NewClient(openobserve.Config{
		BaseURL:    srv.URL,
		Org:        "default",
		Stream:     "humorhello-cron",
		AuthHeader: "Basic dGVzdA==",
	})
	if err != nil {
		t.Fatalf("NewClient: %v", err)
	}

	row := map[string]any{
		"event_name":             "humorhello-cron.app.started",
		"service_name":           "humorhello-cron",
		"service_version":        "0.1.0",
		"container_app_revision": "local",
		"level":                  "info",
		"message":                map[string]any{"pipeline": "humor_generate"},
	}
	if err := client.Ingest(context.Background(), []map[string]any{row}); err != nil {
		t.Fatalf("Ingest: %v", err)
	}
	if gotAuth != "Basic dGVzdA==" {
		t.Errorf("Authorization = %q", gotAuth)
	}
	var payload []map[string]any
	if err := json.Unmarshal(gotBody, &payload); err != nil {
		t.Fatalf("unmarshal body: %v", err)
	}
	if len(payload) != 1 {
		t.Fatalf("payload len = %d", len(payload))
	}
	if payload[0]["event_name"] != "humorhello-cron.app.started" {
		t.Errorf("event_name = %v", payload[0]["event_name"])
	}
}

func TestClientIngestNon2xx(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
	}))
	defer srv.Close()

	client, err := openobserve.NewClient(openobserve.Config{
		BaseURL:    srv.URL,
		Org:        "default",
		Stream:     "humorhello-cron",
		AuthHeader: "Basic dGVzdA==",
	})
	if err != nil {
		t.Fatalf("NewClient: %v", err)
	}
	err = client.Ingest(context.Background(), []map[string]any{{"ok": true}})
	if err == nil {
		t.Fatal("expected error for 401")
	}
}
