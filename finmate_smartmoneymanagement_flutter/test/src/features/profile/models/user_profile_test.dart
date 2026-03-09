import 'package:flutter_test/flutter_test.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/profile/models/user_profile.dart';

void main() {
  group('UserProfile Model', () {
    test('fromJson creates correct instance from valid JSON', () {
      final json = {
        'userId': '123',
        'email': 'user@example.com',
        'fullName': 'Test Profile',
        'hasAvatar': true,
      };

      final profile = UserProfile.fromJson(json);

      expect(profile.userId, '123');
      expect(profile.email, 'user@example.com');
      expect(profile.fullName, 'Test Profile');
      expect(profile.hasAvatar, true);
    });

    test('fromJson handles null or missing fields gracefully', () {
      final json = <String, dynamic>{};

      final profile = UserProfile.fromJson(json);

      expect(profile.userId, '');
      expect(profile.email, '');
      expect(profile.fullName, '');
      expect(profile.hasAvatar, false); // Defaults to false
    });
  });
}
