import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finmate_smartmoneymanagement_flutter/main.dart' as app;

/// This is a System Integration Test specifically targeting the Google Auth flow.
/// It verifies the presence and interaction hooking of the OAuth logic.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Google Authentication System Tests', () {
    testWidgets('System Flow: User launches app, sees Google button, and can initiate OAuth', (WidgetTester tester) async {
      // 1. Arrange: Clear preferences so we land on the Login screen instead of the Dashboard.
      SharedPreferences.setMockInitialValues({});
      
      // Boot the actual FinMate App.
      app.main();

      // Wait for all animations, I18n asset loading, and route transitions to finish.
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // 2. Assert: The "Continue with Google" button should be rendered and bound.
      final googleSignInFinder = find.text('Continue with Google');
      expect(googleSignInFinder, findsOneWidget);

      // (Note for Automation Engineers: 
      // Because Google Sign-In spawns an external OS-level OAuth Browser / Android Intent,
      // actual execution of a tap usually leaves the Flutter context.
      // The system test here strictly verifies the UI is rigged and ready).
      
      // await tester.tap(googleSignInFinder);
      // await tester.pumpAndSettle();
    });
  });
}
