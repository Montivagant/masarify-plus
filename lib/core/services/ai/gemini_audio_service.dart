import 'dart:convert';
import 'dart:developer' as dev;

import 'package:http/http.dart' as http;

import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/savings_goal_entity.dart';
import '../../config/ai_config.dart';
import '../../utils/voice_transaction_parser.dart';

/// Exception thrown by [GeminiAudioService].
class GeminiAudioException implements Exception {
  const GeminiAudioException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isRateLimit => statusCode == 429;
  bool get isUnauthorized => statusCode == 401 || statusCode == 403;
  bool get isServerError => (statusCode ?? 0) >= 500;

  @override
  String toString() => 'GeminiAudioException($statusCode): $message';
}

/// Sends audio bytes to the Gemini REST API for transcription + transaction
/// parsing in a single call. Returns structured [VoiceTransactionDraft] list.
class GeminiAudioService {
  const GeminiAudioService();

  /// Transcribes and parses audio into transaction drafts.
  ///
  /// [audioBytes] — raw WAV audio data from the recorder.
  /// [mimeType] — MIME type of the audio (e.g. `audio/wav`).
  /// [categories] — user's categories for icon matching.
  /// [goals] — user's active savings goals for goal matching.
  Future<List<VoiceTransactionDraft>> parseAudio({
    required List<int> audioBytes,
    required String mimeType,
    required List<CategoryEntity> categories,
    required List<SavingsGoalEntity> goals,
  }) async {
    if (!AiConfig.hasGoogleAiKey) {
      throw const GeminiAudioException(
        'No Google AI API key configured',
        statusCode: 401,
      );
    }

    final base64Audio = base64Encode(audioBytes);
    final url = Uri.parse(
      '${AiConfig.geminiBaseUrl}/models/${AiConfig.geminiAudioModel}'
      ':generateContent?key=${AiConfig.googleAiApiKey}',
    );

    final systemPrompt = _buildSystemPrompt(categories, goals);

    final body = jsonEncode({
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        {
          'parts': [
            {
              'text': 'Transcribe the following audio and parse any financial '
                  'transactions mentioned. Return JSON only.',
            },
            {
              'inline_data': {
                'mime_type': mimeType,
                'data': base64Audio,
              },
            },
          ],
        },
      ],
      'generation_config': {
        'response_mime_type': 'application/json',
        'temperature': 0.2,
      },
    });

    dev.log(
      'Sending ${audioBytes.length} bytes ($mimeType) to Gemini',
      name: 'GeminiAudioService',
    );

    final response = await http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(
          const Duration(seconds: AiConfig.geminiAudioTimeoutSeconds),
        );

    dev.log(
      'Gemini response: ${response.statusCode}',
      name: 'GeminiAudioService',
    );

