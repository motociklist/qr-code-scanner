class SavedQRCode {
  final String id;
  final String title;
  final String content;
  final String type; // URL, TEXT, WIFI, CONTACT
  final DateTime createdAt;
  final int viewCount;

  SavedQRCode({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    this.viewCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'viewCount': viewCount,
    };
  }

  factory SavedQRCode.fromJson(Map<String, dynamic> json) {
    return SavedQRCode(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: json['type'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      viewCount: json['viewCount'] as int? ?? 0,
    );
  }

  SavedQRCode copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    DateTime? createdAt,
    int? viewCount,
  }) {
    return SavedQRCode(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      viewCount: viewCount ?? this.viewCount,
    );
  }
}

