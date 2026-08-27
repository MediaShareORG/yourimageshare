package yourimageshare

import "fmt"

// APIError is returned for any non-2xx response or a `{"type":"error"}`
// payload - mirrors the JS/Python/PHP SDKs' error type exactly (same
// Status/Message shape) so error-handling logic reads the same across
// every official SDK.
type APIError struct {
	Status  int
	Message string
}

func (e *APIError) Error() string {
	return fmt.Sprintf("yourimageshare: [%d] %s", e.Status, e.Message)
}
