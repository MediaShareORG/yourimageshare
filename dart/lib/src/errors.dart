/// Thrown for any non-2xx response or a `{"type": "error"}` payload from the
/// YourImageShare API - mirrors the JS/Python/PHP/Go/Rust/Ruby SDKs' error
/// type exactly (same status/message shape) so error-handling logic reads
/// the same across every official SDK.
class YourImageShareException implements Exception {
  /// The HTTP status code, or `0` for a transport-level failure (no
  /// response was ever received, e.g. a DNS/connection error).
  final int status;

  /// The server's error text (or a generated message for transport
  /// failures / unexpected non-JSON responses).
  final String message;

  YourImageShareException(this.status, this.message);

  @override
  String toString() => 'yourimageshare: [$status] $message';
}
