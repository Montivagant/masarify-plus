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
  /// [walletNames] — user's wallet names for wallet hint extraction.
  Future<List<VoiceTransactionDraft>> parseAudio({
    required List<int> audioBytes,
    required String mimeType,
    required List<CategoryEntity> categories,
    required List<SavingsGoalEntity> goals,
    List<String> walletNames = const [],
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
      ':generateContent',
    );

    final systemPrompt = _buildSystemPrompt(categories, goals, walletNames);

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
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': AiConfig.googleAiApiKey,
          },
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
      final title = tx['title'] as String?;
      final note = tx['note'] as String?;
      final dateOffset = (tx['date_offset'] as int?) ?? 0;
      // LLMs sometimes return literal "null" instead of JSON null
      var walletHint = tx['wallet_hint'] as String?;
      if (walletHint != null &&
          (walletHint.toLowerCase() == 'null' || walletHint.trim().isEmpty)) {
        walletHint = null;
      }
      var toWalletHint = tx['to_wallet_hint'] as String?;
      if (toWalletHint != null &&
          (toWalletHint.toLowerCase() == 'null' ||
              toWalletHint.trim().isEmpty)) {
        toWalletHint = null;
      }

      // Validate category_icon against type-filtered categories.
      // Transfers have no category — skip validation.
      if (categoryIcon != null && type != 'transfer' && categories.isNotEmpty) {
        final validIcons = categories
            .where((c) => c.type == type || c.type == 'both')
            .map((c) => c.iconName)
            .toSet();
        if (!validIcons.contains(categoryIcon)) {
          categoryIcon = null;
        }
      }
      // Ensure transfers have no category icon.
      if (type == 'transfer') categoryIcon = null;

      drafts.add(
        VoiceTransactionDraft(
          rawText: note ?? '',
          amountPiastres: amountPiastres,
          categoryHint: categoryIcon,
          walletHint: walletHint,
          toWalletHint: toWalletHint,
          title: title,
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
    // Use double parsing + rounding to handle scientific notation and
    // fractional piastres correctly (e.g. 5.999 → 600 piastres).
    final value = double.tryParse(amountRaw.toString()) ?? 0.0;
    return (value * 100).round();
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
    List<String> walletNames,
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

    final walletsJson = jsonEncode(walletNames);

    return _systemPromptTemplate
        .replaceAll('{{CATEGORIES_JSON}}', categoriesJson)
        .replaceAll('{{GOALS_JSON}}', goalsJson)
        .replaceAll('{{WALLETS_JSON}}', walletsJson);
  }

  static const _systemPromptTemplate = '''
You are a financial transaction parser for an Egyptian personal finance app called Masarify.
Your job is to TRANSCRIBE the audio and parse any financial transactions mentioned into structured JSON.

RULES:
1. Return ONLY valid JSON. No markdown, no explanation, no code fences.
2. First transcribe the audio, then extract transactions from the transcription.
3. Egyptian Arabic amounts: مية=100, ميتين=200, تلتمية=300, ربعمية=400, خمسمية=500, الف=1000, الفين=2000, نص=0.50
4. Default type is "expense" unless income triggers or cash triggers are detected (see rules below)
5. Split multiple transactions on conjunctions (وبعدين, وكمان, و, and, then, also)
6. category_icon MUST be one of the iconName values from AVAILABLE CATEGORIES. Match expense categories for expenses, income categories for income. For cash_withdrawal/cash_deposit, set category_icon to "bank"
7. Date offsets: امبارح/أمس/yesterday=-1, النهارده/اليوم/today=0, من اسبوع=-7, من يومين=-2
8. Confidence 0.0-1.0 per transaction (how sure you are about the parsing)
9. If text relates to one of the user's savings goals, set goal_match to the goal name
10. If amount is unclear, set amount_egp to 0
11. Always set a note — use the relevant portion of transcript

TYPE DETECTION (priority order — check income BEFORE cash):
- "income": استلمت, اخدت, اتقبضت, قبضت, راتب, مرتب, salary, income, received, earned, got paid
  IMPORTANT: Salary is ALWAYS type "income", even if received in cash.
  "استلمت مرتبي" = income, wallet_hint=null (default account).
  "استلمت مرتبي كاش" = income, wallet_hint="cash" (the app routes to physical cash wallet).
- "expense" (default): دفعت, اشتريت, صرفت, paid, bought, spent
- "cash_withdrawal": سحبت, سحب, ATM, صراف, سحبت من الصراف, withdrew, withdrawal, cash out
  ONLY when explicitly mentioning ATM/cash machine/physical cash withdrawal.
- "cash_deposit": أودعت, إيداع, حطيت فلوس في البنك, deposited, deposit, put money in bank
  ONLY when explicitly depositing into a bank. Never for salary/income.
- "transfer": حولت, حولتلهم, سديت, سددت, نقلت, حطيت في, تحويل, transferred, moved, sent to, settle
  Key signal: TWO wallet/account names mentioned (source and destination).
  For transfer, set BOTH wallet_hint (source account) AND to_wallet_hint (destination account).
  category_icon should be null for transfers.
WALLET HINT: Only set wallet_hint if the user EXPLICITLY mentions an account/bank name. Do NOT guess. Leave null if no account mentioned — the app assigns the default account automatically.
- If user says "كاش"/"cash"/"نقدي", set wallet_hint to "cash" — the app routes to the physical cash wallet.
- For cash_withdrawal/cash_deposit, wallet_hint should be the bank account name mentioned.

AVAILABLE CATEGORIES:
{{CATEGORIES_JSON}}

USER'S ACTIVE SAVINGS GOALS:
{{GOALS_JSON}}

USER'S WALLET/ACCOUNT NAMES:
{{WALLETS_JSON}}

12. If the user mentions a wallet/account name (e.g. "from CIB", "cash", "my bank"), set wallet_hint to that name exactly as spoken
13. When the user mentions a brand or merchant name, use the ENGLISH brand name in the note field for brand icon matching. Common Egyptian brands: Vodafone, Uber, Careem, CIB, NBE, Fawry, Carrefour, McDonald's, KFC, Netflix, Starbucks, Amazon, Noon, Talabat.

RESPONSE SCHEMA:
{
  "transactions": [
    {
      "amount_egp": <number>,
      "type": "expense" | "income" | "cash_withdrawal" | "cash_deposit" | "transfer",
      "category_icon": "<iconName from categories list>",
      "title": "<short 2-4 word title>",
      "note": "<full descriptive text>",
      "date_offset": <integer, 0=today, -1=yesterday>,
      "confidence": <0.0-1.0>,
      "goal_match": "<goal name or null>",
      "wallet_hint": "<wallet name mentioned or null>",
      "to_wallet_hint": "<destination wallet name — ONLY for type=transfer, null otherwise>"
    }
  ]
}

14. For type "transfer", both wallet_hint and to_wallet_hint MUST be set. category_icon should be null.
    When user mentions paying from one bank to settle debt in another, that's a transfer.
15. Always generate a SHORT title (2-4 words, like "KFC Meal", "Grocery Shopping", "Uber Ride", "وجبة كنتاكي", "مشوار اوبر").
    Put the title in the "title" field. Use the "note" field for the full descriptive text.
    Title should be in the same language the user spoke.
''';
}
