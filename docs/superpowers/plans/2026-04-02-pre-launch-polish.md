# Pre-Launch Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete all remaining pre-launch polish — analytics revamp, AI chat CRUD expansion, AI chat widget refresh, and transfer screen glassmorphic conversion.

**Architecture:** Four independent workstreams executed sequentially. Analytics revamp adds wallet/type filters and a month-picker to the reports module. AI chat CRUD adds 6 new action types (update_wallet, update_goal, update_recurring, update_category, create_category, delete_wallet) across 5 files. Transfer screen replaces outline containers with GlassCard. Splash screen was audited and is already compliant — no work needed.

**Tech Stack:** Flutter/Dart, Riverpod 2.x, fl_chart, Drift (SQLite), GlassCard design system, go_router.

---

## Workstream A: Analytics Revamp

### Task A1: Add wallet filter + type toggle to Reports

The reports module currently has no wallet or income/expense filter. Add a shared filter row at the top of the ReportsScreen that feeds into all three tabs.

**Files:**
- Create: `lib/features/reports/presentation/widgets/reports_filter_bar.dart`
- Modify: `lib/features/reports/presentation/screens/reports_screen.dart`
- Modify: `lib/shared/providers/analytics_provider.dart`
- Modify: `lib/features/reports/presentation/widgets/overview_tab.dart`
- Modify: `lib/features/reports/presentation/widgets/categories_tab.dart`
- Modify: `lib/features/reports/presentation/widgets/trends_tab.dart`

- [ ] **Step 1: Add filter state providers to analytics_provider.dart**

Add at the top of `lib/shared/providers/analytics_provider.dart`:

```dart
/// Selected wallet ID for reports filtering (null = all wallets).
final reportsWalletFilterProvider = StateProvider<int?>((ref) => null);

/// Selected transaction type for reports ('expense', 'income', or null for both).
final reportsTypeFilterProvider = StateProvider<String?>((ref) => null);
```

- [ ] **Step 2: Create the ReportsFilterBar widget**

Create `lib/features/reports/presentation/widgets/reports_filter_bar.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/analytics_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';

/// Horizontal filter bar for Reports: wallet dropdown + income/expense/all chips.
class ReportsFilterBar extends ConsumerWidget {
  const ReportsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final activeWallets =
        wallets.where((w) => !w.isArchived && !w.isSystemWallet).toList();
    final selectedWalletId = ref.watch(reportsWalletFilterProvider);
    final selectedType = ref.watch(reportsTypeFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      child: Row(
        children: [
          // Wallet filter dropdown
          Flexible(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: selectedWalletId,
                isDense: true,
                isExpanded: true,
                style: context.textStyles.bodySmall,
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text(context.l10n.reports_all_accounts),
                  ),
                  ...activeWallets.map(
                    (w) => DropdownMenuItem<int?>(
                      value: w.id,
                      child: Text(w.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) =>
                    ref.read(reportsWalletFilterProvider.notifier).state = v,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          // Type filter chips
          ...['expense', 'income'].map(
            (type) => Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSizes.xs),
              child: FilterChip(
                label: Text(
                  type == 'expense'
                      ? context.l10n.dashboard_expense
                      : context.l10n.dashboard_income,
                  style: context.textStyles.labelSmall,
                ),
                selected: selectedType == type,
                onSelected: (on) => ref
                    .read(reportsTypeFilterProvider.notifier)
                    .state = on ? type : null,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Wire filter bar into ReportsScreen**

In `lib/features/reports/presentation/screens/reports_screen.dart`, add the import and insert `ReportsFilterBar` between the AppBar and TabBarView:

```dart
// Add import:
import '../widgets/reports_filter_bar.dart';
```

Change the `body` from a bare `TabBarView` to a `Column`:

```dart
body: const Column(
  children: [
    ReportsFilterBar(),
    Expanded(
      child: TabBarView(
        children: [
          OverviewTab(),
          CategoriesTab(),
          TrendsTab(),
        ],
      ),
    ),
  ],
),
```

- [ ] **Step 4: Update monthlyTotalsProvider to respect filters**

In `lib/shared/providers/analytics_provider.dart`, modify `monthlyTotalsProvider` to accept a record key that includes wallet and type:

Replace the current `monthlyTotalsProvider` definition with:

```dart
/// Returns [MonthlyTotal] for the last [count] months, optionally filtered.
final monthlyTotalsProvider = FutureProvider.family<List<MonthlyTotal>, int>(
  (ref, count) async {
    final now = DateTime.now();
    final repo = ref.watch(transactionRepositoryProvider);
    ref.watch(recentTransactionsProvider);
    final walletId = ref.watch(reportsWalletFilterProvider);
    final typeFilter = ref.watch(reportsTypeFilterProvider);
    final results = <MonthlyTotal>[];

    for (var i = count - 1; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i);
      final y = d.year;
      final m = d.month;

      if (typeFilter != null) {
        // Only one type requested
        final sum = await repo.sumByTypeAndMonth(typeFilter, y, m,
            walletId: walletId);
        final isIncome = typeFilter == 'income';
        results.add(MonthlyTotal(
          year: y,
          month: m,
          income: isIncome ? sum : 0,
          expense: isIncome ? 0 : sum,
        ));
      } else {
        final [income, expense] = await Future.wait([
          repo.sumByTypeAndMonth('income', y, m, walletId: walletId),
          repo.sumByTypeAndMonth('expense', y, m, walletId: walletId),
        ]);
        results.add(
            MonthlyTotal(year: y, month: m, income: income, expense: expense));
      }
    }
    return results;
  },
);
```

**NOTE:** This requires `sumByTypeAndMonth` to accept an optional `walletId` parameter. Check the transaction repository/DAO — if the parameter doesn't exist, add it to `ITransactionRepository.sumByTypeAndMonth`, the implementation, and the DAO. The SQL change is adding `AND wallet_id = ?` when walletId is non-null.

- [ ] **Step 5: Update categoryBreakdownProvider to respect filters**

In `lib/shared/providers/analytics_provider.dart`, update `categoryBreakdownProvider` to also filter by wallet:

Inside the `txAsync.whenData` callback, after the line `final expenses = transactions.where((tx) => tx.type == 'expense');`, add wallet filtering:

```dart
final walletId = ref.watch(reportsWalletFilterProvider);
final typeFilter = ref.watch(reportsTypeFilterProvider);

