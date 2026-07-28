package auth

import (
	"errors"
	"fmt"
)

// Stable JWT verification error codes returned in API 401 responses.
const (
	CodeJWTRequired         = "JWT_REQUIRED"
	CodeJWTMissing          = "JWT_MISSING"
	CodeJWTExpired          = "JWT_EXPIRED"
	CodeJWTInvalidSignature = "JWT_INVALID_SIGNATURE"
	CodeJWTIssuerMismatch   = "JWT_ISSUER_MISMATCH"
	CodeJWTDomainMismatch   = "JWT_DOMAIN_MISMATCH"
	CodeJWTTenantMismatch   = "JWT_TENANT_MISMATCH"
	CodeJWTInvalidClaims    = "JWT_INVALID_CLAIMS"
	CodeJWTMalformed        = "JWT_MALFORMED"
)

// VerifyDetail is one field-level diagnostic for API error.details.
type VerifyDetail struct {
	Field   string
	Message string
}

// VerifyError is a typed JWT verification failure with API and log metadata.
type VerifyError struct {
	Code     string
	Message  string
	Details  []VerifyDetail
	LogExtra map[string]any
}

func (e *VerifyError) Error() string {
	if e == nil {
		return "jwt verification failed"
	}
	if e.Message != "" {
		return e.Message
	}
	return fmt.Sprintf("jwt verification failed: %s", e.Code)
}

func newVerifyError(code, message string, details []VerifyDetail, logExtra map[string]any) *VerifyError {
	return &VerifyError{
		Code:     code,
		Message:  message,
		Details:  details,
		LogExtra: logExtra,
	}
}

func mismatchDetail(expectedLabel, expected, gotLabel, got string) []VerifyDetail {
	return []VerifyDetail{
		{Field: expectedLabel, Message: expected},
		{Field: gotLabel, Message: got},
	}
}

// AsVerifyError returns *VerifyError when err is or wraps one.
func AsVerifyError(err error) (*VerifyError, bool) {
	var ve *VerifyError
	if errors.As(err, &ve) {
		return ve, true
	}
	return nil, false
}
