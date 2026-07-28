package echo

import (
	"net/http"
	"strings"

	echov4 "github.com/labstack/echo/v4"

	"github.com/kovacszsolt/actionpit/go/pkg/auth"
)

const (
	ContextAuthUserID   = "auth_user_id"
	ContextAuthEmail    = "auth_email"
	ContextAuthName     = "auth_name"
	ContextAuthDomain   = "auth_domain"
	ContextAuthTenantID = "auth_tenant_id"
)

var jwtPublicPathPrefixes = []string{
	"/health",
	"/healthz",
}

// JWTAuthOptions configures public-path exceptions for RequireBearerJWT.
type JWTAuthOptions struct {
	// Enabled turns JWT validation on. When false, all requests pass without a token.
	Enabled bool
	// PlaygroundPublic allows GET /graphql without a token when GraphQL Playground is enabled.
	PlaygroundPublic bool
	// OnUnauthorized is called with log-oriented detail before the 401 JSON response.
	// Consumers can wire structured event logging here (e.g. MergeRequestErrorDetail).
	OnUnauthorized func(c echov4.Context, detail map[string]any)
}

func requestPath(c echov4.Context) string {
	return c.Request().URL.Path
}

func isJWTPublicPath(path, method string, opts JWTAuthOptions) bool {
	if path == "/" {
		return true
	}
	if opts.PlaygroundPublic && method == http.MethodGet && path == "/graphql" {
		return true
	}
	for _, p := range jwtPublicPathPrefixes {
		if path == p || strings.HasPrefix(path, p+"/") {
			return true
		}
	}
	return false
}

// RequireBearerJWT rejects requests without a valid Bearer access token.
func RequireBearerJWT(verifier *auth.Verifier, opts JWTAuthOptions) echov4.MiddlewareFunc {
	return func(next echov4.HandlerFunc) echov4.HandlerFunc {
		return func(c echov4.Context) error {
			if !opts.Enabled {
				setDevAuthContext(c)
				return next(c)
			}
			if c.Request().Method == http.MethodOptions || isJWTPublicPath(requestPath(c), c.Request().Method, opts) {
				return next(c)
			}
			authz := c.Request().Header.Get(echov4.HeaderAuthorization)
			if !strings.HasPrefix(authz, "Bearer ") {
				return jwtUnauthorized(c, opts, auth.CodeJWTRequired, "Bearer token is required; send Authorization: Bearer <access_token>.", nil, nil)
			}
			raw := strings.TrimSpace(strings.TrimPrefix(authz, "Bearer "))
			claims, err := verifier.Verify(raw)
			if err != nil {
				return jwtVerifyError(c, opts, err)
			}
			c.Set(ContextAuthUserID, claims.UserID)
			c.Set(ContextAuthTenantID, claims.TenantID)
			c.Set(ContextAuthEmail, claims.Email)
			c.Set(ContextAuthName, claims.Name)
			c.Set(ContextAuthDomain, claims.Domain)
			return next(c)
		}
	}
}

func jwtVerifyError(c echov4.Context, opts JWTAuthOptions, err error) error {
	if ve, ok := auth.AsVerifyError(err); ok {
		return jwtUnauthorized(c, opts, ve.Code, ve.Message, ve.Details, ve.LogExtra)
	}
	return jwtUnauthorized(c, opts, auth.CodeJWTMalformed, "Token verification failed.", nil, map[string]any{
		"jwt.reason":      auth.CodeJWTMalformed,
		"jwt.parse_error": err.Error(),
	})
}

func jwtUnauthorized(c echov4.Context, opts JWTAuthOptions, code, message string, details []auth.VerifyDetail, logExtra map[string]any) error {
	eventDetail := map[string]any{
		"error.message": message,
		"error.code":    code,
		"jwt.reason":    code,
	}
	for k, v := range logExtra {
		eventDetail[k] = v
	}
	mergeAuthorizationLogFields(eventDetail, c.Request().Header.Get(echov4.HeaderAuthorization))
	if opts.OnUnauthorized != nil {
		opts.OnUnauthorized(c, eventDetail)
	}

	dtoDetails := make([]ErrorDetail, 0, len(details))
	for _, d := range details {
		dtoDetails = append(dtoDetails, ErrorDetail{
			Field:   d.Field,
			Message: d.Message,
		})
	}
	return c.JSON(http.StatusUnauthorized, ErrorResponse{
		Error: ErrorBody{
			Code:    code,
			Message: message,
			Details: dtoDetails,
		},
	})
}

// mergeAuthorizationLogFields records how Authorization was sent without logging the token.
func mergeAuthorizationLogFields(dest map[string]any, authz string) {
	authz = strings.TrimSpace(authz)
	if authz == "" {
		dest["jwt.authorization_header"] = "absent"
		return
	}
	if !strings.HasPrefix(authz, "Bearer ") {
		dest["jwt.authorization_header"] = "non_bearer"
		return
	}
	dest["jwt.authorization_header"] = "bearer"
	raw := strings.TrimSpace(strings.TrimPrefix(authz, "Bearer "))
	dest["jwt.token_present"] = raw != ""
	dest["jwt.token_length"] = len(raw)
}

func setDevAuthContext(c echov4.Context) {
	c.Set(ContextAuthUserID, int64(0))
	// Default to the seeded tenant (id=1) when JWT auth is disabled so
	// local/dev requests satisfy tenant checks that require tenant_id > 0.
	c.Set(ContextAuthTenantID, int64(1))
	c.Set(ContextAuthEmail, "dev@local")
	c.Set(ContextAuthName, "Dev")
	c.Set(ContextAuthDomain, "local")
}
