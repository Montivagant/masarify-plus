import 'package:drift/drift.dart';

import '../../domain/entities/sms_parser_log_entity.dart';
import '../../domain/repositories/i_sms_parser_log_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../domain/repositories/i_transfer_repository.dart';
import '../database/app_database.dart';
import '../database/daos/sms_parser_log_dao.dart';

class SmsParserLogRepositoryImpl implements ISmsParserLogRepository {
  const SmsParserLogRepositoryImpl(
    this._dao,
    this._db,
    this._txRepo,
    this._transferRepo,
  );

  final SmsParserLogDao _dao;
  final AppDatabase _db;
  final ITransactionRepository _txRepo;
  final ITransferRepository _transferRepo;

  // ── Streams ──────────────────────────────────────────────────────────────

  @override
  Stream<List<SmsParserLogEntity>> watchPending({int limit = 100}) =>
      _dao.watchPending(limit: limit).map(
            (list) => list.map(_toEntity).toList(),
          );

  @override
  Stream<int> watchPendingCount() => _dao.watchPendingCount();

  // ── Mutations ─────────────────────────────────────────────────────────────

  @override
  Future<void> markStatus(
    int id,
    String status, {
    int? transactionId,
  }) =>
      _dao.markStatus(id, status, transactionId: transactionId);

  @override
  Future<void> updateEnrichment(int id, String enrichmentJson) =>
      _dao.updateEnrichment(id, enrichmentJson);

  @override
  Future<void> linkTransfer(int logId, int transferId) =>
      (_db.update(_db.smsParserLogs)..where((l) => l.id.equals(logId))).write(
        SmsParserLogsCompanion(
          transferId: Value(transferId),
        ),
      );

  // ── Atomic approve operations ─────────────────────────────────────────────

  @override
  Future<int> approveAsTransaction({
    required int logId,
    required int walletId,
    required int categoryId,
    required int amount,
    required String type,
    required String title,
    required DateTime transactionDate,
    String currencyCode = 'EGP',
    String source = 'sms',
    String? rawSourceText,
  }) =>
      _db.transaction(() async {
        final txId = await _txRepo.create(
          walletId: walletId,
          categoryId: categoryId,
          amount: amount,
          type: type,
          title: title,
          transactionDate: transactionDate,
          currencyCode: currencyCode,
          source: source,
          rawSourceText: rawSourceText,
        );
        await _dao.markStatus(logId, 'approved', transactionId: txId);
        return txId;
      });

  @override
  Future<int> approveAsTransfer({
    required int logId,
    required int fromWalletId,
    required int toWalletId,
    required int amount,
    required DateTime transferDate,
    String? note,
  }) =>
      _db.transaction(() async {
        final transferId = await _transferRepo.create(
          fromWalletId: fromWalletId,
          toWalletId: toWalletId,
          amount: amount,
          transferDate: transferDate,
          note: note,
        );
        await _dao.markStatus(logId, 'approved');
        await linkTransfer(logId, transferId);
        return transferId;
      });

  // ── Mapping ───────────────────────────────────────────────────────────────

  static SmsParserLogEntity _toEntity(SmsParserLog row) => SmsParserLogEntity(
        id: row.id,
        senderAddress: row.senderAddress,
        bodyHash: row.bodyHash,
        body: row.body,
        parsedStatus: row.parsedStatus,
        transactionId: row.transactionId,
        source: row.source,
        receivedAt: row.receivedAt,
        processedAt: row.processedAt,
        aiEnrichmentJson: row.aiEnrichmentJson,
        semanticFingerprint: row.semanticFingerprint,
        transferId: row.transferId,
      );
}
