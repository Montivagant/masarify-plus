import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/insight_engine.dart';
import 'budget_provider.dart';
import 'category_provider.dart';
import 'theme_provider.dart';
import 'transaction_provider.dart';

/// Provides a list of smart insights for the current month.
final insightsProvider = FutureProvider<List<Insight>>((ref) async {
  final now = DateTime.now();
  final thisMonthKey = (now.year, now.month);
  final lastMonthDate = DateTime(now.year, now.month - 1);
  final lastMonthKey = (lastMonthDate.year, lastMonthDate.month);

  // Collect all watched values before first await to avoid ref.watch after async gap
  final thisMonthFuture =
      ref.watch(transactionsByMonthProvider(thisMonthKey).future);
  final lastMonthFuture =
      ref.watch(transactionsByMonthProvider(lastMonthKey).future);
  final budgetsFuture =
      ref.watch(budgetsByMonthProvider(thisMonthKey).future);
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
  final lang = ref.watch(localeProvider)?.languageCode ?? 'ar';

  final thisMonthTxns = await thisMonthFuture;
  final lastMonthTxns = await lastMonthFuture;
  final budgets = await budgetsFuture;

  final categoryNames = <int, String>{
    for (final c in categories) c.id: c.displayName(lang),
  };

  return InsightEngine.generate(
    thisMonthTxns: thisMonthTxns,
    lastMonthTxns: lastMonthTxns,
    budgets: budgets,
    categoryNames: categoryNames,
    allRecentTxns: [...thisMonthTxns, ...lastMonthTxns],
  );
});
