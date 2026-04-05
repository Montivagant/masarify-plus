import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction_entity.dart';
import 'repository_providers.dart';
import 'wallet_provider.dart';

/// Sentinel that changes whenever any transaction is created, updated, or deleted.
/// Use this as a staleness trigger instead of watching paginated data.
final transactionChangeTriggerProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(transactionRepositoryProvider);
  return repo.watchCount();
});

/// Set of archived wallet IDs — used to filter transactions from archived
/// wallets out of display lists. Derived from allWalletsProvider so it
/// reactively updates when a wallet is archived or unarchived.
final archivedWalletIdsProvider = Provider<Set<int>>((ref) {
  final allWallets = ref.watch(allWalletsProvider).valueOrNull ?? [];
  return allWallets.where((w) => w.isArchived).map((w) => w.id).toSet();
});

/// Recent transactions (paginated, most recent first).
/// Excludes transactions from archived wallets.
final recentTransactionsProvider =
    Provider<AsyncValue<List<TransactionEntity>>>(
  (ref) {
    final archivedIds = ref.watch(archivedWalletIdsProvider);
    final txsAsync = ref.watch(rawRecentTransactionsProvider);
    return txsAsync.whenData(
      (txs) => txs.where((tx) => !archivedIds.contains(tx.walletId)).toList(),
    );
  },
);

/// Raw stream of all recent transactions (unfiltered by archive status).
final rawRecentTransactionsProvider = StreamProvider<List<TransactionEntity>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchAll(),
);

/// Transactions for a specific (year, month) pair.
/// Excludes transactions from archived wallets.
final transactionsByMonthProvider =
    Provider.family<AsyncValue<List<TransactionEntity>>, (int, int)>(
  (ref, params) {
    final archivedIds = ref.watch(archivedWalletIdsProvider);
    final txsAsync = ref.watch(rawTransactionsByMonthProvider(params));
    return txsAsync.whenData(
      (txs) => txs.where((tx) => !archivedIds.contains(tx.walletId)).toList(),
    );
  },
);

/// Raw stream for a (year, month) pair (unfiltered by archive status).
final rawTransactionsByMonthProvider =
    StreamProvider.family<List<TransactionEntity>, (int, int)>(
  (ref, params) => ref
      .watch(transactionRepositoryProvider)
      .watchByMonth(params.$1, params.$2),
);

/// H14 fix: Total income for a given (year, month).
/// Derived from the reactive [transactionsByMonthProvider] stream — no
/// redundant DB round-trip needed.
final monthlyIncomeProvider = Provider.family<int, (int, int)>((ref, params) {
  final txs = ref.watch(transactionsByMonthProvider(params)).valueOrNull ?? [];
  return txs.where((t) => t.type == 'income').fold(0, (s, t) => s + t.amount);
});

/// H14 fix: Total expense for a given (year, month).
/// Derived from the reactive [transactionsByMonthProvider] stream.
final monthlyExpenseProvider = Provider.family<int, (int, int)>((ref, params) {
  final txs = ref.watch(transactionsByMonthProvider(params)).valueOrNull ?? [];
  return txs.where((t) => t.type == 'expense').fold(0, (s, t) => s + t.amount);
});

/// M1 fix: single transaction by id — auto-invalidates after edits via ref.watch.
final transactionByIdProvider =
    FutureProvider.autoDispose.family<TransactionEntity?, int>((ref, id) {
  // Depend on the reactive stream so this re-fires after mutations.
  // autoDispose ensures fresh data on each screen visit.
  ref.watch(recentTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getById(id);
});
