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

  /// Update the status of a log entry (approved/skipped/failed).
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
        ),
      );
}
