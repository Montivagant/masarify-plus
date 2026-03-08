import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/ai/budget_suggestion_service.dart';
import '../../core/services/ai/categorization_learning_service.dart';
import '../../core/services/ai/recurring_pattern_detector.dart';
import '../../core/services/ai/spending_predictor.dart';
import '../../data/database/daos/category_mapping_dao.dart';
import '../../domain/entities/transaction_entity.dart';
import 'budget_provider.dart';
import 'database_provider.dart';
import 'recurring_rule_provider.dart';
import 'transaction_provider.dart';

// ── Auto-Categorization ────────────────────────────────────────────────

final categoryMappingDaoProvider = Provider<CategoryMappingDao>(
  (ref) => ref.watch(databaseProvider).categoryMappingDao,
);

final categorizationLearningServiceProvider =
    Provider<CategorizationLearningService>(
  (ref) => CategorizationLearningService(
    ref.watch(categoryMappingDaoProvider),
  ),
);

// ── Recurring Pattern Detection ────────────────────────────────────────

final _recurringPatternDetectorProvider = Provider<RecurringPatternDetector>(
  (ref) => RecurringPatternDetector(),
);

final detectedPatternsProvider = Provider<List<DetectedPattern>>((ref) {
  final detector = ref.watch(_recurringPatternDetectorProvider);
  final rules = ref.watch(recurringRulesProvider).valueOrNull ?? [];
  final now = DateTime.now();

  // Use month-based providers for full 90-day coverage (not the paginated
  // recentTransactionsProvider which is limited to 50 rows).
  final allTxs = <TransactionEntity>[];
  for (var i = 0; i <= 3; i++) {
    final m = now.month - i;
    final y = m <= 0 ? now.year - 1 : now.year;
    final adjustedMonth = m <= 0 ? m + 12 : m;
    final txs = ref
            .watch(transactionsByMonthProvider((y, adjustedMonth)))
            .valueOrNull ??
        [];
    allTxs.addAll(txs);
  }

  if (allTxs.isEmpty) return [];

  // Exclude transactions that match a known recurring rule.
  final ruleKeys = <String>{};
  for (final r in rules) {
    ruleKeys.add('${r.categoryId}|${r.amount}');
  }

  final filtered = allTxs
      .where((t) => !ruleKeys.contains('${t.categoryId}|${t.amount}'))
      .toList();

  return detector.detect(filtered);
});

// ── Spending Predictions ───────────────────────────────────────────────

final _spendingPredictorProvider = Provider<SpendingPredictor>(
  (ref) => SpendingPredictor(),
);

final spendingPredictionsProvider = Provider<List<SpendingPrediction>>((ref) {
  final predictor = ref.watch(_spendingPredictorProvider);
  final now = DateTime.now();
  final monthKey = (now.year, now.month);

  final currentTxs =
      ref.watch(transactionsByMonthProvider(monthKey)).valueOrNull ?? [];
  final budgets =
      ref.watch(budgetsByMonthProvider(monthKey)).valueOrNull ?? [];

  if (currentTxs.isEmpty || budgets.isEmpty) return [];

  // Gather last 2 months for historicalAvg (weighted 40% in final prediction).
  final historicalTxs = <TransactionEntity>[];
  for (var i = 1; i <= 2; i++) {
    final m = now.month - i;
    final y = m <= 0 ? now.year - 1 : now.year;
    final adjustedMonth = m <= 0 ? m + 12 : m;
    final txs = ref
            .watch(transactionsByMonthProvider((y, adjustedMonth)))
            .valueOrNull ??
        [];
    historicalTxs.addAll(txs);
  }

  return predictor.predict(
    currentMonthTxs: currentTxs,
    historicalTxs: historicalTxs,
    budgets: budgets,
    now: now,
  );
});

// ── Budget Suggestions ─────────────────────────────────────────────────

final _budgetSuggestionServiceProvider = Provider<BudgetSuggestionService>(
  (ref) => BudgetSuggestionService(),
);

final budgetSuggestionsProvider = Provider<List<BudgetSuggestion>>((ref) {
  final service = ref.watch(_budgetSuggestionServiceProvider);
  final now = DateTime.now();
  final monthKey = (now.year, now.month);

  final budgets =
      ref.watch(budgetsByMonthProvider(monthKey)).valueOrNull ?? [];

  // Gather last 3 months for average.
  final historicalTxs = <TransactionEntity>[];
  for (var i = 1; i <= 3; i++) {
    final m = now.month - i;
    final y = m <= 0 ? now.year - 1 : now.year;
    final adjustedMonth = m <= 0 ? m + 12 : m;
    final txs = ref
            .watch(transactionsByMonthProvider((y, adjustedMonth)))
            .valueOrNull ??
        [];
    historicalTxs.addAll(txs);
  }

  if (historicalTxs.isEmpty) return [];

  return service.suggest(
    budgets: budgets,
    historicalTxs: historicalTxs,
  );
});
