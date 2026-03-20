# Phase 2A: Background AI Intelligence — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add 4 offline-first, heuristic-based AI features — auto-categorization learning, recurring pattern detection, spending predictions, and budget suggestions — all surfaced through existing dashboard insight cards.

**Architecture:** Pure Dart services (no isolates), Drift DB v5 migration for `category_mappings` table, Riverpod providers for reactivity, insight cards integrated into existing `AiInsightsZone` widget.

**Tech Stack:** Flutter/Dart, Drift (SQLite), Riverpod 2.x, existing MasarifyDS components.

---

### Task 1: Create `category_mappings` Drift Table

**Files:**
- Create: `lib/data/database/tables/category_mappings_table.dart`

**Step 1: Create table definition**

```dart
// lib/data/database/tables/category_mappings_table.dart
import 'package:drift/drift.dart';

import 'categories_table.dart';

class CategoryMappings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get titlePattern => text()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get hitCount => integer().withDefault(const Constant(1))();
  IntColumn get lastUsedAt => integer()(); // Unix timestamp (seconds)

  @override
  List<Set<Column>> get uniqueKeys => [
        {titlePattern, categoryId},
      ];
}
```

**Step 2: Verify file created**

Run: `dart analyze lib/data/database/tables/category_mappings_table.dart`
Expected: No issues found

---

### Task 2: Create `CategoryMappingDao`

**Files:**
- Create: `lib/data/database/daos/category_mapping_dao.dart`

**Step 1: Create DAO**

```dart
// lib/data/database/daos/category_mapping_dao.dart
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/category_mappings_table.dart';

part 'category_mapping_dao.g.dart';

@DriftAccessor(tables: [CategoryMappings])
class CategoryMappingDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryMappingDaoMixin {
  CategoryMappingDao(super.db);

  /// Upsert: increment hit_count if exists, else insert.
  Future<void> upsertMapping(String titlePattern, int categoryId) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final existing = await (select(categoryMappings)
          ..where(
            (m) =>
                m.titlePattern.equals(titlePattern) &
                m.categoryId.equals(categoryId),
          ))
        .getSingleOrNull();

    if (existing != null) {
      await (update(categoryMappings)
            ..where((m) => m.id.equals(existing.id)))
          .write(CategoryMappingsCompanion(
        hitCount: Value(existing.hitCount + 1),
        lastUsedAt: Value(now),
      ));
    } else {
      await into(categoryMappings).insert(CategoryMappingsCompanion.insert(
        titlePattern: titlePattern,
        categoryId: categoryId,
        lastUsedAt: now,
      ));
    }
  }

  /// Find best matching category for a title pattern.
  /// Returns categoryId with highest hit_count, or null.
  Future<int?> bestCategoryFor(String titlePattern) async {
    final results = await (select(categoryMappings)
          ..where((m) => m.titlePattern.equals(titlePattern))
          ..orderBy([(m) => OrderingTerm.desc(m.hitCount)])
          ..limit(1))
        .getSingleOrNull();
    return results?.categoryId;
  }
}
```

---

### Task 3: Register Table + DAO in AppDatabase, v5 Migration

**Files:**
- Modify: `lib/data/database/app_database.dart`

**Step 1: Add imports**

Add after existing table/DAO imports:
```dart
import 'daos/category_mapping_dao.dart';
import 'tables/category_mappings_table.dart';
```

**Step 2: Register table and DAO**

Add `CategoryMappings` to the `tables` list (after `ExchangeRates`):
```dart
tables: [
  Wallets,
  Categories,
  Transactions,
  Transfers,
  Budgets,
  SavingsGoals,
  GoalContributions,
  RecurringRules,
  SmsParserLogs,
  ExchangeRates,
  CategoryMappings,  // ← NEW
],
```

