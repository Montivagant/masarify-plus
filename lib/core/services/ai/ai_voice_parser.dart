import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/savings_goal_entity.dart';
import '../../config/ai_config.dart';
import '../../utils/voice_transaction_parser.dart';
import 'openrouter_service.dart';

/// Result of AI voice parsing.
class AiVoiceParseResult {
  const AiVoiceParseResult({
    required this.drafts,
    required this.usedAi,
    this.errorMessage,
  });

  final List<VoiceTransactionDraft> drafts;
  final bool usedAi;
  final String? errorMessage;
}

/// Orchestrates LLM-powered voice transcript parsing with rule-based fallback.
///
/// Flow:
/// 1. If no API key → immediate fallback to rule-based parser
/// 2. Build system prompt with user's categories + goals context
/// 3. Try model(s) via OpenRouter — single or fallback chain
/// 4. Parse JSON response into [VoiceTransactionDraft] list
/// 5. On ALL model failures → graceful fallback to rule-based parser
class AiVoiceParser {
  AiVoiceParser({required this.openRouter});

  final OpenRouterService openRouter;

  static const _fallbackParser = VoiceTransactionParser();

  /// Parses a voice transcript into transaction drafts.
  ///
  /// [modelPreference] controls which model(s) to use:
  /// - `'auto'` → try all models in [AiConfig.fallbackChain] order
  /// - specific model ID → try only that model
  /// On failure, always falls back to rule-based parser.
  Future<AiVoiceParseResult> parse({
    required String transcript,
    required List<CategoryEntity> categories,
    required List<SavingsGoalEntity> goals,
    String modelPreference = 'auto',
  }) async {
    if (!AiConfig.hasApiKey) {
      return _fallback(transcript);
    }

    final systemPrompt = _buildSystemPrompt(categories, goals);
    final models = modelPreference == 'auto'
        ? AiConfig.fallbackChain
        : [modelPreference];

    return _tryModels(systemPrompt, transcript, models, categories);
  }

  /// Iterates through [models] in order, returning the first successful result.
  /// If all models fail, falls back to rule-based parsing.
  Future<AiVoiceParseResult> _tryModels(
    String systemPrompt,
    String transcript,
    List<String> models,
    List<CategoryEntity> categories,
  ) async {
    String? lastError;

    for (final model in models) {
      try {
        dev.log('Trying model: $model', name: 'AiVoiceParser');
        final response = await openRouter.chatCompletion(
          systemPrompt: systemPrompt,
          userMessage: transcript,
          model: model,
        );

        final drafts = _parseResponse(
          response.content,
          transcript,
          categories: categories,
        );
        if (drafts.isEmpty) {
          lastError = 'Model $model returned no transactions';
          dev.log(
              'Model $model returned empty drafts, trying next',
              name: 'AiVoiceParser',
          );
          continue;
        }

        dev.log('Model $model succeeded', name: 'AiVoiceParser');
        return AiVoiceParseResult(drafts: drafts, usedAi: true);
      } on SocketException catch (e) {
        // IM-32 fix: no network — skip remaining models immediately
        dev.log('No network, skipping all models: $e', name: 'AiVoiceParser');
        return _fallback(transcript, errorMessage: 'No network connection');
      } catch (e) {
        lastError = e.toString();
        dev.log('Model $model failed: $e', name: 'AiVoiceParser');
      }
    }

    dev.log(
        'All models exhausted, falling back to rule-based parser',
        name: 'AiVoiceParser',
    );
    return _fallback(transcript, errorMessage: lastError);
  }

  AiVoiceParseResult _fallback(
    String transcript, {
    String? errorMessage,
  }) {
    // When AI was attempted but failed (errorMessage present), return empty
    // drafts so the UI can show an error instead of silently using rule-based.
    if (errorMessage != null) {
      return AiVoiceParseResult(
        drafts: const [],
        usedAi: false,
        errorMessage: errorMessage,
      );
    }
    // No error = no API key configured → rule-based is the only option.
    final drafts = _fallbackParser.parseAll(transcript);
    return AiVoiceParseResult(
      drafts: drafts,
      usedAi: false,
    );
  }

