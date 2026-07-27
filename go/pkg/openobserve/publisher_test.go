package openobserve_test

import (
	"context"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/kovacszsolt/actionpit/go/pkg/openobserve"
)

func TestPublisherAddsEnvelopeFields(t *testing.T) {
	var gotBody []byte
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(r.Body)
		if err != nil {
			t.Fatalf("read body: %v", err)
		}
		gotBody = body
		w.WriteHeader(http.StatusOK)
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
	pub := openobserve.NewPublisher(client, openobserve.Meta{
		ServiceName:          "humorhello-cron",
		ServiceVersion:       "dev",
		ContainerAppRevision: "local",
	}, "session-123", slog.Default())

	pub.Publish(context.Background(), "humorhello-cron.ai.call", "info", map[string]any{
		"pipeline": "humor_generate",
	})

	var payload []map[string]any
	if err := json.Unmarshal(gotBody, &payload); err != nil {
		t.Fatalf("unmarshal: %v", err)
	}
	row := payload[0]
	if row["service_name"] != "humorhello-cron" {
		t.Fatalf("service_name = %v", row["service_name"])
	}
	if row["event_name"] != "humorhello-cron.ai.call" {
		t.Fatalf("event_name = %v", row["event_name"])
	}
	if row["session_id"] != "session-123" {
		t.Fatalf("session_id = %v", row["session_id"])
	}
	message, ok := row["message"].(map[string]any)
	if !ok {
		t.Fatalf("message type = %T", row["message"])
	}
	if message["event.name"] != "humorhello-cron.ai.call" {
		t.Fatalf("message event.name = %v", message["event.name"])
	}
	if message["session_id"] != "session-123" {
		t.Fatalf("message session_id = %v", message["session_id"])
	}
}
