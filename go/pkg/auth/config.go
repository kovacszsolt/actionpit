package auth

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

// JWTAuth holds settings for validating HS256 access tokens.
type JWTAuth struct {
	Enabled  bool
	Secret   string
	Issuer   string
	Domain   string
	TenantID int64 // 0 = do not enforce tenant_id claim
}

// LoadJWTAuth reads JWT validation settings from the environment.
func LoadJWTAuth() (JWTAuth, error) {
	enabled, err := parseBoolEnv("JWT_AUTH_ENABLED", true)
	if err != nil {
		return JWTAuth{}, err
	}
	if !enabled {
		return JWTAuth{Enabled: false}, nil
	}

	secret := strings.TrimSpace(os.Getenv("JWT_SECRET"))
	if len(secret) < 32 {
		return JWTAuth{}, fmt.Errorf("JWT_SECRET: required, at least 32 characters")
	}
	issuer := strings.TrimSpace(os.Getenv("JWT_ISSUER"))
	if issuer == "" {
		issuer = "auth-ba"
	}
	domain := strings.TrimSpace(os.Getenv("JWT_DOMAIN"))
	if domain == "" {
		return JWTAuth{}, fmt.Errorf("JWT_DOMAIN: required (expected token domain claim, e.g. admin app origin)")
	}
	var tenantID int64
	if raw := strings.TrimSpace(os.Getenv("JWT_TENANT_ID")); raw != "" {
		id, err := strconv.ParseInt(raw, 10, 64)
		if err != nil || id <= 0 {
			return JWTAuth{}, fmt.Errorf("JWT_TENANT_ID: invalid positive integer %q", raw)
		}
		tenantID = id
	}
	return JWTAuth{
		Enabled:  true,
		Secret:   secret,
		Issuer:   issuer,
		Domain:   domain,
		TenantID: tenantID,
	}, nil
}

func parseBoolEnv(key string, defaultVal bool) (bool, error) {
	raw := strings.TrimSpace(os.Getenv(key))
	if raw == "" {
		return defaultVal, nil
	}
	v, err := strconv.ParseBool(raw)
	if err != nil {
		return false, fmt.Errorf("invalid %s %q", key, raw)
	}
	return v, nil
}
