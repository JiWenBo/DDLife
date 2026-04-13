import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/reading_record.dart';
import '../services/api_service.dart';

final readingRepositoryProvider = Provider((ref) => ReadingRepository(ref.watch(apiServiceProvider)));

class ReadingRepository {
  final ApiService _apiService;

  ReadingRepository(this._apiService);

  Future<void> addRecord(ReadingRecord record) async {
    await _apiService.post(
      '/v1/reading-records',
      body: {
        'bookId': record.bookId,
        'readAt': record.readAt.toUtc().toIso8601String(),
        if (record.durationSeconds != null) 'durationSeconds': record.durationSeconds,
        if (record.note != null && record.note!.isNotEmpty) 'note': record.note,
      },
    );
  }

  Future<List<ReadingRecord>> getAllRecords() async {
    final response = await _apiService.get('/v1/reading-records');
    return (response['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ReadingRecord.fromJson)
        .toList();
  }

  Future<List<ReadingRecord>> getRecordsByDate(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final response = await _apiService.get(
      '/v1/reading-records',
      queryParameters: {'date': dateStr, 'includeBook': 'true'},
    );
    return (response['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ReadingRecord.fromJson)
        .toList();
  }
}