return txAsync.whenData((transactions) {
  var filtered = transactions.where((tx) => tx.type == 'expense');
  if (typeFilter == 'income') {
    filtered = transactions.where((tx) => tx.type == 'income');
  }
  if (walletId != null) {
    filtered = filtered.where((tx) => tx.walletId == walletId);
  }
  final byCategory = <int, int>{};
  for (final tx in filtered) {
    byCategory[tx.categoryId] =
        (byCategory[tx.categoryId] ?? 0) + tx.amount;
  }
  // ... rest unchanged
```

- [ ] **Step 6: Update dailySpendingProvider to respect filters**

In `lib/shared/providers/analytics_provider.dart`, update `dailySpendingProvider`:

After `final txns = await repo.getByDateRange(start, end);`, filter:

```dart
final walletId = ref.watch(reportsWalletFilterProvider);
final typeFilter = ref.watch(reportsTypeFilterProvider);

// ... after fetching txns:
for (final tx in txns) {
  final matchesType = typeFilter == null || tx.type == typeFilter;
  final matchesWallet = walletId == null || tx.walletId == walletId;
  if (matchesType && matchesWallet && tx.type == 'expense') {
    // ... existing logic
  }
}
```

When `typeFilter == 'income'`, change the condition to track income instead.

- [ ] **Step 7: Add l10n key for "All Accounts"**

In `lib/l10n/app_en.arb`, add:
```json
"reports_all_accounts": "All Accounts",
```

In `lib/l10n/app_ar.arb`, add:
```json
"reports_all_accounts": "كل الحسابات",
```

Run: `flutter gen-l10n`

- [ ] **Step 8: Add walletId parameter to sumByTypeAndMonth if needed**

Check `ITransactionRepository` and `TransactionDao`. If `sumByTypeAndMonth` doesn't already accept a `walletId` parameter, add it:

Interface: `Future<int> sumByTypeAndMonth(String type, int year, int month, {int? walletId});`

DAO implementation: Add `if (walletId != null) ...[Variable(walletId)]` to the query and append `AND wallet_id = ?` to the SQL WHERE clause.

- [ ] **Step 9: Run analyzer and fix issues**

Run: `flutter analyze lib/features/reports/ lib/shared/providers/analytics_provider.dart`

- [ ] **Step 10: Commit**

```bash
git add lib/features/reports/ lib/shared/providers/analytics_provider.dart lib/l10n/app_en.arb lib/l10n/app_ar.arb
git commit -m "feat(reports): add wallet + type filters to analytics"
```

### Task A2: Add month picker to Categories tab

The categories tab only shows the current month. Add a month selector so users can view past months.

**Files:**
- Modify: `lib/features/reports/presentation/widgets/categories_tab.dart`
- Modify: `lib/shared/providers/analytics_provider.dart`

- [ ] **Step 1: Add month selector state**

In `lib/shared/providers/analytics_provider.dart`, add:

```dart
/// Selected month for category breakdown (defaults to current month).
final reportsCategoryMonthProvider =
    StateProvider<(int year, int month)>((ref) {
  final now = DateTime.now();
  return (now.year, now.month);
});
```

- [ ] **Step 2: Add month navigation to CategoriesTab**

In `lib/features/reports/presentation/widgets/categories_tab.dart`, replace the hardcoded `now` with the provider. Change the `_CategoriesTabState`:

In `build()`, replace:
```dart
final now = DateTime.now();
final breakdownAsync =
    ref.watch(categoryBreakdownProvider((now.year, now.month)));
```

With:
```dart
final selectedMonth = ref.watch(reportsCategoryMonthProvider);
final breakdownAsync = ref.watch(categoryBreakdownProvider(selectedMonth));
```

Before the header, add a month navigation row:

```dart
// ── Month selector ─────────────────────────────────────────
Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: AppSizes.screenHPadding,
    vertical: AppSizes.xs,
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      IconButton(
        icon: const Icon(AppIcons.chevronLeft),
        onPressed: () {
          final (y, m) = selectedMonth;
          final prev = m == 1 ? (y - 1, 12) : (y, m - 1);
          ref.read(reportsCategoryMonthProvider.notifier).state = prev;
        },
      ),
      Text(
        DateFormat.yMMMM(context.languageCode)
            .format(DateTime(selectedMonth.$1, selectedMonth.$2)),
        style: context.textStyles.titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
      IconButton(
        icon: const Icon(AppIcons.chevronRight),
        onPressed: () {
          final now = DateTime.now();
          final (y, m) = selectedMonth;
          if (y >= now.year && m >= now.month) return;
          final next = m == 12 ? (y + 1, 1) : (y, m + 1);
          ref.read(reportsCategoryMonthProvider.notifier).state = next;
        },
      ),
    ],
  ),
),
```

Add `import 'package:intl/intl.dart';` and `import '../../../../core/constants/app_icons.dart';` if not already imported.

- [ ] **Step 3: Run analyzer and fix**

Run: `flutter analyze lib/features/reports/presentation/widgets/categories_tab.dart`

- [ ] **Step 4: Commit**

```bash
git add lib/features/reports/ lib/shared/providers/analytics_provider.dart
git commit -m "feat(reports): add month navigation to categories tab"
```

### Task A3: Add income line to Trends tab

Currently trends only shows expense. Add an income line when income type is selected or show both when "all" is selected.

**Files:**
- Modify: `lib/shared/providers/analytics_provider.dart`
- Modify: `lib/features/reports/presentation/widgets/trends_tab.dart`

- [ ] **Step 1: Update dailySpendingProvider to support income**

In `lib/shared/providers/analytics_provider.dart`, the `dailySpendingProvider` currently only tracks expense. Update it to respect the type filter — when typeFilter is 'income' it tracks income, otherwise expense:

The key change is in the inner loop — instead of `if (tx.type == 'expense')`, use:

```dart
final targetType = typeFilter ?? 'expense';
for (final tx in txns) {
  if (tx.type == targetType) {
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
```

- [ ] **Step 2: Update trend chart color based on type filter**

In `lib/features/reports/presentation/widgets/trends_tab.dart`, read the type filter and use the appropriate color:

In `_SpendingLineChart`, read the type filter:

```dart
// At the call site in TrendsTab, pass the type:
_SpendingLineChart(
  data: dailyData,
  days: _selectedDays,
  isIncome: ref.watch(reportsTypeFilterProvider) == 'income',
),
```

In `_SpendingLineChart`, add `final bool isIncome;` field, and replace all `context.appTheme.expenseColor` with:

```dart
final chartColor = isIncome
    ? context.appTheme.incomeColor
    : context.appTheme.expenseColor;
```

- [ ] **Step 3: Run analyzer and commit**

```bash
flutter analyze lib/features/reports/ lib/shared/providers/analytics_provider.dart
git add lib/features/reports/ lib/shared/providers/analytics_provider.dart
git commit -m "feat(reports): trends tab respects wallet/type filters"
```

---

## Workstream B: AI Chat CRUD Expansion

### Task B1: Add 6 new ChatAction subclasses

**Files:**
- Modify: `lib/core/services/ai/chat_action.dart`

- [ ] **Step 1: Add parser cases in fromJson switch**

In `lib/core/services/ai/chat_action.dart`, inside the `switch (action)` block in `fromJson()`, add these cases before the `default`:

```dart
case 'update_wallet':
  return _parseUpdateWallet(json);
case 'update_goal':
  return _parseUpdateGoal(json);
case 'update_recurring':
  return _parseUpdateRecurring(json);
case 'update_category':
  return _parseUpdateCategory(json);
case 'create_category':
  return _parseCreateCategory(json);
case 'delete_wallet':
  return _parseDeleteWallet(json);
```

- [ ] **Step 2: Add parser methods**

Add these static methods inside the `ChatAction` class, after the existing `_parseDeleteRecurring` method:

```dart
static UpdateWalletAction? _parseUpdateWallet(Map<String, dynamic> json) {
  final name = json['name'] as String?;
  if (name == null || name.isEmpty) return null;
  return UpdateWalletAction(
    name: name,
    newName: json['new_name'] as String?,
    newType: json['new_type'] as String?,
  );
}

static UpdateGoalAction? _parseUpdateGoal(Map<String, dynamic> json) {
  final name = json['name'] as String?;
  if (name == null || name.isEmpty) return null;
  final rawNewTarget = json['new_target_amount'];
  final newTargetPiastres =
      rawNewTarget != null ? (_toDouble(rawNewTarget) * 100).round() : null;
  return UpdateGoalAction(
    name: name,
    newName: json['new_name'] as String?,
    newTargetAmountPiastres:
        newTargetPiastres != null && newTargetPiastres > 0 ? newTargetPiastres : null,
    newDeadline: json['new_deadline'] as String?,
  );
}

static UpdateRecurringAction? _parseUpdateRecurring(Map<String, dynamic> json) {
  final title = json['title'] as String?;
  if (title == null || title.isEmpty) return null;
  final rawNewAmount = json['new_amount'];
  final newPiastres =
      rawNewAmount != null ? (_toDouble(rawNewAmount) * 100).round() : null;
  return UpdateRecurringAction(
    title: title,
    newTitle: json['new_title'] as String?,
    newAmountPiastres: newPiastres != null && newPiastres > 0 ? newPiastres : null,
    newFrequency: json['new_frequency'] as String?,
  );
}

static UpdateCategoryAction? _parseUpdateCategory(Map<String, dynamic> json) {
  final name = json['name'] as String?;
  if (name == null || name.isEmpty) return null;
  return UpdateCategoryAction(
    name: name,
    newName: json['new_name'] as String?,
    newNameAr: json['new_name_ar'] as String?,
  );
}

static CreateCategoryAction? _parseCreateCategory(Map<String, dynamic> json) {
  final name = json['name'] as String?;
  final type = json['type'] as String?;
  if (name == null || name.isEmpty || type == null) return null;
  if (type != 'income' && type != 'expense' && type != 'both') return null;
  return CreateCategoryAction(
    name: name,
    nameAr: json['name_ar'] as String? ?? name,
    type: type,
    iconName: json['icon'] as String? ?? 'category',
    colorHex: json['color'] as String? ?? '#9E9E9E',
  );
}

static DeleteWalletAction? _parseDeleteWallet(Map<String, dynamic> json) {
  final name = json['name'] as String?;
  if (name == null || name.isEmpty) return null;
  return DeleteWalletAction(name: name);
}
```

- [ ] **Step 3: Add the 6 new action classes**

Append these classes after the `DeleteRecurringAction` class (before the `ChatActionStatus` enum):

```dart
/// Action to update a wallet/account by name.
class UpdateWalletAction extends ChatAction {
  const UpdateWalletAction({
    required this.name,
    this.newName,
    this.newType,
  });

  /// Current wallet name (for matching).
  final String name;
  final String? newName;
  final String? newType;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'update_wallet',
        'name': name,
        if (newName != null) 'new_name': newName,
        if (newType != null) 'new_type': newType,
      };
}

/// Action to update a savings goal by name.
class UpdateGoalAction extends ChatAction {
  const UpdateGoalAction({
    required this.name,
    this.newName,
    this.newTargetAmountPiastres,
    this.newDeadline,
  });

  final String name;
  final String? newName;
  final int? newTargetAmountPiastres;
  final String? newDeadline;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'update_goal',
        'name': name,
        if (newName != null) 'new_name': newName,
        if (newTargetAmountPiastres != null)
          'new_target_amount': newTargetAmountPiastres! / 100,
        if (newDeadline != null) 'new_deadline': newDeadline,
      };
}

