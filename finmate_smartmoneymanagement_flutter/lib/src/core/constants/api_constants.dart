import 'package:flutter/foundation.dart';

import '../platform/platform_utils.dart';

class ApiConstants {
  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    const configured = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (configured.isNotEmpty) {
      return configured;
    }
    if (kIsWeb) {
      final host = Uri.base.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
        return 'http://localhost:8080';
      }
      return Uri.base.origin;
    }
    if (isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}
