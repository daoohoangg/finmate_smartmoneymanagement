import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/app_toast.dart';
import '../../shared/widgets/primary_button.dart';
import 'reset_password_screen.dart';
import 'services/auth_service.dart';

/// Screen 2: User enters OTP received in email
class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  static const String routeName = '/otp-verify';

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _authService = AuthService();
  bool _isLoading = false;
  bool _isResending = false;
  int _secondsLeft = 600; // 10 minutes
  Timer? _timer;
  late String _email;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _email = ModalRoute.of(context)!.settings.arguments as String? ?? '';
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 600;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_secondsLeft == 0) {
        t.cancel();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _handleVerify() async {
    if (_otp.length < 6) {
      AppToast.error(context, 'Please enter the 6-digit code');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final resetToken = await _authService.verifyOtp(
        email: _email,
        otp: _otp,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        ResetPasswordScreen.routeName,
        arguments: resetToken,
      );
    } catch (e) {
      if (mounted) AppToast.error(context, AppToast.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResend() async {
    setState(() => _isResending = true);
    try {
      await _authService.forgotPassword(_email);
      _startTimer();
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes.first.requestFocus();
      if (mounted) AppToast.success(context, 'New OTP sent to $_email');
    } catch (e) {
      if (mounted) AppToast.error(context, AppToast.friendlyMessage(e));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter OTP'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryRed.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mark_email_read_outlined,
                        size: 48, color: AppColors.primaryRed),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Check your email',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit code to\n$_email',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 32),

                  // 6-digit OTP input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 48,
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            counterText: '',
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: AppColors.primaryRed, width: 2),
                            ),
                          ),
                          onChanged: (v) {
                            if (v.isNotEmpty && i < 5) {
                              _focusNodes[i + 1].requestFocus();
                            } else if (v.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 16),

                  // Timer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        _secondsLeft > 0
                            ? 'Code expires in $_timerText'
                            : 'Code expired',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _secondsLeft > 60
                                  ? AppColors.textSecondary
                                  : Colors.red,
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  PrimaryButton(
                    label: 'Verify Code',
                    color: AppColors.primaryRed,
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleVerify,
                  ),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: (_isResending || _secondsLeft > 540)
                        ? null
                        : _handleResend,
                    child: _isResending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Didn't receive the code? Resend"),
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
