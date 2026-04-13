import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/book.dart';
import '../library/books_provider.dart';
import 'stats_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final heatmapAsync = ref.watch(heatmapDataProvider);
    final dailyRecordsAsync = ref.watch(dailyRecordsProvider);
    final allBooksAsync = ref.watch(booksProvider);
    final statsSummary = ref.watch(statsSummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FFF8),
      appBar: AppBar(
        title: const Text('成长足迹', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 0. 统计概览
            _buildSummaryCards(statsSummary),
            const SizedBox(height: 24),

            // 1. 热力图区域
            const Text(
              '阅读热力图',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2F3E46)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: heatmapAsync.when(
                data: (heatmapData) => _buildCalendarHeatmap(context, ref, heatmapData, selectedDate),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('加载失败: $err')),
              ),
            ),
            
            const SizedBox(height: 32),

            // 2. 每日明细区域
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('M月d日 阅读明细').format(selectedDate),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2F3E46)),
                ),
                Text(
                  DateFormat('yyyy年').format(selectedDate),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            dailyRecordsAsync.when(
              data: (records) {
                if (records.isEmpty) {
                  return _buildEmptyState();
                }
                
                // 获取所有书籍用于查找书名
                final allBooks = allBooksAsync.value ?? [];
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    // 查找对应的书籍
                    final book = allBooks.firstWhere(
                      (b) => b.id == record.bookId,
                      orElse: () => Book(
                        id: 'unknown',
                        isbn: '',
                        title: '未知书籍',
                        createdAt: DateTime.now(),
                      ),
                    );
                    
                    return _buildRecordItem(context, record, book);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('加载失败: $err')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeatmap(BuildContext context, WidgetRef ref, Map<DateTime, int> heatmapData, DateTime selectedDate) {
    // 简单的月历视图：显示当前月份
    // 为了简单起见，我们暂时只显示当前选中的月份
    // 实际生产中可以使用 pageview 切换月份
    
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final startingWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday
    
    return Column(
      children: [
        // 月份切换器
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {
                ref.read(selectedDateProvider.notifier).state = DateTime(selectedDate.year, selectedDate.month - 1, 1);
              },
            ),
            Text(
              DateFormat('yyyy年 M月').format(selectedDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                ref.read(selectedDateProvider.notifier).state = DateTime(selectedDate.year, selectedDate.month + 1, 1);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 星期标题
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['一', '二', '三', '四', '五', '六', '日'].map((day) {
            return SizedBox(
              width: 30,
              child: Center(
                child: Text(
                  day,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        // 日期网格
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: daysInMonth + (startingWeekday - 1),
          itemBuilder: (context, index) {
            if (index < startingWeekday - 1) {
              return const SizedBox();
            }
            
            final day = index - (startingWeekday - 1) + 1;
            final date = DateTime(selectedDate.year, selectedDate.month, day);
            final count = heatmapData[date] ?? 0;
            final isSelected = date.year == selectedDate.year && 
                               date.month == selectedDate.month && 
                               date.day == selectedDate.day;
            
            return GestureDetector(
              onTap: () {
                ref.read(selectedDateProvider.notifier).state = date;
              },
              child: Container(
                decoration: BoxDecoration(
                  color: _getHeatmapColor(count),
                  shape: BoxShape.circle,
                  border: isSelected ? Border.all(color: const Color(0xFF2F3E46), width: 2) : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      color: count > 0 ? Colors.white : Colors.grey[600],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // 图例
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _buildLegendItem(0, '0'),
            const SizedBox(width: 8),
            _buildLegendItem(1, '1-2'),
            const SizedBox(width: 8),
            _buildLegendItem(3, '3-5'),
            const SizedBox(width: 8),
            _buildLegendItem(6, '5+'),
          ],
        ),
      ],
    );
  }
  
  Color _getHeatmapColor(int count) {
    if (count == 0) return Colors.grey[100]!;
    if (count <= 2) return const Color(0xFFCAD2C5); // 浅绿
    if (count <= 5) return const Color(0xFF84A98C); // 中绿
    return const Color(0xFF52796F); // 深绿
  }

  Widget _buildLegendItem(int level, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: _getHeatmapColor(level),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(Icons.menu_book_outlined, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '今天还没有读书哦',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordItem(BuildContext context, dynamic record, Book book) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 左侧：时间或序号
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4F4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                DateFormat('HH:mm').format(record.readAt),
                style: const TextStyle(
                  color: Color(0xFF52796F),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 中间：书名
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F3E46),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (record.note != null && record.note!.isNotEmpty)
                  Text(
                    record.note!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    '已打卡',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
              ],
            ),
          ),
          // 右侧：小图标
          const Icon(Icons.check_circle_outline, color: Color(0xFF84A98C), size: 20),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, int> summary) {
    return Row(
      children: [
        Expanded(child: _buildSummaryCard('累计打卡', '${summary['total']}', const Color(0xFF2F3E46))),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard('本月打卡', '${summary['thisMonth']}', const Color(0xFF52796F))),
        const SizedBox(width: 12),
        Expanded(child: _buildSummaryCard('连续打卡', '${summary['streak']}天', const Color(0xFF84A98C))),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
