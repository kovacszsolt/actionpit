package sbeventlog

import "testing"

func TestShouldEmitConsoleLineEmptyModeAll(t *testing.T) {
	if !ShouldEmitConsoleLine("", "scoutbuddy.feed.result", "info") {
		t.Fatal("empty mode should emit")
	}
}

func TestShouldEmitConsoleLineMinimal(t *testing.T) {
	if !ShouldEmitConsoleLine("minimal", "scoutbuddy.app.started", "info") {
		t.Fatal("app.started")
	}
	if !ShouldEmitConsoleLine("minimal", "scoutbuddy.app.stopped", "info") {
		t.Fatal("app.stopped success")
	}
	if !ShouldEmitConsoleLine("minimal", "scoutbuddy.app.stopped", "error") {
		t.Fatal("app.stopped with error level")
	}
	if !ShouldEmitConsoleLine("minimal", "scoutbuddy.run.complete", "error") {
		t.Fatal("any event at error")
	}
	if ShouldEmitConsoleLine("minimal", "scoutbuddy.feed.result", "info") {
		t.Fatal("feed info hidden")
	}
	if ShouldEmitConsoleLine("minimal", "scoutbuddy.feed.result", "warn") {
		t.Fatal("warn hidden in minimal")
	}
}

func TestShouldEmitConsoleLineSeverityThreshold(t *testing.T) {
	if !ShouldEmitConsoleLine("warn", "x", "warn") || !ShouldEmitConsoleLine("warn", "x", "error") {
		t.Fatal("warn threshold")
	}
	if ShouldEmitConsoleLine("warn", "x", "info") {
		t.Fatal("info below warn")
	}
}
