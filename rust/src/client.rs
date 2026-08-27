use crate::error::ApiError;
use crate::types::{ApiEnvelope, ListResult, UploadResult};
use serde::de::DeserializeOwned;
use serde::Deserialize;
use std::fs::File;
use std::io::{Cursor, Read};
use std::path::Path;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

/// Used when no [`Client::with_base_url`] override is given.
pub const DEFAULT_BASE_URL: &str = "https://yourimageshare.com/api";

const SDK_VERSION: &str = "1.0.0";

/// Talks to the YourImageShare upload API. Build one with [`Client::new`].
#[derive(Debug, Clone)]
pub struct Client {
    api_key: String,
    base_url: String,
    timeout: Duration,
}

/// Optional parameters for [`Client::upload`]/[`Client::upload_reader`].
#[derive(Debug, Clone, Copy, Default)]
pub struct UploadOptions {
    /// Auto-deletes the upload after this many seconds (60 to 2,592,000 =
    /// 30 days). `None` or `Some(0)` means a permanent upload.
    pub expires_in: Option<u32>,
}

impl Client {
    /// Creates a client. `api_key` - get one from the API tab at
    /// <https://yourimageshare.com/my-account>.
    pub fn new(api_key: impl Into<String>) -> Self {
        Self {
            api_key: api_key.into(),
            base_url: DEFAULT_BASE_URL.to_string(),
            timeout: Duration::from_secs(30),
        }
    }

    /// Overrides the API base URL - mainly for testing against a
    /// different environment.
    pub fn with_base_url(mut self, base_url: impl Into<String>) -> Self {
        self.base_url = base_url.into();
        self
    }

    /// Overrides the per-request timeout. Defaults to 30s.
    pub fn with_timeout(mut self, timeout: Duration) -> Self {
        self.timeout = timeout;
        self
    }

    /// Uploads a local file by path. Streams it from disk - does not
    /// buffer the whole file in memory first.
    pub fn upload(
        &self,
        file_path: impl AsRef<Path>,
        opts: Option<UploadOptions>,
    ) -> Result<UploadResult, ApiError> {
        let file_path = file_path.as_ref();
        let file = File::open(file_path).map_err(|e| ApiError {
            status: 0,
            message: format!("opening file: {e}"),
        })?;
        let filename = file_path
            .file_name()
            .map(|n| n.to_string_lossy().into_owned())
            .unwrap_or_else(|| "upload".to_string());
        self.upload_reader(file, &filename, opts)
    }

    /// Uploads from any [`Read`] (an open file, a network stream, an
    /// in-memory buffer) - useful when the data isn't already a file on
    /// disk. `filename` should include a real extension so the server can
    /// infer the content type correctly.
    pub fn upload_reader<R: Read>(
        &self,
        reader: R,
        filename: &str,
        opts: Option<UploadOptions>,
    ) -> Result<UploadResult, ApiError> {
        let opts = opts.unwrap_or_default();
        let boundary = make_boundary();

        let mut preamble = Vec::new();
        preamble.extend_from_slice(format!("--{boundary}\r\n").as_bytes());
        preamble.extend_from_slice(
            format!(
                "Content-Disposition: form-data; name=\"uploads\"; filename=\"{}\"\r\n",
                escape_filename(filename)
            )
            .as_bytes(),
        );
        preamble.extend_from_slice(b"Content-Type: application/octet-stream\r\n\r\n");

        let mut epilogue = Vec::new();
        epilogue.extend_from_slice(b"\r\n");
        if let Some(expires_in) = opts.expires_in.filter(|&v| v > 0) {
            epilogue.extend_from_slice(format!("--{boundary}\r\n").as_bytes());
            epilogue
                .extend_from_slice(b"Content-Disposition: form-data; name=\"expires_in\"\r\n\r\n");
            epilogue.extend_from_slice(expires_in.to_string().as_bytes());
            epilogue.extend_from_slice(b"\r\n");
        }
        epilogue.extend_from_slice(format!("--{boundary}--\r\n").as_bytes());

        // Chains the multipart preamble, the caller's reader, and the
        // epilogue into a single streaming body - never buffers the
        // uploaded content itself into memory (uploads can be up to
        // 200MB for video).
        let body = Cursor::new(preamble)
            .chain(reader)
            .chain(Cursor::new(epilogue));

        let result = ureq::post(&self.base_url)
            .set("X-API-Key", &self.api_key)
            .set("User-Agent", &format!("yourimageshare-rust/{SDK_VERSION}"))
            .set(
                "Content-Type",
                &format!("multipart/form-data; boundary={boundary}"),
            )
            .timeout(self.timeout)
            .send(body);

        #[derive(Deserialize)]
        struct UploadEnvelope {
            data: UploadResult,
        }

        call::<UploadEnvelope>(result).map(|e| e.data)
    }

