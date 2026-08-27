use std::fmt;

/// Returned for any non-2xx response or a `{"type":"error"}` payload -
/// mirrors the JS/Python/PHP/Go SDKs' error type (same status/message
/// shape) so error-handling logic reads the same across every official
/// SDK.
#[derive(Debug, Clone)]
pub struct ApiError {
    pub status: u16,
    pub message: String,
}

impl fmt::Display for ApiError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "yourimageshare: [{}] {}", self.status, self.message)
    }
}

impl std::error::Error for ApiError {}
