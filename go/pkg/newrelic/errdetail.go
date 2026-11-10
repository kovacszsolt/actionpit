package newrelic

import (
	"errors"
	"fmt"
	"strings"
)

// ReportParams configures a multi-line error report for stderr and optional Log API detail.
type ReportParams struct {
	CommandPath     string
	DefaultCommand  string
	Invocation      string
	Err             error
	AppendDiagnostics func(b *strings.Builder, err error)
	FooterNote      string
	// Localized labels (optional); import CLI uses Hungarian defaults below.
	LabelCommand       string
	LabelInvocation    string
	LabelErrorChain    string
	LabelEmptyChain    string
	LabelCausePrefix   string
}

// DefaultHungarianReportLabels returns labels matching the it-hello import CLI.
func DefaultHungarianReportLabels() (cmd, inv, chain, empty, cause string) {
	return "parancs", "teljes hívás", "hiba (unwrap lánc)", "(üres)", "okozó"
}

// FormatErrorReport builds a multi-line summary: command, unwrap chain, optional diagnostics hook, footer.
func FormatErrorReport(p ReportParams) string {
	if p.Err == nil {
		return ""
	}
	var b strings.Builder
	command := strings.TrimSpace(p.DefaultCommand)
	if p.CommandPath != "" {
		command = p.CommandPath
	}
	cmdLabel := p.LabelCommand
	if cmdLabel == "" {
		cmdLabel = "command"
	}
	invLabel := p.LabelInvocation
	if invLabel == "" {
		invLabel = "invocation"
	}
	chainLabel := p.LabelErrorChain
	if chainLabel == "" {
		chainLabel = "error chain"
	}
	emptyLabel := p.LabelEmptyChain
	if emptyLabel == "" {
		emptyLabel = "(empty)"
	}
	causePrefix := p.LabelCausePrefix
	if causePrefix == "" {
		causePrefix = "cause"
	}

	fmt.Fprintf(&b, "%s: %s\n", cmdLabel, command)
	fmt.Fprintf(&b, "%s: %s\n", invLabel, p.Invocation)
	fmt.Fprintf(&b, "%s:\n", chainLabel)

	seen := make(map[string]struct{})
	n := 0
	for e := p.Err; e != nil; e = errors.Unwrap(e) {
		msg := e.Error()
		if msg == "" {
			continue
		}
		if _, dup := seen[msg]; dup {
			continue
		}
		seen[msg] = struct{}{}
		prefix := "  "
		if n > 0 {
			prefix = "  " + causePrefix + ": "
		}
		fmt.Fprintf(&b, "%s%s\n", prefix, msg)
		n++
	}
	if n == 0 {
		fmt.Fprintf(&b, "  %s\n", emptyLabel)
	}
	if p.AppendDiagnostics != nil {
		p.AppendDiagnostics(&b, p.Err)
	}
	if p.FooterNote != "" {
		fmt.Fprintf(&b, "\n%s\n", p.FooterNote)
	}
	return b.String()
}
