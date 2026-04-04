import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/sms_parser_logs_table.dart';

part 'sms_parser_log_dao.g.dart';

@DriftAccessor(tables: [SmsParserLogs])
class SmsParserLogDao extends DatabaseAccessor<AppDatabase>
    with _$SmsParserLogDaoMixin {
  SmsParserLogDao(super.db);

  Stream<List<SmsParserLog>> watchPending({int limit = 100}) =>
      (select(smsParserLogs)
            ..where((l) => l.parsedStatus.equals('pending'))
            ..orderBy([(l) => OrderingTerm.desc(l.receivedAt)])
            ..limit(limit))
          .watch();

  /// Lightweight count-only stream for dashboard badge — avoids loading
  /// full rows with body text and enrichment JSON.
  Stream<int> watchPendingCount() => customSelect(
        'SELECT COUNT(*) AS cnt FROM sms_parser_logs WHERE parsed_status = ?',
        variables: [Variable.withString('pending')],
        readsFrom: {smsParserLogs},
      ).watchSingle().map((row) => row.read<int>('cnt'));

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