Add `CategoryMappingDao` to the `daos` list (after `ExchangeRateDao`):
```dart
daos: [
  WalletDao,
  CategoryDao,
  TransactionDao,
  TransferDao,
  BudgetDao,
  GoalDao,
  RecurringRuleDao,
  SmsParserLogDao,
  ExchangeRateDao,
  CategoryMappingDao,  // ← NEW
],
```

**Step 3: Bump schema version**

Change `schemaVersion => 4` to `schemaVersion => 5`.

**Step 4: Add v5 migration**

Add after the `if (from < 4)` block in `onUpgrade`:
```dart
if (from < 5) {
  await m.createTable(categoryMappings);
}
```

**Step 5: Add index for category_mappings**

Add at the end of `_createIndexes()`:
```dart
// Category mappings
await customStatement(
  'CREATE INDEX IF NOT EXISTS idx_category_mappings_pattern '
  'ON category_mappings(title_pattern)',
);
```

**Step 6: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `app_database.g.dart`, `category_mapping_dao.g.dart`

**Step 7: Verify**

Run: `flutter analyze lib/`
Expected: No issues found

---

### Task 4: Create `CategorizationLearningService`

**Files:**
- Create: `lib/core/services/ai/categorization_learning_service.dart`

**Step 1: Create service**

```dart
// lib/core/services/ai/categorization_learning_service.dart

import '../../../data/database/daos/category_mapping_dao.dart';

/// Learns user's {title → category} mappings from manual saves.
/// Suggests categories for future SMS/notification transactions.
class CategorizationLearningService {
  CategorizationLearningService(this._dao);

  final CategoryMappingDao _dao;

  /// Normalize title for matching: lowercase, trim, strip digits.
  static String normalize(String title) {
    return title.toLowerCase().trim().replaceAll(RegExp(r'\d+'), '').trim();
  }

  /// Record a mapping from a manual transaction save.
  Future<void> recordMapping(String title, int categoryId) async {
    final pattern = normalize(title);
    if (pattern.isEmpty) return;
    await _dao.upsertMapping(pattern, categoryId);
  }

  /// Suggest a category for a title. Returns null if no mapping found.
  Future<int?> suggestCategory(String title) async {
    final pattern = normalize(title);
    if (pattern.isEmpty) return null;
    return _dao.bestCategoryFor(pattern);
  }
}
```

**Step 2: Verify**

Run: `flutter analyze lib/core/services/ai/categorization_learning_service.dart`
Expected: No issues found

---

### Task 5: Create `RecurringPatternDetector`

**Files:**
- Create: `lib/core/services/ai/recurring_pattern_detector.dart`

**Step 1: Create service with data classes and detection logic**

