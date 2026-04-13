import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/reading_repository.dart';
import '../../models/reading_record.dart';

// 选中日期的 Provider
final selectedDateProvider = StateProvider.autoDispose<DateTime>((ref) {
  return DateTime.now();
});

// 所有阅读记录 Provider
final readingRecordsProvider = FutureProvider.autoDispose<List<ReadingRecord>>((ref) async {
  final repository = ref.watch(readingRepositoryProvider);
  return await repository.getAllRecords();
});

// 热力图数据 Provider (Map<DateTime, int>)
// Key: 日期 (也就是那一天的 00:00:00)
// Value: 阅读次数
final heatmapDataProvider = FutureProvider.autoDispose<Map<DateTime, int>>((ref) async {
  final records = await ref.watch(readingRecordsProvider.future);
  
  final Map<DateTime, int> heatmap = {};
  
  for (var record in records) {
    // 归一化到日期（去除时间部分）
    final date = DateTime(record.readAt.year, record.readAt.month, record.readAt.day);
    heatmap[date] = (heatmap[date] ?? 0) + 1;
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
final statsSummaryProvider = Provider.autoDispose<Map<String, int>>((ref) {
  final recordsAsync = ref.watch(readingRecordsProvider);
  
  return recordsAsync.when(
    data: (records) {
      final now = DateTime.now();
      final thisMonthRecords = records.where((r) => 
        r.readAt.year == now.year && r.readAt.month == now.month
      ).length;
      
      // 计算连续打卡天数 (简单实现)
      int streak = 0;
      final uniqueDates = records.map((r) {
        return DateTime(r.readAt.year, r.readAt.month, r.readAt.day);
      }).toSet().toList();
      
      uniqueDates.sort((a, b) => b.compareTo(a)); // 倒序
      
      if (uniqueDates.isNotEmpty) {
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));
        
        // 如果今天没打卡，但昨天打卡了，streak 还是算的，直到今天结束
        // 如果今天打卡了，从今天开始算
        
        DateTime checkDate = today;
        if (!uniqueDates.contains(today) && uniqueDates.contains(yesterday)) {
           checkDate = yesterday;
        }
        
        for (var date in uniqueDates) {
           if (date.year == checkDate.year && date.month == checkDate.month && date.day == checkDate.day) {
             streak++;
             checkDate = checkDate.subtract(const Duration(days: 1));
           } else if (date.isBefore(checkDate)) {
             // 发现断层
             break;
           }
        }
      }

      return {
        'total': records.length,
        'thisMonth': thisMonthRecords,
        'streak': streak,
      };
    },
    loading: () => {'total': 0, 'thisMonth': 0, 'streak': 0},
    error: (_, __) => {'total': 0, 'thisMonth': 0, 'streak': 0},
  );
});
