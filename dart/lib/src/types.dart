/// The response shape for a successful upload - same fields as the
/// JS/Python/PHP/Go/Rust/Ruby SDKs' upload result.
class UploadResult {
  final String id;
  final String type;
  final String path;
  final String src;
  final String direct;
  final String? expiresAt;

  UploadResult({
    required this.id,
    required this.type,
    required this.path,
    required this.src,
    required this.direct,
    this.expiresAt,
  });

  factory UploadResult.fromJson(Map<String, dynamic> json) => UploadResult(
        id: json['id'] as String,
        type: json['type'] as String,
        path: json['path'] as String,
        src: json['src'] as String,
        direct: json['direct'] as String,
        expiresAt: json['expires_at'] as String?,
      );
}

/// One row of a [YourImageShareClient.list] result.
class ListedUpload {
  final String id;
  final String type;
  final String? title;
  final String path;
  final String src;
  final String direct;
  final String? expiresAt;
  final String createdAt;

  ListedUpload({
    required this.id,
    required this.type,
    this.title,
    required this.path,
    required this.src,
    required this.direct,
    this.expiresAt,
    required this.createdAt,
  });

  factory ListedUpload.fromJson(Map<String, dynamic> json) => ListedUpload(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String?,
        path: json['path'] as String,
        src: json['src'] as String,
        direct: json['direct'] as String,
        expiresAt: json['expires_at'] as String?,
        createdAt: json['created_at'] as String,
      );
}

/// Pagination info for a [YourImageShareClient.list] result.
class ListMeta {
  final int currentPage;
  final int lastPage;
  final int total;

  ListMeta({
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory ListMeta.fromJson(Map<String, dynamic> json) => ListMeta(
        currentPage: json['current_page'] as int,
        lastPage: json['last_page'] as int,
        total: json['total'] as int,
      );
}

/// The response shape for [YourImageShareClient.list].
class ListResult {
  final List<ListedUpload> data;
  final ListMeta meta;

  ListResult({required this.data, required this.meta});

  factory ListResult.fromJson(Map<String, dynamic> json) => ListResult(
        data: (json['data'] as List)
            .map((e) => ListedUpload.fromJson(e as Map<String, dynamic>))
            .toList(),
        meta: ListMeta.fromJson(json['meta'] as Map<String, dynamic>),
      );
}
