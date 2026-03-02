/// Centralized app configuration.
/// All secrets are injected at build/run time via `--dart-define` or `--dart-define-from-file=.env`.
///
/// Usage:
///   flutter run --dart-define-from-file=.env
///   flutter run --dart-define=GOOGLE_WEB_CLIENT_ID=your-id-here
class AppConfig {
  AppConfig._();

  /// Google OAuth Web Client ID.
  /// Required for Google Sign-In on Web platform.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );
}
