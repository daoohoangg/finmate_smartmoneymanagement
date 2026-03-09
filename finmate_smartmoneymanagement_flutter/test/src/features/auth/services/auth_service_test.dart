import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/network/api_client.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/auth/services/auth_service.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/auth/models/auth_response.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late AuthService authService;
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
    authService = AuthService(client: mockApiClient);
  });

  group('AuthService', () {
    final mockAuthResponseJson = {
      'userId': '123',
      'email': 'test@example.com',
      'fullName': 'Test',
      'token': 'token123',
    };

    test('login posts credentials and returns AuthResponse', () async {
      when(() => mockApiClient.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => mockAuthResponseJson);

      final result = await authService.login(email: 'test@example.com', password: 'password');

      expect(result, isA<AuthResponse>());
      expect(result.userId, '123');
      verify(() => mockApiClient.post(
            '/api/auth/login',
            body: {'email': 'test@example.com', 'password': 'password'},
          )).called(1);
    });

    test('register posts data and returns AuthResponse', () async {
      when(() => mockApiClient.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => mockAuthResponseJson);

      final result = await authService.register(
        email: 'test@example.com',
        password: 'password',
        fullName: 'Test User',
      );

      expect(result, isA<AuthResponse>());
      verify(() => mockApiClient.post(
            '/api/auth/register',
            body: {
              'email': 'test@example.com',
              'password': 'password',
              'fullName': 'Test User',
            },
          )).called(1);
    });

    test('forgotPassword handles successfully', () async {
      when(() => mockApiClient.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => {}); // or null, depending on api client setup

      await authService.forgotPassword('test@example.com');

      verify(() => mockApiClient.post(
            '/api/auth/forgot-password',
            body: {'email': 'test@example.com'},
          )).called(1);
    });

    test('verifyOtp returns resetToken', () async {
      when(() => mockApiClient.post(any(), body: any(named: 'body')))
          .thenAnswer((_) async => {'resetToken': 'reset123'});

      final token = await authService.verifyOtp(email: 'test@example.com', otp: '123456');

      expect(token, 'reset123');
      verify(() => mockApiClient.post(
            '/api/auth/verify-otp',
            body: {'email': 'test@example.com', 'otp': '123456'},
          )).called(1);
    });
  });
}
