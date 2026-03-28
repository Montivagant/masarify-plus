---
phase: quick
plan: 260328-phz
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/shared/providers/activity_provider.dart
  - lib/data/repositories/wallet_repository_impl.dart
  - lib/data/repositories/category_repository_impl.dart
  - lib/domain/entities/recurring_rule_entity.dart
  - lib/features/voice_input/presentation/screens/voice_confirm_screen.dart
  - lib/features/dashboard/presentation/screens/dashboard_screen.dart
  - lib/main.dart
  - lib/core/services/ai/chat_action_executor.dart
autonomous: true
requirements: [M-1, M-2, M-3, M-4, M-5, M-6, M-7, M-8, M-9, M-10]

must_haves:
  truths:
    - "Archived wallet names still appear in transfer activity labels"
    - "Archiving a wallet deactivates its recurring rules"
    - "Archiving a category purges its learning mappings"
    - "isDue uses date-only comparison, matching isOverdue behavior"
    - "Pull-to-refresh clears insight card predictions"
    - "Voice batch save is atomic (all-or-nothing within Drift transaction)"
    - "Voice confirm rejects same-wallet transfers before save"
    - "Cash wallet is auto-ensured at startup even after DB restore"
    - "AI-created recurring rules get a sensible nextDueDate based on frequency"
    - "Voice save reports partial success when individual drafts fail"
  artifacts:
    - path: "lib/shared/providers/activity_provider.dart"
      provides: "Transfer wallet name lookup from allWalletsProvider"
    - path: "lib/data/repositories/wallet_repository_impl.dart"
      provides: "Cascade-deactivate recurring rules on wallet archive"
    - path: "lib/data/repositories/category_repository_impl.dart"
      provides: "Purge category_mappings on category archive"
    - path: "lib/domain/entities/recurring_rule_entity.dart"
      provides: "Date-only isDue comparison"
    - path: "lib/features/dashboard/presentation/screens/dashboard_screen.dart"
      provides: "Insight provider invalidation on pull-to-refresh"
    - path: "lib/features/voice_input/presentation/screens/voice_confirm_screen.dart"
      provides: "Atomic voice save, same-wallet validation, per-draft error handling"
    - path: "lib/main.dart"
      provides: "ensureSystemWalletExists fire-and-forget at startup"
    - path: "lib/core/services/ai/chat_action_executor.dart"
      provides: "Frequency-aware nextDueDate for AI recurring actions"
  key_links:
    - from: "lib/shared/providers/activity_provider.dart"
      to: "allWalletsProvider"
      via: "import from wallet_provider.dart"
      pattern: "allWalletsProvider"
    - from: "lib/data/repositories/wallet_repository_impl.dart"
      to: "recurring_rules table"
      via: "customStatement in archive transaction"
      pattern: "UPDATE recurring_rules SET is_active"
---

<objective>
Fix 10 medium-priority audit bugs (M-1 through M-10) covering data integrity cascades, voice/AI edge cases, and dashboard refresh gaps.

Purpose: Resolve data correctness issues that cause stale display (M-1), orphaned data (M-2, M-3), timing bugs (M-4), stale UI (M-5), non-atomic saves (M-6, M-10), missing validation (M-8), startup resilience (M-7), and incorrect defaults (M-9).

Output: 8 files patched across providers, repositories, entities, screens, and main.dart.
</objective>

<execution_context>
@D:/Masarify-Plus/.claude/get-shit-done/workflows/execute-plan.md
@D:/Masarify-Plus/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@lib/shared/providers/activity_provider.dart
@lib/shared/providers/wallet_provider.dart
@lib/shared/providers/background_ai_provider.dart
@lib/data/repositories/wallet_repository_impl.dart
@lib/data/repositories/category_repository_impl.dart
@lib/domain/entities/recurring_rule_entity.dart
@lib/features/dashboard/presentation/screens/dashboard_screen.dart
@lib/features/voice_input/presentation/screens/voice_confirm_screen.dart
@lib/main.dart
@lib/core/services/ai/chat_action_executor.dart

<interfaces>
<!-- Key providers and types the executor needs -->

