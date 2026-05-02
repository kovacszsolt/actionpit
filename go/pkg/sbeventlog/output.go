package sbeventlog

import (
	"fmt"
	"strings"
)

// Output selects where Publish writes the event envelope (bitmask).
type Output uint8

const (
	// OutputConsole only stdout via the standard log package.
	OutputConsole Output = 1 << iota // 1
	// OutputServiceBus only Azure Service Bus.
	OutputServiceBus // 2
)

// OutputConsoleAndServiceBus writes to console and Service Bus.
const OutputConsoleAndServiceBus = OutputConsole | OutputServiceBus

// UseConsole is true when console logging is enabled.
func (o Output) UseConsole() bool { return o&OutputConsole != 0 }

// UseServiceBus is true when Service Bus send is enabled.
func (o Output) UseServiceBus() bool { return o&OutputServiceBus != 0 }

// ParseLogEventOutput parses LOG_EVENT_OUTPUT. Empty env returns 0 (unset): NewPublisher uses Service Bus
// only when a sender exists, otherwise returns nil (no pipeline).
//
// Formátum: vesszővel elválasztott célok, szóköz engedett. Tokenek: console, servicebus (kis–nagybetű mindegy).
// Példák: "console", "servicebus", "console,servicebus". Egész szavas alias: both, all → mindkettő.
func ParseLogEventOutput(s string) (Output, error) {
	s = strings.TrimSpace(s)
	if s == "" {
		return 0, nil
	}
	low := strings.ToLower(s)
	if low == "both" || low == "all" {
		return OutputConsoleAndServiceBus, nil
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
		case "servicebus":
			out |= OutputServiceBus
		default:
			return 0, fmt.Errorf("LOG_EVENT_OUTPUT: unknown destination %q in %q (use console and/or servicebus, comma-separated)", p, s)
		}
	}
	if out == 0 {
		return 0, fmt.Errorf("LOG_EVENT_OUTPUT: no valid destinations in %q (e.g. console, servicebus, or console,servicebus)", s)
	}
	return out, nil
}

// String returns a short label for logs.
func (o Output) String() string {
	switch {
	case o == 0:
		return "unset"
	case o == OutputConsole:
		return "console"
	case o == OutputServiceBus:
		return "servicebus"
	case o.UseConsole() && o.UseServiceBus():
		return "console,servicebus"
	default:
		return fmt.Sprintf("output(%d)", o)
	}
}
