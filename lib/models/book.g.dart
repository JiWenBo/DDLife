// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Book _$BookFromJson(Map<String, dynamic> json) => Book(
      id: json['id'] as String,
      isbn: json['isbn'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      coverUrl: json['coverUrl'] as String?,
      category: json['category'] as String?,
      seriesName: json['seriesName'] as String?,
      volumeNumber: (json['volumeNumber'] as num?)?.toInt(),
      edition: json['edition'] as String?,
      audioPath: json['audioPath'] as String?,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      readCount: (json['readCount'] as num?)?.toInt() ?? 0,
      lastReadAt: json['lastReadAt'] == null
          ? null
          : DateTime.parse(json['lastReadAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'id': instance.id,
      'isbn': instance.isbn,
      'title': instance.title,
      'author': instance.author,
      'coverUrl': instance.coverUrl,
      'category': instance.category,
      'seriesName': instance.seriesName,
      'volumeNumber': instance.volumeNumber,
      'edition': instance.edition,
      'audioPath': instance.audioPath,
      'tags': instance.tags,
      'readCount': instance.readCount,
      'lastReadAt': instance.lastReadAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
