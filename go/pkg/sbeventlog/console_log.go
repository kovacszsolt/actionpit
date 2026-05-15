package sbeventlog

import "strings"

// severityRank maps log levels for console filtering (higher = more severe).
func severityRank(level string) int {
	switch strings.ToLower(strings.TrimSpace(level)) {
	case "debug", "trace":
		return 0
	case "info", "":
		return 1
	case "warn", "warning":
		return 2
	case "error", "fatal", "critical":
		return 3
	default:
		return 1
	}
}

// ShouldEmitConsoleLine decides whether a structured event is printed to stdout.
// mode is Meta.ConsoleLog: empty = emit all; "minimal" = app start/stop + any error-level event;
// otherwise mode is a severity threshold (debug, info, warn, error): emit if event severity >= threshold.
func ShouldEmitConsoleLine(mode, eventName, eventLevel string) bool {
	mode = strings.ToLower(strings.TrimSpace(mode))
	if mode == "" {
		return true
	}
	if mode == "minimal" {
		en := strings.TrimSpace(eventName)
		lv := strings.ToLower(strings.TrimSpace(eventLevel))
		return strings.HasSuffix(en, ".app.started") ||
			strings.HasSuffix(en, ".app.stopped") ||
			lv == "error"
	}
	return severityRank(eventLevel) >= severityRank(mode)
}
