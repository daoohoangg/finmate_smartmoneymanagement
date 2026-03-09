import 'package:flutter_test/flutter_test.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/settings/models/user_settings.dart';

void main() {
  group('UserSettings Model', () {
    test('fromJson creates correct instance from valid JSON', () {
      final json = {
        'darkMode': true,
        'language': 'VI',
        'defaultCurrency': 'USD',
        'notificationEnabled': false,
        'budgetAlertThreshold': 90,
        'roundingScale': 0,
        'roundingMode': 'DOWN',
      };

      final settings = UserSettings.fromJson(json);

      expect(settings.darkMode, true);
      expect(settings.language, 'VI');
      expect(settings.defaultCurrency, 'USD');
      expect(settings.notificationEnabled, false);
      expect(settings.budgetAlertThreshold, 90);
      expect(settings.roundingScale, 0);
      expect(settings.roundingMode, 'DOWN');
    });

    test('fromJson handles type conversions and defaults', () {
      final json = {
        // String instead of int
        'budgetAlertThreshold': '75',
        'roundingScale': '3',
      };

      final settings = UserSettings.fromJson(json);

      expect(settings.darkMode, false); // Default
      expect(settings.language, 'EN'); // Default
      expect(settings.defaultCurrency, 'VND'); // Default
      expect(settings.notificationEnabled, false); // Default
      expect(settings.budgetAlertThreshold, 75); // Parsed from String
      expect(settings.roundingScale, 3); // Parsed from String
      expect(settings.roundingMode, 'HALF_UP'); // Default
    });

    test('toJson returns correct map', () {
      final settings = UserSettings(
        darkMode: true,
        language: 'VI',
        defaultCurrency: 'USD',
        notificationEnabled: true,
        budgetAlertThreshold: 85,
        roundingScale: 1,
        roundingMode: 'UP',
      );

      final json = settings.toJson();

      expect(json['darkMode'], true);
      expect(json['language'], 'VI');
      expect(json['defaultCurrency'], 'USD');
      expect(json['notificationEnabled'], true);
      expect(json['budgetAlertThreshold'], 85);
      expect(json['roundingScale'], 1);
      expect(json['roundingMode'], 'UP');
    });
  });
}
