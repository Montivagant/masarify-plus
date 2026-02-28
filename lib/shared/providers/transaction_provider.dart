import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transaction_entity.dart';
import 'repository_providers.dart';

/// Recent transactions (paginated, most recent first).
final recentTransactionsProvider = StreamProvider<List<TransactionEntity>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchAll(),
);

/// Transactions for a specific (year, month) pair.
final transactionsByMonthProvider =
    StreamProvider.family<List<TransactionEntity>, (int, int)>(
  (ref, params) => ref
      .watch(transactionRepositoryProvider)
      .watchByMonth(params.$1, params.$2),
);

/// Transactions for a specific wallet.
final transactionsByWalletProvider =
    StreamProvider.family<List<TransactionEntity>, int>(
  (ref, walletId) =>
      ref.watch(transactionRepositoryProvider).watchByWallet(walletId),
);

/// H14 fix: Total income for a given (year, month).
/// Derived from the reactive [transactionsByMonthProvider] stream — no
/// redundant DB round-trip needed.
final monthlyIncomeProvider =
    Provider.family<int, (int, int)>((ref, params) {
  final txs = ref.watch(transactionsByMonthProvider(params)).valueOrNull ?? [];
  return txs
      .where((t) => t.type == 'income')
      .fold(0, (s, t) => s + t.amount);
});

/// H14 fix: Total expense for a given (year, month).
/// Derived from the reactive [transactionsByMonthProvider] stream.
final monthlyExpenseProvider =
    Provider.family<int, (int, int)>((ref, params) {
  final txs = ref.watch(transactionsByMonthProvider(params)).valueOrNull ?? [];
  return txs
      .where((t) => t.type == 'expense')
      .fold(0, (s, t) => s + t.amount);
});

/// M1 fix: single transaction by id — auto-invalidates after edits via ref.watch.
final transactionByIdProvider =
    FutureProvider.autoDispose.family<TransactionEntity?, int>((ref, id) {
  // Depend on the reactive stream so this re-fires after mutations.
  // autoDispose ensures fresh data on each screen visit.
  ref.watch(recentTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getById(id);
});
