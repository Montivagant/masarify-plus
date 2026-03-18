import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/parsed_event_groups_table.dart';
import '../tables/sms_parser_logs_table.dart';

part 'parsed_event_group_dao.g.dart';

@DriftAccessor(tables: [ParsedEventGroups, SmsParserLogs])
class ParsedEventGroupDao extends DatabaseAccessor<AppDatabase>
    with _$ParsedEventGroupDaoMixin {
  ParsedEventGroupDao(super.db);

  /// Find a group by any of the given fingerprints (current + adjacent window).
  Future<ParsedEventGroup?> findByFingerprints(
    List<String> fingerprints,
  ) async {
    return (select(parsedEventGroups)
          ..where((g) => g.semanticFingerprint.isIn(fingerprints))
          ..limit(1))
        .getSingleOrNull();
  }

  /// Create a new event group with the given log as canonical.
  /// Uses ON CONFLICT DO NOTHING on the unique fingerprint to safely handle
  /// concurrent SMS + notification processing without crashing.
  Future<int> createGroup({
    required String fingerprint,
    required int canonicalLogId,
    required int amountPiastres,
    required String type,
    int? resolvedWalletId,
    String eventType = 'transaction',
    required DateTime eventTime,
  }) {
    return into(parsedEventGroups).insert(
      ParsedEventGroupsCompanion.insert(
        semanticFingerprint: fingerprint,
        canonicalLogId: canonicalLogId,
        amountPiastres: amountPiastres,
        type: type,
        resolvedWalletId: Value(resolvedWalletId),
        eventType: Value(eventType),
        eventTime: eventTime,
      ),
      onConflict: DoNothing(),
    );
  }

  /// Mark a log as 'duplicate' and link it to an existing group.
  /// Keeps the original body so false-positive duplicates can be reviewed.
  Future<void> markAsDuplicate(int logId, String fingerprint) async {
    await (update(smsParserLogs)..where((l) => l.id.equals(logId))).write(
      SmsParserLogsCompanion(
        parsedStatus: const Value('duplicate'),
        semanticFingerprint: Value(fingerprint),
      ),
    );
  }

  /// Update the semantic fingerprint on a log entry.
  Future<void> setLogFingerprint(int logId, String fingerprint) async {
    await (update(smsParserLogs)..where((l) => l.id.equals(logId))).write(
      SmsParserLogsCompanion(
        semanticFingerprint: Value(fingerprint),
      ),
    );
  }
}
