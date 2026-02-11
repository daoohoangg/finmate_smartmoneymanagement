import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';

class ReceiptUploadService {
  ReceiptUploadService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<String> uploadReceipt(Uint8List bytes, String fileName) async {
    final request = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    );
    final response = await _client.multipart(
      '/api/files/upload',
      fields: const <String, String>{},
      file: request,
    );
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        response.statusCode,
        body.isNotEmpty ? body : 'Upload failed',
      );
    }
    if (body.isEmpty) {
      throw ApiException(response.statusCode, 'Upload failed');
    }
    final trimmed = body.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[') || trimmed.startsWith('"')) {
      final decoded = jsonDecode(trimmed);
      if (decoded is String) return decoded;
      if (decoded is Map && decoded['url'] != null) {
        return decoded['url'].toString();
      }
    }
    return trimmed;
  }
}
