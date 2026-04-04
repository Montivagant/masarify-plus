import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'category_provider.dart';
import 'repository_providers.dart';
import 'theme_provider.dart';
import 'transaction_provider.dart';

// ── Report filter state ─────────────────────────────────────────────────

/// Selected wallet ID for reports filtering (null = all wallets).
final reportsWalletFilterProvider = StateProvider<int?>((ref) => null);

/// Selected transaction type for reports ('expense', 'income', or null for both).
final reportsTypeFilterProvider = StateProvider<String?>((ref) => null);

/// Selected month for category breakdown (defaults to current month).
final reportsCategoryMonthProvider =
    StateProvider<(int year, int month)>((ref) {
  final now = DateTime.now();
  return (now.year, now.month);
});

// ── Monthly income/expense pair ──────────────────────────────────────────

class MonthlyTotal {
  const MonthlyTotal({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
  });

  final int year;
  final int month;
  final int income;
  final int expense;

  int get net => income - expense;
}

// ── Category spending aggregate ──────────────────────────────────────────

class CategorySpending {
  const CategorySpending({
    required this.categoryId,
    required this.categoryName,
    required this.colorHex,
    required this.iconName,
    required this.amount,
    required this.fraction,
  });

  final int categoryId;
  final String categoryName;
  final String colorHex;
  final String iconName;
  final int amount;
  final double fraction;
}

// ── Daily spending for trend charts ──────────────────────────────────────

class DailySpending {
  const DailySpending({required this.date, required this.amount});

  final DateTime date;
  final int amount;
}

// ── Last N months income vs expense ──────────────────────────────────────

/// Returns [MonthlyTotal] for the last [count] months (most recent last).
/// Respects wallet and type filters from reports filter bar.
final monthlyTotalsProvider =
    FutureProvider.family<List<MonthlyTotal>, int>((ref, count) async {
  final now = DateTime.now();
  final repo = ref.watch(transactionRepositoryProvider);
  // Watch all recent transactions so past-month edits also trigger refresh
  ref.watch(recentTransactionsProvider);
  final walletId = ref.watch(reportsWalletFilterProvider);
  final typeFilter = ref.watch(reportsTypeFilterProvider);
  final results = <MonthlyTotal>[];

  for (var i = count - 1; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i);
    final y = d.year;
    final m = d.month;

    if (typeFilter != null) {
      final sum =
          await repo.sumByTypeAndMonth(typeFilter, y, m, walletId: walletId);
      final isIncome = typeFilter == 'income';
      results.add(
        MonthlyTotal(
          year: y,
          month: m,
          income: isIncome ? sum : 0,
          expense: isIncome ? 0 : sum,
        ),
      );
    } else {
      final [income, expense] = await Future.wait([
        repo.sumByTypeAndMonth('income', y, m, walletId: walletId),
        repo.sumByTypeAndMonth('expense', y, m, walletId: walletId),
      ]);
      results.add(
        MonthlyTotal(year: y, month: m, income: income, expense: expense),
      );
    }
  }

  return results;
});

// ── Category breakdown for a given month ─────────────────────────────────

/// Categories ranked by amount for a (year, month).
/// Respects wallet and type filters from reports filter bar.
final categoryBreakdownProvider =
    Provider.family<AsyncValue<List<CategorySpending>>, (int year, int month)>(
  (ref, params) {
    final txAsync = ref.watch(transactionsByMonthProvider(params));
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final lang = ref.watch(localeProvider)?.languageCode ?? 'en';
    final walletId = ref.watch(reportsWalletFilterProvider);
    final typeFilter = ref.watch(reportsTypeFilterProvider);
    return txAsync.whenData((transactions) {
      var filtered = transactions.where(
        (tx) => tx.type == (typeFilter ?? 'expense'),
      );
      if (walletId != null) {
        filtered = filtered.where((tx) => tx.walletId == walletId);
      }
      final byCategory = <int, int>{};
      for (final tx in filtered) {
        byCategory[tx.categoryId] =
            (byCategory[tx.categoryId] ?? 0) + tx.amount;
      }

      final sorted = byCategory.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final total = sorted.fold<int>(0, (s, e) => s + e.value);
      if (total == 0) return <CategorySpending>[];

      final categoryMap = {for (final c in categories) c.id: c};

      return sorted.map((entry) {
        final cat = categoryMap[entry.key];
        return CategorySpending(
          categoryId: entry.key,
          categoryName: cat?.displayName(lang) ?? '?',
          colorHex: cat?.colorHex ?? '#9E9E9E',
          iconName: cat?.iconName ?? 'category',
          amount: entry.value,
          fraction: entry.value / total,
        );
      }).toList();
    });
  },
);

// ── Daily spending for trend line ────────────────────────────────────────

/// Daily totals for the last [days] days.
/// Respects wallet and type filters from reports filter bar.
final dailySpendingProvider =
    FutureProvider.family<List<DailySpending>, int>((ref, days) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(Duration(days: days - 1));
  final end = today.add(const Duration(days: 1));

  final repo = ref.watch(transactionRepositoryProvider);
  ref.watch(recentTransactionsProvider);
  final walletId = ref.watch(reportsWalletFilterProvider);
  final typeFilter = ref.watch(reportsTypeFilterProvider);
  final txns = await repo.getByDateRange(start, end);

  final dailyMap = <DateTime, int>{};
  for (var i = 0; i < days; i++) {
    final d = DateTime(start.year, start.month, start.day + i);
    dailyMap[d] = 0;
  }

  for (final tx in txns) {
    final matchesType = tx.type == (typeFilter ?? 'expense');
    if (matchesType) {
      final matchesWallet = walletId == null || tx.walletId == walletId;
      if (matchesWallet) {
        final key = DateTime(
          tx.transactionDate.year,
          tx.transactionDate.month,
          tx.transactionDate.day,
        );
        dailyMap[key] = (dailyMap[key] ?? 0) + tx.amount;
      }
    }
  }

  return dailyMap.entries
      .map((e) => DailySpending(date: e.key, amount: e.value))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
});
