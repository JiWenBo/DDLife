import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/book.dart';
import 'books_provider.dart';
import '../../core/widgets/speech_input_button.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _selectedCategory = '全部';
  String? _deletingBookId;

  // 预定义的分类列表，与录入页面保持一致 + '全部' + '状态'
  final List<String> _filters = [
    '全部',
    '未读',
    '已读',
    '绘本故事',
    '自然科普',
    '历史人文',
    '少儿文学',
    '英语分级',
    '漫画/桥梁书',
    '拼音认读',
    '其他'
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _onSearchChanged(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(booksProvider.notifier).searchBooks(query);
  }

  void _onFilterSelected(String filter) {
    setState(() {
      _selectedCategory = filter;
    });
    ref.read(booksProvider.notifier).filterBy(filter);
  }

  Color _getAvatarColor(String title) {
    // 根据书名生成固定的随机颜色
    final colors = [
      Colors.red.shade100,
      Colors.green.shade100,
      Colors.blue.shade100,
      Colors.orange.shade100,
      Colors.purple.shade100,
      Colors.teal.shade100,
      Colors.pink.shade100,
      Colors.amber.shade100,
    ];
    return colors[title.hashCode % colors.length];
  }

  Color _getAvatarTextColor(String title) {
    final colors = [
      Colors.red.shade900,
      Colors.green.shade900,
      Colors.blue.shade900,
      Colors.orange.shade900,
      Colors.purple.shade900,
      Colors.teal.shade900,
      Colors.pink.shade900,
      Colors.amber.shade900,
    ];
    return colors[title.hashCode % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(booksProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '搜索书名、ISBN 或标签...',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: Colors.grey),
                  suffixIcon: SpeechInputButton(controller: _searchController),
                ),
                style: const TextStyle(fontSize: 18),
              )
            : booksAsync.when(
                data: (books) => Text('我的书架 · 共 ${books.length} 本'),
                loading: () => const Text('我的书架'),
                error: (_, __) => const Text('我的书架'),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  // 退出搜索时重置列表
                  ref.read(booksProvider.notifier).loadBooks();
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.add_box), // 录入入口
              tooltip: '录入书籍',
              onPressed: () {
                context.push('/entry');
              },
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedCategory == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _onFilterSelected(filter);
                      }
                    },
                    backgroundColor: Colors.grey.shade100,
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide.none,
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: booksAsync.when(
        data: (books) {
          if (books.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.menu_book, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    _isSearching ? '没有找到相关书籍' : '书架还是空的',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                  ),
                  if (!_isSearching)
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/entry'),
                        icon: const Icon(Icons.add),
                        label: const Text('去录入第一本书'),
                      ),
                    ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: books.length,
            padding: const EdgeInsets.only(bottom: 80), // 留出底部 TabBar 的空间
            itemBuilder: (context, index) {
              final book = books[index];
              return _buildBookTile(context, book);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载失败: $err')),
      ),
    );
  }

  Widget _buildBookTile(BuildContext context, Book book) {
    final avatarChar = book.title.isNotEmpty ? book.title[0] : '?';
    
    // 构建副标题信息
    final List<String> subtitleParts = [];
    if (book.category != null && book.category!.isNotEmpty) {
      subtitleParts.add(book.category!);
    }
    if (book.seriesName != null && book.seriesName!.isNotEmpty) {
      String seriesInfo = '《${book.seriesName}》';
      if (book.volumeNumber != null) {
        seriesInfo += ' · 第${book.volumeNumber}册';
      }
      subtitleParts.add(seriesInfo);
    }
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: _getAvatarColor(book.title),
        child: Text(
          avatarChar,
          style: TextStyle(
            color: _getAvatarTextColor(book.title),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      title: Text(
        book.title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitleParts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                subtitleParts.join('  '),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (book.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: book.tags.take(3).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '#$tag',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (book.readCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text(
                    '${book.readCount}次',
                    style: TextStyle(
                      fontSize: 12, 
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
          PopupMenuButton<String>(
            enabled: _deletingBookId != book.id,
            icon: _deletingBookId == book.id
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.more_vert, color: Colors.grey),
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(book);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Book book) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除《${book.title}》吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: _deletingBookId == book.id ? null : () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: _deletingBookId == book.id
                ? null
                : () async {
                    setState(() {
                      _deletingBookId = book.id;
                    });
                    try {
                      await ref.read(booksProvider.notifier).deleteBook(book.id);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已删除《${book.title}》')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('删除失败：$e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _deletingBookId = null;
                        });
                      }
                    }
                  },
            child: _deletingBookId == book.id
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
