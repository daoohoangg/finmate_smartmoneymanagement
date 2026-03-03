import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/primary_button.dart';
import 'services/auth_service.dart';

/// Screen 1: User enters email → OTP sent
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  static const String routeName = '/forgot';

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      AppToast.error(context, 'Please enter your email');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.forgotPassword(email);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        '/otp-verify',
        arguments: email,
      );
    } catch (e) {
      if (mounted) AppToast.error(context, AppToast.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reset Password',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your registered email to receive a 6-digit OTP code.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'Email Address',
                    hint: 'example@email.com',
                    keyboardType: TextInputType.emailAddress,
                    controller: _emailController,
                    suffix: const Icon(Icons.mail_outline,
                        color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Send Verification Code',
                    color: AppColors.primaryRed,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleSend,
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.primaryRed, size: 18),
                      label: const Text('Back to Login',
                          style: TextStyle(color: AppColors.primaryRed)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
