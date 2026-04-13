import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiServiceProvider = Provider((ref) => ApiService());

class ApiService {
  static const String _defaultToken = 'mobile-sync-user';
  static const String _devBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String _devToken = String.fromEnvironment(
    'API_AUTH_TOKEN',
    defaultValue: _defaultToken,
  );
  static const bool _useAdbReverse = bool.fromEnvironment(
    'USE_ADB_REVERSE',
    defaultValue: false,
  );

  String get baseUrl {
    if (_devBaseUrl.trim().isNotEmpty) {
      return _devBaseUrl.trim();
    }
    if (Platform.isAndroid) {
      if (_useAdbReverse) {
        return 'http://127.0.0.1:3000';
      }
      return 'http://10.0.2.2:3000';
    }
    return 'http://127.0.0.1:3000';
  }

  String get authToken => _devToken.trim().isEmpty ? _defaultToken : _devToken.trim();

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters: queryParameters);
    return _request('GET', uri);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);
    return _request('POST', uri, body: body);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = _buildUri(path);
    return _request('PATCH', uri, body: body);
  }

  Future<void> delete(String path) async {
    final uri = _buildUri(path);
    await _request('DELETE', uri);
  }

  Uri _buildUri(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final normalizedBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: queryParameters?.map((key, value) => MapEntry(key, value.toString())),
    );
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, uri);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $authToken');
      if (body != null) {
        request.write(jsonEncode(body));
      }
      final response = await request.close();
      final responseBody = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}: ${responseBody.isEmpty ? 'Request failed' : responseBody}');
      }
      if (responseBody.trim().isEmpty) {
        return {};
      }
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } finally {
      client.close(force: true);
    }
  }
}
