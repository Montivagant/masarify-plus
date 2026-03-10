import 'package:drift/drift.dart';

import '../../domain/entities/transfer_entity.dart';
import '../../domain/repositories/i_transfer_repository.dart';
import '../database/app_database.dart';
import '../database/daos/transfer_dao.dart';
import '../database/daos/wallet_dao.dart';

class TransferRepositoryImpl implements ITransferRepository {
  const TransferRepositoryImpl(this._dao, this._walletDao, this._db);

  final TransferDao _dao;
  final WalletDao _walletDao;
  final AppDatabase _db;

  // ── Streams ──────────────────────────────────────────────────────────────

  @override
  Stream<List<TransferEntity>> watchAll() =>
      _dao.watchAll().map((list) => list.map(_toEntity).toList());

  @override
  Stream<List<TransferEntity>> watchByWallet(int walletId) =>
      _dao.watchByWallet(walletId).map((list) => list.map(_toEntity).toList());

  // ── Queries ───────────────────────────────────────────────────────────────

  @override
  Future<TransferEntity?> getById(int id) async {
    final row = await _dao.getById(id);
    return row != null ? _toEntity(row) : null;
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  @override
  Future<int> create({
    required int fromWalletId,
    required int toWalletId,
    required int amount,
    int fee = 0,
    String? note,
    required DateTime transferDate,
  }) async {
    // C2 fix: validate transfer amount is positive
    if (amount <= 0) {
      throw ArgumentError('Transfer amount must be positive');
    }
    // L3 fix: block same-wallet transfer at repository level
    if (fromWalletId == toWalletId) {
      throw ArgumentError('Cannot transfer to the same wallet');
    }
    // L4 fix: validate fee is non-negative
    if (fee < 0) {
      throw ArgumentError('Transfer fee cannot be negative');
    }
    return _db.transaction(() async {
      // Validate wallets exist and are not archived
      final fromWallet = await _walletDao.getById(fromWalletId);
      if (fromWallet == null) {
        throw ArgumentError('Source wallet does not exist');
      }
      if (fromWallet.isArchived) {
        throw ArgumentError('Cannot transfer from archived account');
      }
      final toWallet = await _walletDao.getById(toWalletId);
      if (toWallet == null) {
        throw ArgumentError('Destination wallet does not exist');
      }
      if (toWallet.isArchived) {
        throw ArgumentError('Cannot transfer to archived account');
      }
      final id = await _dao.insertTransfer(
        TransfersCompanion.insert(
          fromWalletId: fromWalletId,
          toWalletId: toWalletId,
          amount: amount,
          fee: Value(fee),
          note: Value(note),
          transferDate: transferDate,
        ),
      );
      // Deduct from source (amount + fee)
      await _walletDao.adjustBalance(fromWalletId, -(amount + fee));
      // Credit destination (amount only)
      await _walletDao.adjustBalance(toWalletId, amount);
      return id;
    });
  }

  @override
  Future<bool> delete(int id) async {
    // L2 fix: move read inside transaction to avoid TOCTOU race
    return _db.transaction(() async {
      final existing = await _dao.getById(id);
      if (existing == null) return false;
      // H8 fix: check wallet existence before balance reversal
      final fromWallet = await _walletDao.getById(existing.fromWalletId);
      final toWallet = await _walletDao.getById(existing.toWalletId);
      // Reverse: restore source, deduct from destination (skip if archived/deleted)
      if (fromWallet != null) {
        await _walletDao.adjustBalance(
          existing.fromWalletId,
          existing.amount + existing.fee,
        );
      }
      if (toWallet != null) {
        await _walletDao.adjustBalance(existing.toWalletId, -existing.amount);
      }
      return _dao.deleteById(id);
    });
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  static TransferEntity _toEntity(Transfer t) => TransferEntity(
        id: t.id,
        fromWalletId: t.fromWalletId,
        toWalletId: t.toWalletId,
        amount: t.amount,
        fee: t.fee,
        note: t.note,
        transferDate: t.transferDate,
        createdAt: t.createdAt,
      );
}
