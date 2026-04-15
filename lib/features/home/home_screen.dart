import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../scanner/scanner_screen.dart';
import '../library/books_provider.dart';
import '../../models/book.dart';
import '../../core/widgets/speech_input_button.dart';
import '../../core/widgets/ocr_input_button.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isCheckingIn = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 处理扫码结果
  Future<void> _handleScan() async {
    final isbn = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
    
    if (isbn != null && mounted) {
      final notifier = ref.read(booksProvider.notifier);
      final books = await notifier.findBooksByIsbn(isbn);
      
      if (books.isEmpty) {
        _showBookNotFoundDialog(isbn: isbn);
      } else if (books.length == 1) {
        _recordReading(books.first);
      } else {
        _showMultipleBooksDialog(books);
      }
    }
  }

  // 处理手动输入
  void _handleManualEntry() {
    bool isSubmitted = false;
    showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '手动记录阅读',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '输入书名...',
                    border: const OutlineInputBorder(),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OcrInputButton(controller: controller),
                        SpeechInputButton(controller: controller),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        if (isSubmitted) return;
                        isSubmitted = true;
                        Navigator.pop(context);
                      },
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () async {
                        if (isSubmitted) return;
                        final title = controller.text.trim();
                        if (title.isNotEmpty) {
                          isSubmitted = true;
                          Navigator.pop(context);
                          _searchAndRecord(title);
                        }
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 搜索并记录
  Future<void> _searchAndRecord(String title) async {
    final notifier = ref.read(booksProvider.notifier);
    final books = await notifier.findBooksByTitle(title);
    
    if (!mounted) return;

    if (books.isEmpty) {
      _showBookNotFoundDialog(title: title);
    } else if (books.length == 1) {
      _recordReading(books.first);
    } else {
      // 多个匹配，让用户选择
      _showMultipleBooksDialog(books, isSearchByTitle: true);
    }
  }

  void _showMultipleBooksDialog(List<Book> books, {bool isSearchByTitle = false}) {
    Book? selectedBook = books.first;
    bool isSubmitted = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.85,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '匹配到多本书籍',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isSearchByTitle
                        ? '该关键词匹配到多本书籍，请选择您要打卡的是哪一本：'
                        : '该 ISBN 对应多本书籍，请选择您要打卡的是哪一本：',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: books.map((book) {
                          final isSelected = selectedBook?.id == book.id;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedBook = book;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected 
                                      ? Theme.of(context).colorScheme.primary 
                                      : Colors.grey.shade300,
                                  width: isSelected ? 2 : 1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                color: isSelected 
                                    ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3) 
                                    : Colors.transparent,
                              ),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: book.id,
                                    groupValue: selectedBook?.id,
                                    onChanged: (value) {
                                      setState(() {
                                        selectedBook = book;
                                      });
                                    },
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book.title,
                                          style: const TextStyle(
                                            fontSize: 16, 
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                        if (book.author != null && book.author!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              '作者: ${book.author}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade700,
                                              ),
                                            ),
                                          ),
                                        if (book.volumeNumber != null || (book.seriesName?.isNotEmpty ?? false))
                                          Padding(
                                            padding: const EdgeInsets.only(top: 4.0),
                                            child: Text(
                                              '${book.seriesName ?? ''} ${book.volumeNumber != null ? '第${book.volumeNumber}册' : ''}'.trim(),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          if (isSubmitted) return;
                          isSubmitted = true;
                          Navigator.pop(context);
                        },
                        child: const Text('取消'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: selectedBook == null
                            ? null
                            : () {
                                if (isSubmitted) return;
                                isSubmitted = true;
                                Navigator.pop(context);
                                _recordReading(selectedBook!);
                              },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('确定打卡'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 记录阅读行为
  void _recordReading(Book book) async {
    if (_isCheckingIn) return;
    setState(() {
      _isCheckingIn = true;
    });
    try {
      await ref.read(booksProvider.notifier).recordReading(book);

      if (!mounted) return;

      // 显示打卡成功动画/提示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool isClosed = false;
          Future.delayed(const Duration(seconds: 2), () {
            if (!isClosed && dialogContext.mounted) {
              isClosed = true;
              if (Navigator.of(dialogContext).canPop()) {
                Navigator.pop(dialogContext);
              }
            }
          });

          return PopScope(
            canPop: true,
            onPopInvokedWithResult: (didPop, result) {
              isClosed = true;
            },
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: MediaQuery.of(dialogContext).size.width * 0.85,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF6B9080), size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          '打卡成功！',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text('《${book.title}》', style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          '这是你第 ${book.readCount + 1} 次阅读',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('打卡失败：$e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingIn = false;
        });
      }
    }
  }

  // 书籍未找到提示
  void _showBookNotFoundDialog({String? isbn, String? title}) {
    bool isSubmitted = false;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '未找到该书',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                '书架中没有找到${title != null ? "名为“$title”" : "此 ISBN"}的书籍。\n是否要去录入？',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      if (isSubmitted) return;
                      isSubmitted = true;
                      Navigator.pop(context);
                    },
                    child: const Text('取消'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      if (isSubmitted) return;
                      isSubmitted = true;
                      Navigator.pop(context);
                      // 跳转到录入页面，这里暂时不支持传参，如果需要预填可以在 EntryScreen 增加参数
                      context.push('/entry');
                      // TODO: 未来可以优化为带参数跳转，自动填入 ISBN
                    },
                    child: const Text('去录入'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FFF8),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
            const Text(
              "今天想读什么书？",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2F3E46),
              ),
            ),
            const SizedBox(height: 60),
            // 呼吸按钮
            GestureDetector(
              onTap: _isCheckingIn ? null : _handleScan,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: 200 + (_controller.value * 20),
                    height: 200 + (_controller.value * 20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF84A98C).withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF52796F),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFCAD2C5),
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 60,
                              color: Colors.white,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '扫码打卡',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 40),
            // 手动输入入口
            TextButton.icon(
              onPressed: _isCheckingIn ? null : _handleManualEntry,
              icon: const Icon(Icons.edit, color: Color(0xFF52796F)),
              label: const Text(
                '找不到条码？手动记录',
                style: TextStyle(
                  color: Color(0xFF52796F),
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 60),
            // 最近读过的小足迹
            _buildRecentFootprints(ref),
              ],
            ),
          ),
          if (_isCheckingIn)
            Positioned.fill(
              child: ColoredBox(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentFootprints(WidgetRef ref) {
    final booksAsync = ref.watch(booksProvider);
    
    return booksAsync.when(
      data: (books) {
        // 筛选出有阅读记录的书籍，按最后阅读时间倒序排列
        final readBooks = books.where((b) => b.lastReadAt != null).toList()
          ..sort((a, b) => b.lastReadAt!.compareTo(a.lastReadAt!));
          
        if (readBooks.isEmpty) {
          return const SizedBox(height: 100); // 占位
        }
        
        final recentBooks = readBooks.take(5).toList();
        
        return Column(
          children: [
            Text('最近足迹', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: recentBooks.length,
                itemBuilder: (context, index) {
                  final book = recentBooks[index];
                  // 生成一个基于 ID 的随机但不变的颜色
                  final colorIndex = book.id.hashCode.abs() % Colors.primaries.length;
                  final color = Colors.primaries[colorIndex];
                  
                  return Tooltip(
                    message: book.title,
                    child: Container(
                      margin: const EdgeInsets.only(right: 16),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Center(
                        child: Text(
                          book.title.isNotEmpty ? book.title.substring(0, 1) : '?',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 100),
      error: (_, __) => const SizedBox(height: 100),
    );
  }
}
