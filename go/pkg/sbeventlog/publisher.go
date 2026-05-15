// Package sbeventlog publishes structured JSON log events to an Azure Service Bus queue.
package sbeventlog

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/Azure/azure-sdk-for-go/sdk/messaging/azservicebus"
)

// Meta is fixed per process (from config / env).
type Meta struct {
	ServiceVersion       string
	ServiceName          string
	ContainerAppRevision string
	// OpenObserveStream: optional OpenObserve log stream name for oo_bridge ParseOOLogEnvelope (JSON key openobserve_stream).
	// Non-empty: envelope matches structured ingest; empty: field omitted (legacy / raw relay).
	OpenObserveStream string
	// LogEventServiceWakeURL: optional HTTP(S) URL (e.g. scale-to-zero warmup). A successful Publish
	// triggers a best-effort GET in the background; the Publish return does not wait for the HTTP response.
	LogEventServiceWakeURL string
	// Output: vesszős lista (see ParseLogEventOutput). Zero: NewPublisher infers servicebus if sender exists.
	Output Output
	// ConsoleLog: filters stdout when Output includes console; empty = print all.
	// "minimal" = only .app.started, .app.stopped, and events with level error.
	// Otherwise: severity threshold (debug, info, warn, error). Service Bus is never filtered.
	ConsoleLog string
}

// Publisher sends one envelope JSON per message. Nil-safe: no-op when not constructed.
type Publisher struct {
	sender  *azservicebus.Sender
	meta    Meta
	out     Output
	wakeURL string
}

// NewPublisher returns nil if there is nothing to do (unset output and no sender), or if Service Bus is
// required but sender is nil. When Output is unset (0) and sender is non-nil, behaves as servicebus-only.
func NewPublisher(sender *azservicebus.Sender, meta Meta) *Publisher {
	out := meta.Output
	if out == 0 {
		if sender == nil {
			return nil
		}
		out = OutputServiceBus
	}
	if out.UseServiceBus() && sender == nil {
		return nil
	}
	if !out.UseConsole() && !out.UseServiceBus() {
		return nil
	}
	return &Publisher{
		sender:  sender,
		meta:    meta,
		out:     out,
		wakeURL: strings.TrimSpace(meta.LogEventServiceWakeURL),
	}
}

// SpanMeta is optional span linkage for oo_bridge OTLP (OpenObserve trace tree). Zero value omits fields.
type SpanMeta struct {
	TraceID      string // e.g. run-20260515T210912Z
	SpanID       string // 16 hex chars
	ParentSpanID string // 16 hex chars; empty for root spans
}

type envelope struct {
	EventName            string          `json:"event_name"`
	ServiceVersion       string          `json:"service_version"`
	ServiceName          string          `json:"service_name"`
	ContainerAppRevision string          `json:"container_app_revision"`
	OpenObserveStream    string          `json:"openobserve_stream,omitempty"`
	TraceID              string          `json:"trace_id,omitempty"`
	SpanID               string          `json:"span_id,omitempty"`
	ParentSpanID         string          `json:"parent_span_id,omitempty"`
	Level                string          `json:"level"`
	Message              json.RawMessage `json:"message"`
}

// Publish sends a JSON body with the canonical schema. level defaults to "info" if empty.
// message must be a JSON object (starts with '{').
// Console branch: one line JSON via standard log (before Service Bus send).
func (p *Publisher) Publish(ctx context.Context, eventName, level string, message json.RawMessage) error {
	return p.PublishWithSpan(ctx, eventName, level, message, SpanMeta{})
}

// PublishWithSpan is like Publish but adds optional trace_id, span_id, parent_span_id on the envelope.
func (p *Publisher) PublishWithSpan(ctx context.Context, eventName, level string, message json.RawMessage, span SpanMeta) error {
	if p == nil {
		return nil
	}
	eventName = strings.TrimSpace(eventName)
	if eventName == "" {
		return fmt.Errorf("sbeventlog: event_name is required")
	}
	msg := bytes.TrimSpace(message)
	if len(msg) == 0 || msg[0] != '{' {
		return fmt.Errorf("sbeventlog: message must be a JSON object")
	}
	level = strings.TrimSpace(level)
	if level == "" {
		level = "info"
	}
	env := envelope{
		EventName:            eventName,
		ServiceVersion:       p.meta.ServiceVersion,
		ServiceName:          p.meta.ServiceName,
		ContainerAppRevision: p.meta.ContainerAppRevision,
		OpenObserveStream:    strings.TrimSpace(p.meta.OpenObserveStream),
		Level:                level,
		Message:              msg,
	}
	if tid := strings.TrimSpace(span.TraceID); tid != "" {
		env.TraceID = tid
	}
	if sid := strings.TrimSpace(span.SpanID); sid != "" {
		env.SpanID = sid
	}
	if pid := strings.TrimSpace(span.ParentSpanID); pid != "" {
		env.ParentSpanID = pid
	}
	body, err := json.Marshal(env)
	if err != nil {
		return fmt.Errorf("sbeventlog: marshal: %w", err)
	}
	if p.out.UseConsole() && ShouldEmitConsoleLine(p.meta.ConsoleLog, eventName, level) {
		log.Printf("[sbeventlog] %s", body)
	}
	if p.out.UseServiceBus() {
		if p.sender == nil {
			return fmt.Errorf("sbeventlog: service bus sender is nil")
		}
		ct := "application/json"
		if err := p.sender.SendMessage(ctx, &azservicebus.Message{Body: body, ContentType: &ct}, nil); err != nil {
			return err
		}
		p.wakeLogEventServiceAsync()
	}
	return nil
}

const wakeHTTPClientTimeout = 5 * time.Second

// wakeLogEventServiceAsync GET LogEventServiceWakeURL without blocking Publish.
func (p *Publisher) wakeLogEventServiceAsync() {
	if p == nil || p.wakeURL == "" {
		return
	}
	u := p.wakeURL
	go func() {
		ctx, cancel := context.WithTimeout(context.Background(), wakeHTTPClientTimeout)
		defer cancel()
		req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
		if err != nil {
			return
		}
		c := &http.Client{Timeout: wakeHTTPClientTimeout}
		_, _ = c.Do(req)
	}()
}

// MarshalMessage encodes a map as JSON object bytes for Publish.
func MarshalMessage(m map[string]any) (json.RawMessage, error) {
	if m == nil {
		m = map[string]any{}
	}
	b, err := json.Marshal(m)
	if err != nil {
		return nil, err
	}
	if len(b) == 0 || b[0] != '{' {
		return nil, fmt.Errorf("sbeventlog: message must serialize to a JSON object")
	}
	return json.RawMessage(b), nil
}
