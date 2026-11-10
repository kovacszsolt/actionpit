package newrelic_test

import (
	"errors"
	"fmt"
	"strings"
	"testing"

	"github.com/kovacszsolt/actionpit/go/pkg/newrelic"
)

func TestFormatErrorReport_unwrapChain(t *testing.T) {
	inner := errors.New("inner")
	wrapped := fmt.Errorf("outer: %w", inner)
	out := newrelic.FormatErrorReport(newrelic.ReportParams{
		CommandPath:    "import scrape",
		Invocation:     "import scrape --site 1",
		Err:            wrapped,
		DefaultCommand: "import",
	})
	if !strings.Contains(out, "import scrape") {
		t.Fatalf("missing command:\n%s", out)
	}
	if !strings.Contains(out, "outer:") || !strings.Contains(out, "inner") {
		t.Fatalf("missing chain:\n%s", out)
	}
}

func TestFormatErrorReport_nilErr(t *testing.T) {
	if got := newrelic.FormatErrorReport(newrelic.ReportParams{Err: nil}); got != "" {
		t.Fatalf("want empty, got %q", got)
	}
}
