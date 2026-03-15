import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/network/api_client.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/network/api_exception.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/storage/session_storage.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockHttpClient;
  late ApiClient apiClient;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() async {
    mockHttpClient = MockHttpClient();
    apiClient = ApiClient(client: mockHttpClient);
    
    SharedPreferences.setMockInitialValues({
      'auth_token': 'dummy_token',
      'user_id': 'dummy_id'
    });
    await SessionStorage.instance.init();
  });

  group('ApiClient Tests', () {
    test('GET request attaches headers and parses JSON on 200', () async {
      when(() => mockHttpClient.get(
        any(),
        headers: any(named: 'headers'),
      )).thenAnswer(
        (_) async => http.Response(jsonEncode({'data': 'success'}), 200),
      );

      final result = await apiClient.get('/test');
      
      expect(result, isA<Map>());
      expect(result['data'], 'success');
      
      final captured = verify(() => mockHttpClient.get(
        any(),
        headers: captureAny(named: 'headers'),
      )).captured;
      
      final headers = captured.last as Map<String, String>?;
      expect(headers?['Authorization'], 'Bearer dummy_token');
      expect(headers?['User-Id'], 'dummy_id');
      expect(headers?['Content-Type'], 'application/json');
    });

    test('POST request sends body and throws ApiException on 400', () async {
      when(() => mockHttpClient.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      )).thenAnswer(
        (_) async => http.Response(jsonEncode({'message': 'Validation Failed'}), 400),
      );

      expect(
        () => apiClient.post('/test', body: {'foo': 'bar'}),
        throwsA(
          isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 400)
            .having((e) => e.message, 'message', 'Validation Failed')
        ),
      );
    });

    test('Response parsing handles empty 204 successfully', () async {
      when(() => mockHttpClient.delete(
        any(),
        headers: any(named: 'headers'),
      )).thenAnswer(
        (_) async => http.Response('', 204), // 204 No Content
      );

      final result = await apiClient.delete('/test');
      
      expect(result, isNull);
    });
  });
}
