import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/wallets_table.dart';

part 'wallet_dao.g.dart';

@DriftAccessor(tables: [Wallets])
class WalletDao extends DatabaseAccessor<AppDatabase> with _$WalletDaoMixin {
  WalletDao(super.db);

  /// All non-archived wallets ordered by displayOrder
  Stream<List<Wallet>> watchAll() => (select(wallets)
        ..where((w) => w.isArchived.not())
        ..orderBy([(w) => OrderingTerm.asc(w.displayOrder)]))
      .watch();

  Future<List<Wallet>> getAll() => (select(wallets)
        ..where((w) => w.isArchived.not())
        ..orderBy([(w) => OrderingTerm.asc(w.displayOrder)]))
      .get();

  Future<Wallet?> getById(int id) =>
      (select(wallets)..where((w) => w.id.equals(id))).getSingleOrNull();

  Stream<Wallet?> watchById(int id) =>
      (select(wallets)..where((w) => w.id.equals(id))).watchSingleOrNull();

  /// Returns the auto-incremented integer PK of the inserted row.
  Future<int> insertWallet(WalletsCompanion entry) =>
      into(wallets).insert(entry);

  Future<bool> saveWallet(WalletsCompanion entry) =>
      (update(wallets)..where((w) => w.id.equals(entry.id.value)))
          .write(entry)
          .then((count) => count > 0);

  Future<bool> archive(int id) =>
      (update(wallets)..where((w) => w.id.equals(id)))
          .write(const WalletsCompanion(isArchived: Value(true)))
          .then((count) => count > 0);

  /// M3 fix: check if a wallet with the given name already exists.
  Future<bool> existsByName(String name, {int? excludeId}) async {
    final query = select(wallets)
      ..where(
        (w) => w.name.equals(name) & w.isArchived.not(),
      );
    if (excludeId != null) {
      query.where((w) => w.id.equals(excludeId).not());
    }
    final result = await query.get();
    return result.isNotEmpty;
  }

  /// Adjust balance by [deltaPiastres] (positive = add, negative = subtract)
  Future<void> adjustBalance(int id, int deltaPiastres) async {
    await customUpdate(
      'UPDATE wallets SET balance = balance + ? WHERE id = ?',
      variables: [Variable.withInt(deltaPiastres), Variable.withInt(id)],
      updates: {wallets},
    );
  }

  /// Total balance across all non-archived wallets (in piastres)
  Future<int> getTotalBalance() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(balance), 0) AS total '
      'FROM wallets WHERE is_archived = 0',
      readsFrom: {wallets},
    ).getSingle();
    return result.read<int>('total');
  }

  /// Check if a wallet has any transactions or transfers referencing it.
  Future<bool> hasReferences(int walletId) async {
    final result = await customSelect(
      'SELECT EXISTS('
      '  SELECT 1 FROM transactions WHERE wallet_id = ?'
      ') OR EXISTS('
      '  SELECT 1 FROM transfers WHERE from_wallet_id = ? OR to_wallet_id = ?'
      ') AS has_refs',
      variables: [
        Variable.withInt(walletId),
        Variable.withInt(walletId),
        Variable.withInt(walletId),
      ],
    ).getSingle();
    return result.read<int>('has_refs') == 1;
  }

  /// H4 fix: reactive stream of total balance across all non-archived wallets.
  Stream<int> watchTotalBalance() =>
      customSelect(
        'SELECT COALESCE(SUM(balance), 0) AS total '
        'FROM wallets WHERE is_archived = 0',
        readsFrom: {wallets},
      ).watchSingle().map((row) => row.read<int>('total'));
}
