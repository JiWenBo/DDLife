import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/reading_repository.dart';
import '../../core/services/api_service.dart';
import '../../models/reading_record.dart';

// 选中日期的 Provider
final selectedDateProvider = StateProvider.autoDispose<DateTime>((ref) {
  return DateTime.now();
});

// 热力图数据 Provider (Map<DateTime, int>)
// Key: 日期 (也就是那一天的 00:00:00)
// Value: 阅读次数
final heatmapDataProvider = FutureProvider.autoDispose<Map<DateTime, int>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/v1/stats/summary');
  final checkinDays = (response['checkinDays'] as List<dynamic>? ?? []).map((e) => e.toString());

  final Map<DateTime, int> heatmap = {};
  for (final day in checkinDays) {
    final parsed = DateTime.tryParse(day);
    if (parsed == null) {
      continue;
    }
    final date = DateTime(parsed.year, parsed.month, parsed.day);
    heatmap[date] = 1;
  }

  return heatmap;
});

// 选中日期的阅读记录 Provider
final dailyRecordsProvider = FutureProvider.autoDispose<List<ReadingRecord>>((ref) async {
  final selectedDate = ref.watch(selectedDateProvider);
  final repository = ref.watch(readingRepositoryProvider);
  
  // 这里的 getRecordsByDate 已经在 repository 里实现了
  return await repository.getRecordsByDate(selectedDate);
});

// 统计摘要 Provider
final statsSummaryProvider = FutureProvider.autoDispose<Map<String, int>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final response = await api.get('/v1/stats/summary');
  return {
    'total': response['total'] is int ? response['total'] as int : 0,
    'thisMonth': response['thisMonth'] is int ? response['thisMonth'] as int : 0,
    'streak': response['streak'] is int ? response['streak'] as int : 0,
  };
});
