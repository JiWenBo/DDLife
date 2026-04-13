
import 'package:json_annotation/json_annotation.dart';

part 'book.g.dart';

@JsonSerializable()
class Book {
  final String id;
  final String isbn;
  final String title;
  
  // 作者暂时保留字段，但不强制使用
  final String? author;
  
  // 封面暂时保留字段，不强制使用
  final String? coverUrl;
  
  final String? category;
  
  // 录入的详细字段
  final String? seriesName;
  final int? volumeNumber;
  final String? edition;
  final String? audioPath;
  
  // 标签
  final List<String> tags;
  
  // 核心阅读数据
  final int readCount;
  final DateTime? lastReadAt;
  final DateTime createdAt;

  Book({
    required this.id,
    required this.isbn,
    required this.title,
    this.author,
    this.coverUrl,
    this.category,
    this.seriesName,
    this.volumeNumber,
    this.edition,
    this.audioPath,
    this.tags = const [],
    this.readCount = 0,
    this.lastReadAt,
    required this.createdAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
  Map<String, dynamic> toJson() => _$BookToJson(this);

  Book copyWith({
    String? id,
    String? isbn,
    String? title,
    String? author,
    String? coverUrl,
    String? category,
    String? seriesName,
    int? volumeNumber,
    String? edition,
    String? audioPath,
    List<String>? tags,
    int? readCount,
    DateTime? lastReadAt,
    DateTime? createdAt,
  }) {
    return Book(
      id: id ?? this.id,
      isbn: isbn ?? this.isbn,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      category: category ?? this.category,
      seriesName: seriesName ?? this.seriesName,
      volumeNumber: volumeNumber ?? this.volumeNumber,
      edition: edition ?? this.edition,
      audioPath: audioPath ?? this.audioPath,
      tags: tags ?? this.tags,
      readCount: readCount ?? this.readCount,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
