import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/wallets_table.dart';

part 'wallet_dao.g.dart';

@DriftAccessor(tables: [Wallets])
class WalletDao extends DatabaseAccessor<AppDatabase> with _$WalletDaoMixin {
  WalletDao(super.db);

  /// All non-archived wallets — system wallet first, then by sortOrder, id.
  Stream<List<Wallet>> watchAll() => (select(wallets)
        ..where((w) => w.isArchived.not())
        ..orderBy([
          (w) => OrderingTerm.desc(w.isSystemWallet),
          (w) => OrderingTerm.asc(w.sortOrder),
          (w) => OrderingTerm.asc(w.id),
        ]))
      .watch();

  Future<List<Wallet>> getAll() => (select(wallets)
        ..where((w) => w.isArchived.not())
        ..orderBy([
          (w) => OrderingTerm.desc(w.isSystemWallet),
          (w) => OrderingTerm.asc(w.sortOrder),
          (w) => OrderingTerm.asc(w.id),
        ]))
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

  Future<bool> archive(int id) async {
    return transaction(() async {
      final wallet = await getById(id);
      if (wallet != null && wallet.isSystemWallet) {
        throw ArgumentError(
          'The Physical Cash system wallet cannot be archived',
        );
      }
      if (wallet != null && wallet.isDefaultAccount) {
        throw ArgumentError(
          'The Default account cannot be archived',
        );
      }
      return (update(wallets)..where((w) => w.id.equals(id)))
          .write(const WalletsCompanion(isArchived: Value(true)))
          .then((count) => count > 0);
    });
  }

  /// The mandatory Physical Cash system wallet (always exists after onboarding).
  Future<Wallet?> getSystemWallet() =>
      (select(wallets)..where((w) => w.isSystemWallet.equals(true)))
          .getSingleOrNull();

  Stream<Wallet?> watchSystemWallet() =>
      (select(wallets)..where((w) => w.isSystemWallet.equals(true)))
          .watchSingleOrNull();

  /// The mandatory default bank account (fallback for transaction assignment).
  Future<Wallet?> getDefaultAccount() =>
      (select(wallets)..where((w) => w.isDefaultAccount.equals(true)))
          .getSingleOrNull();

  Stream<Wallet?> watchDefaultAccount() =>
      (select(wallets)..where((w) => w.isDefaultAccount.equals(true)))
          .watchSingleOrNull();

  /// Unarchive a wallet (set isArchived = false).
  Future<bool> unarchive(int id) async {
    return (update(wallets)..where((w) => w.id.equals(id)))
        .write(const WalletsCompanion(isArchived: Value(false)))
        .then((count) => count > 0);
  }

  /// All wallets INCLUDING archived — for the Wallets management screen.
  Stream<List<Wallet>> watchAllIncludingArchived() => (select(wallets)
        ..orderBy([
          (w) => OrderingTerm.desc(w.isSystemWallet),
          (w) => OrderingTerm.asc(w.isArchived),
          (w) => OrderingTerm.asc(w.sortOrder),
          (w) => OrderingTerm.asc(w.id),
        ]))
      .watch();

  /// All wallets INCLUDING archived — one-shot Future variant.
  Future<List<Wallet>> getAllIncludingArchived() => (select(wallets)
        ..orderBy([
          (w) => OrderingTerm.desc(w.isSystemWallet),
          (w) => OrderingTerm.asc(w.isArchived),
          (w) => OrderingTerm.asc(w.sortOrder),
          (w) => OrderingTerm.asc(w.id),
        ]))
      .get();

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

  /// Total balance across all non-archived, non-system wallets (in piastres).
  /// Excludes the Cash system wallet so "All Accounts" shows bank-only total.
  Future<int> getTotalBalance() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(balance), 0) AS total '
      'FROM wallets WHERE is_archived = 0 AND is_system_wallet = 0',
      readsFrom: {wallets},
    ).getSingle();
    return result.read<int>('total');
  }

  /// Check if a wallet has any transactions, transfers, or goal contributions referencing it.
  Future<bool> hasReferences(int walletId) async {
    final result = await customSelect(
      'SELECT EXISTS('
      '  SELECT 1 FROM transactions WHERE wallet_id = ?'
      ') OR EXISTS('
      '  SELECT 1 FROM transfers WHERE from_wallet_id = ? OR to_wallet_id = ?'
      ') OR EXISTS('
      '  SELECT 1 FROM goal_contributions WHERE wallet_id = ?'
      ') AS has_refs',
      variables: [
        Variable.withInt(walletId),
        Variable.withInt(walletId),
        Variable.withInt(walletId),
        Variable.withInt(walletId),
      ],
      readsFrom: {
        attachedDatabase.transactions,
        attachedDatabase.transfers,
        attachedDatabase.goalContributions,
      },
    ).getSingle();
    return result.read<int>('has_refs') == 1;
  }

  /// Batch-update sort orders for carousel drag-and-drop reordering.
  Future<void> updateSortOrders(List<({int id, int sortOrder})> updates) async {
    await batch((b) {
      for (final u in updates) {
        b.update(
          wallets,
          WalletsCompanion(sortOrder: Value(u.sortOrder)),
          where: (w) => w.id.equals(u.id),
        );
      }
    });
  }

  /// H4 fix: reactive stream of total balance across all non-archived,
  /// non-system wallets. Excludes Cash so "All Accounts" shows bank-only total.
  Stream<int> watchTotalBalance() => customSelect(
        'SELECT COALESCE(SUM(balance), 0) AS total '
        'FROM wallets WHERE is_archived = 0 AND is_system_wallet = 0',
        readsFrom: {wallets},
      ).watchSingle().map((row) => row.read<int>('total'));
}