From lib/shared/providers/wallet_provider.dart:
```dart
final walletsProvider = StreamProvider<List<WalletEntity>>(...);  // Non-archived only
final allWalletsProvider = StreamProvider<List<WalletEntity>>(...);  // ALL including archived
final systemWalletProvider = StreamProvider<WalletEntity?>(...);
```

From lib/shared/providers/background_ai_provider.dart:
```dart
final detectedPatternsProvider = Provider<List<DetectedPattern>>(...);
final spendingPredictionsProvider = Provider<List<SpendingPrediction>>(...);
final budgetSuggestionsProvider = Provider<List<BudgetSuggestion>>(...);
final budgetSavingsProvider = Provider<List<BudgetSaving>>(...);
final upcomingBillsProvider = Provider<List<RecurringRuleEntity>>(...);
```

From lib/shared/providers/repository_providers.dart:
```dart
final walletRepositoryProvider = Provider<IWalletRepository>(...);
final databaseProvider = Provider<AppDatabase>(...);
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Data integrity cascades and date fix (M-1, M-2, M-3, M-4)</name>
  <files>
    lib/shared/providers/activity_provider.dart,
    lib/data/repositories/wallet_repository_impl.dart,
    lib/data/repositories/category_repository_impl.dart,
    lib/domain/entities/recurring_rule_entity.dart
  </files>
  <action>
**M-1: Archived wallet names in transfer labels (activity_provider.dart)**
In both `recentActivityProvider` and `activityByWalletProvider`, change:
```dart
final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
```
to:
```dart
final wallets = ref.watch(allWalletsProvider).valueOrNull ?? [];
```
This makes `walletNames` map include archived wallet names so transfer labels always resolve. The `allWalletsProvider` already exists in `wallet_provider.dart` and streams ALL wallets including archived.

**M-2: Wallet archive cascade for recurring rules (wallet_repository_impl.dart)**
Replace the current passthrough `archive` method:
```dart
@override
Future<bool> archive(int id) => _dao.archive(id);
```
with a method that wraps the DAO call in a `_db.transaction()` and adds a `customStatement` to deactivate recurring rules BEFORE calling `_dao.archive(id)`:
```dart
@override
Future<bool> archive(int id) async {
  return _db.transaction(() async {
    // M-2 fix: cascade — deactivate recurring rules for this wallet
    await _db.customStatement(
      'UPDATE recurring_rules SET is_active = 0 WHERE wallet_id = ?',
      [id],
    );
    return _dao.archive(id);
  });
}
```
This mirrors the pattern already established in `category_repository_impl.dart`'s archive method.

**M-3: Purge category mappings on archive (category_repository_impl.dart)**
Inside the existing `archive` transaction, add a `DELETE FROM category_mappings WHERE category_id = ?` statement. Insert it right after the recurring rules deactivation and before the budgets deletion:
```dart
// M-3 fix: purge stale learning data for archived category
await _db.customStatement(
  'DELETE FROM category_mappings WHERE category_id = ?',
  [id],
);
```

**M-4: isDue date-only comparison (recurring_rule_entity.dart)**
In the `isDue` getter, normalize `now` to date-only before comparison, matching how `isOverdue` already works:
```dart
bool get isDue {
  final now = DateTime.now();
  final todayDate = DateTime(now.year, now.month, now.day);
  final dueDate = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
  final due = dueDate.isBefore(todayDate) ||
      (dueDate.year == todayDate.year &&
       dueDate.month == todayDate.month &&
       dueDate.day == todayDate.day);
  if (frequency == 'once') return due && !isPaid;
  return due;
}
```
This simplifies to: `final due = !dueDate.isAfter(todayDate);` (due date is today or earlier). Use that cleaner form.
  </action>
  <verify>
    <automated>cd D:/Masarify-Plus && flutter analyze lib/shared/providers/activity_provider.dart lib/data/repositories/wallet_repository_impl.dart lib/data/repositories/category_repository_impl.dart lib/domain/entities/recurring_rule_entity.dart</automated>
  </verify>
  <done>
    - activity_provider uses allWalletsProvider for walletNames (archived names resolve)
    - wallet archive cascades recurring rule deactivation via customStatement
    - category archive purges category_mappings rows
    - isDue uses date-only comparison consistent with isOverdue
  </done>
</task>

<task type="auto">
  <name>Task 2: Voice confirm robustness (M-6, M-8, M-10)</name>
  <files>lib/features/voice_input/presentation/screens/voice_confirm_screen.dart</files>
  <action>
**M-8: Same-wallet transfer validation (voice_confirm_screen.dart)**
In the `_confirmAll` method, inside the validation loop (around line 469-495), after the existing transfer destination check (`draft.type == 'transfer' && draft.toWalletId == null`), add a same-wallet guard:
```dart
// M-8 fix: reject same-wallet transfers
if (draft.type == 'transfer' && draft.walletId == draft.toWalletId) {
  SnackHelper.showError(ctx, '$prefix${ctx.l10n.transfer_same_wallet_error}');
  return;
}
```
Check if `transfer_same_wallet_error` l10n key exists. If not, use a hardcoded fallback or an existing key like `common_error_generic`. Grep for existing transfer error keys first — there may be a `transferSameWallet` key already. The `ChatActionMessages` has `transferSameWallet` but that's for AI chat. Check `app_en.arb` and `app_ar.arb` for a suitable key. If none exists, use a reasonable existing error message rather than adding new l10n keys (this is a quick fix).

**M-10: Per-draft error handling instead of all-or-nothing (voice_confirm_screen.dart)**
Replace the `createBatch` call in the regular transaction section with individual `create` calls wrapped in try/catch. Change the block starting at `if (txDrafts.isNotEmpty)` (around line 557) to:

```dart
if (txDrafts.isNotEmpty) {
  final txRepo = ref.read(transactionRepositoryProvider);
  int txSuccessCount = 0;
  int txFailCount = 0;
  for (final draft in txDrafts) {
    try {
      await txRepo.create(
        walletId: draft.walletId!,
        categoryId: draft.categoryId!,
        amount: draft.amountPiastres,
        type: draft.type,
        title: draft.noteController.text.trim().isNotEmpty
            ? draft.noteController.text.trim()
            : draft.rawText,
        transactionDate: draft.transactionDate,
        source: 'voice',
        rawSourceText: draft.rawText,
        note: draft.note,
        goalId: draft.goalId,
      );
      txSuccessCount++;
      // H-1: Wire category learning for voice transactions.
      if (draft.categoryId != null) {
        final learningService = ref.read(categorizationLearningServiceProvider);
        final title = draft.noteController.text.trim().isNotEmpty
            ? draft.noteController.text.trim()
            : draft.rawText;
        learningService.recordMapping(title, draft.categoryId!);
      }
    } catch (_) {
      txFailCount++;
    }
  }
```
Then update the success/error message after the try block to report partial success. Track total successes/failures across all 3 phases (cash, transfer, tx). If all succeeded, show normal success. If some failed, show "Saved X of Y" via SnackHelper.showInfo. If all failed, show error.

**M-6: Atomic voice batch save (voice_confirm_screen.dart)**
NOTE: M-6 (atomic save) and M-10 (per-draft error handling) are somewhat contradictory. M-10 takes priority since it's a better UX — we want partial success, not all-or-nothing. So M-6 is superseded by M-10's per-draft approach. The individual drafts themselves are already atomic (each repo.create is a single DB transaction). The value of M-10 is that one bad draft doesn't kill the whole batch. Do NOT wrap everything in a single `_db.transaction()`.

Track totals across all three phases:
```dart
int totalSuccess = 0;
int totalFail = 0;
```
Increment these in each phase (cash, transfer, tx). At the end, before `nav.pop()`:
- If `totalFail == 0`: show normal success message (existing behavior)
- If `totalSuccess > 0 && totalFail > 0`: show `SnackHelper.showInfo(context, 'Saved $totalSuccess of ${totalSuccess + totalFail} transactions')`
- If `totalSuccess == 0`: show error message

For cash and transfer phases, wrap each individual `transferRepo.create` in try/catch and count success/fail similarly.
  </action>
  <verify>
    <automated>cd D:/Masarify-Plus && flutter analyze lib/features/voice_input/presentation/screens/voice_confirm_screen.dart</automated>
  </verify>
  <done>
    - Same-wallet transfers rejected with error snackbar before save attempt
    - Each draft saved individually with try/catch; partial success reported
    - Category learning only fires for successfully saved drafts
    - Cash wallet missing still caught early and blocks only cash drafts (not all)
  </done>
</task>

<task type="auto">
  <name>Task 3: Dashboard refresh, startup resilience, AI recurring date (M-5, M-7, M-9)</name>
  <files>
    lib/features/dashboard/presentation/screens/dashboard_screen.dart,
    lib/main.dart,
    lib/core/services/ai/chat_action_executor.dart
  </files>
  <action>
**M-5: Insight cards not invalidated on pull-to-refresh (dashboard_screen.dart)**
In the `onRefresh` callback of the `RefreshIndicator` (around line 77), add invalidation for all background AI insight providers after the existing invalidations:
```dart
ref.invalidate(spendingPredictionsProvider);
ref.invalidate(detectedPatternsProvider);
ref.invalidate(budgetSuggestionsProvider);
ref.invalidate(budgetSavingsProvider);
ref.invalidate(upcomingBillsProvider);
```
Add the import for `background_ai_provider.dart` at the top:
```dart
import '../../../../shared/providers/background_ai_provider.dart';
```

**M-7: Cash wallet ensured at startup (main.dart)**
After the existing `runApp()` call and before the notification callback setup (around line 67), add:
```dart
// M-7 fix: ensure Cash wallet exists even after DB restore/corruption
unawaited(container.read(walletRepositoryProvider).ensureSystemWalletExists());
```
The `unawaited` import is already present (`dart:async`). The `walletRepositoryProvider` import from `repository_providers.dart` is already present. The method `ensureSystemWalletExists` already exists in `WalletRepositoryImpl` — it checks for existing system wallet first and only creates if missing, with a default name of 'Cash'.

**M-9: AI CreateRecurringAction nextDueDate calculation (chat_action_executor.dart)**
In the `_executeRecurring` method (around line 258), replace the hardcoded `nextDueDate: now` with a frequency-aware calculation:

```dart
final now = DateTime.now();

// M-9 fix: compute sensible nextDueDate based on frequency
DateTime nextDueDate;
// If the action JSON has a date, use it as the starting reference.
final parsedDate = action.date != null ? DateTime.tryParse(action.date!) : null;

switch (action.frequency) {
  case 'daily':
    nextDueDate = parsedDate ?? now.add(const Duration(days: 1));
    break;
  case 'weekly':
    nextDueDate = parsedDate ?? now.add(const Duration(days: 7));
    break;
  case 'monthly':
    final ref = parsedDate ?? now;
    nextDueDate = DateTime(ref.year, ref.month + 1, 1);
    break;
  case 'yearly':
    final ref = parsedDate ?? now;
    nextDueDate = DateTime(ref.year + 1, ref.month, ref.day);
    break;
  case 'once':
    nextDueDate = parsedDate ?? now;
    break;
  default:
    nextDueDate = parsedDate ?? now;
}
```
Then use `nextDueDate` in the `_recurringRepo.create()` call instead of `now`. Also update `startDate` to use `parsedDate ?? now` for consistency.

Check that `CreateRecurringAction` has a `date` field by grepping `chat_action.dart`. If it doesn't have a `date` field, just compute nextDueDate from frequency without a parsed date (remove the parsedDate logic and use now as the base).
  </action>
  <verify>
    <automated>cd D:/Masarify-Plus && flutter analyze lib/features/dashboard/presentation/screens/dashboard_screen.dart lib/main.dart lib/core/services/ai/chat_action_executor.dart</automated>
  </verify>
  <done>
    - Pull-to-refresh invalidates all 5 insight card providers
    - Cash wallet auto-ensured on app startup (fire-and-forget, no crash if already exists)
    - AI recurring actions get frequency-appropriate nextDueDate (not just DateTime.now())
  </done>
</task>

</tasks>

<verification>
```bash
cd D:/Masarify-Plus && flutter analyze lib/
```
Must report "No issues found!" across all modified files.
</verification>

<success_criteria>
- All 10 medium-priority bugs (M-1 through M-10) addressed
- Zero analyzer warnings introduced
- No new l10n keys required (use existing keys or hardcoded dev strings)
- No breaking changes to public APIs
- Each fix is minimal and surgical — no unnecessary refactoring
</success_criteria>

<output>
After completion, create `.planning/quick/260328-phz-fix-medium-priority-audit-bugs-wave-a-m1/260328-phz-SUMMARY.md`
</output>
