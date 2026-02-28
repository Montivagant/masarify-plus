import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../constants/egyptian_sms_patterns.dart';

/// A parsed candidate from a bank/wallet notification or SMS.
class ParsedNotificationTransaction {
  const ParsedNotificationTransaction({
    required this.senderAddress,
    required this.body,
    required this.bodyHash,
    required this.amountPiastres,
    required this.type,
    required this.receivedAt,
    this.source = 'notification',
  });

  final String senderAddress;
  final String body;
  final String bodyHash;
  final int amountPiastres;
  final String type; // 'income' | 'expense'
  final DateTime receivedAt;
  final String source; // 'notification' | 'sms'
}

/// Parses Egyptian bank/wallet notification & SMS bodies into transactions.
///
/// Uses regex patterns from [EgyptianSmsPatterns] for amount extraction
/// and credit/debit detection. Deduplication is via SHA-256 hash of the body.
abstract final class NotificationTransactionParser {
  /// Returns `true` if [sender] is a known financial institution.
  static bool isFinancialSender(String sender) {
    final upper = sender.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    return EgyptianSmsPatterns.financialSenders.any(
      (s) => upper.contains(s),
    );
  }

  /// Returns `true` if [packageName] belongs to a known financial app.
  /// IM-34 fix: some bank apps send notifications from their package name
  /// without a recognizable title/sender.
  static bool isFinancialPackage(String packageName) {
    final lower = packageName.toLowerCase();
    return EgyptianSmsPatterns.financialPackages.any(
      (p) => lower.contains(p),
    );
  }

  /// Parse a notification/SMS body into a [ParsedNotificationTransaction],
  /// or `null` if the body doesn't look like a financial transaction.
  static ParsedNotificationTransaction? parse({
    required String sender,
    required String body,
    required DateTime receivedAt,
    String source = 'notification',
  }) {
    // 1. Extract amount
    final amountPiastres = _extractAmount(body);
    if (amountPiastres == null || amountPiastres <= 0) return null;

    // 2. Determine type (credit/debit)
    final type = _detectType(body);
    if (type == null) return null;

    // 3. Compute dedup hash
    final hash = sha256.convert(utf8.encode(body.trim())).toString();

    return ParsedNotificationTransaction(
      senderAddress: sender,
      body: body,
      bodyHash: hash,
      amountPiastres: amountPiastres,
      type: type,
      receivedAt: receivedAt,
      source: source,
    );
  }

  /// Extract amount in piastres from the body text.
  /// IM-36 fix: tries suffix-currency first ("1,500 EGP"),
  /// then prefix-currency ("EGP 1,500").
  static int? _extractAmount(String body) {
    // Try suffix pattern first (most common)
    var match = RegExp(EgyptianSmsPatterns.amountRegex).firstMatch(body);
    // IM-36: try prefix pattern if suffix didn't match
    match ??= RegExp(EgyptianSmsPatterns.amountRegexPrefix).firstMatch(body);
    if (match == null) return null;

    // R5-I4 fix: null-safe regex group access
    final raw = match.group(1);
    if (raw == null) return null;
    // H5 fix: normalize Eastern Arabic numerals (٠١٢٣...) to Western digits
    // before parsing. Without this, double.tryParse('١٢٣') returns null.
    final normalized = EgyptianSmsPatterns.normalizeDigits(
      raw.replaceAll(',', ''),
    );
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) return null;

    return (value * 100).round();
  }

  /// Detect credit (income) or debit (expense) from body keywords.
  static String? _detectType(String body) {
    final lower = body.toLowerCase();

    for (final pattern in EgyptianSmsPatterns.creditPatterns) {
      if (lower.contains(pattern.toLowerCase())) return 'income';
    }
    for (final pattern in EgyptianSmsPatterns.debitPatterns) {
      if (lower.contains(pattern.toLowerCase())) return 'expense';
    }

    return null;
  }

  /// Compute SHA-256 hash for deduplication.
  static String bodyHash(String body) =>
      sha256.convert(utf8.encode(body.trim())).toString();
}
