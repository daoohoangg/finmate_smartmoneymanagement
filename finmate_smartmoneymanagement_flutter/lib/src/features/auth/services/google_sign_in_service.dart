import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
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
  /// On Windows desktop, uses desktop_webview_auth and returns accessToken.
  Future<GoogleSignInResult?> signIn() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        return await _performWindowsDesktopSignIn();
      }

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
  
  /// Performs the custom OAuth 2.0 loopback flow for Windows Desktop.
  Future<GoogleSignInResult?> _performWindowsDesktopSignIn() async {
    // 1. Create a local HTTP server to listen for the redirect
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final redirectUri = 'http://127.0.0.1:${server.port}';

    // 2. Launch the OAuth URL in the user's default browser
    final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': AppConfig.googleWindowsClientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'email profile openid',
      // Include code challenge parameters here if using PKCE (recommended but we will skip for simplicity here unless required)
    });

    if (await canLaunchUrl(authUrl)) {
      await launchUrl(authUrl, mode: LaunchMode.externalApplication);
    } else {
      server.close();
      throw Exception('Could not launch browser for authentication.');
    }

    // 3. Wait for the redirect request
    HttpRequest? request;
    try {
      request = await server.first;
    } catch (e) {
      server.close();
      return null;
    }

    // 4. Extract the code and show success page
    final code = request.uri.queryParameters['code'];
    
    request.response
      ..statusCode = 200
      ..headers.set('Content-Type', 'text/html; charset=utf-8')
      ..write('<html><body><h1>Authentication Successful</h1><p>You can close this tab and return to the app.</p><script>window.close();</script></body></html>');
    await request.response.close();
    await server.close();

    if (code == null) return null; // User cancelled or error

    // 5. Exchange the authorization code for an ID Token / Access Token
    final tokenResponse = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      body: {
        'code': code,
        'client_id': AppConfig.googleWindowsClientId,
        'client_secret': AppConfig.googleWindowsClientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
    );

    if (tokenResponse.statusCode == 200) {
      final data = jsonDecode(tokenResponse.body);
      final idToken = data['id_token'];
      final accessToken = data['access_token'];
      // For desktop, idToken is usually preferred by the backend
      return GoogleSignInResult(idToken: idToken, accessToken: accessToken);
    } else {
      throw Exception('Failed to exchange code for token: ${tokenResponse.body}');
    }
  }
}
