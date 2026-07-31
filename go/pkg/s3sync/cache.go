package s3sync

import "strings"

const (
	cacheLong   = "public,max-age=31536000,immutable"
	cacheMedium = "public,max-age=86400,must-revalidate"
	cacheShort  = "public,max-age=300,must-revalidate"
)

// CacheControlFunc returns a Cache-Control header for a path relative to the source root.
type CacheControlFunc func(relPath string) string

// DefaultStaticSiteCacheControl applies common static-site caching rules
// (long for assets, medium for search indexes, short for HTML).
func DefaultStaticSiteCacheControl(rel string) string {
	rel = strings.ToLower(rel)
	switch {
	case strings.HasPrefix(rel, "css/"),
		strings.HasPrefix(rel, "js/"),
		strings.HasPrefix(rel, "article-images/"),
		strings.HasPrefix(rel, "favicon"),
		rel == "apple-touch-icon.png":
		return cacheLong
	case strings.HasPrefix(rel, "pagefind/"):
		return cacheMedium
	default:
		return cacheShort
	}
}

func (c Config) cacheControl() CacheControlFunc {
	if c.CacheControl != nil {
		return c.CacheControl
	}
	return DefaultStaticSiteCacheControl
}
