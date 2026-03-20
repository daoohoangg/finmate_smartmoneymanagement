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
    
    final String successHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Login successful - FinMate</title>
  <style>
    body { font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background: linear-gradient(135deg, #e0c3fc 0%, #8ec5fc 100%); display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; color: #333; }
    .container { background-color: white; padding: 40px 50px; border-radius: 24px; box-shadow: 0 15px 35px rgba(0,0,0,0.1); text-align: center; max-width: 400px; animation: fadeIn 0.6s cubic-bezier(0.22, 1, 0.36, 1); }
    @keyframes fadeIn { from { opacity: 0; transform: translateY(20px) scale(0.95); } to { opacity: 1; transform: translateY(0) scale(1); } }
    .icon { background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%); color: white; width: 80px; height: 80px; border-radius: 50%; display: flex; justify-content: center; align-items: center; margin: 0 auto 20px; font-size: 36px; box-shadow: 0 10px 20px rgba(0,198,255,0.3); }
    h1 { font-size: 26px; margin: 0 0 10px; color: #1a1a1a; font-weight: 700; }
    p { font-size: 15px; color: #666; line-height: 1.6; margin: 0 0 30px; }
    .btn { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border: none; padding: 12px 28px; border-radius: 10px; font-size: 15px; font-weight: 600; cursor: pointer; transition: transform 0.2s, box-shadow 0.2s; box-shadow: 0 4px 15px rgba(118,75,162,0.3); }
    .btn:hover { transform: translateY(-2px); box-shadow: 0 6px 20px rgba(118,75,162,0.4); }
  </style>
</head>
<body>
  <div class="container">
    <div class="icon">✓</div>
    <h1>Login complete!</h1>
    <p>Your Google account has been securely authenticated by FinMate. You can close this browser and return to the app.</p>
    <button class="btn" onclick="window.close()">Return to app</button>
  </div>
  <script>setTimeout(function() { window.close(); }, 4000);</script>
</body>
</html>
''';

    request.response
      ..statusCode = 200
      ..headers.set('Content-Type', 'text/html; charset=utf-8')
      ..write(successHtml);
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
