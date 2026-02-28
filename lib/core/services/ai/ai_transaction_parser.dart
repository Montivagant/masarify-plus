import 'dart:convert';
import 'dart:developer' as dev;

import '../../../domain/entities/category_entity.dart';
import '../../config/ai_config.dart';
import '../../utils/money_formatter.dart';
import 'openrouter_service.dart';

/// AI enrichment result for a parsed SMS/notification transaction.
class AiTransactionEnrichment {
  const AiTransactionEnrichment({
    required this.categoryIcon,
    required this.merchant,
    required this.note,
    required this.confidence,
  });

  factory AiTransactionEnrichment.fromJson(Map<String, dynamic> json) {
    return AiTransactionEnrichment(
      categoryIcon: json['category_icon'] as String? ?? '',
      merchant: json['merchant'] as String? ?? '',
      note: json['note'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  final String categoryIcon;
  final String merchant;
  final String note;
  final double confidence;

  Map<String, dynamic> toJson() => {
        'category_icon': categoryIcon,
        'merchant': merchant,
        'note': note,
        'confidence': confidence,
      };
}

/// Uses a fast, free AI model to enrich parsed SMS/notification transactions
/// with category, merchant name, and note.
///
/// Uses [AiConfig.modelQwen3_4b] (free, fastest, low token usage).
/// Returns `null` on any failure — regex data is always the fallback.
class AiTransactionParser {
  AiTransactionParser({required this.openRouter});

  final OpenRouterService openRouter;

  /// Enrich a parsed transaction with AI-suggested category, merchant, and note.
  ///
  /// Returns `null` if AI is unavailable or fails. The caller should
  /// gracefully fall back to regex-only data.
  Future<AiTransactionEnrichment?> enrich({
    required String sender,
    required String body,
    required int amountPiastres,
    required String type,
    required List<CategoryEntity> categories,
  }) async {
    if (!AiConfig.hasApiKey) return null;

    try {
      final systemPrompt = _buildSystemPrompt(categories);
      final userMessage = _buildUserMessage(sender, body, amountPiastres, type);

      final response = await openRouter.chatCompletion(
        systemPrompt: systemPrompt,
        userMessage: userMessage,
        model: AiConfig.modelQwen3_4b,
        temperature: 0.1,
      );

      // IM-33 fix: strip Qwen3 <think>...</think> tokens before parsing
      final cleaned = response.content
          .replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '')
          .trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      final enrichment = AiTransactionEnrichment.fromJson(json);

      if (enrichment.categoryIcon.isEmpty && enrichment.merchant.isEmpty) {
        return null;
      }

      dev.log(
        'Enriched: ${enrichment.merchant} → ${enrichment.categoryIcon}',
        name: 'AiTransactionParser',
      );
      return enrichment;
    } catch (e) {
      dev.log('Enrichment failed: $e', name: 'AiTransactionParser');
      return null;
    }
  }

  String _buildUserMessage(
    String sender,
    String body,
    int amountPiastres,
    String type,
  ) {
    final amountEgp = MoneyFormatter.toDisplayDouble(amountPiastres);
    return 'Sender: $sender\n'
        'Body: $body\n'
        'Amount: $amountEgp EGP\n'
        'Type: $type';
  }

  String _buildSystemPrompt(List<CategoryEntity> categories) {
    final catList = categories
        .where((c) => !c.isArchived)
        .map((c) => '${c.iconName}|${c.name}|${c.nameAr}|${c.type}')
        .join(', ');

    return _systemPrompt.replaceAll('{{CATEGORIES}}', catList);
  }

  static const _systemPrompt = '''
You parse Egyptian bank/wallet SMS and notification messages.
Given a sender, body, amount, and type, return JSON with:
- category_icon: best matching iconName from the list
- merchant: clean merchant/store name extracted from body
- note: short Arabic or English description of the transaction
- confidence: 0.0-1.0

Categories: {{CATEGORIES}}

Rules:
1. Return ONLY valid JSON. No markdown, no explanation.
2. category_icon MUST be one of the iconName values from the Categories list. Match expense categories for expense type, income for income type
3. Extract merchant name from body (e.g., "Carrefour", "Uber", "Vodafone")
4. If merchant unclear, use sender name cleaned up
5. Note should be concise (max 6 words)
6. If unsure about category, use the closest match with lower confidence
''';
}
