import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/reading_record.dart';
import '../services/storage_service.dart';

final readingRepositoryProvider = Provider((ref) => ReadingRepository(ref.watch(storageServiceProvider)));

class ReadingRepository {
  final StorageService _storageService;
  List<ReadingRecord> _records = [];
  bool _isLoaded = false;

  ReadingRepository(this._storageService);

  Future<void> _ensureLoaded() async {
    if (!_isLoaded) {
      final jsonList = await _storageService.loadReadingRecords();
      _records = jsonList.map((json) => ReadingRecord.fromJson(json)).toList();
      _isLoaded = true;
    }
  }

  Future<void> addRecord(ReadingRecord record) async {
    await _ensureLoaded();
    _records.add(record);
    await _storageService.saveReadingRecords(_records.map((r) => r.toJson()).toList());
  }

  Future<List<ReadingRecord>> getAllRecords() async {
    await _ensureLoaded();
    return List.unmodifiable(_records);
  }

  // 获取指定日期的记录
  Future<List<ReadingRecord>> getRecordsByDate(DateTime date) async {
    await _ensureLoaded();
    return _records.where((r) {
      return r.readAt.year == date.year &&
             r.readAt.month == date.month &&
             r.readAt.day == date.day;
    }).toList();
  }
}
