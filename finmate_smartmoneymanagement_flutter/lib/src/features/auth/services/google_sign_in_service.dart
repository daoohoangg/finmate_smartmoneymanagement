import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/config/app_config.dart';

/// Result of Google Sign-In containing either idToken or accessToken
class GoogleSignInResult {
  final String? idToken;
  final String? accessToken;

  GoogleSignInResult({this.idToken, this.accessToken});

  bool get isValid => idToken != null || accessToken != null;
}

/// Service wrapper for Google Sign-In functionality.
/// Handles platform-specific differences between Web and Mobile/Desktop.
class GoogleSignInService {
  GoogleSignInService._();
  static final GoogleSignInService instance = GoogleSignInService._();

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? AppConfig.googleWebClientId : null,
    serverClientId: kIsWeb ? null : AppConfig.googleWebClientId,
    scopes: ['email', 'profile'],
  );

  /// Attempts to sign in silently (if user has previously signed in).
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      return null;
    }
  }

  /// Initiates Google Sign-In flow and returns the result.
  /// On web, returns accessToken. On mobile/desktop, returns idToken.
  Future<GoogleSignInResult?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;
      
      if (kIsWeb) {
        // On web, use accessToken since idToken is not reliably provided
        return GoogleSignInResult(accessToken: auth.accessToken);
      } else {
        // On mobile/desktop, use idToken
        return GoogleSignInResult(idToken: auth.idToken);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  /// Disconnects the user (revokes access).
  Future<void> disconnect() async {
    await _googleSignIn.disconnect();
  }

  /// Checks if user is currently signed in.
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Gets the current signed-in account.
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Gets the GoogleSignIn instance for advanced usage.
  GoogleSignIn get googleSignIn => _googleSignIn;
}
