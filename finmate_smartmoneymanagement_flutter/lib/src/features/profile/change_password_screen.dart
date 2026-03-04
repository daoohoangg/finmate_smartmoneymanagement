import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import 'services/profile_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  static const String routeName = '/change-password';

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _profileService = ProfileService();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentPassword = _currentController.text.trim();
    final newPassword = _newController.text.trim();
    final confirmPassword = _confirmController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      _showSnack('Please fill in all fields');
      return;
    }
    if (newPassword.length < 6) {
      _showSnack('New password must be at least 6 characters');
      return;
    }
    if (newPassword != confirmPassword) {
      _showSnack('New passwords do not match');
      return;
    }
    if (currentPassword == newPassword) {
      _showSnack('New password must be different from current password');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _profileService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      if (!mounted) return;
      _showSnack('Password changed successfully');
      Navigator.pop(context);
    } catch (e) {
      _showSnack(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      bottomNavigationBar: const FinMateBottomNav(active: FinMateNavItem.utilities),
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
                    'Update your password',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose a strong password to keep your account secure.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Current Password',
                    hint: 'Enter current password',
                    obscureText: _obscureCurrent,
                    controller: _currentController,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureCurrent = !_obscureCurrent;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'New Password',
                    hint: 'Enter new password',
                    obscureText: _obscureNew,
                    controller: _newController,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureNew ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNew = !_obscureNew;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Confirm New Password',
                    hint: 'Re-enter new password',
                    obscureText: _obscureConfirm,
                    controller: _confirmController,
                    suffix: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Save Changes',
                    color: AppColors.primaryRed,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _submit,
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
