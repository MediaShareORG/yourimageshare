// Package yourimageshare is the official Go client for the YourImageShare
// upload API (https://yourimageshare.com/about/api). It mirrors the
// existing JS (npm), Python (PyPI), and PHP (Packagist) SDKs - same
// method names, same result shapes, same error type - just idiomatic Go
// on top (methods return (result, error), not exceptions).
//
// Zero third-party dependencies - only the standard library.
package yourimageshare

import (
	"encoding/json"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"
	"net/url"
	"os"
	"path/filepath"
	"strconv"
	"time"
)

// DefaultBaseURL is used when no WithBaseURL option is given.
const DefaultBaseURL = "https://yourimageshare.com/api"

const sdkVersion = "1.0.0"

// Client talks to the YourImageShare upload API. Create one with
// NewClient; a Client is safe for concurrent use by multiple goroutines
// (it holds no mutable state after construction).
type Client struct {
	apiKey     string
	baseURL    string
	httpClient *http.Client
}

// Option configures a Client. See WithBaseURL and WithHTTPClient.
type Option func(*Client)

// WithBaseURL overrides the API base URL - mainly for testing against a
// different environment. Defaults to DefaultBaseURL.
func WithBaseURL(baseURL string) Option {
	return func(c *Client) {
		c.baseURL = baseURL
	}
}

// WithHTTPClient overrides the *http.Client used for requests, e.g. to set
// a custom timeout or transport. Defaults to a client with a 30s timeout.
func WithHTTPClient(httpClient *http.Client) Option {
	return func(c *Client) {
		c.httpClient = httpClient
	}
}

// NewClient creates a Client. apiKey is required - get one from the API
// tab at https://yourimageshare.com/my-account.
func NewClient(apiKey string, opts ...Option) (*Client, error) {
	if apiKey == "" {
		return nil, fmt.Errorf("yourimageshare: apiKey is required")
	}

	c := &Client{
		apiKey:     apiKey,
		baseURL:    DefaultBaseURL,
		httpClient: &http.Client{Timeout: 30 * time.Second},
	}
	for _, opt := range opts {
		opt(c)
	}
	return c, nil
}

// UploadOptions are the optional parameters for Upload/UploadReader.
type UploadOptions struct {
	// ExpiresIn auto-deletes the upload after this many seconds (60 to
	// 2,592,000 = 30 days). Zero means a permanent upload.
	ExpiresIn int
}

// Upload uploads a local file by path.
func (c *Client) Upload(filePath string, opts *UploadOptions) (*UploadResult, error) {
	f, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("yourimageshare: %w", err)
	}
	defer f.Close()

	return c.UploadReader(f, filepath.Base(filePath), opts)
}

// UploadReader uploads from any io.Reader (an open file, a network stream,
// an in-memory buffer) - useful when the data isn't already a file on
// disk. filename should include a real extension so the server can infer
// the content type correctly.
func (c *Client) UploadReader(r io.Reader, filename string, opts *UploadOptions) (*UploadResult, error) {
	if opts == nil {
		opts = &UploadOptions{}
	}

	// Streams the multipart body via io.Pipe instead of buffering the
	// whole file in memory first - uploads can be up to 200MB (video), and
	// loading that wholesale would be wasteful for a library meant to be
	// used in resource-constrained places too.
	pr, pw := io.Pipe()
	mw := multipart.NewWriter(pw)

	go func() {
		defer pw.Close()
		defer mw.Close()

		part, err := mw.CreateFormFile("uploads", filename)
		if err != nil {
			pw.CloseWithError(err)
			return
		}
		if _, err := io.Copy(part, r); err != nil {
			pw.CloseWithError(err)
			return
		}
		if opts.ExpiresIn > 0 {
			if err := mw.WriteField("expires_in", strconv.Itoa(opts.ExpiresIn)); err != nil {
				pw.CloseWithError(err)
				return
			}
		}
	}()

	req, err := http.NewRequest(http.MethodPost, c.baseURL, pr)
	if err != nil {
		return nil, fmt.Errorf("yourimageshare: %w", err)
	}
	req.Header.Set("Content-Type", mw.FormDataContentType())
	c.setCommonHeaders(req)

	var body struct {
		Data UploadResult `json:"data"`
	}
	if err := c.do(req, &body); err != nil {
		return nil, err
	}
	return &body.Data, nil
}

// List returns your uploads, newest first, 50 per page. page < 2 fetches
// the first page.
func (c *Client) List(page int) (*ListResult, error) {
	u := c.baseURL
	if page > 1 {
		u += "?" + url.Values{"page": {strconv.Itoa(page)}}.Encode()
	}

	req, err := http.NewRequest(http.MethodGet, u, nil)
	if err != nil {
		return nil, fmt.Errorf("yourimageshare: %w", err)
	}
	c.setCommonHeaders(req)

	var result ListResult
	if err := c.do(req, &result); err != nil {
		return nil, err
	}
	return &result, nil
}

// Delete removes one of your uploads by id. Returns an *APIError on a
// 404/401.
func (c *Client) Delete(id string) error {
	req, err := http.NewRequest(http.MethodDelete, c.baseURL+"/"+url.PathEscape(id), nil)
	if err != nil {
		return fmt.Errorf("yourimageshare: %w", err)
	}
	c.setCommonHeaders(req)

	return c.do(req, nil)
}

func (c *Client) setCommonHeaders(req *http.Request) {
	req.Header.Set("X-API-Key", c.apiKey)
	req.Header.Set("User-Agent", "yourimageshare-go/"+sdkVersion)
}

// do executes req, decodes a successful JSON body into out (if non-nil),
// and returns *APIError for any non-2xx response or a `{"type":"error"}`
// payload.
func (c *Client) do(req *http.Request, out interface{}) error {
	resp, err := c.httpClient.Do(req)
	if err != nil {
		return fmt.Errorf("yourimageshare: request failed: %w", err)
	}
	defer resp.Body.Close()

	raw, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("yourimageshare: reading response: %w", err)
	}

	var envelope apiEnvelope
	if jsonErr := json.Unmarshal(raw, &envelope); jsonErr != nil {
		return &APIError{Status: resp.StatusCode, Message: fmt.Sprintf("unexpected non-JSON response (HTTP %d)", resp.StatusCode)}
	}

	if resp.StatusCode < 200 || resp.StatusCode >= 300 || envelope.Type == "error" {
		message := envelope.Errors
		if message == "" {
			message = fmt.Sprintf("request failed (HTTP %d)", resp.StatusCode)
		}
		return &APIError{Status: resp.StatusCode, Message: message}
	}

	if out != nil {
		if err := json.Unmarshal(raw, out); err != nil {
			return fmt.Errorf("yourimageshare: decoding response: %w", err)
		}
	}
	return nil
}
