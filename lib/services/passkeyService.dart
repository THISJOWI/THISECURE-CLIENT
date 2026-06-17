import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api.dart';
import 'token_manager.dart';

class PasskeyService {
  String get baseUrl => ApiConfig.passkeysUrl;
  final TokenManager _tokenManager = TokenManager();
  http.Client httpClient = http.Client();
  Duration timeout = const Duration(seconds: 30);

  Future<Map<String, String>?> _getAuthHeaders() async {
    final token = await _tokenManager.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  dynamic _tryDecode(String text) {
    try {
      return jsonDecode(text);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _wrap(Future<http.Response> Function() send) async {
    try {
      final res = await send().timeout(timeout);
      final body = _tryDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return {
          'success': true,
          'data': body,
          'message': 'OK',
        };
      }
      if (res.statusCode == 401) {
        return {'success': false, 'message': 'Invalid or expired token.', 'data': <dynamic>[]};
      }
      if (res.statusCode == 403) {
        return {'success': false, 'message': 'Access denied.', 'data': <dynamic>[]};
      }
      if (res.statusCode == 500) {
        return {'success': false, 'message': 'Server error. Please try again later.', 'data': <dynamic>[]};
      }
      return {
        'success': false,
        'message': (body is Map && body['error'] != null) ? body['error'].toString() : 'Error: ${res.statusCode}',
        'data': <dynamic>[],
      };
    } on TimeoutException {
      return {'success': false, 'message': 'Connection timeout. Please try again.', 'data': <dynamic>[]};
    } catch (e) {
      return {'success': false, 'message': 'Failed: $e', 'data': <dynamic>[]};
    }
  }

  Future<Map<String, dynamic>> getAll() async {
    final headers = await _getAuthHeaders();
    return _wrap(() => httpClient.get(Uri.parse(baseUrl), headers: headers));
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> data) async {
    final headers = await _getAuthHeaders();
    return _wrap(() => httpClient.post(Uri.parse(baseUrl), headers: headers, body: jsonEncode(data)));
  }

  Future<Map<String, dynamic>> update(String id, Map<String, dynamic> data) async {
    final headers = await _getAuthHeaders();
    return _wrap(() => httpClient.put(Uri.parse('$baseUrl/$id'), headers: headers, body: jsonEncode(data)));
  }

  Future<Map<String, dynamic>> delete(String id) async {
    final headers = await _getAuthHeaders();
    return _wrap(() => httpClient.delete(Uri.parse('$baseUrl/$id'), headers: headers));
  }
}