```dart
// lib/core/services/ai/recurring_pattern_detector.dart

import 'dart:math' as math;

import '../../../domain/entities/transaction_entity.dart';

/// A detected recurring spending pattern.
class DetectedPattern {
  const DetectedPattern({
    required this.categoryId,
    required this.amount,
    required this.title,
    required this.frequency,
    required this.confidence,
    required this.nextExpectedDate,
  });

  final int categoryId;
  final int amount;
  final String title;

  /// 'weekly' or 'monthly'
  final String frequency;

  /// 0.0 – 1.0
  final double confidence;

  final DateTime nextExpectedDate;
}

/// Detects repeated transactions that look like recurring expenses.
class RecurringPatternDetector {
  /// Analyze transactions from the last 90 days.
  /// Excludes transactions already linked to a RecurringRule.
  List<DetectedPattern> detect(List<TransactionEntity> transactions) {
    // Filter: only expense, not already recurring, last 90 days.
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    final candidates = transactions.where((t) {
      return t.type == 'expense' &&
          !t.isRecurring &&
          t.transactionDate.isAfter(cutoff);
    }).toList();

    // Group by (categoryId, amount).
    final groups = <String, List<TransactionEntity>>{};
    for (final tx in candidates) {
      final key = '${tx.categoryId}|${tx.amount}';
      (groups[key] ??= []).add(tx);
    }

    final patterns = <DetectedPattern>[];

    for (final entry in groups.entries) {
      final txs = entry.value;
      if (txs.length < 3) continue;

      // Sort by date ascending.
      txs.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));

      // Compute intervals in days.
      final intervals = <int>[];
      for (var i = 1; i < txs.length; i++) {
        intervals.add(
          txs[i].transactionDate.difference(txs[i - 1].transactionDate).inDays,
        );
      }

      final avgInterval =
          intervals.reduce((a, b) => a + b) / intervals.length;
      final variance = intervals
              .map((i) => (i - avgInterval).abs())
              .reduce((a, b) => a + b) /
          intervals.length;

      // Check monthly (28-31 ± 3) or weekly (7 ± 1).
      String? frequency;
      if (avgInterval >= 25 && avgInterval <= 34) {
        frequency = 'monthly';
      } else if (avgInterval >= 6 && avgInterval <= 8) {
        frequency = 'weekly';
      }

      if (frequency == null) continue;

      // Confidence scoring.
      double confidence;
      if (txs.length >= 5) {
        confidence = 0.95;
      } else if (txs.length >= 4) {
        confidence = 0.85;
      } else {
        confidence = 0.7;
      }
      if (variance > 2) confidence -= 0.1;
      confidence = math.max(0.0, confidence);

      if (confidence < 0.7) continue;

      // Most common title in the group.
      final titleCounts = <String, int>{};
      for (final tx in txs) {
        titleCounts[tx.title] = (titleCounts[tx.title] ?? 0) + 1;
      }
      final bestTitle = titleCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      // Next expected date.
      final lastDate = txs.last.transactionDate;
      final nextDate = frequency == 'monthly'
          ? DateTime(lastDate.year, lastDate.month + 1, lastDate.day)
          : lastDate.add(const Duration(days: 7));

      patterns.add(DetectedPattern(
        categoryId: txs.first.categoryId,
        amount: txs.first.amount,
        title: bestTitle,
        frequency: frequency,
        confidence: confidence,
        nextExpectedDate: nextDate,
      ));
    }

    // Sort by confidence desc.
    patterns.sort((a, b) => b.confidence.compareTo(a.confidence));
    return patterns;
  }
}
```

**Step 2: Verify**

Run: `flutter analyze lib/core/services/ai/recurring_pattern_detector.dart`
Expected: No issues found

---

### Task 6: Create `SpendingPredictor`

**Files:**
- Create: `lib/core/services/ai/spending_predictor.dart`

**Step 1: Create service**

