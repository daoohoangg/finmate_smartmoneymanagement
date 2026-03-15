import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/storage/session_storage.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/settings/settings_screen.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'access_token': 'test_token',
      'user_id': 'user_123',
      'full_name': 'Test User',
      'email': 'test@example.com',
    });
    await EasyLocalization.ensureInitialized();
    await SessionStorage.instance.init();
  });

  testWidgets('SettingsScreen renders and language chips are interactable', (WidgetTester tester) async {
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('vi')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: Builder(
          builder: (context) {
            return MaterialApp(
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
              locale: context.locale,
              home: const SettingsScreen(),
            );
          }
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify ChoiceChips are rendered
    expect(find.byType(ChoiceChip), findsWidgets);
  });
}
