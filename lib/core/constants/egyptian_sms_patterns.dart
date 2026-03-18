import '../utils/arabic_number_parser.dart';

/// Regex patterns for Egyptian bank and wallet SMS parsing.
/// Used by SmsTransactionParser and NotificationTransactionParser.
abstract final class EgyptianSmsPatterns {
  /// Known Egyptian financial SMS senders.
  static const List<String> financialSenders = [
    // Banks
    'CIB', 'NBE', 'BANQUEMISR', 'MISR', 'QNB', 'AAIB',
    'ALEXBANK', 'ADIB', 'AHLI', 'HSBC', 'FAISAL',
    // Mobile Money
    'VODAFONE', 'VODAFONECASH', 'VCASH', 'ORANGE',
    'ETISALAT', 'ECASH', 'WE',
    // Fintech & Payments
    'INSTAPAY', 'FAWRY', 'VALU', 'SOUHOOLA', 'CONTACT',
    // E-commerce
    'AMAZON', 'NOON', 'JUMIA', 'TALABAT',
  ];

  /// Known Egyptian financial app package names.
  /// IM-34 fix: used for notification filtering by package name.
  static const List<String> financialPackages = [
    'com.cib.cibmobile',
    'com.nbe.nbe',
    'com.bm.banquemisr',
    'com.qnb.qnb',
    'com.aaib.aaibmobile',
    'com.alexbank',
    'com.vodafone.ecash',
    'com.orange.money',
    'com.instapay',
    'com.fawry',
    'com.valu',
  ];

  /// All supported currency codes for extraction.
  // Note: ج\.م\.? comes before any shorter ج\.م alternative so the
  // optional trailing period is matched. Previous version had both, making
  // the longer form unreachable.
  static const String _currencyCodes =
      r'(?:EGP|LE|جنيه|ج\.م\.?|USD|EUR|GBP|SAR|AED|KWD|QAR|BHD|OMR|JOD)';

  /// Amount extraction: matches "1,500.50 EGP", "150 USD", "١٥٠ ج.م", etc.
  /// I9 fix: include Eastern Arabic numerals (٠-٩) alongside Western digits.
  /// IM-36 fix: also matches prefix-currency format (e.g. "EGP 1,500").
  static String get amountRegex =>
      r'([\d٠-٩]+(?:[,،][\d٠-٩]{3})*(?:\.[\d٠-٩]{1,2})?)\s*' + _currencyCodes;

  /// IM-36 fix: prefix-currency regex (e.g. "EGP 1,500.50", "USD 150").
  static String get amountRegexPrefix =>
      _currencyCodes + r'\s*([\d٠-٩]+(?:[,،][\d٠-٩]{3})*(?:\.[\d٠-٩]{1,2})?)';

  /// Normalize Eastern Arabic numerals to Western digits.
  /// Delegates to canonical [ArabicNumberParser.normalizeDigits].
  static String normalizeDigits(String input) =>
      ArabicNumberParser.normalizeDigits(input);

  /// Credit/income patterns
  static const List<String> creditPatterns = [
    'تم إيداع',
    'تم ايداع',
    'تم استلام',
    'رصيد جديد',
    'credited',
    'received',
    'deposited',
    'added to',
    'تحويل وارد',
  ];

  /// Debit/expense patterns
  static const List<String> debitPatterns = [
    'تم خصم',
    'تم السداد',
    'تم الشراء',
    'جارى خصم',
    'debited',
    'deducted',
    'charged',
    'purchase',
    'payment of',
    'تحويل صادر',
    'سحب',
  ];

  /// WS3b: ATM/cash withdrawal patterns — used to detect bank→cash transfers.
  static const List<String> atmPatterns = [
    'سحب نقدي',
    'سحب من ماكينة',
    'سحب من الصراف',
    'ATM',
    'cash withdrawal',
    'ATM withdrawal',
  ];

  /// Balance-indicating keywords — amounts near these are likely the remaining
  /// balance, not the transaction amount. Used by context-aware extraction.
  ///
  /// IMPORTANT: These must NOT be substrings of [creditPatterns] entries.
  /// E.g. 'رصيد' would match inside 'رصيد جديد' (a credit pattern), so we
  /// use the more specific 'رصيدك' / 'رصيد حسابك' instead.
  static const List<String> balanceKeywords = [
    'رصيدك',
    'رصيد حسابك',
    'رصيد متاح',
    'المتبقي',
    'balance',
    'remaining',
    'available',
  ];
}