```dart
// lib/core/services/ai/spending_predictor.dart

import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/transaction_entity.dart';

/// A prediction that a budgeted category will exceed its limit.
class SpendingPrediction {
  const SpendingPrediction({
    required this.categoryId,
    required this.predictedAmount,
    required this.budgetLimit,
    required this.overByAmount,
  });

  final int categoryId;

  /// Predicted end-of-month spending in piastres.
  final int predictedAmount;

  /// Budget effective limit in piastres.
  final int budgetLimit;

  /// How much over budget (piastres). Always > 0.
  final int overByAmount;
}

/// Predicts end-of-month spending per budgeted category.
class SpendingPredictor {
  /// [currentMonthTxs]: this month's transactions.
  /// [historicalTxs]: last 2-3 months of transactions for averaging.
  /// [budgets]: current month's budgets.
  /// [now]: current date (injectable for testing).
  List<SpendingPrediction> predict({
    required List<TransactionEntity> currentMonthTxs,
    required List<TransactionEntity> historicalTxs,
    required List<BudgetEntity> budgets,
    DateTime? now,
  }) {
    final today = now ?? DateTime.now();
    final dayOfMonth = today.day;
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;

    // Need at least 3 days of data to project meaningfully.
    if (dayOfMonth < 3) return [];

    final predictions = <SpendingPrediction>[];

    for (final budget in budgets) {
      final catId = budget.categoryId;
      final limit = budget.effectiveLimit;
      if (limit <= 0) continue;

      // Current month spending for this category.
      final currentSpent = currentMonthTxs
          .where((t) => t.categoryId == catId && t.type == 'expense')
          .fold<int>(0, (s, t) => s + t.amount);

      // Pace projection: extrapolate current spending to full month.
      final paceProjection =
          (currentSpent / dayOfMonth * daysInMonth).round();

      // Historical average for this category (monthly).
      final historicalByMonth = <String, int>{};
      for (final t in historicalTxs) {
        if (t.categoryId != catId || t.type != 'expense') continue;
        final key = '${t.transactionDate.year}-${t.transactionDate.month}';
        historicalByMonth[key] = (historicalByMonth[key] ?? 0) + t.amount;
      }

      final historicalAvg = historicalByMonth.isNotEmpty
          ? historicalByMonth.values.reduce((a, b) => a + b) ~/
              historicalByMonth.length
          : 0;

      // Blended prediction: 60% pace, 40% historical.
      final predicted = historicalAvg > 0
          ? (0.6 * paceProjection + 0.4 * historicalAvg).round()
          : paceProjection;

      // Flag if predicted exceeds budget by 10%+.
      final threshold = (limit * 1.1).round();
      if (predicted > threshold) {
        predictions.add(SpendingPrediction(
          categoryId: catId,
          predictedAmount: predicted,
          budgetLimit: limit,
          overByAmount: predicted - limit,
        ));
      }
    }

    // Sort by overByAmount desc (most over-budget first).
    predictions.sort((a, b) => b.overByAmount.compareTo(a.overByAmount));
    return predictions;
  }
}
```

**Step 2: Verify**

Run: `flutter analyze lib/core/services/ai/spending_predictor.dart`
Expected: No issues found

---

### Task 7: Create `BudgetSuggestionService`

**Files:**
- Create: `lib/core/services/ai/budget_suggestion_service.dart`

**Step 1: Create service**

```dart
// lib/core/services/ai/budget_suggestion_service.dart

import '../../../domain/entities/budget_entity.dart';
import '../../../domain/entities/transaction_entity.dart';

/// A suggestion to set a budget for a high-spending unbudgeted category.
class BudgetSuggestion {
  const BudgetSuggestion({
    required this.categoryId,
    required this.suggestedAmount,
    required this.monthlyAvg,
  });

  final int categoryId;

  /// Suggested budget limit in piastres, rounded up to nearest 10,000.
  final int suggestedAmount;

  /// 3-month average spending in piastres.
  final int monthlyAvg;
}

/// Suggests budgets for high-spending categories without existing budgets.
class BudgetSuggestionService {
  /// [budgets]: current month budgets (to identify already-budgeted categories).
  /// [historicalTxs]: last 3 months of transactions.
  List<BudgetSuggestion> suggest({
    required List<BudgetEntity> budgets,
    required List<TransactionEntity> historicalTxs,
  }) {
    final budgetedCatIds = budgets.map((b) => b.categoryId).toSet();

    // Compute 3-month average per expense category.
    final totalByCategory = <int, int>{};
    final monthsByCategory = <int, Set<String>>{};
    for (final t in historicalTxs) {
      if (t.type != 'expense') continue;
      totalByCategory[t.categoryId] =
          (totalByCategory[t.categoryId] ?? 0) + t.amount;
      final monthKey =
          '${t.transactionDate.year}-${t.transactionDate.month}';
      (monthsByCategory[t.categoryId] ??= {}).add(monthKey);
    }

    final suggestions = <BudgetSuggestion>[];

    for (final entry in totalByCategory.entries) {
      final catId = entry.key;
      final total = entry.value;
      final monthCount = monthsByCategory[catId]?.length ?? 1;
      final avg = total ~/ monthCount;

      // Skip if already budgeted or below threshold (50,000 piastres = 500 EGP).
      if (budgetedCatIds.contains(catId)) continue;
      if (avg < 50000) continue;

      // Round up to nearest 10,000 piastres (100 EGP).
      final suggested = ((avg / 10000).ceil()) * 10000;

      suggestions.add(BudgetSuggestion(
        categoryId: catId,
        suggestedAmount: suggested,
        monthlyAvg: avg,
      ));
    }

    // Sort by spending desc, take top 2.
    suggestions.sort((a, b) => b.monthlyAvg.compareTo(a.monthlyAvg));
    return suggestions.take(2).toList();
  }
}
```

