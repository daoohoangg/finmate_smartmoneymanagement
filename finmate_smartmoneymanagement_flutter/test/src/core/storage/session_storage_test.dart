import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/storage/session_storage.dart';

void main() {
  group('SessionStorage', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SessionStorage.instance.init();
    });

    test('saveAuth saves standard auth data correctly', () async {
      await SessionStorage.instance.saveAuth(
        token: 'test_token',
        userId: '1',
        email: 'test@example.com',
        fullName: 'Test User',
      );

      expect(SessionStorage.instance.token, 'test_token');
      expect(SessionStorage.instance.userId, '1');
      expect(SessionStorage.instance.email, 'test@example.com');
      expect(SessionStorage.instance.fullName, 'Test User');
    });

    test('updateProfile updates specific fields', () async {
      await SessionStorage.instance.saveAuth(
        token: 'test_token',
        userId: '1',
        email: 'test@example.com',
        fullName: 'Test User',
      );

      await SessionStorage.instance.updateProfile(fullName: 'Updated Name');

      expect(SessionStorage.instance.fullName, 'Updated Name');
      expect(SessionStorage.instance.email, 'test@example.com'); // Unchanged
    });

    test('setSurveyCompleted sets flag correctly', () async {
      expect(SessionStorage.instance.surveyCompleted, false);

      await SessionStorage.instance.setSurveyCompleted(true);

      expect(SessionStorage.instance.surveyCompleted, true);
    });

    test('clear removes all data', () async {
      await SessionStorage.instance.saveAuth(
        token: 'test_token',
        userId: '1',
        email: 'test@example.com',
        fullName: 'Test User',
      );
      await SessionStorage.instance.setSurveyCompleted(true);

      await SessionStorage.instance.clear();

      expect(SessionStorage.instance.token, isNull);
      expect(SessionStorage.instance.userId, isNull);
      expect(SessionStorage.instance.email, isNull);
      expect(SessionStorage.instance.fullName, isNull);
      expect(SessionStorage.instance.surveyCompleted, false);
    });
  });
}
