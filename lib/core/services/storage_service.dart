import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ddbook/models/book.dart';

final storageServiceProvider = Provider((ref) => StorageService());

class StorageService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/books.json');
  }

  Future<File> get _readingRecordsFile async {
    final path = await _localPath;
    return File('$path/reading_records.json');
  }

  Future<List<Book>> loadBooks() async {
    try {
      final file = await _localFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.map((json) => Book.fromJson(json)).toList();
    } catch (e) {
      // 发生错误时返回空列表，避免应用崩溃
      return [];
    }
  }

  Future<void> saveBooks(List<Book> books) async {
    final file = await _localFile;
    final String jsonString = jsonEncode(books.map((b) => b.toJson()).toList());
    await file.writeAsString(jsonString);
  }

  Future<List<Map<String, dynamic>>> loadReadingRecords() async {
    try {
      final file = await _readingRecordsFile;
      if (!await file.exists()) {
        return [];
      }
      final contents = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(contents);
      return jsonList.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveReadingRecords(List<Map<String, dynamic>> records) async {
    final file = await _readingRecordsFile;
    final String jsonString = jsonEncode(records);
    await file.writeAsString(jsonString);
  }

  // 获取 books.json 文件的绝对路径，用于分享或导出
  Future<String> getExportFilePath() async {
    final file = await _localFile;
    return file.path;
  }
}
