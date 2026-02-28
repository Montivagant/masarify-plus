import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/ai_config.dart';

/// Response from OpenRouter chat completion API.
class OpenRouterResponse {
  const OpenRouterResponse({required this.content, required this.tokensUsed});

  final String content;
  final int tokensUsed;
}

/// Exception for OpenRouter API errors.
class OpenRouterException implements Exception {
  const OpenRouterException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  bool get isRateLimit => statusCode == 429;
  bool get isUnauthorized => statusCode == 401;
  bool get isServerError => statusCode >= 500;

  @override
  String toString() => 'OpenRouterException($statusCode): $message';
}

/// HTTP client for OpenRouter chat completions API.
class OpenRouterService {
  const OpenRouterService();

  /// Sends a chat completion request to OpenRouter.
  ///
  /// Returns the parsed response content and token usage.
  /// Throws [OpenRouterException] on API errors.
  Future<OpenRouterResponse> chatCompletion({
    required String systemPrompt,
    required String userMessage,
    String? model,
    double temperature = 0.2,
  }) async {
    final uri = Uri.parse('${AiConfig.openRouterBaseUrl}/chat/completions');

    final body = jsonEncode({
      'model': model ?? AiConfig.defaultModel,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userMessage},
      ],
      'response_format': {'type': 'json_object'},
      'temperature': temperature,
      'max_tokens': AiConfig.maxResponseTokens,
      'provider': {'zdr': true},
    });

    final response = await http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer ${AiConfig.openRouterApiKey}',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://masarify.app',
            'X-Title': 'Masarify',
          },
          body: body,
        )
        .timeout(const Duration(seconds: AiConfig.apiTimeoutSeconds));

    if (response.statusCode != 200) {
      // Sanitize: only include status code and error category,
      // never the raw body which may echo request content (bank SMS text).
      final category = response.statusCode == 429
          ? 'rate_limit'
          : response.statusCode == 401
              ? 'unauthorized'
              : response.statusCode >= 500
                  ? 'server_error'
                  : 'client_error';
      throw OpenRouterException(
        response.statusCode,
        'API error: $category (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = json['choices'] as List<dynamic>;
    if (choices.isEmpty) {
      throw const OpenRouterException(500, 'Empty choices array');
    }

    final message = choices[0]['message'] as Map<String, dynamic>;
    final content = message['content'] as String? ?? '';

    final usage = json['usage'] as Map<String, dynamic>?;
    final tokensUsed = (usage?['total_tokens'] as int?) ?? 0;

    return OpenRouterResponse(content: content, tokensUsed: tokensUsed);
  }
}
