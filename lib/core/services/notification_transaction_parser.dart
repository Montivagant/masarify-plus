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
    this.currency = 'EGP',
  });

  final String senderAddress;
  final String body;
  final String bodyHash;
  final int amountPiastres;
  final String type; // 'income' | 'expense'
  final DateTime receivedAt;
  final String source; // 'notification' | 'sms'
  final String currency; // 'EGP', 'USD', 'EUR', etc.
}

/// Parses Egyptian bank/wallet notification & SMS bodies into transactions.
///
/// Uses regex patterns from [EgyptianSmsPatterns] for amount extraction
/// and credit/debit detection. Deduplication is via SHA-256 hash of the body.
abstract final class NotificationTransactionParser {
  // Cached compiled regexps — avoids recompilation on every parse() call,
  // which matters since parse() is called from ListView.builder build().
  static final RegExp _amountSuffix = RegExp(EgyptianSmsPatterns.amountRegex);
  static final RegExp _amountPrefix =
      RegExp(EgyptianSmsPatterns.amountRegexPrefix);

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

    // 3. Detect currency code
    final currency = _detectCurrency(body);

    // 4. Compute dedup hash
    final hash = sha256.convert(utf8.encode(body.trim())).toString();

    return ParsedNotificationTransaction(
      senderAddress: sender,
      body: body,
      bodyHash: hash,
      amountPiastres: amountPiastres,
      type: type,
      receivedAt: receivedAt,
      source: source,
      currency: currency,
    );
  }

  /// Extract amount in piastres from the body text.
  ///
  /// Context-aware: when multiple amounts are found (e.g. "تم خصم 500 EGP.
  /// رصيدك 2500 EGP"), prefers the amount nearest a debit/credit keyword and
  /// avoids amounts near balance keywords.
  static int? _extractAmount(String body) {
    // Collect all amount matches from both suffix and prefix patterns.
    // Deduplicate by start position to avoid scoring the same token twice.
    final suffixMatches = _amountSuffix.allMatches(body).toList();
    final suffixStarts = suffixMatches.map((m) => m.start).toSet();
    final prefixMatches = _amountPrefix
        .allMatches(body)
        .where((m) => !suffixStarts.contains(m.start))
        .toList();
    final allMatches = [...suffixMatches, ...prefixMatches];
    if (allMatches.isEmpty) return null;

    // If only one match, use it (no ambiguity).
    if (allMatches.length == 1) {
      return _parseMatchToPiastres(allMatches.first);
    }

    // Multiple matches: prefer the one nearest a debit/credit keyword.
    final lowerBody = body.toLowerCase();
    final transactionKeywords = [
      ...EgyptianSmsPatterns.debitPatterns,
      ...EgyptianSmsPatterns.creditPatterns,
    ];

    // Find ALL keyword positions in the body (not just first occurrence).
    final keywordPositions = <int>[];
    for (final kw in transactionKeywords) {
      for (final m
          in RegExp(RegExp.escape(kw.toLowerCase())).allMatches(lowerBody)) {
        keywordPositions.add(m.start);
      }
    }

    // Balance-indicating keywords — matches near these should be avoided.
    // Uses allMatches to catch multiple balance mentions in one SMS.
    final balancePositions = <int>[];
    for (final kw in EgyptianSmsPatterns.balanceKeywords) {
      for (final m
          in RegExp(RegExp.escape(kw.toLowerCase())).allMatches(lowerBody)) {
        balancePositions.add(m.start);
      }
    }

    // Partition matches: separate those near balance keywords from the rest.
    // "Near" = within 30 chars in either direction (symmetric window covers
    // both Arabic "رصيدك 2500" and English "balance: 2500 EGP").
    bool isNearBalance(RegExpMatch m) => balancePositions.any(
          (bp) => (bp - m.start).abs() <= 30,
        );

    final nonBalanceMatches =
        allMatches.where((m) => !isNearBalance(m)).toList();
    // Score non-balance matches if any exist; otherwise fall back to all.
    final candidates =
        nonBalanceMatches.isNotEmpty ? nonBalanceMatches : allMatches;

    // Score each candidate: prefer the one nearest a debit/credit keyword.
    RegExpMatch? best;
    var bestScore = double.infinity;
    for (final m in candidates) {
      if (keywordPositions.isEmpty) {
        // No keywords found — fall back to first candidate.
        best = m;
        break;
      }
      final dist = keywordPositions
          .map((kp) => (m.start - kp).abs())
          .reduce((a, b) => a < b ? a : b);
      if (dist < bestScore) {
        bestScore = dist.toDouble();
        best = m;
      }
    }
    best ??= candidates.first; // Ultimate fallback

    return _parseMatchToPiastres(best);
  }

  /// Parse a regex match's capture group 1 into piastres.
  static int? _parseMatchToPiastres(RegExpMatch match) {
    final raw = match.group(1);
    if (raw == null) return null;
    final normalized = EgyptianSmsPatterns.normalizeDigits(
      raw.replaceAll(',', ''),
    );
    final value = double.tryParse(normalized);
    if (value == null || value <= 0) return null;
    return (value * 100).round();
  }

  /// Detect credit (income) or debit (expense) from body keywords.
  ///
  /// WS1 fix: checks debit FIRST (expense is the 80% case). When both
  /// debit and credit patterns match, uses positional analysis — the keyword
  /// that appears FIRST in the body indicates the primary transaction type.
  /// This correctly handles "تحويل وارد 1000 ج.م تم خصم عمولة 10 ج.م"
  /// (incoming transfer with fee deduction → income, not expense).
  static String? _detectType(String body) {
    final lower = body.toLowerCase();

    // Find earliest position of each type's keyword.
    var firstDebitPos = -1;
    for (final pattern in EgyptianSmsPatterns.debitPatterns) {
      final pos = lower.indexOf(pattern.toLowerCase());
      if (pos >= 0 && (firstDebitPos < 0 || pos < firstDebitPos)) {
        firstDebitPos = pos;
      }
    }

    var firstCreditPos = -1;
    for (final pattern in EgyptianSmsPatterns.creditPatterns) {
      final pos = lower.indexOf(pattern.toLowerCase());
      if (pos >= 0 && (firstCreditPos < 0 || pos < firstCreditPos)) {
        firstCreditPos = pos;
      }
    }

    final hasDebit = firstDebitPos >= 0;
    final hasCredit = firstCreditPos >= 0;

    // Both matched → the keyword appearing first indicates the primary event.
    if (hasDebit && hasCredit) {
      return firstDebitPos <= firstCreditPos ? 'expense' : 'income';
    }
    if (hasDebit) return 'expense';
    if (hasCredit) return 'income';

    return null;
  }

  /// Detect currency code from SMS body. Defaults to 'EGP'.
  /// Uses word-boundary regex to avoid false positives from substrings
  /// (e.g. "NEUROSPINE" should not match "EUR").
  static String _detectCurrency(String body) {
    const foreignCurrencies = [
      'USD',
      'EUR',
      'GBP',
      'SAR',
      'AED',
      'KWD',
      'QAR',
      'BHD',
      'OMR',
      'JOD',
    ];
    final upper = body.toUpperCase();
    for (final c in foreignCurrencies) {
      if (RegExp('\\b$c\\b').hasMatch(upper)) return c;
    }
    return 'EGP';
  }

  /// WS3b: Detect ATM/cash withdrawal from body keywords.
  static bool isAtmWithdrawal(String body) {
    final lower = body.toLowerCase();
    return EgyptianSmsPatterns.atmPatterns.any(
      (p) => lower.contains(p.toLowerCase()),
    );
  }

  /// Compute SHA-256 hash for deduplication.
  static String bodyHash(String body) =>
      sha256.convert(utf8.encode(body.trim())).toString();
}