    /// Returns your uploads, newest first, 50 per page. `page` of `None`
    /// or `Some(n)` with `n < 2` fetches the first page.
    pub fn list(&self, page: Option<u32>) -> Result<ListResult, ApiError> {
        let mut request = ureq::get(&self.base_url)
            .set("X-API-Key", &self.api_key)
            .set("User-Agent", &format!("yourimageshare-rust/{SDK_VERSION}"))
            .timeout(self.timeout);
        if let Some(page) = page.filter(|&p| p > 1) {
            request = request.query("page", &page.to_string());
        }

        call::<ListResult>(request.call())
    }

    /// Removes one of your uploads by id. Returns an [`ApiError`] on a
    /// 404/401.
    pub fn delete(&self, id: &str) -> Result<(), ApiError> {
        let url = format!("{}/{}", self.base_url, urlencode(id));
        let result = ureq::delete(&url)
            .set("X-API-Key", &self.api_key)
            .set("User-Agent", &format!("yourimageshare-rust/{SDK_VERSION}"))
            .timeout(self.timeout)
            .call();

        #[derive(Deserialize)]
        struct Empty {}

        call::<Empty>(result).map(|_| ())
    }
}

fn make_boundary() -> String {
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_nanos())
        .unwrap_or(0);
    format!("----yourimageshareRustBoundary{nanos:x}")
}

fn escape_filename(filename: &str) -> String {
    filename.replace('\\', "\\\\").replace('"', "\\\"")
}

fn urlencode(s: &str) -> String {
    let mut out = String::with_capacity(s.len());
    for b in s.bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                out.push(b as char)
            }
            _ => out.push_str(&format!("%{b:02X}")),
        }
    }
    out
}

/// Executes a ureq result, decodes a successful JSON body into `T`, and
/// returns an [`ApiError`] for any non-2xx response, a
/// `{"type":"error"}` payload, or a transport/IO failure (status `0` in
/// that last case - there is no HTTP status to report).
fn call<T: DeserializeOwned>(result: Result<ureq::Response, ureq::Error>) -> Result<T, ApiError> {
    let (status, body) = match result {
        Ok(resp) => {
            let status = resp.status();
            let body = resp.into_string().map_err(|e| ApiError {
                status: 0,
                message: format!("reading response: {e}"),
            })?;
            (status, body)
        }
        Err(ureq::Error::Status(status, resp)) => (status, resp.into_string().unwrap_or_default()),
        Err(ureq::Error::Transport(t)) => {
            return Err(ApiError {
                status: 0,
                message: format!("request failed: {t}"),
            })
        }
    };

    let envelope: ApiEnvelope = serde_json::from_str(&body).map_err(|_| ApiError {
        status,
        message: format!("unexpected non-JSON response (HTTP {status})"),
    })?;

    if !(200..300).contains(&status) || envelope.kind == "error" {
        let message = if envelope.errors.is_empty() {
            format!("request failed (HTTP {status})")
        } else {
            envelope.errors
        };
        return Err(ApiError { status, message });
    }

    serde_json::from_str(&body).map_err(|e| ApiError {
        status,
        message: format!("decoding response: {e}"),
    })
}
