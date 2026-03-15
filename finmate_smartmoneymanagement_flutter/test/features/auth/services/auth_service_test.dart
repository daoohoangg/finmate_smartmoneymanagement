import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/auth/services/auth_service.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/network/api_client.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/auth/models/auth_response.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late AuthService authService;

  setUp(() {
    mockApiClient = MockApiClient();
    authService = AuthService(client: mockApiClient);
  });

  group('AuthService Tests', () {
    test('loginWithGoogle with idToken returns AuthResponse', () async {
      final mockData = {
        'token': 'mock_token',
        'userId': '123',
        'email': 'mobile@gmail.com',
        'fullName': 'Mobile User',
      };

      when(() => mockApiClient.post(
        '/api/auth/google',
        body: {'idToken': 'test_id_token'},
      )).thenAnswer((_) async => mockData);

      final response = await authService.loginWithGoogle(idToken: 'test_id_token');

      expect(response, isA<AuthResponse>());
      expect(response.token, 'mock_token');
      expect(response.email, 'mobile@gmail.com');
      verify(() => mockApiClient.post(
        '/api/auth/google',
        body: {'idToken': 'test_id_token'},
      )).called(1);
    });

    test('loginWithGoogle with accessToken returns AuthResponse', () async {
      final mockData = {
        'token': 'mock_token_web',
        'userId': '456',
        'email': 'web@gmail.com',
        'fullName': 'Web User',
      };

      when(() => mockApiClient.post(
        '/api/auth/google',
        body: {'accessToken': 'test_access_token'},
      )).thenAnswer((_) async => mockData);

      final response = await authService.loginWithGoogle(accessToken: 'test_access_token');

      expect(response, isA<AuthResponse>());
      expect(response.token, 'mock_token_web');
      expect(response.email, 'web@gmail.com');
      verify(() => mockApiClient.post(
        '/api/auth/google',
        body: {'accessToken': 'test_access_token'},
      )).called(1);
    });
  });
}