**Step 2: Verify**

Run: `flutter analyze lib/core/services/ai/budget_suggestion_service.dart`
Expected: No issues found

---

### Task 8: Create `background_ai_provider.dart`

**Files:**
- Create: `lib/shared/providers/background_ai_provider.dart`

**Step 1: Create providers**

```dart
// lib/shared/providers/background_ai_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/ai/budget_suggestion_service.dart';
import '../../core/services/ai/categorization_learning_service.dart';
import '../../core/services/ai/recurring_pattern_detector.dart';
import '../../core/services/ai/spending_predictor.dart';
import '../../data/database/daos/category_mapping_dao.dart';
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
  final txs = ref.watch(recentTransactionsProvider).valueOrNull ?? [];
  final rules = ref.watch(recurringRulesProvider).valueOrNull ?? [];

  if (txs.isEmpty) return [];

  // Exclude transactions that match a known recurring rule.
  final ruleKeys = <String>{};
  for (final r in rules) {
    ruleKeys.add('${r.categoryId}|${r.amount}');
  }

  final filtered = txs
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

  // Gather last 2 months for historical average.
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
```

Note: This file imports `TransactionEntity` transitively through `transaction_provider.dart`. If the analyzer complains, add an explicit import of `../../domain/entities/transaction_entity.dart`.

**Step 2: Verify**

Run: `flutter analyze lib/shared/providers/background_ai_provider.dart`
Expected: No issues found

---

### Task 9: Add L10n Strings

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`

**Step 1: Add keys to `app_en.arb`**

Add these entries (after the existing `dashboard_insight_*` keys):

```json
"insight_recurring_detected": "Monthly: {title} — add as recurring?",
"@insight_recurring_detected": {
  "placeholders": {
    "title": { "type": "String" }
  }
},
"insight_over_budget_prediction": "{category} may exceed budget by {amount}",
"@insight_over_budget_prediction": {
  "placeholders": {
    "category": { "type": "String" },
    "amount": { "type": "String" }
  }
},
"insight_budget_suggestion": "Set a {amount} budget for {category}?",
"@insight_budget_suggestion": {
  "placeholders": {
    "amount": { "type": "String" },
    "category": { "type": "String" }
  }
}
```

**Step 2: Add keys to `app_ar.arb`**

```json
"insight_recurring_detected": "شهري: {title} — أضف كمتكرر؟",
"insight_over_budget_prediction": "{category} قد يتجاوز الميزانية بـ {amount}",
"insight_budget_suggestion": "حدد ميزانية {amount} لـ {category}؟"
```

**Step 3: Regenerate localizations**

Run: `flutter gen-l10n`
Or if using build_runner: `dart run build_runner build --delete-conflicting-outputs`

**Step 4: Verify**

Run: `flutter analyze lib/l10n/`
Expected: No issues found

---

### Task 10: Integrate Auto-Categorization into Add Transaction Screen

**Files:**
- Modify: `lib/features/transactions/presentation/screens/add_transaction_screen.dart`

**Step 1: Add import**

```dart
import '../../../../shared/providers/background_ai_provider.dart';
```

**Step 2: Call `recordMapping()` on save**

In the `_save()` method, find the block after `repo.create(...)` where `categoryFrequencyServiceProvider.recordUsage` is called. Add the categorization learning call right after:

```dart
// Existing line:
await ref
    .read(categoryFrequencyServiceProvider)
    .recordUsage(_type, categoryId);
