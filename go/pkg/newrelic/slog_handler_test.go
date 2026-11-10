package newrelic

import (
	"bytes"
	"context"
	"io"
	"log/slog"
	"strings"
	"testing"
	"time"
)

func TestResolveLogFormat(t *testing.T) {
	t.Run("json explicit", func(t *testing.T) {
		if got := ResolveLogFormat("json", nonTTYWriter()); got != "json" {
			t.Fatalf("got %q", got)
		}
	})
	t.Run("auto non-tty", func(t *testing.T) {
		if got := ResolveLogFormat("auto", nonTTYWriter()); got != "json" {
			t.Fatalf("got %q", got)
		}
	})
	t.Run("console explicit", func(t *testing.T) {
		if got := ResolveLogFormat("console", nonTTYWriter()); got != "console" {
			t.Fatalf("got %q", got)
		}
	})
}

func TestNewStdoutHandler_jsonNoForwardWhenDisabled(t *testing.T) {
	var buf bytes.Buffer
	h := NewStdoutHandler(SlogOptions{
		Level:  slog.LevelInfo,
		Format: "json",
		Output: &buf,
	}, NewClient(Config{}))

	rec := slog.NewRecord(time.Now(), slog.LevelError, "test error", 0)
	rec.AddAttrs(slog.String("event.name", "test.error"))
	if err := h.Handle(context.Background(), rec); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(buf.String(), "test error") {
		t.Fatalf("stdout: %q", buf.String())
	}
}

func nonTTYWriter() io.Writer {
	return &bytes.Buffer{}
}
