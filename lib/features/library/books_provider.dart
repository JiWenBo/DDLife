import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/book.dart';
import '../../models/reading_record.dart';
import '../../core/repositories/book_repository.dart';
import '../../core/repositories/reading_repository.dart';

final booksProvider = StateNotifierProvider<BooksNotifier, AsyncValue<List<Book>>>((ref) {
  final bookRepository = ref.watch(bookRepositoryProvider);
  final readingRepository = ref.watch(readingRepositoryProvider);
  return BooksNotifier(bookRepository, readingRepository);
});

class BooksNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final BookRepository _bookRepository;
  final ReadingRepository _readingRepository;

  BooksNotifier(this._bookRepository, this._readingRepository) : super(const AsyncValue.loading()) {
    loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      final books = await _bookRepository.getAllBooks();
      // 创建可变副本并按录入时间倒序排列
      final sortedBooks = books.toList();
      sortedBooks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(sortedBooks);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addBook(Book book) async {
    try {
      await _bookRepository.addBook(book);
      // 重新加载以保持排序和一致性
      await loadBooks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteBook(String id) async {
    try {
      await _bookRepository.deleteBook(id);
      await loadBooks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // 记录阅读
  Future<void> recordReading(Book book) async {
    try {
      // 1. 更新书籍本身的统计信息（用于快速展示）
      final updatedBook = book.copyWith(
        readCount: book.readCount + 1,
        lastReadAt: DateTime.now(),
      );
      await _bookRepository.addBook(updatedBook);
      
      // 2. 添加详细的阅读记录（用于热力图和历史回溯）
      final record = ReadingRecord(
        id: '${DateTime.now().millisecondsSinceEpoch}_${book.id}',
        bookId: book.id,
        readAt: DateTime.now(),
      );
      await _readingRepository.addRecord(record);

      await loadBooks();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // 根据 ISBN 查找书籍
  Future<Book?> findBookByIsbn(String isbn) async {
    try {
      return await _bookRepository.getBookByIsbn(isbn);
    } catch (e) {
      return null;
    }
  }

  // 根据 ISBN 查找所有匹配的书籍
  Future<List<Book>> findBooksByIsbn(String isbn) async {
    try {
      return await _bookRepository.getBooksByIsbn(isbn);
    } catch (e) {
      return [];
    }
  }

  // 根据标题模糊查找书籍
  Future<List<Book>> findBooksByTitle(String title) async {
    try {
      final books = await _bookRepository.getAllBooks();
      final query = title.toLowerCase();
      return books.where((b) {
        return b.title.toLowerCase().contains(query) || 
               (b.seriesName?.toLowerCase().contains(query) ?? false) ||
               (b.author?.toLowerCase().contains(query) ?? false);
      }).toList();
    } catch (e) {
      return [];
    }
  }
  
  // 搜索书籍
  void searchBooks(String query) async {
    if (query.isEmpty) {
      await loadBooks();
      return;
    }
    
    final books = await _bookRepository.getAllBooks();
    final filtered = books.where((book) {
      return book.title.contains(query) || 
             book.isbn.contains(query) || 
             (book.seriesName?.contains(query) ?? false) ||
             (book.tags.any((tag) => tag.contains(query)));
    }).toList();
    
    // 依然按时间倒序
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = AsyncValue.data(filtered);
  }
  
  // 根据分类或状态筛选
  void filterBy(String criterion) async {
    if (criterion == '全部') {
      await loadBooks();
      return;
    }
    
    final books = await _bookRepository.getAllBooks();
    List<Book> filtered;
    
    if (criterion == '未读') {
      filtered = books.where((book) => book.readCount == 0).toList();
    } else if (criterion == '已读') {
      filtered = books.where((book) => book.readCount > 0).toList();
    } else {
      // 按分类筛选
      filtered = books.where((book) => book.category == criterion).toList();
    }
    
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    state = AsyncValue.data(filtered);
  }
}
