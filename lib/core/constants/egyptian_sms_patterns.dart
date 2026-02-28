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

  /// Amount extraction: matches "1,500.50 EGP", "EGP 1,500.50", or "١٥٠ ج.م"
  /// I9 fix: include Eastern Arabic numerals (٠-٩) alongside Western digits.
  /// IM-36 fix: also matches prefix-currency format (e.g. "EGP 1,500").
  static const String amountRegex =
      r'([\d٠-٩]{1,3}(?:[,،][\d٠-٩]{3})*(?:[.\.][\d٠-٩]{1,2})?)\s*(?:EGP|LE|جنيه|ج\.م|ج\.م\.?)';

  /// IM-36 fix: prefix-currency regex (e.g. "EGP 1,500.50").
  static const String amountRegexPrefix =
      r'(?:EGP|LE|جنيه|ج\.م)\s*([\d٠-٩]{1,3}(?:[,،][\d٠-٩]{3})*(?:[.\.][\d٠-٩]{1,2})?)';

  /// Normalize Eastern Arabic numerals to Western digits.
  static String normalizeDigits(String input) {
    const mapping = {
      '٠': '0', '١': '1', '٢': '2', '٣': '3', '٤': '4',
      '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9',
      '،': ',',
    };
    var result = input;
    for (final entry in mapping.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

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
    'purchase',
    'payment of',
    'تحويل صادر',
    'سحب',
  ];
}
