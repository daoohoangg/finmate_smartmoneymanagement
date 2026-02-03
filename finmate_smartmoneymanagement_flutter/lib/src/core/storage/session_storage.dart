import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  SessionStorage._internal();

  static final SessionStorage instance = SessionStorage._internal();

  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'email';
  static const String _fullNameKey = 'full_name';
  static const String _surveyCompletedKey = 'survey_completed';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? get token => _prefs?.getString(_tokenKey);
  String? get userId => _prefs?.getString(_userIdKey);
  String? get email => _prefs?.getString(_emailKey);
  String? get fullName => _prefs?.getString(_fullNameKey);
  bool get surveyCompleted => _prefs?.getBool(_surveyCompletedKey) ?? false;

  Future<void> saveAuth({
    required String token,
    required String userId,
    required String email,
    required String fullName,
  }) async {
    await _prefs?.setString(_tokenKey, token);
    await _prefs?.setString(_userIdKey, userId);
    await _prefs?.setString(_emailKey, email);
    await _prefs?.setString(_fullNameKey, fullName);
  }

  Future<void> updateProfile({
    String? fullName,
    String? email,
  }) async {
    if (fullName != null) {
      await _prefs?.setString(_fullNameKey, fullName);
    }
    if (email != null) {
      await _prefs?.setString(_emailKey, email);
    }
  }

  Future<void> setSurveyCompleted(bool value) async {
    await _prefs?.setBool(_surveyCompletedKey, value);
  }

  Future<void> clear() async {
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userIdKey);
    await _prefs?.remove(_emailKey);
    await _prefs?.remove(_fullNameKey);
    await _prefs?.remove(_surveyCompletedKey);
  }
}
