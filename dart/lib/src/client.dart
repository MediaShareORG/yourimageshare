import 'dart:convert';

import 'package:http/http.dart' as http;

import 'errors.dart';
import 'types.dart';

const _defaultBaseUrl = 'https://yourimageshare.com/api';
const _sdkVersion = '1.0.0';

/// Official Dart/Flutter client for the YourImageShare upload API
/// (https://yourimageshare.com/about/api). Mirrors the existing JS, Python,
/// PHP, Go, Rust, and Ruby SDKs - same method names, same result shapes,
/// same error type - just idiomatic Dart on top (throws
/// [YourImageShareException] instead of returning an error value).
class YourImageShareClient {
  final String _apiKey;
  final String _baseUrl;
  final http.Client _httpClient;

  /// [apiKey] is required - get one from the API tab at
  /// https://yourimageshare.com/my-account. [baseUrl] overrides the API
  /// base URL (mainly for testing). [httpClient] overrides the underlying
  /// `http.Client`, e.g. to inject a custom timeout or a mock for tests.
  YourImageShareClient(
    String apiKey, {
    String baseUrl = _defaultBaseUrl,
    http.Client? httpClient,
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl,
        _httpClient = httpClient ?? http.Client() {
    if (_apiKey.isEmpty) {
      throw ArgumentError('yourimageshare: apiKey is required');
    }
  }

  /// Uploads a local file by path. Streams from disk via
  /// `http.MultipartFile.fromPath` - doesn't buffer the whole file in
  /// memory first. [expiresIn] auto-deletes the upload after this many
  /// seconds (60 to 2,592,000 = 30 days); omit for a permanent upload.
  Future<UploadResult> upload(String filePath, {int? expiresIn}) async {
    final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
    request.files.add(await http.MultipartFile.fromPath('uploads', filePath));
    if (expiresIn != null && expiresIn > 0) {
      request.fields['expires_in'] = expiresIn.toString();
    }
    return _sendUpload(request);
  }

  /// Uploads from raw bytes - useful when the data isn't already a file on
  /// disk (e.g. a network response, an in-memory buffer). [filename]
  /// should include a real extension so the server can infer the content
  /// type correctly.
  Future<UploadResult> uploadBytes(
    List<int> bytes,
    String filename, {
    int? expiresIn,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(_baseUrl));
    request.files.add(
      http.MultipartFile.fromBytes('uploads', bytes, filename: filename),
    );
    if (expiresIn != null && expiresIn > 0) {
      request.fields['expires_in'] = expiresIn.toString();
    }
    return _sendUpload(request);
  }

  Future<UploadResult> _sendUpload(http.MultipartRequest request) async {
    _setCommonHeaders(request);
    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    final raw = _decodeOrThrow(response);
    return UploadResult.fromJson(raw['data'] as Map<String, dynamic>);
  }

  /// Returns your uploads, newest first, 50 per page. [page] < 2 fetches
  /// the first page.
  Future<ListResult> list({int page = 1}) async {
    var uri = Uri.parse(_baseUrl);
    if (page > 1) {
      uri = uri.replace(queryParameters: {'page': page.toString()});
    }
    final request = http.Request('GET', uri);
    _setCommonHeaders(request);
    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    final raw = _decodeOrThrow(response);
    return ListResult.fromJson(raw);
  }

  /// Removes one of your uploads by id. Throws a
  /// [YourImageShareException] on a 404/401.
  Future<void> delete(String id) async {
    final uri = Uri.parse('$_baseUrl/${Uri.encodeComponent(id)}');
    final request = http.Request('DELETE', uri);
    _setCommonHeaders(request);
    final streamed = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamed);
    _decodeOrThrow(response);
  }

  void _setCommonHeaders(http.BaseRequest request) {
    request.headers['X-API-Key'] = _apiKey;
    request.headers['User-Agent'] = 'yourimageshare-dart/$_sdkVersion';
  }

  /// Decodes the `{"type": "success"|"error", ...}` envelope, throwing
  /// [YourImageShareException] for any non-2xx response or a
  /// `type == "error"` payload - mirrors the Go SDK's `do()`.
  Map<String, dynamic> _decodeOrThrow(http.Response response) {
    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw YourImageShareException(
        response.statusCode,
        'unexpected non-JSON response (HTTP ${response.statusCode})',
      );
    }

    final isError = response.statusCode < 200 ||
        response.statusCode >= 300 ||
        envelope['type'] == 'error';
    if (isError) {
      final errors = envelope['errors'] as String?;
      final message = (errors == null || errors.isEmpty)
          ? 'request failed (HTTP ${response.statusCode})'
          : errors;
      throw YourImageShareException(response.statusCode, message);
    }

    return envelope;
  }
}
