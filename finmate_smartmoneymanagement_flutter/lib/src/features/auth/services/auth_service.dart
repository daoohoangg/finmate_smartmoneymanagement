import '../../../core/network/api_client.dart';
import '../models/auth_response.dart';

class AuthService {
  AuthService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final data = await _client.post(
      '/api/auth/register',
      body: {
        'email': email,
        'password': password,
        'fullName': fullName,
      },
    );
    return AuthResponse.fromJson(data as Map<String, dynamic>);
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.post(
      '/api/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );
    return AuthResponse.fromJson(data as Map<String, dynamic>);
  }

  /// Login with Google. 
  /// [idToken] is used for mobile/desktop platforms.
  /// [accessToken] is used for web platform.
  Future<AuthResponse> loginWithGoogle({
    String? idToken,
    String? accessToken,
  }) async {
    final body = <String, dynamic>{};
    if (idToken != null) body['idToken'] = idToken;
    if (accessToken != null) body['accessToken'] = accessToken;

    final data = await _client.post(
      '/api/auth/google',
      body: body,
    );
    return AuthResponse.fromJson(data as Map<String, dynamic>);
  }
}
