import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum ToastType { success, error, info }

class AppToast {
  /// Show a slide-down top toast that auto-dismisses after [duration].
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismiss: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  static void success(BuildContext context, String message) =>
      show(context, message, type: ToastType.success);

  static void error(BuildContext context, String message) =>
      show(context, message, type: ToastType.error);

  static void info(BuildContext context, String message) =>
      show(context, message, type: ToastType.info);

  /// Convert raw API/system errors to user-friendly messages.
  static String friendlyMessage(Object error) {
    final raw = error.toString().toLowerCase();

    // Network
    if (raw.contains('failed to fetch') ||
        raw.contains('clientexception') ||
        raw.contains('sockettimeout') ||
        raw.contains('connection refused')) {
      return 'Cannot connect to server. Please check your internet connection.';
    }

    // Auth
    if (raw.contains('invalid email or password') ||
        raw.contains('bad credentials')) {
      return 'Incorrect email or password.';
    }
    if (raw.contains('email already') || raw.contains('duplicate')) {
      return 'This email is already registered.';
    }
    if (raw.contains('invalid or expired otp') || raw.contains('otp')) {
      return 'OTP code is invalid or has expired. Please try again.';
    }
    if (raw.contains('invalid or expired reset token') ||
        raw.contains('reset token')) {
      return 'The session has expired. Please restart the password reset process.';
    }
    if (raw.contains('user not found')) {
      return 'No account found with this email.';
    }
    if (raw.contains('unauthorized') || raw.contains('403')) {
      return 'You are not authorized to perform this action.';
    }

    // Mail
    if (raw.contains('failed to send')) {
      return 'Could not send verification email. Please try again later.';
    }

    // Password
    if (raw.contains('do not match')) {
      return 'Passwords do not match.';
    }
    if (raw.contains('at least 6') || raw.contains('too short')) {
      return 'Password must be at least 6 characters.';
    }

    // Generic server errors — never expose raw system errors
    if (raw.contains('500') ||
        raw.contains('apiexception') ||
        raw.contains('exception') ||
        raw.contains('error')) {
      return 'Something went wrong. Please try again.';
    }

    return message.length > 80 ? 'Something went wrong. Please try again.' : message;
  }

  static String get message => '';
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final ToastType type;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFF16A34A);
      case ToastType.error:
        return const Color(0xFFDC2626);
      case ToastType.info:
        return AppColors.primaryBlue;
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 12;
    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnim,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _bgColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _bgColor.withAlpha(100),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_icon, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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
