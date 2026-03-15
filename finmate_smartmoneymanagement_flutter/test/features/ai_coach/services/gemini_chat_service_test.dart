import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/ai_coach/services/gemini_chat_service.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late MockHttpClient mockHttpClient;
  late GeminiChatService geminiService;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://localhost'));
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    geminiService = GeminiChatService(client: mockHttpClient);
  });

  group('GeminiChatService Exception Tests', () {
    test('Throws exception on HTTP error', () async {
      when(() => mockHttpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response('Error', 400));

      expect(
        () => geminiService.sendMessage(userMessage: 'Hello'),
        throwsA(isA<GeminiChatException>()),
      );
    });

    test('Throws exception on blocked content', () async {
      when(() => mockHttpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode({
                'candidates': [],
                'promptFeedback': {'blockReason': 'SAFETY'}
              }), 200));

      expect(
        () => geminiService.sendMessage(userMessage: 'Hello'),
        throwsA(
          isA<GeminiChatException>().having((e) => e.message, 'message', contains('SAFETY')),
        ),
      );
    });
  });

  group('GeminiChatService Success Tests', () {
    test('Successfully extracts and formats text from API response', () async {
      final mockResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Hello World\n• Point 1'}
              ]
            }
          }
        ]
      };

      when(() => mockHttpClient.post(any(), headers: any(named: 'headers'), body: any(named: 'body')))
          .thenAnswer((_) async => http.Response(jsonEncode(mockResponse), 200));

      final result = await geminiService.sendMessage(userMessage: 'Test');

      expect(result, contains('Hello World'));
      expect(result, contains('• Point 1'));
    });
  });

  group('GeminiTurn Tests', () {
    test('toApiJson formats correctly for user', () {
      const turn = GeminiTurn(isUser: true, text: 'Hello');
      final json = turn.toApiJson();
      expect(json['role'], 'user');
      expect(json['parts'][0]['text'], 'Hello');
    });

    test('toApiJson formats correctly for model', () {
      const turn = GeminiTurn(isUser: false, text: 'Hi there');
      final json = turn.toApiJson();
      expect(json['role'], 'model');
      expect(json['parts'][0]['text'], 'Hi there');
    });
  });
}
