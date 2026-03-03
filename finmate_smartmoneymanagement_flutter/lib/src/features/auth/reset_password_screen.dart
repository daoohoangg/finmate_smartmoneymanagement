import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/primary_button.dart';
import 'login_screen.dart';
import 'services/auth_service.dart';

/// Screen 3: User sets new password using the reset token
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});
  static const String routeName = '/reset-password';
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}
class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  late String _resetToken;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resetToken =
        ModalRoute.of(context)!.settings.arguments as String? ?? '';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.isEmpty || confirm.isEmpty) {
      AppToast.error(context, 'Please fill in all fields');
      return;
    }
    if (password != confirm) {
      AppToast.error(context, 'Passwords do not match');
      return;
    }
    if (password.length < 6) {
      AppToast.error(context, 'Password must be at least 6 characters');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(
        resetToken: _resetToken,
        newPassword: password,
      );
      if (!mounted) return;
      AppToast.success(context, 'Password reset successfully! Please log in.');
      Navigator.pushNamedAndRemoveUntil(
        context,
        LoginScreen.routeName,
        (route) => false,
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
        title: const Text('Set New Password'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_reset_outlined,
                        size: 40, color: AppColors.primaryBlue),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Create New Password',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your new password must be at least 6 characters.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 28),
                  AppTextField(
                    label: 'New Password',
                    hint: 'Enter new password',
                    obscureText: _obscurePassword,
                    controller: _passwordController,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Confirm Password',
                    hint: 'Re-enter new password',
                    obscureText: _obscureConfirm,
                    controller: _confirmController,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  const SizedBox(height: 28),
                  PrimaryButton(
                    label: 'Reset Password',
                    color: AppColors.primaryBlue,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleReset,
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
