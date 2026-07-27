package oolifecycle_test

import (
	"errors"
	"testing"
	"time"

	"github.com/kovacszsolt/actionpit/go/pkg/oolifecycle"
)

func TestAppStartedMessage(t *testing.T) {
	msg := oolifecycle.AppStartedMessage("humorhello-cron.app.started", "humor_generate")
	if msg["event.name"] != "humorhello-cron.app.started" {
		t.Errorf("event.name = %v", msg["event.name"])
	}
	if msg["pipeline"] != "humor_generate" {
		t.Errorf("pipeline = %v", msg["pipeline"])
	}
	if msg["success"] != true {
		t.Errorf("success = %v", msg["success"])
	}
}

func TestAppStoppedMessage(t *testing.T) {
	msg := oolifecycle.AppStoppedMessage(
		"humorhello-cron.app.stopped",
		"humor_generate",
		true,
		1200*time.Millisecond,
		oolifecycle.RunCostStats{AICalls: 3, TotalCostUSD: 0.0123},
	)
	if msg["event.name"] != "humorhello-cron.app.stopped" {
		t.Errorf("event.name = %v", msg["event.name"])
	}
	if msg["pipeline"] != "humor_generate" {
		t.Errorf("pipeline = %v", msg["pipeline"])
	}
	if msg["success"] != true {
		t.Errorf("success = %v", msg["success"])
	}
	if msg["duration_ms"] != int64(1200) {
		t.Errorf("duration_ms = %v", msg["duration_ms"])
	}
	if msg["ai_calls"] != 3 {
		t.Errorf("ai_calls = %v", msg["ai_calls"])
	}
	if msg["ai_total_cost_usd"] != 0.0123 {
		t.Errorf("ai_total_cost_usd = %v", msg["ai_total_cost_usd"])
	}
}

func TestPipelineFailedMessage(t *testing.T) {
	err := errors.New("ai_api_key is empty")
	msg := oolifecycle.PipelineFailedMessage(
		"humorhello-cron.pipeline.failed",
		"humor_generate",
		err,
		740*time.Millisecond,
	)
	if msg["event.name"] != "humorhello-cron.pipeline.failed" {
		t.Errorf("event.name = %v", msg["event.name"])
	}
	if msg["pipeline"] != "humor_generate" {
		t.Errorf("pipeline = %v", msg["pipeline"])
	}
	if msg["success"] != false {
		t.Errorf("success = %v", msg["success"])
	}
	if msg["error.message"] != err.Error() {
		t.Errorf("error.message = %v", msg["error.message"])
	}
}
