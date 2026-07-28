package echo_test

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	echov4 "github.com/labstack/echo/v4"

	"github.com/kovacszsolt/actionpit/go/pkg/auth"
	authecho "github.com/kovacszsolt/actionpit/go/pkg/auth/echo"
)

const testSecret = "dev-test-jwt-secret-min-32-characters!!"

func testVerifier() *auth.Verifier {
	return auth.NewVerifier(auth.JWTAuth{
		Enabled: true,
		Secret:  testSecret,
		Issuer:  "auth-ba",
		Domain:  "http://127.0.0.1:5175",
	})
}

func enabledJWTOptions(playgroundPublic bool) authecho.JWTAuthOptions {
	return authecho.JWTAuthOptions{
		Enabled:          true,
		PlaygroundPublic: playgroundPublic,
	}
}

func signToken(t *testing.T) string {
	t.Helper()
	claims := struct {
		UserID   int64  `json:"user_id"`
		TenantID int64  `json:"tenant_id"`
		Email    string `json:"email"`
		Name     string `json:"name"`
		Domain   string `json:"domain"`
		jwt.RegisteredClaims
	}{
		UserID: 1, TenantID: 2, Email: "a@b.com", Name: "User", Domain: "http://127.0.0.1:5175",
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    "auth-ba",
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
		},
	}
	s, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(testSecret))
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func TestRequireBearerJWT_skipsHealth(t *testing.T) {
	e := echov4.New()
	e.Use(authecho.RequireBearerJWT(testVerifier(), authecho.JWTAuthOptions{Enabled: true}))
	e.GET("/health/live", func(c echov4.Context) error { return c.NoContent(http.StatusOK) })

	req := httptest.NewRequest(http.MethodGet, "/health/live", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status=%d", rec.Code)
	}
}

func TestRequireBearerJWT_skipsHealthz(t *testing.T) {
	e := echov4.New()
	e.Use(authecho.RequireBearerJWT(testVerifier(), authecho.JWTAuthOptions{Enabled: true}))
	e.GET("/healthz", func(c echov4.Context) error { return c.NoContent(http.StatusOK) })

	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status=%d", rec.Code)
	}
}

func decodeErrorBody(t *testing.T, body string) authecho.ErrorBody {
	t.Helper()
	var resp authecho.ErrorResponse
	if err := json.Unmarshal([]byte(body), &resp); err != nil {
		t.Fatalf("decode body: %v body=%s", err, body)
	}
	return resp.Error
}

func TestRequireBearerJWT_unauthorizedWithoutToken(t *testing.T) {
	e := echov4.New()
	e.Use(authecho.RequireBearerJWT(testVerifier(), authecho.JWTAuthOptions{Enabled: true}))
	e.POST("/graphql", func(c echov4.Context) error { return c.NoContent(http.StatusOK) })

	req := httptest.NewRequest(http.MethodPost, "/graphql", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
	errBody := decodeErrorBody(t, rec.Body.String())
	if errBody.Code != auth.CodeJWTRequired {
		t.Fatalf("code=%q body=%s", errBody.Code, rec.Body.String())
	}
}

func signTokenWithDomain(t *testing.T, domain string, expired bool) string {
	t.Helper()
	exp := time.Now().Add(time.Hour)
	if expired {
		exp = time.Now().Add(-time.Hour)
	}
	claims := struct {
		UserID   int64  `json:"user_id"`
		TenantID int64  `json:"tenant_id"`
		Email    string `json:"email"`
		Name     string `json:"name"`
		Domain   string `json:"domain"`
		jwt.RegisteredClaims
	}{
		UserID: 1, TenantID: 2, Email: "a@b.com", Name: "User", Domain: domain,
		RegisteredClaims: jwt.RegisteredClaims{
			Issuer:    "auth-ba",
			ExpiresAt: jwt.NewNumericDate(exp),
		},
	}
	s, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte(testSecret))
	if err != nil {
		t.Fatal(err)
	}
	return s
}

func TestRequireBearerJWT_expiredToken(t *testing.T) {
	e := echov4.New()
	e.Use(authecho.RequireBearerJWT(testVerifier(), authecho.JWTAuthOptions{Enabled: true}))
	e.POST("/graphql", func(c echov4.Context) error { return c.NoContent(http.StatusOK) })

	req := httptest.NewRequest(http.MethodPost, "/graphql", nil)
	req.Header.Set(echov4.HeaderAuthorization, "Bearer "+signTokenWithDomain(t, "http://127.0.0.1:5175", true))
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
	errBody := decodeErrorBody(t, rec.Body.String())
	if errBody.Code != auth.CodeJWTExpired {
		t.Fatalf("code=%q body=%s", errBody.Code, rec.Body.String())
	}
}

