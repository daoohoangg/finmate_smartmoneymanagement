import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/session_storage.dart';
import '../models/user_profile.dart';

class ProfileService {
  ProfileService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<UserProfile> getProfile() async {
    final data = await _client.get('/api/profile');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile(String fullName) async {
    final data = await _client.put('/api/profile', body: {'fullName': fullName});
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.put('/api/profile/password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<UserProfile> uploadAvatar(Uint8List bytes, String fileName) async {
    final request = http.MultipartFile.fromBytes(
      'file',
      bytes,
      filename: fileName,
    );
    final response = await _client.multipart(
      '/api/profile/avatar',
      fields: {},
      file: request,
    );
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, body.isNotEmpty ? body : 'Upload failed');
    }
    if (body.isEmpty) {
      return await getProfile();
    }
    return UserProfile.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  Future<Uint8List?> downloadAvatar() async {
    final token = SessionStorage.instance.token;
    final userId = SessionStorage.instance.userId;
    if (token == null || token.isEmpty) {
      return null;
    }
    final headers = <String, String>{
      'Authorization': 'Bearer $token',
    };
    if (userId != null && userId.isNotEmpty) {
      headers['User-Id'] = userId;
    }
    final uri = Uri.parse('${ApiConstants.baseUrl}/api/profile/avatar');
    final response = await http.get(uri, headers: headers);
    if (response.statusCode == 404) {
      return null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, response.body);
    }
    return response.bodyBytes;
  }

  Future<UserProfile> deleteAvatar() async {
    final data = await _client.delete('/api/profile/avatar');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }
}
