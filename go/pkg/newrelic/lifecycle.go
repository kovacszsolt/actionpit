package newrelic

import (
	"context"
	"fmt"
	"strings"
	"time"
)

// RunFinished describes one CLI or batch process exit (success or failure).
type RunFinished struct {
	Command      string
	Invocation   string
	ProcessLabel string
	Err          error
	Detail       string
	Duration     time.Duration
}

// PublishProcessStarted posts one info-level line when a process starts.
func (c *Client) PublishProcessStarted(ctx context.Context, processLabel string) error {
	label := strings.TrimSpace(processLabel)
	if label == "" {
		label = "process"
	}
	return c.Post(ctx, []map[string]any{
		{
			"message":   fmt.Sprintf("%s process started", label),
			"level":     "info",
			"timestamp": time.Now().UnixMilli(),
			"service":   c.AppName(),
			"hostname":  hostname(),
		},
	})
}

// PublishRunFinished posts one Log API line for process exit (success or failure).
func (c *Client) PublishRunFinished(ctx context.Context, p RunFinished) error {
	command := strings.TrimSpace(p.Command)
	if command == "" {
		command = "unknown"
	}
	label := strings.TrimSpace(p.ProcessLabel)
	if label == "" {
		label = "process"
	}

	detail := strings.TrimSpace(p.Detail)
	durationMs := p.Duration.Milliseconds()
	ts := time.Now().UnixMilli()
	inv := strings.TrimSpace(p.Invocation)

	base := map[string]any{
		"timestamp":   ts,
		"service":     c.AppName(),
		"hostname":    hostname(),
		"command":     command,
		"invocation":  inv,
		"duration_ms": durationMs,
	}

	if p.Err != nil {
		msg := fmt.Sprintf("%s failed [%s]: %v (duration_ms=%d)", label, command, p.Err, durationMs)
		if detail != "" {
			msg += "\n" + detail
		}
		base["message"] = msg
		base["level"] = "error"
		base["success"] = false
		base["error_message"] = p.Err.Error()
		if detail != "" {
			base["error_detail"] = detail
		}
		return c.Post(ctx, []map[string]any{base})
	}

	base["message"] = fmt.Sprintf("%s finished [%s] (duration_ms=%d)", label, command, durationMs)
	base["level"] = "info"
	base["success"] = true
	if detail != "" {
		base["detail"] = detail
	}
	return c.Post(ctx, []map[string]any{base})
}
