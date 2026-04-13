class ReadingRecord {
  final String id;
  final String bookId; // 关联的书籍 ID
  final DateTime readAt; // 阅读时间
  final int? durationSeconds; // 阅读时长（可选）
  final String? note; // 心得/备注（可选）

  ReadingRecord({
    required this.id,
    required this.bookId,
    required this.readAt,
    this.durationSeconds,
    this.note,
  });

  factory ReadingRecord.fromJson(Map<String, dynamic> json) {
    return ReadingRecord(
      id: json['id'] as String,
      bookId: json['bookId'] as String,
      readAt: DateTime.parse(json['readAt'] as String),
      durationSeconds: json['durationSeconds'] as int?,
      note: json['note'] as String?,
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
