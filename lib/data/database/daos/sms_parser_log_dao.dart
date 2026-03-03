import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sms_parser_logs_table.dart';

part 'sms_parser_log_dao.g.dart';

@DriftAccessor(tables: [SmsParserLogs])
class SmsParserLogDao extends DatabaseAccessor<AppDatabase>
    with _$SmsParserLogDaoMixin {
  SmsParserLogDao(super.db);

  /// Check if a body with [bodyHash] has already been processed
  Future<bool> exists(String bodyHash) async {
    final row = await (select(smsParserLogs)
          ..where((l) => l.bodyHash.equals(bodyHash)))
        .getSingleOrNull();
    return row != null;
  }

  Future<SmsParserLog?> getByHash(String bodyHash) =>
      (select(smsParserLogs)..where((l) => l.bodyHash.equals(bodyHash)))
          .getSingleOrNull();

  Future<void> insertLog(SmsParserLogsCompanion entry) =>
      into(smsParserLogs).insert(entry, onConflict: DoNothing());

  Future<List<SmsParserLog>> getRecent({int limit = 100}) =>
      (select(smsParserLogs)
            ..orderBy([(l) => OrderingTerm.desc(l.processedAt)])
            ..limit(limit))
          .get();

  Future<List<SmsParserLog>> getPending({int limit = 100}) =>
      (select(smsParserLogs)
            ..where((l) => l.parsedStatus.equals('pending'))
            ..orderBy([(l) => OrderingTerm.desc(l.receivedAt)])
            ..limit(limit))
          .get();

  Stream<List<SmsParserLog>> watchPending({int limit = 100}) =>
      (select(smsParserLogs)
            ..where((l) => l.parsedStatus.equals('pending'))
            ..orderBy([(l) => OrderingTerm.desc(l.receivedAt)])
            ..limit(limit))
          .watch();

  /// Get pending logs that have no AI enrichment yet (for sync-on-reconnect).
  Future<List<SmsParserLog>> getPendingUnenriched({int limit = 20}) =>
      (select(smsParserLogs)
            ..where((l) => l.parsedStatus.equals('pending'))
            ..where((l) => l.aiEnrichmentJson.isNull())
            ..orderBy([(l) => OrderingTerm.desc(l.receivedAt)])
            ..limit(limit))
          .get();

  /// Update AI enrichment JSON for a log entry.
  Future<void> updateEnrichment(int id, String enrichmentJson) =>
      (update(smsParserLogs)..where((l) => l.id.equals(id))).write(
        SmsParserLogsCompanion(
          aiEnrichmentJson: Value(enrichmentJson),
        ),
      );

  /// Update the status of a log entry (approved/skipped/failed).
  /// For non-approved statuses, clears the raw body to avoid storing
  /// bank SMS content (partial account numbers, amounts) permanently.
  Future<void> markStatus(
    int id,
    String status, {
    int? transactionId,
  }) =>
      (update(smsParserLogs)..where((l) => l.id.equals(id))).write(
        SmsParserLogsCompanion(
          parsedStatus: Value(status),
          transactionId: Value(transactionId),
          processedAt: Value(DateTime.now()),
          // Redact body for non-approved entries to avoid storing bank data
          body: status != 'approved'
              ? const Value('[redacted]')
              : const Value.absent(),
        ),
      );
}
