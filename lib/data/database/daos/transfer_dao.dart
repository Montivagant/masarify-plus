import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/transfers_table.dart';

part 'transfer_dao.g.dart';

@DriftAccessor(tables: [Transfers])
class TransferDao extends DatabaseAccessor<AppDatabase>
    with _$TransferDaoMixin {
  TransferDao(super.db);

  Stream<List<Transfer>> watchAll({int limit = 50, int offset = 0}) =>
      (select(transfers)
            ..orderBy([(t) => OrderingTerm.desc(t.transferDate)])
            ..limit(limit, offset: offset))
          .watch();

  Stream<List<Transfer>> watchByWallet(
    int walletId, {
    int limit = 50,
    int offset = 0,
  }) =>
      (select(transfers)
            ..where(
              (t) =>
                  t.fromWalletId.equals(walletId) |
                  t.toWalletId.equals(walletId),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.transferDate)])
            ..limit(limit, offset: offset))
          .watch();

  Future<Transfer?> getById(int id) =>
      (select(transfers)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> insertTransfer(TransfersCompanion entry) =>
      into(transfers).insert(entry);

  Future<bool> deleteById(int id) =>
      (delete(transfers)..where((t) => t.id.equals(id)))
          .go()
          .then((count) => count > 0);

  /// H10 fix: count transfers involving this wallet (as source or dest).
  Future<int> countByWallet(int walletId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM transfers '
      'WHERE from_wallet_id = ? OR to_wallet_id = ?',
      variables: [
        Variable.withInt(walletId),
        Variable.withInt(walletId),
      ],
      readsFrom: {transfers},
    ).getSingle();
    return result.read<int>('cnt');
  }
}
