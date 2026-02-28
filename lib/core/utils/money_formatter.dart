import 'package:intl/intl.dart';

/// MANDATORY formatter for all monetary amounts.
/// ALL amounts stored as INTEGER piastres. NEVER use double for money storage.
/// Rule: 100.50 EGP → stored as 10050 piastres.
///
/// Usage:
///   MoneyFormatter.format(10050)  // → "100.50 EGP" or "١٠٠٫٥٠ ج.م"
///   MoneyFormatter.parseToInt("150.75")  // → 15075
abstract final class MoneyFormatter {
  /// Current app locale for formatting. Set by the app on locale changes.
  static String _activeLocale = 'en-US';

  /// The active locale string (e.g. 'en-US' or 'ar-EG').
  static String get activeLocale => _activeLocale;

  /// Update the active locale. Called from app.dart on every locale change.
  static void setLocale(String languageCode) {
    _activeLocale = languageCode == 'ar' ? 'ar-EG' : 'en-US';
  }

  /// Returns the currency symbol for the default currency (EGP)
  /// in the current locale.
  static String currencySymbol({String currency = 'EGP'}) {
    return _symbol(currency, _activeLocale);
  }

  /// Convert piastres integer → formatted currency string.
  static String format(
    int piastres, {
    String currency = 'EGP',
    String? locale,
  }) {
    final effectiveLocale = locale ?? _activeLocale;
    final amount = piastres / 100.0;
    return NumberFormat.currency(
      locale: effectiveLocale,
      symbol: _symbol(currency, effectiveLocale),
      decimalDigits: 2,
    ).format(amount);
  }

  /// Same as [format] but without currency symbol — for compact display.
  static String formatAmount(
    int piastres, {
    String? locale,
  }) {
    final effectiveLocale = locale ?? _activeLocale;
    final amount = piastres / 100.0;
    return NumberFormat('#,##0.00', effectiveLocale).format(amount);
  }

  /// Compact format for large numbers: "12.5K" or "1.2M".
  static String formatCompact(
    int piastres, {
    String currency = 'EGP',
    String? locale,
  }) {
    final effectiveLocale = locale ?? _activeLocale;
    final amount = piastres / 100.0;
    return NumberFormat.compactCurrency(
      locale: effectiveLocale,
      symbol: _symbol(currency, effectiveLocale),
    ).format(amount);
  }

  /// Parse user-typed input string → integer piastres.
  /// Returns null if input is not a valid number.
  /// Examples:
  ///   "150.75"   → 15075
  ///   "1,500"    → 150000
  ///   "١٥٠"      → 15000
  ///   "abc"      → null
  static int? tryParseToInt(String input) {
    final cleaned = input
        .replaceAll(',', '')
        .replaceAll('٬', '')
        .replaceAll('\u066C', '') // Arabic thousands separator
        .trim();
    if (cleaned.isEmpty) return null;
    final normalized = _normalizeDigits(cleaned);
    final value = double.tryParse(normalized);
    if (value == null) return null;
    return (value * 100).round();
  }

  /// Parse user-typed input string → integer piastres.
  /// Returns 0 for invalid input (legacy callers).
  /// Prefer [tryParseToInt] for new code.
  static int parseToInt(String input) => tryParseToInt(input) ?? 0;

  /// Convert piastres to display double (for UI only — never store doubles).
  static double toDisplayDouble(int piastres) => piastres / 100.0;

  // ── Private helpers ────────────────────────────────────────────────────

  static String _symbol(String currency, String locale) {
    final isAr = locale.startsWith('ar');
    return switch (currency) {
      'EGP' => isAr ? 'ج.م' : 'EGP',
      'SAR' => isAr ? 'ر.س' : 'SAR',
      'AED' => isAr ? 'د.إ' : 'AED',
      'KWD' => isAr ? 'د.ك' : 'KWD',
      'USD' => '\$',
      'EUR' => '€',
      _ => currency,
    };
  }

  static String _normalizeDigits(String input) {
    const easternArabic = '٠١٢٣٤٥٦٧٨٩';
    var result = input;
    for (var i = 0; i < easternArabic.length; i++) {
      result = result.replaceAll(easternArabic[i], '$i');
    }
    return result;
  }
}