    if (response.statusCode != 200) {
      dev.log(
        'Gemini error ${response.statusCode}: '
        '${response.body.substring(0, response.body.length.clamp(0, 500))}',
        name: 'GeminiAudioService',
      );
      final errorBody = _tryParseError(response.body);
      throw GeminiAudioException(
        errorBody ?? 'HTTP ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final drafts = _parseResponse(response.body, categories);
    if (drafts.isEmpty) {
      dev.log(
        'Gemini returned 200 but no transactions were parsed',
        name: 'GeminiAudioService',
      );
    }
    return drafts;
  }

  // ── Response parsing ────────────────────────────────────────────────────

  List<VoiceTransactionDraft> _parseResponse(
    String responseBody,
    List<CategoryEntity> categories,
  ) {
    final dynamic json;
    try {
      json = jsonDecode(responseBody);
    } on FormatException {
      dev.log('Failed to decode Gemini response', name: 'GeminiAudioService');
      return [];
    }

    // Extract text content from Gemini response envelope.
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return [];

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    if (content == null) return [];

    final parts = content['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return [];

    final text = parts[0]['text'] as String?;
    if (text == null || text.trim().isEmpty) return [];

    dev.log(
      'Gemini content: ${text.substring(0, text.length.clamp(0, 200))}',
      name: 'GeminiAudioService',
    );

    // Parse the JSON transaction payload.
    final dynamic decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      dev.log('Failed to parse transaction JSON', name: 'GeminiAudioService');
      return [];
    }

    if (decoded is! Map<String, dynamic>) return [];
    final transactions = decoded['transactions'] as List<dynamic>?;
    if (transactions == null || transactions.isEmpty) return [];

    final drafts = <VoiceTransactionDraft>[];
    for (final tx in transactions) {
      if (tx is! Map<String, dynamic>) continue;

      final amountRaw = tx['amount_egp'];
      final int? amountPiastres =
          amountRaw != null ? _toPiastres(amountRaw) : null;

      final type = (tx['type'] as String?) ?? 'expense';
      var categoryIcon = tx['category_icon'] as String?;
      final note = tx['note'] as String?;
      final dateOffset = (tx['date_offset'] as int?) ?? 0;

      // Validate category_icon against type-filtered categories.
      if (categoryIcon != null && categories.isNotEmpty) {
        final validIcons = categories
            .where((c) => c.type == type || c.type == 'both')
            .map((c) => c.iconName)
            .toSet();
        if (!validIcons.contains(categoryIcon)) {
          categoryIcon = null;
        }
      }

      drafts.add(
        VoiceTransactionDraft(
          rawText: note ?? '',
          amountPiastres: amountPiastres,
          categoryHint: categoryIcon,
          note: note,
          type: type,
          dateOffset: dateOffset,
        ),
      );
    }

    dev.log(
      'Parsed ${drafts.length} transaction drafts',
      name: 'GeminiAudioService',
    );
    return drafts;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Convert an amount (num or String from JSON) to piastres without
  /// floating-point precision errors.
  static int _toPiastres(dynamic amountRaw) {
    final amountStr = amountRaw.toString();
    final parts = amountStr.split('.');
    final pounds = int.tryParse(parts[0]) ?? 0;
    var piastres = 0;
    if (parts.length > 1) {
      final frac = parts[1].padRight(2, '0').substring(0, 2);
      piastres = int.tryParse(frac) ?? 0;
    }
    return pounds * 100 + piastres;
  }

  String? _tryParseError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final error = json['error'] as Map<String, dynamic>?;
      return error?['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _buildSystemPrompt(
    List<CategoryEntity> categories,
    List<SavingsGoalEntity> goals,
  ) {
    final categoriesJson = jsonEncode(
      categories
          .map(
            (c) => {
              'iconName': c.iconName,
              'name': c.name,
              'nameAr': c.nameAr,
              'type': c.type,
            },
          )
          .toList(),
    );

    final goalsJson = jsonEncode(
      goals
          .map(
            (g) => {
              'name': g.name,
              'keywords': g.keywords,
            },
          )
          .toList(),
    );

    return _systemPromptTemplate
        .replaceAll('{{CATEGORIES_JSON}}', categoriesJson)
        .replaceAll('{{GOALS_JSON}}', goalsJson);
  }

  static const _systemPromptTemplate = '''
You are a financial transaction parser for an Egyptian personal finance app called Masarify.
Your job is to TRANSCRIBE the audio and parse any financial transactions mentioned into structured JSON.

RULES:
1. Return ONLY valid JSON. No markdown, no explanation, no code fences.
2. First transcribe the audio, then extract transactions from the transcription.
3. Egyptian Arabic amounts: مية=100, ميتين=200, تلتمية=300, ربعمية=400, خمسمية=500, الف=1000, الفين=2000, نص=0.50
4. Default type is "expense" unless income triggers are detected (e.g. اتقبضت, راتب, مرتب, salary, income, received, earned)
5. Split multiple transactions on conjunctions (وبعدين, وكمان, و, and, then, also)
6. category_icon MUST be one of the iconName values from AVAILABLE CATEGORIES. Match expense categories for expenses, income categories for income
7. Date offsets: امبارح/أمس/yesterday=-1, النهارده/اليوم/today=0, من اسبوع=-7, من يومين=-2
8. Confidence 0.0-1.0 per transaction (how sure you are about the parsing)
9. If text relates to one of the user's savings goals, set goal_match to the goal name
10. If amount is unclear, set amount_egp to 0
11. Always set a note — use the relevant portion of transcript

AVAILABLE CATEGORIES:
{{CATEGORIES_JSON}}

USER'S ACTIVE SAVINGS GOALS:
{{GOALS_JSON}}

RESPONSE SCHEMA:
{
  "transactions": [
    {
      "amount_egp": <number>,
      "type": "expense" | "income",
      "category_icon": "<iconName from categories list>",
      "note": "<short description>",
      "date_offset": <integer, 0=today, -1=yesterday>,
      "confidence": <0.0-1.0>,
      "goal_match": "<goal name or null>"
    }
  ]
}
''';
}
