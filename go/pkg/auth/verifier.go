// Package auth validates HS256 Bearer access tokens (user_id, tenant_id, email, name, domain, iss=auth-ba).
package auth

import (
	"errors"
	"fmt"
	"strconv"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

// Claims is the validated access token payload.
type Claims struct {
	UserID   int64
	TenantID int64
	Email    string
	Name     string
	Domain   string
}

type accessClaims struct {
	UserID   int64  `json:"user_id"`
	TenantID int64  `json:"tenant_id"`
	Email    string `json:"email"`
	Name     string `json:"name"`
	Domain   string `json:"domain"`
	jwt.RegisteredClaims
}

// Verifier validates Bearer access tokens.
type Verifier struct {
	cfg JWTAuth
}

// NewVerifier creates a JWT verifier from loaded config.
func NewVerifier(cfg JWTAuth) *Verifier {
	return &Verifier{cfg: cfg}
}

// Verify parses and validates a raw JWT string.
func (v *Verifier) Verify(tokenString string) (*Claims, error) {
	secret := strings.TrimSpace(v.cfg.Secret)
	tokenString = strings.TrimSpace(tokenString)
	if tokenString == "" {
		return nil, newVerifyError(
			CodeJWTMissing,
			"Bearer token is empty; send Authorization: Bearer <access_token>.",
			nil,
			nil,
		)
	}
	tok, err := jwt.ParseWithClaims(tokenString, &accessClaims{}, func(t *jwt.Token) (any, error) {
		if t.Method != jwt.SigningMethodHS256 {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return []byte(secret), nil
	})
	if err != nil {
		return nil, mapParseError(err)
	}
	raw, ok := tok.Claims.(*accessClaims)
	if !ok || !tok.Valid {
		return nil, newVerifyError(
			CodeJWTMalformed,
			"Token is invalid or could not be parsed; ensure it is a valid HS256 access token.",
			nil,
			nil,
		)
	}
	if raw.Issuer != v.cfg.Issuer {
		return nil, newVerifyError(
			CodeJWTIssuerMismatch,
			"Token issuer (iss) does not match JWT_ISSUER; align settings backend JWT_ISSUER with auth token issuer.",
			mismatchDetail("expected", v.cfg.Issuer, "got", raw.Issuer),
			map[string]any{
				"jwt.reason":          CodeJWTIssuerMismatch,
				"jwt.expected_issuer": v.cfg.Issuer,
				"jwt.token_issuer":    raw.Issuer,
			},
		)
	}
	email := strings.TrimSpace(raw.Email)
	name := strings.TrimSpace(raw.Name)
	domain := strings.TrimSpace(raw.Domain)
	if missing := missingRequiredClaims(raw.UserID, email, name, domain); len(missing) > 0 {
		details := make([]VerifyDetail, 0, len(missing))
		for _, claim := range missing {
			details = append(details, VerifyDetail{
				Field:   claim,
				Message: "required claim is missing or empty",
			})
		}
		return nil, newVerifyError(
			CodeJWTInvalidClaims,
			"Token is missing required claims (user_id, email, name, domain); re-issue token via auth login.",
			details,
			map[string]any{
				"jwt.reason":         CodeJWTInvalidClaims,
				"jwt.missing_claims": missing,
			},
		)
	}
	if domain != v.cfg.Domain {
		return nil, newVerifyError(
			CodeJWTDomainMismatch,
			"Token domain claim does not match JWT_DOMAIN; align auth tenant post-login URL / domain with admin app origin.",
			mismatchDetail("expected", v.cfg.Domain, "got", domain),
			map[string]any{
				"jwt.reason":          CodeJWTDomainMismatch,
				"jwt.expected_domain": v.cfg.Domain,
				"jwt.token_domain":    domain,
			},
		)
	}
	if v.cfg.TenantID > 0 && raw.TenantID != v.cfg.TenantID {
		return nil, newVerifyError(
			CodeJWTTenantMismatch,
			"Token tenant_id does not match JWT_TENANT_ID; align settings JWT_TENANT_ID with auth tenant.",
			mismatchDetail("expected", strconv.FormatInt(v.cfg.TenantID, 10), "got", strconv.FormatInt(raw.TenantID, 10)),
			map[string]any{
				"jwt.reason":          CodeJWTTenantMismatch,
				"jwt.expected_tenant": v.cfg.TenantID,
				"jwt.token_tenant":    raw.TenantID,
			},
		)
	}
	return &Claims{
		UserID:   raw.UserID,
		TenantID: raw.TenantID,
		Email:    email,
		Name:     name,
		Domain:   domain,
	}, nil
}

func mapParseError(err error) error {
	switch {
	case errors.Is(err, jwt.ErrTokenExpired):
		return newVerifyError(
			CodeJWTExpired,
			"Access token expired; sign in again or check auth tenant JWT_TTL.",
			nil,
			map[string]any{"jwt.reason": CodeJWTExpired},
		)
	case errors.Is(err, jwt.ErrTokenSignatureInvalid):
		return newVerifyError(
			CodeJWTInvalidSignature,
			"Token signature is invalid; ensure JWT_SECRET matches auth tenant jwt_secret.",
			nil,
			map[string]any{"jwt.reason": CodeJWTInvalidSignature},
		)
	case errors.Is(err, jwt.ErrTokenMalformed),
		errors.Is(err, jwt.ErrTokenUnverifiable),
		errors.Is(err, jwt.ErrTokenNotValidYet),
		errors.Is(err, jwt.ErrTokenInvalidClaims),
		errors.Is(err, jwt.ErrTokenInvalidAudience),
		errors.Is(err, jwt.ErrTokenInvalidIssuer),
		errors.Is(err, jwt.ErrTokenInvalidId):
		return newVerifyError(
			CodeJWTMalformed,
			"Token is malformed or uses an unsupported algorithm; expected HS256 access token.",
			nil,
			map[string]any{"jwt.reason": CodeJWTMalformed, "jwt.parse_error": err.Error()},
		)
	default:
		if strings.Contains(err.Error(), "unexpected signing method") {
			return newVerifyError(
				CodeJWTMalformed,
				"Token uses an unexpected signing algorithm; expected HS256.",
				nil,
				map[string]any{"jwt.reason": CodeJWTMalformed, "jwt.parse_error": err.Error()},
			)
		}
		return newVerifyError(
			CodeJWTMalformed,
			"Token could not be parsed; ensure it is a valid HS256 access token.",
			nil,
			map[string]any{"jwt.reason": CodeJWTMalformed, "jwt.parse_error": err.Error()},
		)
	}
}

func missingRequiredClaims(userID int64, email, name, domain string) []string {
	var missing []string
	if userID <= 0 {
		missing = append(missing, "user_id")
	}
	if email == "" {
		missing = append(missing, "email")
	}
	if name == "" {
		missing = append(missing, "name")
	}
	if domain == "" {
		missing = append(missing, "domain")
	}
	return missing
}
