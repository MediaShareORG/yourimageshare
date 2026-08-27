package yourimageshare

// UploadResult is the response shape for a successful upload - same
// fields as the JS/Python/PHP SDKs' UploadResult.
type UploadResult struct {
	ID        string  `json:"id"`
	Type      string  `json:"type"`
	Path      string  `json:"path"`
	Src       string  `json:"src"`
	Direct    string  `json:"direct"`
	ExpiresAt *string `json:"expires_at"`
}

// ListedUpload is one row of a List() result.
type ListedUpload struct {
	ID        string  `json:"id"`
	Type      string  `json:"type"`
	Title     *string `json:"title"`
	Path      string  `json:"path"`
	Src       string  `json:"src"`
	Direct    string  `json:"direct"`
	ExpiresAt *string `json:"expires_at"`
	CreatedAt string  `json:"created_at"`
}

// ListMeta carries the pagination info for a List() result.
type ListMeta struct {
	CurrentPage int `json:"current_page"`
	LastPage    int `json:"last_page"`
	Total       int `json:"total"`
}

// ListResult is the response shape for List().
type ListResult struct {
	Data []ListedUpload `json:"data"`
	Meta ListMeta       `json:"meta"`
}

// apiEnvelope is the raw `{"type": "success"|"error", ...}` wrapper every
// endpoint returns - unexported, callers only ever see the typed results
// above or an *APIError.
type apiEnvelope struct {
	Type   string `json:"type"`
	Errors string `json:"errors"`
}
