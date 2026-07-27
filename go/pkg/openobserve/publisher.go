package openobserve

import (
	"context"
	"log/slog"
	"time"
)

// Publisher sends structured lifecycle/domain events to OpenObserve.
type Publisher struct {
	client    *Client
	meta      Meta
	sessionID string
	logger    *slog.Logger
}

// NewPublisher wraps an optional OpenObserve client. Nil client makes Publish a no-op.
func NewPublisher(client *Client, meta Meta, sessionID string, logger *slog.Logger) *Publisher {
	if logger == nil {
		logger = slog.Default()
	}
	return &Publisher{
		client:    client,
		meta:      meta,
		sessionID: sessionID,
		logger:    logger,
	}
}

// ServiceName returns the configured service label used in event names.
func (p *Publisher) ServiceName() string {
	if p == nil {
		return ""
	}
	return p.meta.ServiceName
}

// SessionID returns the process-level correlation id.
func (p *Publisher) SessionID() string {
	if p == nil {
		return ""
	}
	return p.sessionID
}

// Publish sends one structured event. Failures are logged and ignored (best-effort).
func (p *Publisher) Publish(ctx context.Context, eventName, level string, message map[string]any) {
	if p == nil || p.client == nil {
		return
	}
	if message == nil {
		message = map[string]any{}
	}
	if _, ok := message["event.name"]; !ok {
		message["event.name"] = eventName
	}
	if p.sessionID != "" {
		message["session_id"] = p.sessionID
	}
	if level == "" {
		level = "info"
	}
	row := map[string]any{
		"_timestamp":             time.Now().UnixMicro(),
		"event_name":             eventName,
		"service_name":           p.meta.ServiceName,
		"service_version":        p.meta.ServiceVersion,
		"container_app_revision": p.meta.ContainerAppRevision,
		"session_id":             p.sessionID,
		"level":                  level,
		"message":                message,
	}
	pubCtx, cancel := context.WithTimeout(ctx, 8*time.Second)
	defer cancel()
	if err := p.client.Ingest(pubCtx, []map[string]any{row}); err != nil {
		p.logger.Warn("openobserve publish failed", "event", eventName, "error", err)
	}
}
