package newrelic

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"
)

type forwardHandler struct {
	inner       slog.Handler
	client      *Client
	serviceName string
	minLevel    slog.Level
}

func (h *forwardHandler) Enabled(ctx context.Context, level slog.Level) bool {
	return h.inner.Enabled(ctx, level)
}

func (h *forwardHandler) Handle(ctx context.Context, r slog.Record) error {
	if err := h.inner.Handle(ctx, r); err != nil {
		return err
	}
	if h.client == nil || !h.client.Enabled() {
		return nil
	}
	if r.Level < h.minLevel {
		return nil
	}

	fields := recordFields(r)
	eventName := r.Message
	if v, ok := fields["event.name"].(string); ok && v != "" {
		eventName = v
	}
	level := slogLevelName(r.Level)
	h.publishRecordAsync(ctx, eventName, level, fields)
	return nil
}

func (h *forwardHandler) WithAttrs(attrs []slog.Attr) slog.Handler {
	return &forwardHandler{
		inner:       h.inner.WithAttrs(attrs),
		client:      h.client,
		serviceName: h.serviceName,
		minLevel:    h.minLevel,
	}
}

func (h *forwardHandler) WithGroup(name string) slog.Handler {
	return &forwardHandler{
		inner:       h.inner.WithGroup(name),
		client:      h.client,
		serviceName: h.serviceName,
		minLevel:    h.minLevel,
	}
}

func (h *forwardHandler) publishRecordAsync(ctx context.Context, eventName, level string, fields map[string]any) {
	message := eventName
	if level == "error" {
		if em, ok := fields["error.message"].(string); ok && em != "" {
			message = fmt.Sprintf("%s: %s", eventName, em)
		} else if em, ok := fields["error"].(string); ok && em != "" {
			message = fmt.Sprintf("%s: %s", eventName, em)
		}
	}

	service := h.serviceName
	if service == "" {
		service = h.client.AppName()
	}

	entry := map[string]any{
		"timestamp":  time.Now().UnixMilli(),
		"service":    service,
		"level":      level,
		"message":    message,
		"event.name": eventName,
	}
	for k, v := range fields {
		entry[k] = v
	}

	go func() {
		pubCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := h.client.Post(pubCtx, []map[string]any{entry}); err != nil {
			var skip ErrDisabled
			if errors.As(err, &skip) {
				return
			}
			warn := slog.NewRecord(time.Now(), slog.LevelWarn, "new relic publish failed", 0)
			warn.AddAttrs(
				slog.String("event", eventName),
				slog.Any("error", err),
			)
			_ = h.inner.Handle(pubCtx, warn)
		}
	}()
}

func recordFields(r slog.Record) map[string]any {
	fields := map[string]any{
		"message":   r.Message,
		"timestamp": r.Time.UnixMilli(),
	}
	r.Attrs(func(a slog.Attr) bool {
		fields[a.Key] = a.Value.Any()
		return true
	})
	return fields
}

func slogLevelName(level slog.Level) string {
	switch {
	case level >= slog.LevelError:
		return "error"
	case level >= slog.LevelWarn:
		return "warn"
	case level < slog.LevelInfo:
		return "debug"
	default:
		return "info"
	}
}

// ParseLogLevel maps common LOG_LEVEL strings to slog levels.
func ParseLogLevel(raw string) (slog.Level, error) {
	switch strings.ToLower(strings.TrimSpace(raw)) {
	case "", "info":
		return slog.LevelInfo, nil
	case "debug":
		return slog.LevelDebug, nil
	case "warn", "warning":
		return slog.LevelWarn, nil
	case "error":
		return slog.LevelError, nil
	default:
		return slog.LevelInfo, fmt.Errorf("invalid LOG_LEVEL %q (use debug, info, warn, error)", raw)
	}
}