/// Action to update a recurring rule by title.
class UpdateRecurringAction extends ChatAction {
  const UpdateRecurringAction({
    required this.title,
    this.newTitle,
    this.newAmountPiastres,
    this.newFrequency,
  });

  final String title;
  final String? newTitle;
  final int? newAmountPiastres;
  final String? newFrequency;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'update_recurring',
        'title': title,
        if (newTitle != null) 'new_title': newTitle,
        if (newAmountPiastres != null) 'new_amount': newAmountPiastres! / 100,
        if (newFrequency != null) 'new_frequency': newFrequency,
      };
}

/// Action to update a category's name/nameAr.
class UpdateCategoryAction extends ChatAction {
  const UpdateCategoryAction({
    required this.name,
    this.newName,
    this.newNameAr,
  });

  final String name;
  final String? newName;
  final String? newNameAr;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'update_category',
        'name': name,
        if (newName != null) 'new_name': newName,
        if (newNameAr != null) 'new_name_ar': newNameAr,
      };
}

/// Action to create a custom category.
class CreateCategoryAction extends ChatAction {
  const CreateCategoryAction({
    required this.name,
    required this.nameAr,
    required this.type,
    required this.iconName,
    required this.colorHex,
  });

  final String name;
  final String nameAr;
  final String type;
  final String iconName;
  final String colorHex;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'create_category',
        'name': name,
        'name_ar': nameAr,
        'type': type,
        'icon': iconName,
        'color': colorHex,
      };
}

