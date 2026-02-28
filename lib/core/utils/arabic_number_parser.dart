import '../constants/voice_dictionary.dart';

/// Parses spoken Egyptian Arabic numbers into piastres (INTEGER).
///
/// Examples:
///   "مية" → 10000  (100 EGP in piastres)
///   "خمسين" → 5000  (50 EGP)
///   "مية وخمسين" → 15000  (150 EGP)
///   "الف" → 100000  (1000 EGP)
///   "150" → 15000  (numeric input also handled)
///   "نص" → 50  (half pound = 50 piastres)
///   "ربع" → 25  (quarter pound = 25 piastres)
abstract final class ArabicNumberParser {
  // ── Arabic digit mapping ───────────────────────────────────────────────

  static const _arabicDigits = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  // ── Spoken number words → piastres ─────────────────────────────────────

  static const _wordToPiastres = <String, int>{
    'واحد': 100,
    'اتنين': 200,
    'تلاتة': 300,
    'اربعة': 400,
    'خمسة': 500,
    'ستة': 600,
    'سبعة': 700,
    'تمانية': 800,
    'تسعة': 900,
    'عشرة': 1000,
    'عشر': 1000,
    'حداشر': 1100,
    'اتناشر': 1200,
    'تلتاشر': 1300,
    'اربعتاشر': 1400,
    'خمستاشر': 1500,
    'ستاشر': 1600,
    'سبعتاشر': 1700,
    'تمنتاشر': 1800,
    'تسعتاشر': 1900,
    'عشرين': 2000,
    'تلاتين': 3000,
    'اربعين': 4000,
    'خمسين': 5000,
    'ستين': 6000,
    'سبعين': 7000,
    'تمانين': 8000,
    'تسعين': 9000,
    'مية': 10000,
    'ميت': 10000,
    'ميتين': 20000,
    'تلتمية': 30000,
    'ربعمية': 40000,
    'خمسمية': 50000,
    'ستمية': 60000,
    'سبعمية': 70000,
    'تمنمية': 80000,
    'تسعمية': 90000,
    'الف': 100000,
    'ألف': 100000,
    'الفين': 200000,
  };

  /// Multiplier words — "تلات آلاف" needs "آلاف" to multiply by 1000.
  static const _multipliers = <String, int>{
    'آلاف': 100000,
    'الاف': 100000,
  };

  // ── Public API ─────────────────────────────────────────────────────────

  /// Parses [text] into piastres. Returns null if no number found.
  ///
  /// Handles:
  /// - Arabic numeral digits ("١٥٠" → 15000)
  /// - Latin digits ("150" → 15000)
  /// - Spoken words ("مية وخمسين" → 15000)
  /// - Fractions ("نص" → 50, "ربع" → 25)
  /// - Mixed ("100 جنيه" → 10000)
  static int? parse(String text) {
    final normalized = _normalizeArabicDigits(text.trim());

    // Try numeric first (most reliable)
    final numericResult = _tryNumeric(normalized);
    if (numericResult != null) return numericResult;

    // Try spoken word parsing
    return _trySpokenWords(normalized);
  }

  // ── Private helpers ────────────────────────────────────────────────────

  static String _normalizeArabicDigits(String input) {
    var result = input;
    for (final entry in _arabicDigits.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  /// Try to extract a numeric value from the text.
  static int? _tryNumeric(String text) {
    // Match digits with optional decimal point
    final numRegex = RegExp(r'(\d+(?:\.\d+)?)');
    final match = numRegex.firstMatch(text);
    if (match == null) return null;

    final numStr = match.group(1)!;
    final value = double.tryParse(numStr);
    if (value == null || value <= 0) return null;

    // Convert EGP to piastres
    return (value * 100).round();
  }

  /// Try to parse spoken Arabic number words.
  ///
  /// I7 fix: multiplier words (آلاف) now apply to the accumulated group,
  /// not just the immediately preceding word.
  /// e.g., "مية وخمسين ألف" → group=15000 (150 EGP) × 1000 = 15,000,000 piastres
  static int? _trySpokenWords(String text) {
    final words = text
        .replaceAll('و', ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    var total = 0; // final accumulated result
    var group = 0; // current group being built (before a multiplier)
    var foundAny = false;

    for (var i = 0; i < words.length; i++) {
      final word = words[i];

      // Check if this word is a multiplier (e.g., آلاف)
      final multiplier = _multipliers[word];
      if (multiplier != null && group > 0) {
        // Multiply the entire accumulated group
        final unitCount = group ~/ 100; // convert piastres to EGP units
        total += unitCount * multiplier;
        group = 0;
        foundAny = true;
        continue;
      }

      // Check direct word match
      final piastres = _wordToPiastres[word];
      if (piastres != null) {
        group += piastres;
        foundAny = true;
        continue;
      }

      // Check fractional words from VoiceDictionary ("نص" = 50, "ربع" = 25)
      final fractionPiastres = VoiceDictionary.fractions[word];
      if (fractionPiastres != null) {
        group += fractionPiastres;
        foundAny = true;
        continue;
      }

      // Skip filler words
    }

    // Add any remaining group that wasn't followed by a multiplier
    total += group;

    return foundAny ? total : null;
  }
}
