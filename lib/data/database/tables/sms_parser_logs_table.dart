import 'package:drift/drift.dart';

// Prevents duplicate SMS/notification processing via SHA-256 hash dedup.
class SmsParserLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get senderAddress => text()();
  TextColumn get bodyHash =>
      text().unique()(); // SHA-256 of SMS body — dedup key
  TextColumn get body => text()();

  /// 'pending' | 'approved' | 'skipped' | 'failed' | 'duplicate'
  TextColumn get parsedStatus => text()();
  IntColumn get transactionId => integer().nullable()();
  TextColumn get source => text()(); // 'sms' | 'notification'
  DateTimeColumn get receivedAt => dateTime()();
  DateTimeColumn get processedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// AI enrichment JSON: {category_icon, merchant, note, confidence}
  TextColumn get aiEnrichmentJson => text().nullable()();

  /// WS3: Semantic fingerprint for cross-source deduplication.
  /// SHA-256 of "walletOrSender|amount|type|5minWindow".
  TextColumn get semanticFingerprint => text().nullable()();

  /// WS3b: Link to transfer (for ATM withdrawal → bank-to-cash).
  /// Soft FK (no .references()) — same pattern as recurring_rules.linkedTransactionId.
  /// Deleting a transfer should not cascade to parser logs.
  IntColumn get transferId => integer().nullable()();
}
