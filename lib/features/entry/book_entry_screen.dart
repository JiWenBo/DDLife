import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/book.dart';
import '../library/books_provider.dart';
import '../../core/widgets/speech_input_button.dart';
import '../../core/widgets/ocr_input_button.dart';

class BookEntryScreen extends ConsumerStatefulWidget {
  const BookEntryScreen({super.key});

  @override
  ConsumerState<BookEntryScreen> createState() => _BookEntryScreenState();
}

class _BookEntryScreenState extends ConsumerState<BookEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _isbnController = TextEditingController();
  final _titleController = TextEditingController();
  final _seriesNameController = TextEditingController();
  final _volumeNumberController = TextEditingController();
  final _editionController = TextEditingController();
  final _tagsController = TextEditingController();

  String? _selectedCategory;

  // 更新为更适合 6-12 岁的童趣分类
  final List<String> _categories = [
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
  void dispose() {
    _isbnController.dispose();
    _titleController.dispose();
    _seriesNameController.dispose();
    _volumeNumberController.dispose();
    _editionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _scanIsbn() async {
    // 导航到扫码页面，等待返回结果
    final result = await context.push<String>('/scanner');
    if (result != null && result.isNotEmpty) {
      setState(() {
        _isbnController.text = result;
      });
      // 可以选择在这里调用一个根据 ISBN 获取书名的 API
    }
  }

  void _saveBook() async {
    if (_formKey.currentState!.validate()) {
      final isbn = _isbnController.text.trim();
      final title = _titleController.text.trim();

      // 查重逻辑：如果 ISBN 相同且书名也相同，则拦截并提示
      if (isbn.isNotEmpty) {
        final existingBooks = await ref.read(booksProvider.notifier).findBooksByIsbn(isbn);
        if (existingBooks.isNotEmpty) {
          final isDuplicate = existingBooks.any((book) => book.title == title);
          if (isDuplicate) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('重复录入提示'),
                  content: Text('书架中已存在 ISBN 为 "$isbn" 且书名为《$title》的书籍，无需重复录入。'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('知道了'),
                    ),
                  ],
                ),
              );
            }
            return; // 终止保存流程
          }
        }
      }

      // 处理标签 (逗号分隔)
      List<String> tags = _tagsController.text
          .split(RegExp(r'[,，]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final newBook = Book(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // 使用时间戳作为极简的唯一 ID
        isbn: isbn,
        title: title,
        category: _selectedCategory,
        seriesName: _seriesNameController.text.trim().isEmpty ? null : _seriesNameController.text.trim(),
        volumeNumber: int.tryParse(_volumeNumberController.text.trim()),
        edition: _editionController.text.trim().isEmpty ? null : _editionController.text.trim(),
        tags: tags,
        createdAt: DateTime.now(),
      );

      // await bookRepository.addBook(newBook);
      await ref.read(booksProvider.notifier).addBook(newBook);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 录入成功！您可以继续录入下一本。'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
        
        // 录入成功后不清空表单全部内容，保留分类等，只清空 ISBN、书名、册数等核心内容，方便连续录入
        _isbnController.clear();
        _volumeNumberController.clear();
        _titleController.clear(); // 清空书名，防止连续录入同一本书
        _seriesNameController.clear();
        _editionController.clear();
     
        
        // 注释掉 pop，不跳回上一页
        // context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('录入书籍'),
        actions: [
          TextButton(
            onPressed: _saveBook,
            child: const Text('保存', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. 核心信息区
            const _SectionTitle(title: '核心信息'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _isbnController,
                    decoration: const InputDecoration(
                      labelText: 'ISBN',
                      hintText: '如: 9787533259563',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      // ISBN 不再强制必填，允许留空
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56, // 与输入框等高
                  child: ElevatedButton.icon(
                    onPressed: _scanIsbn,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('扫码'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: '书名 *',
                      border: const OutlineInputBorder(),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OcrInputButton(controller: _titleController),
                          SpeechInputButton(controller: _titleController),
                        ],
                      ),
                    ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '请输入书名';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 32),
            // 2. 分类与标签区
            const _SectionTitle(title: '分类与标签'),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: const InputDecoration(
                labelText: '分类',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: '标签 (用逗号分隔)',
                hintText: '如: 睡前故事, 情绪管理',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 32),
            // 3. 套系与版本区
            const _SectionTitle(title: '套系与版本 (选填)'),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _seriesNameController,
                    decoration: const InputDecoration(
                      labelText: '套系',
                      hintText: '第一套',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _volumeNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '第几册',
                      hintText: '如: 3',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // 备注单独一行
            TextFormField(
              controller: _editionController,
              decoration: const InputDecoration(
                labelText: '备注',
                hintText: '备注信息',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveBook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '保存书籍',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
