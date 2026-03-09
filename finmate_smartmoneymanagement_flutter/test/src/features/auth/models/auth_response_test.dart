import 'package:flutter_test/flutter_test.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/auth/models/auth_response.dart';

void main() {
  group('AuthResponse Model', () {
    test('fromJson creates correct instance from valid JSON', () {
      final json = {
        'userId': '123',
        'email': 'test@example.com',
        'fullName': 'Test User',
        'token': 'abc.123.dfg',
      };

      final authResponse = AuthResponse.fromJson(json);

      expect(authResponse.userId, '123');
      expect(authResponse.email, 'test@example.com');
      expect(authResponse.fullName, 'Test User');
      expect(authResponse.token, 'abc.123.dfg');
    });

    test('fromJson handles null or missing values gracefully', () {
      final json = <String, dynamic>{}; // Empty JSON

      final authResponse = AuthResponse.fromJson(json);

      expect(authResponse.userId, '');
      expect(authResponse.email, '');
      expect(authResponse.fullName, '');
      expect(authResponse.token, '');
    });
  });
}
