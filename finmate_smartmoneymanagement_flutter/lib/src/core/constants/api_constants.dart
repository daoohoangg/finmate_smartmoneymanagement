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
      return 'http://localhost:8080';
    }
    if (isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}