/// Action to archive (delete) a wallet by name.
class DeleteWalletAction extends ChatAction {
  const DeleteWalletAction({required this.name});

  final String name;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'delete_wallet',
        'name': name,
      };
}
```

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze lib/core/services/ai/chat_action.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/core/services/ai/chat_action.dart
git commit -m "feat(ai-chat): add 6 new ChatAction subclasses"
```

### Task B2: Add executor methods + messages for new actions

**Files:**
- Modify: `lib/core/services/ai/chat_action_executor.dart`
- Modify: `lib/core/services/ai/chat_action_messages.dart`
- Modify: `lib/shared/providers/chat_provider.dart`

- [ ] **Step 1: Add new message fields to ChatActionMessages**

In `lib/core/services/ai/chat_action_messages.dart`, add these fields inside the constructor and class body:

New constructor parameters (add after `recurringNotFound`):
```dart
required this.walletUpdated,
required this.goalUpdated,
required this.recurringUpdated,
required this.categoryUpdated,
required this.categoryCreated,
required this.walletArchived,
required this.categoryNotUpdatable,
required this.categoryExists,
required this.walletHasReferences,
```

New field declarations:
```dart
// ── Success (new actions) ──────────────────────────────────────────
final String Function(String name) walletUpdated;
final String Function(String name) goalUpdated;
final String Function(String title) recurringUpdated;
final String Function(String name) categoryUpdated;
final String Function(String name) categoryCreated;
final String Function(String name) walletArchived;

// ── Errors (new actions) ───────────────────────────────────────────
final String categoryNotUpdatable;
final String Function(String name) categoryExists;
final String Function(String name) walletHasReferences;
```

- [ ] **Step 2: Add executor constructor param for categoryRepo**

In `lib/core/services/ai/chat_action_executor.dart`, add `ICategoryRepository` to the constructor:

Add import: `import '../../../domain/repositories/i_category_repository.dart';`

Add to constructor:
```dart
required ICategoryRepository categoryRepo,
```

Add field:
```dart
final ICategoryRepository _categoryRepo;
```

Initialize in the initializer list: `_categoryRepo = categoryRepo,`

- [ ] **Step 3: Add new cases to execute() switch**

In `lib/core/services/ai/chat_action_executor.dart`, in the `execute()` method's `return switch (action)`, add:

```dart
UpdateWalletAction() => _executeUpdateWallet(action, wallets, messages),
UpdateGoalAction() => _executeUpdateGoal(action, messages),
UpdateRecurringAction() => _executeUpdateRecurring(action, messages),
UpdateCategoryAction() =>
  _executeUpdateCategory(action, categories, messages),
CreateCategoryAction() =>
  _executeCreateCategory(action, categories, messages),
DeleteWalletAction() =>
  _executeDeleteWallet(action, wallets, messages),
```

- [ ] **Step 4: Add the 6 executor methods**

Add these methods after `_executeDeleteRecurring`:

