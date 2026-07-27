package openobserve

import (
	"fmt"
	"strings"
)

// Output selects where OpenObserve-style events are written.
type Output uint8

const (
	// OutputConsole enables stdout-only logging.
	OutputConsole Output = 1 << iota
	// OutputOpenObserve enables HTTP ingest to OpenObserve.
	OutputOpenObserve
)

// OutputConsoleAndOpenObserve writes to both outputs.
const OutputConsoleAndOpenObserve = OutputConsole | OutputOpenObserve

// UseConsole reports whether console logging is enabled.
func (o Output) UseConsole() bool { return o&OutputConsole != 0 }

// UseOpenObserve reports whether OpenObserve ingest is enabled.
func (o Output) UseOpenObserve() bool { return o&OutputOpenObserve != 0 }

// ParseLogEventOutput parses LOG_EVENT_OUTPUT values like console, openobserve, or both.
func ParseLogEventOutput(s string) (Output, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, nil
	}
	low := strings.ToLower(s)
	if low == "both" || low == "all" {
		return OutputConsoleAndOpenObserve, nil
	}
	var out Output
	for _, part := range strings.Split(s, ",") {
		p := strings.ToLower(strings.TrimSpace(part))
		if p == "" {
			continue
		}
		switch p {
		case "console":
			out |= OutputConsole
		case "openobserve":
			out |= OutputOpenObserve
		default:
			return 0, fmt.Errorf("LOG_EVENT_OUTPUT: unknown destination %q in %q (use console and/or openobserve, comma-separated)", p, s)
		}
	}
	if out == 0 {
		return 0, fmt.Errorf("LOG_EVENT_OUTPUT: no valid destinations in %q (e.g. console, openobserve, or console,openobserve)", s)
	}
	return out, nil
}
