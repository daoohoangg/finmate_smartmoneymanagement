import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../core/constants/app_colors.dart';
import '../../core/config/app_config.dart';
import '../../core/storage/session_storage.dart';
import '../dashboard/monthly_dashboard_screen.dart';
import 'services/auth_service.dart';
import 'services/google_sign_in_service.dart';
import '../../shared/widgets/app_text_field.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/primary_button.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const String routeName = '/login';

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      AppToast.error(context, 'email_password_required'.tr());
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );
      await SessionStorage.instance.saveAuth(
        token: response.token,
        userId: response.userId,
        email: response.email,
        fullName: response.fullName,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, MonthlyDashboardScreen.routeName);
    } catch (e) {
      if (mounted) AppToast.error(context, AppToast.friendlyMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      print('--- GOOGLE SIGN IN DEBUG ---');
      print('GOOGLE_WEB_CLIENT_ID: "${AppConfig.googleWebClientId}"');
      
      if (AppConfig.googleWebClientId.isEmpty) {
        if (mounted) {
          AppToast.error(context, 'Missing GOOGLE_WEB_CLIENT_ID! Please select the "Android" / "Windows" Run Config or add --dart-define-from-file=..\\.env');
        }
        return;
      }
      
      // Use GoogleSignInService to get token result
      final result = await GoogleSignInService.instance.signIn();
      if (result == null || !result.isValid) {
        if (mounted) AppToast.info(context, 'sign_in_cancelled'.tr());
        return;
      }

      // Send token to backend for authentication
      // On web: sends accessToken, on mobile/desktop: sends idToken
      final response = await _authService.loginWithGoogle(
        idToken: result.idToken,
        accessToken: result.accessToken,
      );
      await SessionStorage.instance.saveAuth(
        token: response.token,
        userId: response.userId,
        email: response.email,
        fullName: response.fullName,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, MonthlyDashboardScreen.routeName);
    } catch (e, stackTrace) {
      print('================ GOOGLE SIGN IN ERROR ================');
      print(e);
      print(stackTrace);
      print('======================================================');
      if (mounted) AppToast.error(context, AppToast.friendlyMessage(e));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.page,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Personal Finance',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'welcome_back'.tr(),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'log_in_to_track'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      label: 'email'.tr(),
                      hint: 'name@example.com',
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'password'.tr(),
                      hint: 'password'.tr(),
                      obscureText: _obscurePassword,
                      controller: _passwordController,
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            ForgotPasswordScreen.routeName,
                          );
                        },
                        child: Text('forgot_password'.tr()),
                      ),
                    ),
                    const SizedBox(height: 4),
                    PrimaryButton(
                      label: 'login'.tr(),
                      color: AppColors.primaryBlue,
                      isLoading: _isLoading,
                      onPressed: _isLoading ? null : _handleLogin,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or_continue_with'.tr(),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                        ),
                        label: Text(
                          'continue_with_google'.tr(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              RegisterScreen.routeName,
                            );
                          },
                          child: const Text('Create Account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
