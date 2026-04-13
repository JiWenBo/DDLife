import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddbook/models/book.dart';
import 'package:ddbook/core/services/api_service.dart';

final bookRepositoryProvider = Provider((ref) => BookRepository(ref.watch(apiServiceProvider)));

class BookRepository {
  final ApiService _apiService;

  BookRepository(this._apiService);

  Future<List<Book>> getAllBooks() async {
    final response = await _apiService.get('/v1/books');
    final items = (response['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_fromApi)
        .toList();
    return List.unmodifiable(items);
  }

  Future<void> addBook(Book book) async {
    await _apiService.post(
      '/v1/books',
      body: {
        'isbn': book.isbn,
        'title': book.title,
        'author': book.author,
        'coverUrl': book.coverUrl,
        'category': book.category,
        'seriesName': book.seriesName,
        'volumeNumber': book.volumeNumber,
        'edition': book.edition,
        'audioUrl': book.audioPath,
        'tags': book.tags,
      },
    );
  }

  Future<void> deleteBook(String id) async {
    await _apiService.delete('/v1/books/$id');
  }

  Future<Book?> getBookByIsbn(String isbn) async {
    final books = await getBooksByIsbn(isbn);
    if (books.isEmpty) return null;
    return books.first;
  }

  Future<List<Book>> getBooksByIsbn(String isbn) async {
    if (isbn.isEmpty) return [];
    final response = await _apiService.get('/v1/books', queryParameters: {'isbn': isbn});
    return (response['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(_fromApi)
        .toList();
  }

  Future<String> exportDataFilePath() async {
    return _apiService.baseUrl;
  }

  Book _fromApi(Map<String, dynamic> json) {
    return Book(
      id: (json['id'] ?? '').toString(),
      isbn: (json['isbn'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      author: json['author']?.toString(),
      coverUrl: json['coverUrl']?.toString(),
      category: json['category']?.toString(),
      seriesName: json['seriesName']?.toString(),
      volumeNumber: json['volumeNumber'] is int ? json['volumeNumber'] as int : null,
      edition: json['edition']?.toString(),
      audioPath: json['audioUrl']?.toString(),
      tags: (json['tags'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      readCount: json['readCount'] is int ? json['readCount'] as int : 0,
      lastReadAt: json['lastReadAt'] != null ? DateTime.tryParse(json['lastReadAt'].toString()) : null,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
