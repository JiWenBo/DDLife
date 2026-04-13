import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ddbook/models/book.dart';
import 'package:ddbook/core/services/storage_service.dart';

final bookRepositoryProvider = Provider((ref) => BookRepository(ref.watch(storageServiceProvider)));

class BookRepository {
  final StorageService _storageService;
  List<Book> _books = [];
  bool _isLoaded = false;

  BookRepository(this._storageService);

  Future<void> _ensureLoaded() async {
    if (!_isLoaded) {
      _books = await _storageService.loadBooks();
      _isLoaded = true;
    }
  }

  Future<List<Book>> getAllBooks() async {
    await _ensureLoaded();
    return List.unmodifiable(_books);
  }

  Future<void> addBook(Book book) async {
    await _ensureLoaded();
    // 使用 ID 检查是否已存在（而不是 ISBN，因为不同册可能共享相同 ISBN）
    final index = _books.indexWhere((b) => b.id == book.id);
    if (index != -1) {
      _books[index] = book; // 更新
    } else {
      _books.add(book);
    }
    await _storageService.saveBooks(_books);
  }

  Future<void> deleteBook(String id) async {
    await _ensureLoaded();
    _books.removeWhere((b) => b.id == id);
    await _storageService.saveBooks(_books);
  }
  
  Future<Book?> getBookByIsbn(String isbn) async {
    await _ensureLoaded();
    try {
      return _books.firstWhere((b) => b.isbn == isbn && isbn.isNotEmpty);
    } catch (e) {
      return null;
    }
  }

  // 获取所有具有相同 ISBN 的书籍（处理同ISBN不同书名的情况）
  Future<List<Book>> getBooksByIsbn(String isbn) async {
    await _ensureLoaded();
    if (isbn.isEmpty) return [];
    return _books.where((b) => b.isbn == isbn).toList();
  }

  // 导出所有数据的文件路径
  Future<String> exportDataFilePath() async {
    // 确保数据已保存到本地
    await _ensureLoaded();
    return await _storageService.getExportFilePath();
  }
}
