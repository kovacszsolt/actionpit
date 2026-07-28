package auth_test

import (
	"testing"

	"github.com/kovacszsolt/actionpit/go/pkg/auth"
)

func TestLoadJWTAuth_disabledSkipsSecretValidation(t *testing.T) {
	t.Setenv("JWT_AUTH_ENABLED", "false")
	t.Setenv("JWT_SECRET", "")
	t.Setenv("JWT_DOMAIN", "")

	cfg, err := auth.LoadJWTAuth()
	if err != nil {
		t.Fatalf("LoadJWTAuth: %v", err)
	}
	if cfg.Enabled {
		t.Fatal("expected JWT auth to be disabled")
	}
}

func TestLoadJWTAuth_enabledRequiresSecret(t *testing.T) {
	t.Setenv("JWT_AUTH_ENABLED", "true")
	t.Setenv("JWT_SECRET", "short")
	t.Setenv("JWT_DOMAIN", "http://127.0.0.1:5175")

	_, err := auth.LoadJWTAuth()
	if err == nil {
		t.Fatal("expected error for short JWT_SECRET")
	}
}