func TestRequireBearerJWT_domainMismatch(t *testing.T) {
	e := echov4.New()
	e.Use(authecho.RequireBearerJWT(testVerifier(), authecho.JWTAuthOptions{Enabled: true}))
	e.POST("/graphql", func(c echov4.Context) error { return c.NoContent(http.StatusOK) })

	req := httptest.NewRequest(http.MethodPost, "/graphql", nil)
	req.Header.Set(echov4.HeaderAuthorization, "Bearer "+signTokenWithDomain(t, "http://127.0.0.1:5173", false))
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
	errBody := decodeErrorBody(t, rec.Body.String())
	if errBody.Code != auth.CodeJWTDomainMismatch {
		t.Fatalf("code=%q body=%s", errBody.Code, rec.Body.String())
	}
	if len(errBody.Details) != 2 {
		t.Fatalf("details=%#v", errBody.Details)
	}
}

func TestRequireBearerJWT_invalidSignature(t *testing.T) {
	e := echov4.New()
	e.Use(authecho.RequireBearerJWT(testVerifier(), authecho.JWTAuthOptions{Enabled: true}))
	e.POST("/graphql", func(c echov4.Context) error { return c.NoContent(http.StatusOK) })

	req := httptest.NewRequest(http.MethodPost, "/graphql", nil)
	req.Header.Set(echov4.HeaderAuthorization, "Bearer "+signToken(t)+"x")
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
	errBody := decodeErrorBody(t, rec.Body.String())
	if errBody.Code != auth.CodeJWTInvalidSignature {
		t.Fatalf("code=%q body=%s", errBody.Code, rec.Body.String())
	}
	if !strings.Contains(errBody.Message, "JWT_SECRET") {
		t.Fatalf("message=%q", errBody.Message)
	}
}

func TestRequireBearerJWT_okWithBearer(t *testing.T) {
	e := echov4.New()
	e.Use(authecho.RequireBearerJWT(testVerifier(), authecho.JWTAuthOptions{Enabled: true}))
	e.POST("/graphql", func(c echov4.Context) error {
		if c.Get(authecho.ContextAuthUserID) == nil {
			return echov4.ErrUnauthorized
		}
		return c.NoContent(http.StatusOK)
	})

	req := httptest.NewRequest(http.MethodPost, "/graphql", nil)
	req.Header.Set(echov4.HeaderAuthorization, "Bearer "+signToken(t))
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
}

func TestRequireBearerJWT_skipsRoot(t *testing.T) {
	e := echov4.New()
	e.Use(authecho.RequireBearerJWT(testVerifier(), authecho.JWTAuthOptions{Enabled: true}))
	e.GET("/", func(c echov4.Context) error { return c.NoContent(http.StatusOK) })

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status=%d", rec.Code)
	}
}

func TestRequireBearerJWT_skipsOptions(t *testing.T) {
	e := echov4.New()
	e.Use(authecho.RequireBearerJWT(testVerifier(), authecho.JWTAuthOptions{Enabled: true}))
	e.OPTIONS("/graphql", func(c echov4.Context) error { return c.NoContent(http.StatusNoContent) })

	req := httptest.NewRequest(http.MethodOptions, "/graphql", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusNoContent {
		t.Fatalf("status=%d", rec.Code)
	}
}

func TestRequireBearerJWT_playgroundGETPublic(t *testing.T) {
	e := echov4.New()
	e.Use(authecho.RequireBearerJWT(testVerifier(), enabledJWTOptions(true)))
	e.GET("/graphql", func(c echov4.Context) error { return c.NoContent(http.StatusOK) })

	req := httptest.NewRequest(http.MethodGet, "/graphql", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
}

func TestRequireBearerJWT_playgroundPOSTProtected(t *testing.T) {
	e := echov4.New()
	e.Use(authecho.RequireBearerJWT(testVerifier(), enabledJWTOptions(true)))
	e.POST("/graphql", func(c echov4.Context) error { return c.NoContent(http.StatusOK) })

	req := httptest.NewRequest(http.MethodPost, "/graphql", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
	errBody := decodeErrorBody(t, rec.Body.String())
	if errBody.Code != auth.CodeJWTRequired {
		t.Fatalf("code=%q body=%s", errBody.Code, rec.Body.String())
	}
}

func TestRequireBearerJWT_playgroundGETProtectedWhenDisabled(t *testing.T) {
	e := echov4.New()
	e.Use(authecho.RequireBearerJWT(testVerifier(), enabledJWTOptions(false)))
	e.GET("/graphql", func(c echov4.Context) error { return c.NoContent(http.StatusOK) })

	req := httptest.NewRequest(http.MethodGet, "/graphql", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusUnauthorized {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
}

func TestRequireBearerJWT_authDisabledAllowsGraphQLWithoutToken(t *testing.T) {
	e := echov4.New()
	e.Use(authecho.RequireBearerJWT(nil, authecho.JWTAuthOptions{Enabled: false}))
	e.POST("/graphql", func(c echov4.Context) error {
		email, _ := c.Get(authecho.ContextAuthEmail).(string)
		if email != "dev@local" {
			t.Fatalf("email=%q", email)
		}
		return c.NoContent(http.StatusOK)
	})

	req := httptest.NewRequest(http.MethodPost, "/graphql", nil)
	rec := httptest.NewRecorder()
	e.ServeHTTP(rec, req)
	if rec.Code != http.StatusOK {
		t.Fatalf("status=%d body=%s", rec.Code, rec.Body.String())
	}
}
