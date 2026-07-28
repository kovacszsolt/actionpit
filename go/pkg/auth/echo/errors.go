package echo

// ErrorDetail is one field-level diagnostic in a 401 response.
type ErrorDetail struct {
	Field   string `json:"field,omitempty"`
	Message string `json:"message"`
}

// ErrorBody is the nested error object in API error responses.
type ErrorBody struct {
	Code    string        `json:"code"`
	Message string        `json:"message"`
	Details []ErrorDetail `json:"details"`
}

// ErrorResponse is the standard JSON shape for auth failures.
type ErrorResponse struct {
	Error ErrorBody `json:"error"`
}
