// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:ddbook/models/book.dart';

void main() {
  test('Book json serialize/deserialize', () {
    final now = DateTime.now();
    final book = Book(
      id: 'id-1',
      isbn: '978123',
      title: '测试书',
      tags: const ['科普'],
      createdAt: now,
    );
    final json = book.toJson();
    final decoded = Book.fromJson(json);
    expect(decoded.id, 'id-1');
    expect(decoded.title, '测试书');
    expect(decoded.tags, ['科普']);
  });
}
