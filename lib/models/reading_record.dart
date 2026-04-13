class ReadingRecord {
  final String id;
  final String bookId; // 关联的书籍 ID
  final DateTime readAt; // 阅读时间
  final int? durationSeconds; // 阅读时长（可选）
  final String? note; // 心得/备注（可选）
  final String? bookTitle;
  final String? bookCoverUrl;

  ReadingRecord({
    required this.id,
    required this.bookId,
    required this.readAt,
    this.durationSeconds,
    this.note,
    this.bookTitle,
    this.bookCoverUrl,
  });

  factory ReadingRecord.fromJson(Map<String, dynamic> json) {
    final rawBook = json['book'];
    final book = rawBook is Map<String, dynamic> ? rawBook : null;
    return ReadingRecord(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      readAt: DateTime.parse(json['readAt'] as String),
      durationSeconds: json['durationSeconds'] as int?,
      note: json['note'] as String?,
      bookTitle: book?['title']?.toString(),
      bookCoverUrl: book?['coverUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookId': bookId,
      'readAt': readAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'note': note,
    };
  }
}