```dart
Future<ExecutionResult> _executeUpdateWallet(
  UpdateWalletAction action,
  List<WalletEntity> wallets,
  ChatActionMessages m,
) async {
  final active =
      wallets.where((w) => !w.isArchived && !w.isSystemWallet).toList();
  final match = WalletMatcher.match(action.name, active);
  if (match == null) {
    throw ArgumentError(m.walletNotFound(action.name));
  }

  // Check name uniqueness if renaming.
  if (action.newName != null && action.newName != match.name) {
    final exists =
        await _walletRepo.existsByName(action.newName!, excludeId: match.id);
    if (exists) throw ArgumentError(m.walletExists);
  }

  const validTypes = {
    'physical_cash', 'bank', 'mobile_wallet',
    'credit_card', 'prepaid_card', 'investment',
  };
  final updated = WalletEntity(
    id: match.id,
    name: action.newName ?? match.name,
    type: action.newType != null && validTypes.contains(action.newType)
        ? action.newType!
        : match.type,
    balance: match.balance,
    currencyCode: match.currencyCode,
    iconName: match.iconName,
    colorHex: match.colorHex,
    isArchived: match.isArchived,
    displayOrder: match.displayOrder,
    createdAt: match.createdAt,
    linkedSenders: match.linkedSenders,
    isSystemWallet: match.isSystemWallet,
    isDefaultAccount: match.isDefaultAccount,
    sortOrder: match.sortOrder,
  );
  await _walletRepo.update(updated);
  return ExecutionResult(m.walletUpdated(updated.name));
}

Future<ExecutionResult> _executeUpdateGoal(
  UpdateGoalAction action,
  ChatActionMessages m,
) async {
  final goals = await _goalRepo.watchActive().first;
  final query = action.name.toLowerCase();
  final match =
      goals.where((g) => g.name.toLowerCase().contains(query)).firstOrNull;
  if (match == null) {
    throw ArgumentError(m.goalNotFound(action.name));
  }

  DateTime? newDeadline;
  if (action.newDeadline != null) {
    newDeadline = DateTime.tryParse(action.newDeadline!);
  }

  final updated = SavingsGoalEntity(
    id: match.id,
    name: action.newName ?? match.name,
    iconName: match.iconName,
    colorHex: match.colorHex,
    targetAmount: action.newTargetAmountPiastres ?? match.targetAmount,
    currentAmount: match.currentAmount,
    currencyCode: match.currencyCode,
    deadline: newDeadline ?? match.deadline,
    isCompleted: match.isCompleted,
    keywords: match.keywords,
    walletId: match.walletId,
    createdAt: match.createdAt,
  );
  await _goalRepo.updateGoal(updated);
  return ExecutionResult(m.goalUpdated(updated.name));
}

Future<ExecutionResult> _executeUpdateRecurring(
  UpdateRecurringAction action,
  ChatActionMessages m,
) async {
  final rules = await _recurringRepo.getAll();
  final query = action.title.toLowerCase();
  final match =
      rules.where((r) => r.title.toLowerCase().contains(query)).firstOrNull;
  if (match == null) {
    throw ArgumentError(m.recurringNotFound(action.title));
  }

  final newFreq = action.newFrequency;
  const validFreqs = {'once', 'daily', 'weekly', 'monthly', 'yearly'};

  final updated = match.copyWith(
    title: action.newTitle ?? match.title,
    amount: action.newAmountPiastres ?? match.amount,
    frequency: newFreq != null && validFreqs.contains(newFreq)
        ? newFreq
        : match.frequency,
  );
  await _recurringRepo.update(updated);
  return ExecutionResult(m.recurringUpdated(updated.title));
}

Future<ExecutionResult> _executeUpdateCategory(
  UpdateCategoryAction action,
  List<CategoryEntity> categories,
  ChatActionMessages m,
) async {
  final matched = _matchCategory(
    action.name,
    categories.where((c) => !c.isArchived).toList(),
    m,
  );

  // Don't allow editing default/system categories.
  if (matched.isDefault) {
    throw ArgumentError(m.categoryNotUpdatable);
  }

  final updated = matched.copyWith(
    name: action.newName ?? matched.name,
    nameAr: action.newNameAr ?? matched.nameAr,
  );
  await _categoryRepo.update(updated);
  return ExecutionResult(m.categoryUpdated(updated.name));
}

Future<ExecutionResult> _executeCreateCategory(
  CreateCategoryAction action,
  List<CategoryEntity> categories,
  ChatActionMessages m,
) async {
  // Check for duplicate name.
  final exists = categories.any(
    (c) =>
        !c.isArchived &&
        (c.name.toLowerCase() == action.name.toLowerCase() ||
         c.nameAr.toLowerCase() == action.nameAr.toLowerCase()),
  );
  if (exists) {
    throw ArgumentError(m.categoryExists(action.name));
  }

  await _categoryRepo.create(
    name: action.name,
    nameAr: action.nameAr,
    iconName: action.iconName,
    colorHex: action.colorHex,
    type: action.type,
  );
  return ExecutionResult(m.categoryCreated(action.name));
}

Future<ExecutionResult> _executeDeleteWallet(
  DeleteWalletAction action,
  List<WalletEntity> wallets,
  ChatActionMessages m,
) async {
  final active =
      wallets.where((w) => !w.isArchived && !w.isSystemWallet).toList();
  final match = WalletMatcher.match(action.name, active);
  if (match == null) {
    throw ArgumentError(m.walletNotFound(action.name));
  }

  // Don't delete wallets with transactions — archive instead.
  final hasRefs = await _walletRepo.hasReferences(match.id);
  if (hasRefs) {
    await _walletRepo.archive(match.id);
    return ExecutionResult(m.walletArchived(match.name));
  }

  await _walletRepo.archive(match.id);
  return ExecutionResult(m.walletArchived(match.name));
}
```

Add imports for entities used:
```dart
import '../../../domain/entities/savings_goal_entity.dart';
```

- [ ] **Step 5: Wire categoryRepo into chatActionExecutorProvider**

In `lib/shared/providers/chat_provider.dart`, update the executor provider:

```dart
final chatActionExecutorProvider = Provider<ChatActionExecutor>((ref) {
  return ChatActionExecutor(
    goalRepo: ref.watch(goalRepositoryProvider),
    txRepo: ref.watch(transactionRepositoryProvider),
    budgetRepo: ref.watch(budgetRepositoryProvider),
    recurringRepo: ref.watch(recurringRuleRepositoryProvider),
    walletRepo: ref.watch(walletRepositoryProvider),
    transferRepo: ref.watch(transferRepositoryProvider),
    learningService: ref.watch(categorizationLearningServiceProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
  );
});
```

