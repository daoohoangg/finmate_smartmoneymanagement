import 'package:flutter/material.dart';
import '../services/google_sign_in_service.dart';


class GoogleSignInButton extends StatefulWidget {
  final void Function({String? idToken, String? accessToken}) onSuccess;
  final void Function(String error) onError;
  final bool isLoading;

  const GoogleSignInButton({
    super.key,
    required this.onSuccess,
    required this.onError,
    this.isLoading = false,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _isSigningIn = false;

  Future<void> _handleSignIn() async {
    if (_isSigningIn || widget.isLoading) return;
    
    setState(() => _isSigningIn = true);
    
    try {
      final result = await GoogleSignInService.instance.signIn();
      if (result != null && result.isValid) {
        widget.onSuccess(
          idToken: result.idToken,
          accessToken: result.accessToken,
        );
      } else {
        widget.onError('Sign-in was cancelled');
      }
    } catch (e) {
      widget.onError(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isSigningIn || widget.isLoading;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: isLoading ? null : _handleSignIn,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5E7EB)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Google Logo
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Center(
                      child: Text(
                        'G',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Continue with Google',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}
