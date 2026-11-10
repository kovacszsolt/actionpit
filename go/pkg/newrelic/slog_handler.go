package newrelic

import (
	"io"
	"log/slog"
	"os"
	"strings"
	"time"

	"github.com/lmittmann/tint"
	"github.com/mattn/go-isatty"
)

// SlogOptions configures stdout slog output (tint console or JSON) and optional Log API forwarding.
type SlogOptions struct {
	Level          slog.Level
	Format         string // "json", "console", "auto", or empty (treated as auto)
	ServiceName    string
	Output         io.Writer
	AddSourceOnDebug bool
}

// ResolveLogFormat picks console (tint) or json. Format "auto" uses console when w is a TTY.
func ResolveLogFormat(format string, w io.Writer) string {
	f := strings.ToLower(strings.TrimSpace(format))
	switch f {
	case "", "auto":
		if isWriterTTY(w) {
			return "console"
		}
		return "json"
	case "json":
		return "json"
	case "console", "text", "pretty":
		return "console"
	default:
		return "console"
	}
}

func isWriterTTY(w io.Writer) bool {
	if w == nil {
		w = os.Stdout
	}
	if f, ok := w.(*os.File); ok {
		return isatty.IsTerminal(f.Fd())
	}
	return false
}

// NewStdoutHandler builds a handler that writes to opts.Output (default stdout) and forwards to nr when enabled.
func NewStdoutHandler(opts SlogOptions, nr *Client) slog.Handler {
	out := opts.Output
	if out == nil {
		out = os.Stdout
	}
	lv := opts.Level
	if lv == 0 {
		lv = slog.LevelInfo
	}

	resolved := ResolveLogFormat(opts.Format, out)
	var inner slog.Handler
	switch resolved {
	case "json":
		inner = slog.NewJSONHandler(out, &slog.HandlerOptions{Level: lv})
	default:
		addSource := opts.AddSourceOnDebug
		if !opts.AddSourceOnDebug && lv == slog.LevelDebug {
			addSource = true
		}
		inner = tint.NewHandler(out, &tint.Options{
			Level:      lv,
			TimeFormat: time.RFC3339,
			AddSource:  addSource,
		})
	}

	service := strings.TrimSpace(opts.ServiceName)
	if service != "" {
		inner = inner.WithAttrs([]slog.Attr{slog.String("service.name", service)})
	}

	if nr == nil || !nr.Enabled() {
		return inner
	}
	return &forwardHandler{
		inner:       inner,
		client:      nr,
		serviceName: service,
		minLevel:    lv,
	}
}

// InstallDefaultLogger sets slog.Default to a logger using NewStdoutHandler.
func InstallDefaultLogger(opts SlogOptions, nr *Client) *slog.Logger {
	logger := slog.New(NewStdoutHandler(opts, nr))
	slog.SetDefault(logger)
	return logger
}
