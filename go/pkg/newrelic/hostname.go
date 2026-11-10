package newrelic

import "os"

func hostname() string {
	h, err := os.Hostname()
	if err != nil || h == "" {
		return "unknown"
	}
	return h
}
