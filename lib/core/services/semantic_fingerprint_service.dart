import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../constants/egyptian_sms_patterns.dart';

/// Pure-Dart service that computes semantic fingerprints for cross-source
/// transaction deduplication.
///
/// Two messages (SMS + notification) about the same financial event share the
/// same fingerprint because it's based on _parsed semantics_ (amount, type,
/// sender, time window) rather than raw body text.
abstract final class SemanticFingerprintService {
  /// 5-minute window in milliseconds.
  static const int _windowMs = 5 * 60 * 1000;

  /// Normalize a raw sender address to a canonical bank name.
  ///
  /// SMS sender "CIB" and notification sender "CIB Transactions" both
  /// normalize to "CIB", ensuring cross-source fingerprints match.
  /// Falls back to uppercased alpha-only string if no known bank matches.
  static String normalizeSender(String rawSender) {
    final upper = rawSender.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    for (final bank in EgyptianSmsPatterns.financialSenders) {
      if (upper.contains(bank)) return bank;
    }
    return upper;
  }

  /// Compute a semantic fingerprint for a parsed transaction.
  ///
  /// Normalizes [senderOrWalletId] to a canonical bank name before hashing,
  /// so SMS ("CIB") and notification ("CIB Transactions") produce the same
  /// fingerprint for the same financial event.
  ///
  /// Returns both current and adjacent window fingerprints to handle messages
  /// that straddle the boundary.
  static List<String> compute({
    required String senderOrWalletId,
    required int amountPiastres,
    required String type,
    required DateTime receivedAt,
  }) {
    final normalizedSender = normalizeSender(senderOrWalletId);
    final epochMs = receivedAt.millisecondsSinceEpoch;
    final currentWindow = epochMs ~/ _windowMs;
    // Adjacent window = previous window (handles boundary crossing).
    final adjacentWindow = currentWindow - 1;

    return [
      _hash(normalizedSender, amountPiastres, type, currentWindow),
      _hash(normalizedSender, amountPiastres, type, adjacentWindow),
    ];
  }

  static String _hash(
    String senderOrWalletId,
    int amountPiastres,
    String type,
    int timeWindow,
  ) {
    final data = '$senderOrWalletId|$amountPiastres|$type|$timeWindow';
    return sha256.convert(utf8.encode(data)).toString();
  }
}
