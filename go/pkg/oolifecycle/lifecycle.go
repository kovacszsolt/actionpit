package oolifecycle

import (
	"context"
	"time"

	"github.com/kovacszsolt/actionpit/go/pkg/openobserve"
)

// RunCostStats is optional AI cost summary attached to app.stopped.
type RunCostStats struct {
	AICalls      int
	TotalCostUSD float64
}

// AppStartedMessage builds the message object for {service}.app.started.
func AppStartedMessage(eventName, pipeline string) map[string]any {
	return map[string]any{
		"event.name": eventName,
		"pipeline":   pipeline,
		"success":    true,
	}
}

// AppStoppedMessage builds the message object for {service}.app.stopped.
func AppStoppedMessage(eventName, pipeline string, success bool, duration time.Duration, stats ...RunCostStats) map[string]any {
	msg := map[string]any{
		"event.name":  eventName,
		"pipeline":    pipeline,
		"success":     success,
		"duration_ms": duration.Milliseconds(),
	}
	if len(stats) > 0 {
		msg["ai_calls"] = stats[0].AICalls
		msg["ai_total_cost_usd"] = stats[0].TotalCostUSD
	}
	return msg
}

// PipelineFailedMessage builds the message object for {service}.pipeline.failed.
func PipelineFailedMessage(eventName, pipeline string, err error, duration time.Duration) map[string]any {
	msg := map[string]any{
		"event.name":  eventName,
		"pipeline":    pipeline,
		"success":     false,
		"duration_ms": duration.Milliseconds(),
	}
	if err != nil {
		msg["error.message"] = err.Error()
	}
	return msg
}

// PublishAppStarted sends {service}.app.started using the provided publisher.
func PublishAppStarted(pub *openobserve.Publisher, ctx context.Context, pipeline string) {
	if pub == nil {
		return
	}
	eventName := pub.ServiceName() + ".app.started"
	pub.Publish(ctx, eventName, "info", AppStartedMessage(eventName, pipeline))
}

// PublishAppStopped sends {service}.app.stopped using the provided publisher.
func PublishAppStopped(pub *openobserve.Publisher, ctx context.Context, pipeline string, success bool, duration time.Duration, stats ...RunCostStats) {
	if pub == nil {
		return
	}
	eventName := pub.ServiceName() + ".app.stopped"
	pub.Publish(ctx, eventName, "info", AppStoppedMessage(eventName, pipeline, success, duration, stats...))
}

// PublishPipelineFailed sends {service}.pipeline.failed using the provided publisher.
func PublishPipelineFailed(pub *openobserve.Publisher, ctx context.Context, pipeline string, err error, duration time.Duration) {
	if pub == nil {
		return
	}
	eventName := pub.ServiceName() + ".pipeline.failed"
	pub.Publish(ctx, eventName, "error", PipelineFailedMessage(eventName, pipeline, err, duration))
}
