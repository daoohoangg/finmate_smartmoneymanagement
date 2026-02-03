import '../../../core/network/api_client.dart';

class SyncService {
  SyncService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<Map<String, dynamic>> syncAll() async {
    final data = await _client.get('/api/sync');
    return data as Map<String, dynamic>;
  }
}
