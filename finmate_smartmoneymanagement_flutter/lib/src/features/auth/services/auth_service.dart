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

  /// Sends a 6-digit OTP to the given email.
  Future<void> forgotPassword(String email) async {
    await _client.post(
      '/api/auth/forgot-password',
      body: {'email': email},
    );
  }

  /// Verifies the OTP and returns a one-time reset token.
  Future<String> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final data = await _client.post(
      '/api/auth/verify-otp',
      body: {'email': email, 'otp': otp},
    );
    final map = data as Map<String, dynamic>;
    return map['resetToken'] as String;
  }

  /// Resets the password using the token from [verifyOtp].
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await _client.post(
      '/api/auth/reset-password',
      body: {
        'resetToken': resetToken,
        'newPassword': newPassword,
      },
    );
  }
}
