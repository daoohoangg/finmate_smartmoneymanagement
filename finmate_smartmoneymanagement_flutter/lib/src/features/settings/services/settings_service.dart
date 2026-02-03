import '../../../core/network/api_client.dart';
import '../models/user_settings.dart';

class SettingsService {
  SettingsService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<UserSettings> getSettings() async {
    final data = await _client.get('/api/settings');
    return UserSettings.fromJson(data as Map<String, dynamic>);
  }

  Future<UserSettings> updateSettings(UserSettings settings) async {
    final data = await _client.put('/api/settings', body: settings.toJson());
    return UserSettings.fromJson(data as Map<String, dynamic>);
  }
}
