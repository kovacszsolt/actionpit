package sbeventlog

import (
	"encoding/json"
	"testing"
)

func TestPublishWithSpan_marshalsEnvelopeFields(t *testing.T) {
	env := envelope{
		EventName:            "scoutbuddy.test",
		ServiceVersion:       "1.0.0",
		ServiceName:          "scoutbuddy",
		ContainerAppRevision: "rev",
		OpenObserveStream:    "scoutbuddy",
		TraceID:              "run-20260515T210912Z",
		SpanID:               "0102030405060708",
		ParentSpanID:         "0a0b0c0d0e0f1011",
		Level:                "info",
		Message:              json.RawMessage(`{"event.name":"scoutbuddy.test"}`),
	}
	body, err := json.Marshal(env)
	if err != nil {
		t.Fatal(err)
	}
	var m map[string]json.RawMessage
	if err := json.Unmarshal(body, &m); err != nil {
		t.Fatal(err)
	}
	for _, key := range []string{"trace_id", "span_id", "parent_span_id"} {
		if _, ok := m[key]; !ok {
			t.Fatalf("missing envelope key %q: %s", key, body)
		}
	}
}

func TestPublishWithSpan_omitsEmptySpanMeta(t *testing.T) {
	env := envelope{
		EventName:     "e",
		ServiceName:   "s",
		Level:         "info",
		Message:       json.RawMessage(`{}`),
		OpenObserveStream: "stream",
	}
	body, err := json.Marshal(env)
	if err != nil {
		t.Fatal(err)
	}
	var m map[string]any
	if err := json.Unmarshal(body, &m); err != nil {
		t.Fatal(err)
	}
	for _, key := range []string{"trace_id", "span_id", "parent_span_id"} {
		if _, ok := m[key]; ok {
			t.Fatalf("expected %q omitted, got %s", key, body)
		}
	}
}
