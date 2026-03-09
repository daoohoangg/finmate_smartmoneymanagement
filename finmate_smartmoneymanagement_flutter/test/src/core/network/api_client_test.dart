import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'dart:convert';
import 'package:finmate_smartmoneymanagement_flutter/src/core/network/api_client.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/network/api_exception.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/constants/api_constants.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/core/storage/session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late ApiClient apiClient;
  late MockHttpClient mockHttpClient;

  setUp(() async {
    mockHttpClient = MockHttpClient();
    apiClient = ApiClient(client: mockHttpClient);
    
    // Setup mock session storage to avoid null pointer exceptions during tests if no token exists
    SharedPreferences.setMockInitialValues({});
    await SessionStorage.instance.init();
    
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  group('ApiClient', () {
    test('get request successful', () async {
      final mockResponse = {'data': 'test_data'};
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await apiClient.get('/test');

      expect(result, equals(mockResponse));
      verify(() => mockHttpClient.get(
            Uri.parse('${ApiConstants.baseUrl}/test'),
            headers: any(named: 'headers'),
          )).called(1);
    });

    test('get request throws ApiException on failure', () async {
      when(() => mockHttpClient.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"message": "Not Found"}', 404));

      expect(() => apiClient.get('/test'), throwsA(isA<ApiException>()));
    });
    
    test('post request successful', () async {
      final mockResponse = {'id': 1};
      final body = {'name': 'test'};
      when(() => mockHttpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 201));

      final result = await apiClient.post('/test', body: body);

      expect(result, equals(mockResponse));
      verify(() => mockHttpClient.post(
            Uri.parse('${ApiConstants.baseUrl}/test'),
            headers: any(named: 'headers'),
            body: jsonEncode(body),
          )).called(1);
    });

    test('put request successful', () async {
      final mockResponse = {'success': true};
      final body = {'name': 'test_updated'};
      when(() => mockHttpClient.put(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await apiClient.put('/test', body: body);

      expect(result, equals(mockResponse));
    });

    test('delete request successful', () async {
      final mockResponse = {'success': true};
      when(() => mockHttpClient.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await apiClient.delete('/test');

      expect(result, equals(mockResponse));
    });
  });
}
