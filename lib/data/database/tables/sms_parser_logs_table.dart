import 'package:drift/drift.dart';

// Prevents duplicate SMS/notification processing via SHA-256 hash dedup.
class SmsParserLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get senderAddress => text()();
  TextColumn get bodyHash =>
      text().unique()(); // SHA-256 of SMS body — dedup key
  TextColumn get body => text()();
  TextColumn get parsedStatus =>
      text()(); // 'approved' | 'skipped' | 'failed'
  IntColumn get transactionId => integer().nullable()();
  TextColumn get source => text()(); // 'sms' | 'notification'
  DateTimeColumn get receivedAt => dateTime()();
  DateTimeColumn get processedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// AI enrichment JSON: {category_icon, merchant, note, confidence}
  TextColumn get aiEnrichmentJson => text().nullable()();
}