Add import: `import 'category_provider.dart';` — or wherever `categoryRepositoryProvider` is exported from. Check `repository_providers.dart`.

- [ ] **Step 6: Run analyzer**

Run: `flutter analyze lib/core/services/ai/ lib/shared/providers/chat_provider.dart`

- [ ] **Step 7: Commit**

```bash
git add lib/core/services/ai/ lib/shared/providers/chat_provider.dart
git commit -m "feat(ai-chat): add executor + messages for 6 new CRUD actions"
```

### Task B3: Add l10n keys for new actions

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`

- [ ] **Step 1: Add English l10n keys**

In `lib/l10n/app_en.arb`, add near the other `chat_action_*` keys:

```json
"chat_action_update_wallet_title": "Update Account",
"chat_action_update_goal_title": "Update Goal",
"chat_action_update_recurring_title": "Update Subscription",
"chat_action_update_category_title": "Update Category",
"chat_action_create_category_title": "Create Category",
"chat_action_delete_wallet_title": "Archive Account",

"chat_action_wallet_updated": "Account \"{name}\" updated!",
"@chat_action_wallet_updated": {
  "placeholders": { "name": { "type": "String" } }
},
"chat_action_goal_updated": "Goal \"{name}\" updated!",
"@chat_action_goal_updated": {
  "placeholders": { "name": { "type": "String" } }
},
"chat_action_recurring_updated": "Subscription \"{title}\" updated!",
"@chat_action_recurring_updated": {
  "placeholders": { "title": { "type": "String" } }
},
"chat_action_category_updated": "Category \"{name}\" updated!",
"@chat_action_category_updated": {
  "placeholders": { "name": { "type": "String" } }
},
"chat_action_category_created": "Category \"{name}\" created!",
"@chat_action_category_created": {
  "placeholders": { "name": { "type": "String" } }
},
"chat_action_wallet_archived": "Account \"{name}\" archived!",
"@chat_action_wallet_archived": {
  "placeholders": { "name": { "type": "String" } }
},
"chat_action_category_not_updatable": "Default categories cannot be renamed",
"chat_action_category_exists": "A category named \"{name}\" already exists",
"@chat_action_category_exists": {
  "placeholders": { "name": { "type": "String" } }
},
"chat_action_wallet_has_references": "Account \"{name}\" has transactions — it will be archived instead of deleted",
"@chat_action_wallet_has_references": {
  "placeholders": { "name": { "type": "String" } }
}
```

- [ ] **Step 2: Add Arabic l10n keys**

In `lib/l10n/app_ar.arb`, add the Arabic equivalents:

```json
"chat_action_update_wallet_title": "تعديل الحساب",
"chat_action_update_goal_title": "تعديل الهدف",
"chat_action_update_recurring_title": "تعديل الاشتراك",
"chat_action_update_category_title": "تعديل الفئة",
"chat_action_create_category_title": "إنشاء فئة",
"chat_action_delete_wallet_title": "أرشفة الحساب",
"chat_action_wallet_updated": "تم تعديل الحساب \"{name}\"!",
"@chat_action_wallet_updated": {
  "placeholders": { "name": { "type": "String" } }
},
"chat_action_goal_updated": "تم تعديل الهدف \"{name}\"!",
"@chat_action_goal_updated": {
  "placeholders": { "name": { "type": "String" } }
},
"chat_action_recurring_updated": "تم تعديل الاشتراك \"{title}\"!",
"@chat_action_recurring_updated": {
  "placeholders": { "title": { "type": "String" } }
},
"chat_action_category_updated": "تم تعديل الفئة \"{name}\"!",
"@chat_action_category_updated": {
  "placeholders": { "name": { "type": "String" } }
},
"chat_action_category_created": "تم إنشاء الفئة \"{name}\"!",
"@chat_action_category_created": {
  "placeholders": { "name": { "type": "String" } }
},
"chat_action_wallet_archived": "تم أرشفة الحساب \"{name}\"!",
"@chat_action_wallet_archived": {
  "placeholders": { "name": { "type": "String" } }
},
"chat_action_category_not_updatable": "لا يمكن تعديل الفئات الافتراضية",
"chat_action_category_exists": "فئة باسم \"{name}\" موجودة بالفعل",
"@chat_action_category_exists": {
  "placeholders": { "name": { "type": "String" } }
},
"chat_action_wallet_has_references": "الحساب \"{name}\" لديه معاملات — سيتم أرشفته بدلاً من حذفه",
"@chat_action_wallet_has_references": {
  "placeholders": { "name": { "type": "String" } }
}
```

- [ ] **Step 3: Generate l10n**

Run: `flutter gen-l10n`

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/
git commit -m "feat(l10n): add EN/AR keys for 6 new AI chat actions"
```

### Task B4: Wire new actions into chat_screen.dart messages builder + action_card.dart

**Files:**
- Modify: `lib/features/ai_chat/presentation/screens/chat_screen.dart` (the ChatActionMessages builder)
- Modify: `lib/features/ai_chat/presentation/widgets/action_card.dart`

- [ ] **Step 1: Update ChatActionMessages construction in chat_screen.dart**

Find where `ChatActionMessages(...)` is constructed in `chat_screen.dart` and add the new fields:

```dart
walletUpdated: (name) => context.l10n.chat_action_wallet_updated(name),
goalUpdated: (name) => context.l10n.chat_action_goal_updated(name),
recurringUpdated: (title) => context.l10n.chat_action_recurring_updated(title),
categoryUpdated: (name) => context.l10n.chat_action_category_updated(name),
categoryCreated: (name) => context.l10n.chat_action_category_created(name),
walletArchived: (name) => context.l10n.chat_action_wallet_archived(name),
categoryNotUpdatable: context.l10n.chat_action_category_not_updatable,
categoryExists: (name) => context.l10n.chat_action_category_exists(name),
walletHasReferences: (name) => context.l10n.chat_action_wallet_has_references(name),
```