  List<VoiceTransactionDraft> _parseResponse(
    String content,
    String rawTranscript, {
    List<CategoryEntity> categories = const [],
  }) {
    // Strip Qwen3 <think>...</think> blocks if present
    final cleaned = content.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '').trim();
    final dynamic decoded;
    try {
      decoded = jsonDecode(cleaned);
    } on FormatException {
      dev.log('JSON parse failed for response', name: 'AiVoiceParser');
      return [];
    }
    if (decoded is! Map<String, dynamic>) return [];
    final transactions = decoded['transactions'] as List<dynamic>?;
    if (transactions == null || transactions.isEmpty) return [];

    final drafts = <VoiceTransactionDraft>[];
    for (final tx in transactions) {
      if (tx is! Map<String, dynamic>) continue;
      final map = tx;

      // C5 fix: avoid floating-point precision issues (e.g. 199.99*100=19998.999)
      // by parsing integer and fractional parts separately.
      final amountRaw = map['amount_egp'];
      final int? amountPiastres = amountRaw != null
          ? _toPiastres(amountRaw)
          : null;

      final type = (map['type'] as String?) ?? 'expense';
      var categoryIcon = map['category_icon'] as String?;
      final note = map['note'] as String?;
      final dateOffset = (map['date_offset'] as int?) ?? 0;

      // WS-4 fix: validate returned category_icon against type-filtered categories.
      // Null out any icon that doesn't match the transaction type so keyword
      // fallback gets a chance to find a correct category.
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
          rawText: rawTranscript,
          amountPiastres: amountPiastres,
          categoryHint: categoryIcon,
          note: note ?? rawTranscript,
          type: type,
          dateOffset: dateOffset,
        ),
      );
    }

    return drafts;
  }

  String _buildSystemPrompt(
    List<CategoryEntity> categories,
    List<SavingsGoalEntity> goals,
  ) {
    final categoriesJson = jsonEncode(
      categories
          .map((c) => {
                'iconName': c.iconName,
                'name': c.name,
                'nameAr': c.nameAr,
                'type': c.type,
              },)
          .toList(),
    );

    final goalsJson = jsonEncode(
      goals
          .map((g) => {
                'name': g.name,
                'keywords': g.keywords,
              },)
          .toList(),
    );

    return _systemPromptTemplate
        .replaceAll('{{CATEGORIES_JSON}}', categoriesJson)
        .replaceAll('{{GOALS_JSON}}', goalsJson);
  }

  /// C5 fix: convert an amount (num or String from JSON) to piastres
  /// without floating-point precision errors.
  static int _toPiastres(dynamic amountRaw) {
    final amountStr = amountRaw.toString();
    final parts = amountStr.split('.');
    final pounds = int.tryParse(parts[0]) ?? 0;
    var piastres = 0;
    if (parts.length > 1) {
      // Pad to 2 digits, truncate beyond 2
      final frac = parts[1].padRight(2, '0').substring(0, 2);
      piastres = int.tryParse(frac) ?? 0;
    }
    return pounds * 100 + piastres;
  }

  static const _systemPromptTemplate = '''
You are a financial transaction parser for an Egyptian personal finance app called Masarify.
Your job is to parse Arabic (Egyptian dialect), English, or mixed voice transcripts into structured transactions.

RULES:
1. Return ONLY valid JSON. No markdown, no explanation, no code fences.
2. Egyptian Arabic amounts: مية=100, ميتين=200, تلتمية=300, ربعمية=400, خمسمية=500, الف=1000, الفين=2000, نص=0.50
3. Default type is "expense" unless income triggers are detected (e.g. اتقبضت, راتب, مرتب, salary, income, received, earned)
4. Split multiple transactions on conjunctions (وبعدين, وكمان, و, and, then, also)
5. category_icon MUST be one of the iconName values from AVAILABLE CATEGORIES. Match expense categories for expenses, income categories for income
6. Date offsets: امبارح/أمس/yesterday=-1, النهارده/اليوم/today=0, من اسبوع=-7, من يومين=-2
7. Confidence 0.0-1.0 per transaction (how sure you are about the parsing)
8. If text relates to one of the user's savings goals, set goal_match to the goal name
9. If amount is unclear, set amount_egp to 0
10. Always set a note — use the relevant portion of transcript

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
