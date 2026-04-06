import 'package:intl/intl.dart';

/// MANDATORY formatter for all monetary amounts.
/// ALL amounts stored as INTEGER piastres. NEVER use double for money storage.
/// Rule: 100.50 EGP → stored as 10050 piastres.
///
/// Usage:
///   MoneyFormatter.format(10050)  // → "100.50 EGP" or "١٠٠٫٥٠ ج.م"
abstract final class MoneyFormatter {
  /// Current app locale for formatting. Set by the app on locale changes.
  static String _activeLocale = 'en-US';

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

  /// Trailing-symbol format: "1,000.00 EGP" (amount first, symbol after).
  ///
  /// Used on the home screen where the design puts the currency after the
  /// number instead of the locale-default position.
  static String formatTrailing(
    int piastres, {
    String currency = 'EGP',
    String? locale,
  }) {
    return '${formatAmount(piastres, locale: locale)} ${currencySymbol(currency: currency)}';
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

  /// Convert piastres to display double (for UI only — never store doubles).
  static double toDisplayDouble(int piastres) => piastres / 100.0;

  /// Format an integer percentage with locale-aware digits.
  ///
  /// Returns e.g. `"75%"` in English, `"٧٥%"` in Arabic.
  static String formatPercent(int pct, {String? locale}) {
    final effectiveLocale = locale ?? _activeLocale;
    return '${NumberFormat.decimalPattern(effectiveLocale).format(pct)}%';
  }

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
}
