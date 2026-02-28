import '../entities/transfer_entity.dart';

/// Transfers are NEVER counted as income or expense. Rule #8.
abstract interface class ITransferRepository {
  Stream<List<TransferEntity>> watchAll();

  Stream<List<TransferEntity>> watchByWallet(int walletId);

  Future<TransferEntity?> getById(int id);

  /// Creates the transfer AND atomically adjusts both wallet balances.
  /// Returns the new transfer's id.
  Future<int> create({
    required int fromWalletId,
    required int toWalletId,
    required int amount,
    int fee = 0,
    String? note,
    required DateTime transferDate,
  });

  /// Deletes the transfer AND reverses both wallet balance adjustments atomically.
  Future<bool> delete(int id);
}
