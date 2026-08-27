use serde::Deserialize;

/// Response shape for a successful upload - same fields as the
/// JS/Python/PHP/Go SDKs' upload result.
#[derive(Debug, Clone, Deserialize)]
pub struct UploadResult {
    pub id: String,
    #[serde(rename = "type")]
    pub kind: String,
    pub path: String,
    pub src: String,
    pub direct: String,
    pub expires_at: Option<String>,
}

/// One row of a `list()` result.
#[derive(Debug, Clone, Deserialize)]
pub struct ListedUpload {
    pub id: String,
    #[serde(rename = "type")]
    pub kind: String,
    pub title: Option<String>,
    pub path: String,
    pub src: String,
    pub direct: String,
    pub expires_at: Option<String>,
    pub created_at: String,
}

/// Pagination info for a `list()` result.
#[derive(Debug, Clone, Deserialize)]
pub struct ListMeta {
    pub current_page: u32,
    pub last_page: u32,
    pub total: u32,
}

/// Response shape for `list()`.
#[derive(Debug, Clone, Deserialize)]
pub struct ListResult {
    pub data: Vec<ListedUpload>,
    pub meta: ListMeta,
}

/// The raw `{"type": "success"|"error", ...}` wrapper every endpoint
/// returns.
#[derive(Debug, Deserialize)]
pub(crate) struct ApiEnvelope {
    #[serde(rename = "type")]
    pub kind: String,
    #[serde(default)]
    pub errors: String,
}
