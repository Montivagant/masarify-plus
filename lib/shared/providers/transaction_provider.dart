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
/// Depends on the reactive transaction stream so it auto-refreshes
/// when transactions change, without requiring navigation away and back.
final monthlyIncomeProvider =
    FutureProvider.family<int, (int, int)>((ref, params) {
  // Watch the transaction stream to trigger re-computation on changes
  ref.watch(transactionsByMonthProvider(params));
  return ref
      .read(transactionRepositoryProvider)
      .sumByTypeAndMonth('income', params.$1, params.$2);
});

/// H14 fix: Total expense for a given (year, month).
/// Same reactive pattern as monthlyIncomeProvider.
final monthlyExpenseProvider =
    FutureProvider.family<int, (int, int)>((ref, params) {
  // Watch the transaction stream to trigger re-computation on changes
  ref.watch(transactionsByMonthProvider(params));
  return ref
      .read(transactionRepositoryProvider)
      .sumByTypeAndMonth('expense', params.$1, params.$2);
});

/// M1 fix: single transaction by id — auto-invalidates after edits via ref.watch.
final transactionByIdProvider =
    FutureProvider.autoDispose.family<TransactionEntity?, int>((ref, id) {
  // Depend on the reactive stream so this re-fires after mutations.
  // autoDispose ensures fresh data on each screen visit.
  ref.watch(recentTransactionsProvider);
  return ref.read(transactionRepositoryProvider).getById(id);
});
