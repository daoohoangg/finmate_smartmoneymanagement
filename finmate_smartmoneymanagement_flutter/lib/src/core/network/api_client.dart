import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../storage/session_storage.dart';
import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${ApiConstants.baseUrl}$path');

  Future<Map<String, String>> _headers({bool json = true}) async {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
    }
    final token = SessionStorage.instance.token;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final userId = SessionStorage.instance.userId;
    if (userId != null && userId.isNotEmpty) {
      headers['User-Id'] = userId;
    }
    return headers;
  }

  Future<dynamic> get(String path) async {
    final response = await _client.get(_uri(path), headers: await _headers());
    return _handleResponse(response);
  }

  Future<dynamic> post(String path, {Object? body}) async {
    final response = await _client.post(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> put(String path, {Object? body}) async {
    final response = await _client.put(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body ?? {}),
    );
    return _handleResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final response = await _client.delete(_uri(path), headers: await _headers());
    return _handleResponse(response);
  }

  Future<http.StreamedResponse> multipart(
    String path, {
    required Map<String, String> fields,
    required http.MultipartFile file,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path));
    request.fields.addAll(fields);
    request.files.add(file);
    final headers = await _headers(json: false);
    request.headers.addAll(headers);
    return request.send();
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    }
    String message = 'Request failed';
    try {
      final data = jsonDecode(response.body);
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }
    } catch (_) {
      if (response.body.isNotEmpty) {
        message = response.body;
      }
    }
    throw ApiException(response.statusCode, message);
  }
}
