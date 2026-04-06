import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'category_provider.dart';
import 'repository_providers.dart';
import 'theme_provider.dart';
import 'transaction_provider.dart';

// ── Report filter state ─────────────────────────────────────────────────

/// Selected month for category breakdown (defaults to current month).
final reportsCategoryMonthProvider =
    StateProvider<(int year, int month)>((ref) {
  final now = DateTime.now();
  return (now.year, now.month);
});

// ── Data classes ────────────────────────────────────────────────────────

/// Monthly income/expense pair.
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

/// Category spending aggregate.
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

/// Daily spending for trend charts.
class DailySpending {
  const DailySpending({required this.date, required this.amount});

  final DateTime date;
  final int amount;
}

// ── Parameterized provider parameter types ──────────────────────────────
// Each tab passes its own filter values via these records, so tabs don't
// share global filter state.

/// Params for [monthlyTotalsProvider].
typedef MonthlyTotalsParams = ({
  int count,
  int? walletId,
  String? typeFilter,
});

/// Params for [categoryBreakdownProvider].
typedef CategoryBreakdownParams = ({
  int year,
  int month,
  int? walletId,
  String? typeFilter,
});

/// Params for [dailySpendingProvider].
typedef DailySpendingParams = ({
  int days,
  int? walletId,
  String? typeFilter,
});

// ── Last N months income vs expense ──────────────────────────────────────

/// Returns [MonthlyTotal] for the last [p.count] months (most recent last).
/// Wallet and type filters are passed via [MonthlyTotalsParams].
final monthlyTotalsProvider = FutureProvider.autoDispose
    .family<List<MonthlyTotal>, MonthlyTotalsParams>((ref, p) async {
  final now = DateTime.now();
  final repo = ref.watch(transactionRepositoryProvider);
  ref.watch(transactionChangeTriggerProvider);
  final results = <MonthlyTotal>[];

  for (var i = p.count - 1; i >= 0; i--) {
    final d = DateTime(now.year, now.month - i);
    final y = d.year;
    final m = d.month;

    if (p.typeFilter != null) {
      final sum = await repo.sumByTypeAndMonth(
        p.typeFilter!,
        y,
        m,
        walletId: p.walletId,
      );
      final isIncome = p.typeFilter == 'income';
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
        repo.sumByTypeAndMonth('income', y, m, walletId: p.walletId),
        repo.sumByTypeAndMonth('expense', y, m, walletId: p.walletId),
      ]);
      results.add(
        MonthlyTotal(year: y, month: m, income: income, expense: expense),
      );
    }
  }

  return results;
});

// ── Category breakdown for a given month ─────────────────────────────────

/// Categories ranked by amount for the given month.
/// Wallet and type filters passed via [CategoryBreakdownParams].
final categoryBreakdownProvider = Provider.family<
    AsyncValue<List<CategorySpending>>, CategoryBreakdownParams>(
  (ref, p) {
    final txAsync = ref.watch(transactionsByMonthProvider((p.year, p.month)));
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final lang = ref.watch(localeProvider)?.languageCode ?? 'en';
    return txAsync.whenData((transactions) {
      var filtered = p.typeFilter == null
          ? transactions
          : transactions.where((tx) => tx.type == p.typeFilter);
      if (p.walletId != null) {
        filtered = filtered.where((tx) => tx.walletId == p.walletId);
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

/// Daily totals for the last [p.days] days.
/// Wallet and type filters passed via [DailySpendingParams].
final dailySpendingProvider = FutureProvider.autoDispose
    .family<List<DailySpending>, DailySpendingParams>((ref, p) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(Duration(days: p.days - 1));
  final end = today.add(const Duration(days: 1));

  final repo = ref.watch(transactionRepositoryProvider);
  ref.watch(transactionChangeTriggerProvider);
  final archivedIds = ref.watch(archivedWalletIdsProvider);
  final txns = await repo.getByDateRange(start, end);

  final dailyMap = <DateTime, int>{};
  for (var i = 0; i < p.days; i++) {
    final d = DateTime(start.year, start.month, start.day + i);
    dailyMap[d] = 0;
  }

  for (final tx in txns) {
    if (archivedIds.contains(tx.walletId)) continue;
    final matchesType = p.typeFilter == null || tx.type == p.typeFilter;
    if (matchesType) {
      final matchesWallet = p.walletId == null || tx.walletId == p.walletId;
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
