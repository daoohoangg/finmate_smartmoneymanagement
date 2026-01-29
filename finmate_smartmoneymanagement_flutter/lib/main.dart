import 'package:flutter/material.dart';

import 'src/core/theme/app_theme.dart';
import 'src/features/auth/forgot_password_screen.dart';
import 'src/features/auth/login_screen.dart';
import 'src/features/auth/register_screen.dart';
import 'src/features/settings/settings_screen.dart';

void main() {
  runApp(const FinMateApp());
}

class FinMateApp extends StatelessWidget {
  const FinMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FinMate',
      theme: buildAppTheme(),
      initialRoute: LoginScreen.routeName,
      routes: {
        LoginScreen.routeName: (_) => const LoginScreen(),
        RegisterScreen.routeName: (_) => const RegisterScreen(),
        ForgotPasswordScreen.routeName: (_) => const ForgotPasswordScreen(),
        SettingsScreen.routeName: (_) => const SettingsScreen(),
      },
    );
  }
}
