import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiChatService {
  GeminiChatService({http.Client? client}) : _client = client ?? http.Client();

  static const String _model = 'gemini-3-flash-preview';
  static const String _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyCzl2XuDH2CfUlqK11kbHBL9MELvakZXPU',
  );
  static const String _systemPrompt =
      'You are FinMate AI, a personal finance coach. '
      'Give practical steps, bullet points when needed, and mention risks clearly. '
      'Provide detailed and helpful explanations. Respond in English.';

  final http.Client _client;

  Future<String> sendMessage({
    required String userMessage,
    List<GeminiTurn> history = const <GeminiTurn>[],
  }) async {
    final apiKey = _apiKey.trim();
    if (apiKey.isEmpty) {
      throw GeminiChatException(
        'Missing Gemini API key. Start app with --dart-define=GEMINI_API_KEY=YOUR_KEY',
      );
    }

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey',
    );

    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [
          {'text': _systemPrompt},
        ],
      },
      ...history.map((item) => item.toApiJson()),
      {
        'role': 'user',
        'parts': [
          {'text': userMessage},
        ],
      },
    ];

    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.6,
          'topP': 0.9,
          'maxOutputTokens': 900,
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw GeminiChatException(
        'Gemini request failed (${response.statusCode}): ${response.body}',
      );
    }

    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (_) {
      throw GeminiChatException('Invalid Gemini response format');
    }

    if (data is! Map<String, dynamic>) {
      throw GeminiChatException('Unexpected Gemini response body');
    }

    final candidates = data['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      final blockReason = _extractBlockReason(data);
      if (blockReason != null && blockReason.isNotEmpty) {
        throw GeminiChatException('Gemini blocked response: $blockReason');
      }
      throw GeminiChatException('Gemini did not return any candidate');
    }

    final first = candidates.first;
    if (first is! Map) {
      throw GeminiChatException('Unexpected Gemini candidate format');
    }

    final content = first['content'];
    if (content is! Map) {
      throw GeminiChatException('Missing Gemini content');
    }

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      throw GeminiChatException('Gemini response is empty');
    }

    final texts = <String>[];
    for (final part in parts) {
      if (part is Map && part['text'] != null) {
        final text = part['text'].toString().trim();
        if (text.isNotEmpty) {
          texts.add(text);
        }
      }
    }

    if (texts.isEmpty) {
      throw GeminiChatException('Gemini returned no readable text');
    }
    
    final rawText = texts.join('\n').trim();
    return _formatResponseText(rawText);
  }

  String _formatResponseText(String text) {
    var formatted = text;
    // Remove markdown headers
    formatted = formatted.replaceAll(RegExp(r'^#+\s*', multiLine: true), '');
    // Remove markdown bold
    formatted = formatted.replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1');
    // Ensure consistent bullet points
    formatted = formatted.replaceAll(RegExp(r'^\*\s+', multiLine: true), '• ');
    formatted = formatted.replaceAll(RegExp(r'^-\s+', multiLine: true), '• ');
    // Condense multiple newlines
    formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return formatted.trim();
  }

  String? _extractBlockReason(Map<String, dynamic> data) {
    final promptFeedback = data['promptFeedback'];
    if (promptFeedback is Map && promptFeedback['blockReason'] != null) {
      return promptFeedback['blockReason'].toString();
    }
    return null;
  }
}

class GeminiTurn {
  const GeminiTurn({required this.isUser, required this.text});

  final bool isUser;
  final String text;

  Map<String, dynamic> toApiJson() {
    return {
      'role': isUser ? 'user' : 'model',
      'parts': [
        {'text': text},
      ],
    };
  }
}

class GeminiChatException implements Exception {
  GeminiChatException(this.message);

  final String message;

  @override
  String toString() => message;
}
