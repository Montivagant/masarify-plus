import '../entities/sms_parser_log_entity.dart';

abstract interface class ISmsParserLogRepository {
  /// Reactive stream of pending parsed logs, ordered by receivedAt descending.
  Stream<List<SmsParserLogEntity>> watchPending({int limit = 100});

  /// Lightweight count-only stream for dashboard badge — avoids loading
  /// full rows with body text and enrichment JSON.
  Stream<int> watchPendingCount();

  /// Update the status of a log entry (approved/skipped/failed).
  /// For non-approved statuses, clears the raw body to avoid storing
  /// bank SMS content permanently.
  Future<void> markStatus(int id, String status, {int? transactionId});

  /// Update AI enrichment JSON for a log entry.
  Future<void> updateEnrichment(int id, String enrichmentJson);

  /// Link a transfer to a parser log entry (ATM withdrawal -> bank-to-cash).
  Future<void> linkTransfer(int logId, int transferId);
}
