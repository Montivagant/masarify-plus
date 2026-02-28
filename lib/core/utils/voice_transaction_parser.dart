import '../constants/voice_dictionary.dart';
import 'arabic_number_parser.dart';

/// Parses free-form Arabic voice input into structured transaction drafts.
///
/// Rule #7: Every parsed result MUST pass through VoiceConfirmScreen
/// before being saved — never auto-save.
///
/// Example input: "دفعت مية جنيه على الأكل"
/// Expected output: VoiceTransactionDraft(amount: 10000, categoryHint: 'food')
class VoiceTransactionParser {
  const VoiceTransactionParser();

  // ── Public API ─────────────────────────────────────────────────────────

  /// Parses [rawText] from STT into one or more draft transactions.
  /// Supports multi-transaction input via split keywords.
  List<VoiceTransactionDraft> parseAll(String rawText) {
    if (rawText.trim().isEmpty) return [];

    // Try splitting on multi-transaction keywords
    var segments = [rawText.trim()];
    for (final keyword in VoiceDictionary.splitKeywords) {
      final newSegments = <String>[];
      for (final segment in segments) {
        newSegments.addAll(
          segment
              .split(keyword)
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty),
        );
      }
      segments = newSegments;
    }

    final results = <VoiceTransactionDraft>[];
    for (final segment in segments) {
      final draft = _parseSingle(segment);
      if (draft != null) {
        results.add(draft);
      }
    }

    return results;
  }

  /// Parses [rawText] into a single draft (legacy API).
  VoiceTransactionDraft? parse(String rawText) {
    final results = parseAll(rawText);
    return results.isNotEmpty ? results.first : null;
  }

  // ── Private parsing logic ──────────────────────────────────────────────

  VoiceTransactionDraft? _parseSingle(String text) {
    final lower = text.trim();
    if (lower.isEmpty) return null;

    final amount = ArabicNumberParser.parse(lower);
    // A draft without an amount is not actionable — treat as unparseable.
    if (amount == null) return null;

    return VoiceTransactionDraft(
      rawText: text.trim(),
      amountPiastres: amount,
      categoryHint: _detectCategory(lower),
      note: text.trim(),
      type: _detectType(lower),
      dateOffset: _detectDateOffset(lower),
    );
  }

  /// I8 fix: when both income and expense triggers are present,
  /// use positional priority (whichever appears first in text wins).
  static String _detectType(String text) {
    int? firstIncome;
    int? firstExpense;

    for (final trigger in VoiceDictionary.incomeTriggers) {
      final idx = text.indexOf(trigger);
      if (idx != -1 && (firstIncome == null || idx < firstIncome)) {
        firstIncome = idx;
      }
    }
    for (final trigger in VoiceDictionary.expenseTriggers) {
      final idx = text.indexOf(trigger);
      if (idx != -1 && (firstExpense == null || idx < firstExpense)) {
        firstExpense = idx;
      }
    }

    if (firstIncome != null && firstExpense != null) {
      return firstIncome < firstExpense ? 'income' : 'expense';
    }
    if (firstIncome != null) return 'income';
    return 'expense';
  }

  static String? _detectCategory(String text) {
    for (final entry in VoiceDictionary.categoryKeywords.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static int _detectDateOffset(String text) {
    for (final entry in VoiceDictionary.timeKeywords.entries) {
      if (text.contains(entry.key)) return entry.value;
    }
    return 0;
  }
}

/// Intermediate data class produced by [VoiceTransactionParser].
/// Passed to VoiceConfirmScreen for user review before saving.
class VoiceTransactionDraft {
  const VoiceTransactionDraft({
    required this.rawText,
    this.amountPiastres,
    this.categoryHint,
    this.note,
    this.type = 'expense',
    this.dateOffset = 0,
  });

  final String rawText;

  /// Parsed amount in piastres (INTEGER — Rule #4), or null if unparseable.
  final int? amountPiastres;

  final String? categoryHint;
  final String? note;

  /// 'income' or 'expense' (defaults to expense).
  final String type;

  /// Days offset from today (0 = today, -1 = yesterday).
  final int dateOffset;

  /// Computed transaction date.
  DateTime get transactionDate =>
      DateTime.now().add(Duration(days: dateOffset));
}
