package newrelic

// ErrDisabled is returned when NEW_RELIC_LICENSE_KEY is unset (no HTTP request is made).
type ErrDisabled struct{}

func (ErrDisabled) Error() string { return "new relic logs disabled (no license key)" }
