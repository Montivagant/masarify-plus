import 'package:drift/drift.dart';

import 'sms_parser_logs_table.dart';

/// Groups semantically identical parsed events (same wallet + amount + type
/// within a 5-minute window) to prevent cross-source duplicate transactions.
///
/// When both SMS and notification arrive for the same ATM withdrawal,
/// they produce the same semantic fingerprint and are linked to one group.
/// Only the canonical log (first arrival) appears in the pending review.
class ParsedEventGroups extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// SHA-256 of "walletId|amountPiastres|type|timeWindow".
  /// Unique: exactly one group per fingerprint (prevents duplicate groups
  /// from concurrent SMS + notification processing).
  TextColumn get semanticFingerprint => text().unique()();

  /// The first log that created this group — shown as the pending item.
  IntColumn get canonicalLogId => integer().references(SmsParserLogs, #id)();

  /// Parsed amount in piastres for quick querying.
  IntColumn get amountPiastres => integer()();

  /// 'income' or 'expense'.
  TextColumn get type => text()();

  /// Resolved wallet ID, if available.
  IntColumn get resolvedWalletId => integer().nullable()();

  /// Event classification: 'transaction', 'atm_withdrawal', or 'transfer'.
  TextColumn get eventType =>
      text().withDefault(const Constant('transaction'))();

  /// When the financial event occurred.
  DateTimeColumn get eventTime => dateTime()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