- [ ] **Step 2: Add new action rendering in ActionCard**

In `lib/features/ai_chat/presentation/widgets/action_card.dart`, add new cases to both the header switch (icon, label, tint) and the `_buildDetails` switch:

**Header switch — add before the closing `};`:**

```dart
UpdateWalletAction() => (
    AppIcons.wallet,
    context.l10n.chat_action_update_wallet_title,
    cs.primary,
  ),
UpdateGoalAction() => (
    AppIcons.goals,
    context.l10n.chat_action_update_goal_title,
    cs.primary,
  ),
UpdateRecurringAction() => (
    AppIcons.recurring,
    context.l10n.chat_action_update_recurring_title,
    cs.secondary,
  ),
UpdateCategoryAction() => (
    AppIcons.edit,
    context.l10n.chat_action_update_category_title,
    cs.tertiary,
  ),
CreateCategoryAction() => (
    AppIcons.add,
    context.l10n.chat_action_create_category_title,
    cs.tertiary,
  ),
DeleteWalletAction() => (
    AppIcons.delete,
    context.l10n.chat_action_delete_wallet_title,
    theme.expenseColor,
  ),
```

**Details switch — add before the closing `};`:**

```dart
UpdateWalletAction(:final name, :final newName, :final newType) => [
    _DetailLine(
      label: context.l10n.wallet_name_label,
      value: name,
      labelStyle: labelS,
      valueStyle: valueStyle,
    ),
    if (newName != null)
      _DetailLine(
        label: '→ ${context.l10n.wallet_name_label}',
        value: newName,
        labelStyle: labelS,
        valueStyle: valueStyle?.copyWith(color: cs.primary),
      ),
    if (newType != null)
      _DetailLine(
        label: '→ ${context.l10n.wallet_type_label}',
        value: _localizeWalletType(context, newType),
        labelStyle: labelS,
        valueStyle: valueStyle?.copyWith(color: cs.primary),
      ),
  ],
UpdateGoalAction(:final name, :final newName, :final newTargetAmountPiastres, :final newDeadline) => [
    _DetailLine(
      label: context.l10n.transaction_title_label,
      value: name,
      labelStyle: labelS,
      valueStyle: valueStyle,
    ),
    if (newName != null)
      _DetailLine(
        label: '→ ${context.l10n.transaction_title_label}',
        value: newName,
        labelStyle: labelS,
        valueStyle: valueStyle?.copyWith(color: cs.primary),
      ),
    if (newTargetAmountPiastres != null)
      _DetailLine(
        label: '→ ${context.l10n.goal_target_label}',
        value: MoneyFormatter.format(newTargetAmountPiastres),
        labelStyle: labelS,
        valueStyle: valueStyle?.copyWith(color: cs.primary),
      ),
    if (newDeadline != null)
      _DetailLine(
        label: '→ ${context.l10n.goal_deadline}',
        value: _formatDeadline(context, newDeadline),
        labelStyle: labelS,
        valueStyle: valueStyle?.copyWith(color: cs.primary),
      ),
  ],
UpdateRecurringAction(:final title, :final newTitle, :final newAmountPiastres, :final newFrequency) => [
    _DetailLine(
      label: context.l10n.transaction_title_label,
      value: title,
      labelStyle: labelS,
      valueStyle: valueStyle,
    ),
    if (newTitle != null)
      _DetailLine(
        label: '→ ${context.l10n.transaction_title_label}',
        value: newTitle,
        labelStyle: labelS,
        valueStyle: valueStyle?.copyWith(color: cs.primary),
      ),
    if (newAmountPiastres != null)
      _DetailLine(
        label: '→ ${context.l10n.common_amount}',
        value: MoneyFormatter.format(newAmountPiastres),
        labelStyle: labelS,
        valueStyle: valueStyle?.copyWith(color: cs.primary),
      ),
    if (newFrequency != null)
      _DetailLine(
        label: '→ ${context.l10n.recurring_frequency_label}',
        value: _localizeFrequency(context, newFrequency),
        labelStyle: labelS,
        valueStyle: valueStyle?.copyWith(color: cs.primary),
      ),
  ],
UpdateCategoryAction(:final name, :final newName, :final newNameAr) => [
    _DetailLine(
      label: context.l10n.transaction_category,
      value: name,
      labelStyle: labelS,
      valueStyle: valueStyle,
    ),
    if (newName != null)
      _DetailLine(
        label: '→ ${context.l10n.transaction_category}',
        value: newName,
        labelStyle: labelS,
        valueStyle: valueStyle?.copyWith(color: cs.primary),
      ),
    if (newNameAr != null)
      _DetailLine(
        label: '→ AR',
        value: newNameAr,
        labelStyle: labelS,
        valueStyle: valueStyle?.copyWith(color: cs.primary),
      ),
  ],
CreateCategoryAction(:final name, :final nameAr, :final type) => [
    _DetailLine(
      label: context.l10n.transaction_category,
      value: '$name ($nameAr)',
      labelStyle: labelS,
      valueStyle: valueStyle,
    ),
    _DetailLine(
      label: context.l10n.wallet_type_label,
      value: type,
      labelStyle: labelS,
      valueStyle: valueStyle,
    ),
  ],
DeleteWalletAction(:final name) => [
    _DetailLine(
      label: context.l10n.wallet_name_label,
      value: name,
      labelStyle: labelS,
      valueStyle:
          valueStyle?.copyWith(color: context.appTheme.expenseColor),
    ),
  ],
```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze lib/features/ai_chat/`

- [ ] **Step 4: Commit**

```bash
git add lib/features/ai_chat/
git commit -m "feat(ai-chat): wire 6 new actions into UI — cards + messages"
```

### Task B5: Update system prompt with new action formats

**Files:**
- Modify: `lib/core/services/ai/ai_chat_service.dart`

- [ ] **Step 1: Add new action formats to English prompt**

In `_buildSystemPrompt`, in the ACTIONS section (after the existing `delete_recurring` line), add:

```dart
'update_wallet: {"action":"update_wallet","name":"CIB","new_name":"opt","new_type":"opt: bank|mobile_wallet|credit_card|prepaid_card|investment"}\n'
'update_goal: {"action":"update_goal","name":"House","new_name":"opt","new_target_amount":10000,"new_deadline":"opt: YYYY-MM-DD"}\n'
'update_recurring: {"action":"update_recurring","title":"Netflix","new_title":"opt","new_amount":250,"new_frequency":"opt: daily|weekly|monthly|yearly"}\n'
'update_category: {"action":"update_category","name":"Food","new_name":"opt","new_name_ar":"opt"}\n'
'create_category: {"action":"create_category","name":"Gym","name_ar":"جيم","type":"expense","icon":"opt","color":"opt: hex"}\n'
'delete_wallet: {"action":"delete_wallet","name":"Old Account"}\n'
```

- [ ] **Step 2: Add same lines to Arabic prompt**

In `_buildArabicPrompt`, add the same 6 lines in the same location (action formats are always English JSON, shared between both prompts).

- [ ] **Step 3: Run analyzer and commit**

```bash
flutter analyze lib/core/services/ai/ai_chat_service.dart
git add lib/core/services/ai/ai_chat_service.dart
git commit -m "feat(ai-chat): add 6 new action formats to system prompt"
```

### Task B6: Fix date parsing bug in executor

The executor uses `DateTime.tryParse(date) ?? DateTime.now()` which silently falls back to today when the AI sends a malformed date. This should warn rather than silently use wrong date.

**Files:**
- Modify: `lib/core/services/ai/chat_action_executor.dart`

- [ ] **Step 1: Add _parseDate helper**

Add a helper method in the executor that validates dates more strictly:

```dart
/// Parse a date string, returning null if invalid instead of falling back
/// to DateTime.now() silently. The caller decides the fallback.
DateTime? _parseDate(String? dateStr) {
  if (dateStr == null) return null;
  final parsed = DateTime.tryParse(dateStr);
  if (parsed == null) return null;
  // Reject dates that are clearly nonsensical (before 2020 or after 2100).
  if (parsed.year < 2020 || parsed.year > 2100) return null;
  return parsed;
}
```

- [ ] **Step 2: Replace all DateTime.tryParse ?? DateTime.now() calls**

Replace the pattern `DateTime.tryParse(action.date!) ?? DateTime.now()` with `_parseDate(action.date) ?? DateTime.now()` in:
- `_executeTransaction` (line ~169)
- `_executeTransfer` (line ~434)
- `_executeRecurring` (lines ~274, 281)

This is a minor improvement — at least now obviously wrong dates (year 0001, etc.) won't pass through.

- [ ] **Step 3: Commit**

```bash
git add lib/core/services/ai/chat_action_executor.dart
git commit -m "fix(ai-chat): stricter date validation in executor"
```

---

## Workstream C: Transfer Screen Glassmorphic

### Task C1: Replace outline containers with GlassCard

**Files:**
- Modify: `lib/features/wallets/presentation/screens/transfer_screen.dart`

- [ ] **Step 1: Add GlassCard import**

Add at the top of the file:
```dart
import '../../../../shared/widgets/cards/glass_card.dart';
```

- [ ] **Step 2: Replace _WalletSelector Container with GlassCard**

In `_WalletSelector.build()`, replace:

```dart
child: Container(
  padding: const EdgeInsets.symmetric(
    horizontal: AppSizes.md,
    vertical: AppSizes.md,
  ),
  decoration: BoxDecoration(
    border: Border.all(color: cs.outline),
    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
  ),
  child: Row(
```

With:

```dart
child: GlassCard(
  padding: const EdgeInsets.symmetric(
    horizontal: AppSizes.md,
    vertical: AppSizes.md,
  ),
  child: Row(
```

- [ ] **Step 3: Wrap the amount + note section in a GlassCard**

In the `build()` method of `_TransferScreenState`, wrap the amount input and note field in a GlassCard. Replace:

```dart
const SizedBox(height: AppSizes.xl),
Text(
  context.l10n.transfer_amount_label,
  ...
),
const SizedBox(height: AppSizes.sm),
AmountInput(...),
const SizedBox(height: AppSizes.lg),
AppTextField(...),
```

With:

```dart
const SizedBox(height: AppSizes.lg),
GlassCard(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        context.l10n.transfer_amount_label,
        style: context.textStyles.labelLarge
            ?.copyWith(color: context.colors.outline),
      ),
      const SizedBox(height: AppSizes.sm),
      AmountInput(
        onAmountChanged: (p) => setState(() => _amountPiastres = p),
      ),
      const SizedBox(height: AppSizes.lg),
      AppTextField(
        label: context.l10n.transfer_note_label,
        controller: _noteController,
        maxLines: 2,
      ),
    ],
  ),
),
```

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze lib/features/wallets/presentation/screens/transfer_screen.dart`

- [ ] **Step 5: Commit**

```bash
git add lib/features/wallets/presentation/screens/transfer_screen.dart
git commit -m "feat(transfer): glassmorphic conversion — GlassCard sections"
```

---

## Workstream D: Final Verification

### Task D1: Full analyzer pass

- [ ] **Step 1: Run full analyzer**

Run: `flutter analyze lib/`

Fix any issues found.

- [ ] **Step 2: Final commit if fixes needed**

```bash
git add -A
git commit -m "fix: resolve analyzer issues from pre-launch polish"
```
