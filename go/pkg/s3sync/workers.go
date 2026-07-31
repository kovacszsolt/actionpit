package s3sync

import (
	"strconv"
	"strings"
)

// DefaultRegion is used when Config.Region is empty after normalization.
const DefaultRegion = "eu-north-1"

const (
	defaultUploadWorkers = 48
	deleteBatchSize      = 1000
	// CloudFront CreateInvalidation allows up to 3000 paths; stay under with margin.
	maxInvalidationPaths = 2000
)

// ParseUploadWorkers parses a positive worker count from a string (e.g. env var).
// Empty or invalid values return 0 (meaning use the package default).
func ParseUploadWorkers(raw string) int {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return 0
	}
	n, err := strconv.Atoi(raw)
	if err != nil || n <= 0 {
		return 0
	}
	return n
}

// NormalizePrefix trims slashes and ensures a trailing "/" when non-empty.
func NormalizePrefix(prefix string) string {
	prefix = strings.TrimSpace(prefix)
	prefix = strings.TrimLeft(prefix, "/")
	if prefix != "" && !strings.HasSuffix(prefix, "/") {
		prefix += "/"
	}
	return prefix
}

// NormalizeRegion trims whitespace/quotes; empty becomes fallback (or DefaultRegion).
func NormalizeRegion(region, fallback string) string {
	region = strings.Trim(strings.TrimSpace(region), `"'`)
	if region != "" {
		return region
	}
	if fallback != "" {
		return fallback
	}
	return DefaultRegion
}
