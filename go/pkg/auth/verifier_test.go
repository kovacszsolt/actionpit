package auth_test

import (
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"github.com/kovacszsolt/actionpit/go/pkg/auth"
)

const testSecret = "dev-test-jwt-secret-min-32-characters!!"

func testJWTAuth() auth.JWTAuth {
	return auth.JWTAuth{
		Secret: testSecret,
		Issuer: "auth-ba",
		Domain: "http://127.0.0.1:5175",
	}
}

func signTestToken(t *testing.T, cfg auth.JWTAuth, mutate func(*jwt.RegisteredClaims)) string {
	t.Helper()
	claims := struct {
		UserID   int64  `json:"user_id"`
		TenantID int64  `json:"tenant_id"`
		Email    string `json:"email"`
		Name     string `json:"name"`
		Domain   string `json:"domain"`
		jwt.RegisteredClaims
	}{
		UserID:   1,
		TenantID: 42,
		Email:    "user@example.com",
		Name:     "Test User",
		Domain:   cfg.Domain,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    cfg.Issuer,
			IssuedAt:  jwt.NewNumericDate(time.Now()),
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
		},
	}
	if mutate != nil {
		mutate(&claims.RegisteredClaims)
	}
	tok := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	s, err := tok.SignedString([]byte(cfg.Secret))
	if err != nil {
		t.Fatalf("sign: %v", err)
	}
	return s
}

func assertVerifyError(t *testing.T, err error, wantCode string) *auth.VerifyError {
	t.Helper()
	ve, ok := auth.AsVerifyError(err)
	if !ok {
		t.Fatalf("expected VerifyError, got %T: %v", err, err)
	}
	if ve.Code != wantCode {
		t.Fatalf("code = %q, want %q (message=%q)", ve.Code, wantCode, ve.Message)
	}
	return ve
}

func TestVerifier_Verify_valid(t *testing.T) {
	cfg := testJWTAuth()
	v := auth.NewVerifier(cfg)
	raw := signTestToken(t, cfg, nil)
	got, err := v.Verify(raw)
	if err != nil {
		t.Fatalf("Verify: %v", err)
	}
	if got.UserID != 1 || got.TenantID != 42 || got.Email != "user@example.com" {
		t.Fatalf("claims: %+v", got)
	}
}

func TestVerifier_Verify_emptyToken(t *testing.T) {
	cfg := testJWTAuth()
	v := auth.NewVerifier(cfg)
	_, err := v.Verify("   ")
	assertVerifyError(t, err, auth.CodeJWTMissing)
}

func TestVerifier_Verify_expired(t *testing.T) {
	cfg := testJWTAuth()
	v := auth.NewVerifier(cfg)
	raw := signTestToken(t, cfg, func(rc *jwt.RegisteredClaims) {
		rc.ExpiresAt = jwt.NewNumericDate(time.Now().Add(-time.Hour))
	})
	_, err := v.Verify(raw)
	assertVerifyError(t, err, auth.CodeJWTExpired)
}

func TestVerifier_Verify_invalidSignature(t *testing.T) {
	cfg := testJWTAuth()
	v := auth.NewVerifier(cfg)
	raw := signTestToken(t, cfg, nil)
	_, err := v.Verify(raw + "tampered")
	assertVerifyError(t, err, auth.CodeJWTInvalidSignature)
}

func TestVerifier_Verify_invalidIssuer(t *testing.T) {
	cfg := testJWTAuth()
	v := auth.NewVerifier(cfg)
	raw := signTestToken(t, cfg, func(rc *jwt.RegisteredClaims) { rc.Issuer = "other" })
	_, err := v.Verify(raw)
	ve := assertVerifyError(t, err, auth.CodeJWTIssuerMismatch)
	if len(ve.Details) != 2 || ve.Details[0].Message != cfg.Issuer || ve.Details[1].Message != "other" {
		t.Fatalf("details = %#v", ve.Details)
	}
}

func TestVerifier_Verify_invalidDomain(t *testing.T) {
	cfg := testJWTAuth()
	v := auth.NewVerifier(cfg)
	claims := struct {
		UserID   int64  `json:"user_id"`
		TenantID int64  `json:"tenant_id"`
		Email    string `json:"email"`
		Name     string `json:"name"`
		Domain   string `json:"domain"`
		jwt.RegisteredClaims
	}{
		UserID: 1, TenantID: 42, Email: "a@b.com", Name: "N", Domain: "http://wrong",
		RegisteredClaims: jwt.RegisteredClaims{Issuer: cfg.Issuer, ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour))},
	}
	tok, _ := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(cfg.Secret))
	_, err := v.Verify(tok)
	ve := assertVerifyError(t, err, auth.CodeJWTDomainMismatch)
	if len(ve.Details) != 2 || ve.Details[0].Message != cfg.Domain || ve.Details[1].Message != "http://wrong" {
		t.Fatalf("details = %#v", ve.Details)
	}
}

func TestVerifier_Verify_tenantEnforced(t *testing.T) {
	cfg := testJWTAuth()
	cfg.TenantID = 99
	v := auth.NewVerifier(cfg)
	raw := signTestToken(t, testJWTAuth(), nil)
	_, err := v.Verify(raw)
	ve := assertVerifyError(t, err, auth.CodeJWTTenantMismatch)
	if len(ve.Details) != 2 || ve.Details[0].Message != "99" || ve.Details[1].Message != "42" {
		t.Fatalf("details = %#v", ve.Details)
	}
}

func TestVerifier_Verify_missingClaims(t *testing.T) {
	cfg := testJWTAuth()
	v := auth.NewVerifier(cfg)
	claims := struct {
		UserID   int64  `json:"user_id"`
		TenantID int64  `json:"tenant_id"`
		Email    string `json:"email"`
		Name     string `json:"name"`
		Domain   string `json:"domain"`
		jwt.RegisteredClaims
	}{
		UserID: 0, TenantID: 42, Email: "", Name: "N", Domain: cfg.Domain,
		RegisteredClaims: jwt.RegisteredClaims{Issuer: cfg.Issuer, ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour))},
	}
	tok, _ := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(cfg.Secret))
	_, err := v.Verify(tok)
	assertVerifyError(t, err, auth.CodeJWTInvalidClaims)
}

func TestVerifier_Verify_wrongSecret(t *testing.T) {
	cfg := testJWTAuth()
	v := auth.NewVerifier(cfg)
	claims := struct {
		UserID   int64  `json:"user_id"`
		TenantID int64  `json:"tenant_id"`
		Email    string `json:"email"`
		Name     string `json:"name"`
		Domain   string `json:"domain"`
		jwt.RegisteredClaims
	}{
		UserID: 1, TenantID: 42, Email: "a@b.com", Name: "N", Domain: cfg.Domain,
		RegisteredClaims: jwt.RegisteredClaims{Issuer: cfg.Issuer, ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour))},
	}
	tok, _ := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte("other-secret-that-is-long-enough-32ch"))
	_, err := v.Verify(tok)
	assertVerifyError(t, err, auth.CodeJWTInvalidSignature)
}