// NEW: record title→category mapping for auto-categorization
await ref
    .read(categorizationLearningServiceProvider)
    .recordMapping(title, categoryId);
```

**Step 3: Verify**

Run: `flutter analyze lib/features/transactions/presentation/screens/add_transaction_screen.dart`
Expected: No issues found

---

### Task 11: Add 3 New Insight Types to `AiInsightsZone`

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/ai_insights_zone.dart`

**Step 1: Add imports**

Add to the import block:
```dart
import '../../../../core/services/ai/recurring_pattern_detector.dart';
import '../../../../shared/providers/background_ai_provider.dart';
import '../../../../shared/providers/category_provider.dart';
```

Note: `category_provider.dart` is already imported. Only add it if missing. `budget_provider.dart` is already imported.

**Step 2: Add provider watches in `build()`**

After the existing `lastMonthTxs` line, add:
```dart
final detectedPatterns = ref.watch(detectedPatternsProvider);
final spendingPredictions = ref.watch(spendingPredictionsProvider);
final budgetSuggestions = ref.watch(budgetSuggestionsProvider);
```

**Step 3: Pass new data to `_computeInsights()`**

Update the `_computeInsights()` call signature and invocation:

```dart
final insights = _computeInsights(
  context: context,
  now: now,
  budgets: budgets,
  categories: categories,
  thisMonthTxs: thisMonthTxs,
  lastMonthTxs: lastMonthTxs,
  detectedPatterns: detectedPatterns,
  spendingPredictions: spendingPredictions,
  budgetSuggestions: budgetSuggestions,
);
```

**Step 4: Update `_computeInsights()` signature**

```dart
List<Widget> _computeInsights({
  required BuildContext context,
  required DateTime now,
  required List<dynamic>? budgets,
  required List<CategoryEntity> categories,
  required List<TransactionEntity> thisMonthTxs,
  required List<TransactionEntity> lastMonthTxs,
  required List<DetectedPattern> detectedPatterns,
  required List<SpendingPrediction> spendingPredictions,
  required List<BudgetSuggestion> budgetSuggestions,
}) {
```

(Import `SpendingPrediction` and `BudgetSuggestion` — they come from `background_ai_provider.dart` transitively. If not, add explicit imports of the service files.)

**Step 5: Add new insight cards**

Insert these 3 blocks into `_computeInsights()`, respecting the priority order defined in the design doc:

After Insight 1 (Budget at risk), add **Insight 2: Over-budget prediction**:

```dart
// ── Insight 2: Over-budget prediction (new) ──────────────────────
if (spendingPredictions.isNotEmpty) {
  final pred = spendingPredictions.first;
  final cat = catMap[pred.categoryId];
  if (cat != null) {
    insights.add(
      _InsightCard(
        icon: AppIcons.trendingUp,
        iconColor: context.appTheme.expenseColor,
        text: context.l10n.insight_over_budget_prediction(
          cat.displayName(context.languageCode),
          MoneyFormatter.formatCompact(pred.overByAmount),
        ),
        onTap: () => context.push(AppRoutes.budgets),
      ),
    );
  }
}
```

After the existing spending trend insight (now Insight 3), add **Insight 4: Recurring detected**:

```dart
// ── Insight 4: Recurring detected (new) ──────────────────────────
if (detectedPatterns.isNotEmpty) {
  final pattern = detectedPatterns.first;
  insights.add(
    _InsightCard(
      icon: AppIcons.recurring,
      iconColor: context.colors.primary,
      text: context.l10n.insight_recurring_detected(pattern.title),
      onTap: () => context.push(AppRoutes.recurringAdd),
    ),
  );
}
```

After the top category insight (now Insight 5), add **Insight 6: Budget suggestion**:

```dart
// ── Insight 6: Budget suggestion (new) ───────────────────────────
if (budgetSuggestions.isNotEmpty) {
  final suggestion = budgetSuggestions.first;
  final cat = catMap[suggestion.categoryId];
  if (cat != null) {
    insights.add(
      _InsightCard(
        icon: AppIcons.budget,
        iconColor: context.colors.primary,
        text: context.l10n.insight_budget_suggestion(
          MoneyFormatter.formatCompact(suggestion.suggestedAmount),
          cat.displayName(context.languageCode),
        ),
        onTap: () => context.push(AppRoutes.budgetSet),
      ),
    );
  }
}
```

**Updated insight card ordering:**
1. Budget at risk (existing)
2. Over-budget prediction (new)
3. Spending trend (existing)
4. Recurring detected (new)
5. Top category (existing)
6. Budget suggestion (new)

**Step 6: Verify**

Run: `flutter analyze lib/features/dashboard/presentation/widgets/ai_insights_zone.dart`
Expected: No issues found

---

### Task 12: Full Verification

**Step 1: Run code generation**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Success, no errors

**Step 2: Static analysis**

Run: `flutter analyze lib/`
Expected: No issues found

**Step 3: Run tests**

Run: `flutter test`
Expected: All tests pass (64+ tests)

**Step 4: Commit**

```bash
git add lib/data/database/tables/category_mappings_table.dart \
  lib/data/database/daos/category_mapping_dao.dart \
  lib/data/database/daos/category_mapping_dao.g.dart \
  lib/data/database/app_database.dart \
  lib/data/database/app_database.g.dart \
  lib/core/services/ai/categorization_learning_service.dart \
  lib/core/services/ai/recurring_pattern_detector.dart \
  lib/core/services/ai/spending_predictor.dart \
  lib/core/services/ai/budget_suggestion_service.dart \
  lib/shared/providers/background_ai_provider.dart \
  lib/features/transactions/presentation/screens/add_transaction_screen.dart \
  lib/features/dashboard/presentation/widgets/ai_insights_zone.dart \
  lib/l10n/app_en.arb lib/l10n/app_ar.arb \
  lib/l10n/app_localizations.dart \
  lib/l10n/app_localizations_en.dart \
  lib/l10n/app_localizations_ar.dart
git commit -m "feat: add Phase 2A background AI intelligence

- Auto-categorization learning (DB v5, category_mappings table)
- Recurring pattern detection (heuristic, 90-day window)
- Spending predictions (pace + historical blend)
- Budget suggestions (unbudgeted high-spend categories)
- 3 new insight cards on dashboard
- All offline-first, no LLM required"
```

---

## Dependency Order

```
Task 1 (table) → Task 2 (DAO) → Task 3 (DB registration + v5 migration)
                                       ↓
                              Task 4 (CategorizationLearningService)
                              Task 5 (RecurringPatternDetector)      ← independent
                              Task 6 (SpendingPredictor)             ← independent
                              Task 7 (BudgetSuggestionService)       ← independent
                                       ↓
                              Task 8 (providers) → depends on Tasks 4-7
                              Task 9 (l10n) ← independent
                                       ↓
                              Task 10 (add_transaction_screen) → depends on Task 8
                              Task 11 (ai_insights_zone) → depends on Tasks 8, 9
                                       ↓
                              Task 12 (verification) → depends on all
```

Tasks 4, 5, 6, 7 are independent and can be created in any order.
Tasks 9 and 8 are independent of each other.
Tasks 10 and 11 can be done in parallel after 8 and 9.

## Verification

1. `dart run build_runner build --delete-conflicting-outputs` — success
2. `flutter analyze lib/` — zero issues
3. `flutter test` — all pass
4. Manual testing:
   - Save 3+ transactions with same title → mapping recorded in DB
   - Add 3+ monthly-interval transactions in same category → recurring insight appears
   - Spending pace > budget → prediction insight appears
   - High-spend category with no budget → suggestion insight appears
   - Test AR/RTL
   - Test offline (all components work without internet)
