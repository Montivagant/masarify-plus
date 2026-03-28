---
phase: quick
plan: 260328-omm
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/voice_input/presentation/screens/voice_confirm_screen.dart
  - lib/core/services/ai/chat_action_executor.dart
  - lib/shared/providers/chat_provider.dart
  - lib/shared/providers/smart_defaults_provider.dart
  - lib/core/constants/app_sizes.dart
  - lib/core/constants/app_durations.dart
  - lib/features/dashboard/presentation/widgets/month_summary_inline.dart
  - lib/features/dashboard/presentation/widgets/filter_bar.dart
  - lib/features/wallets/presentation/screens/transfer_screen.dart
  - lib/shared/providers/subscription_provider.dart
  - lib/features/ai_chat/presentation/screens/chat_screen.dart
autonomous: true
requirements: []

must_haves:
  truths:
    - "Voice-confirmed transactions learn category mappings (same as manual add)"
    - "AI-chat-created transactions learn category mappings"
    - "No orphaned providers or constants from deleted Quick Start feature"
    - "Month summary uses Phosphor icons, not Material Icons"
    - "FilterBar._topCategories returns List<CategoryEntity>, not List<dynamic>"
    - "Transfer wallet picker excludes archived and system wallets"
    - "Trial expiration detected mid-session without app restart"
    - "Chat screen error snackbar uses SnackHelper, not raw ScaffoldMessenger"
  artifacts:
    - path: "lib/features/voice_input/presentation/screens/voice_confirm_screen.dart"
      provides: "recordMapping calls after voice transaction save"
      contains: "categorizationLearningServiceProvider"
    - path: "lib/core/services/ai/chat_action_executor.dart"
      provides: "recordMapping call after AI chat transaction create"
      contains: "CategorizationLearningService"
    - path: "lib/shared/providers/chat_provider.dart"
      provides: "learningService parameter passed to ChatActionExecutor constructor"
      contains: "categorizationLearningServiceProvider"
    - path: "lib/shared/providers/smart_defaults_provider.dart"
      provides: "Only categoryFrequencyServiceProvider (no frequentTransactionsProvider)"
    - path: "lib/features/dashboard/presentation/widgets/month_summary_inline.dart"
      provides: "AppIcons.income and AppIcons.expense instead of Icons.*"
      contains: "AppIcons.income"
    - path: "lib/features/wallets/presentation/screens/transfer_screen.dart"
      provides: "Filtered wallet list in picker"
      contains: "isArchived"
    - path: "lib/shared/providers/subscription_provider.dart"
      provides: "Daily tick provider for trial expiry mid-session"
      contains: "_dailyTickProvider"
  key_links:
    - from: "voice_confirm_screen.dart"
      to: "categorizationLearningServiceProvider"
      via: "ref.read after createBatch"
      pattern: "categorizationLearningServiceProvider.*recordMapping"
    - from: "chat_action_executor.dart"
      to: "CategorizationLearningService"
      via: "constructor injection"
      pattern: "_learningService.recordMapping"
    - from: "chat_provider.dart"
      to: "ChatActionExecutor"
      via: "constructor call with learningService param"
      pattern: "learningService.*categorizationLearningServiceProvider"
---

<objective>
Fix 8 high-priority audit bugs (H-1 through H-8) with surgical code changes.

Purpose: Close audit findings that affect feature correctness, design-token compliance, type safety, and subscription integrity.
Output: 8 bugs fixed across 11 files, zero analyzer warnings.
</objective>

<execution_context>
@D:/Masarify-Plus/.claude/get-shit-done/workflows/execute-plan.md
@D:/Masarify-Plus/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md

<interfaces>
<!-- CategorizationLearningService — the service we need to wire in H-1 -->
From lib/core/services/ai/categorization_learning_service.dart:
```dart
class CategorizationLearningService {
  CategorizationLearningService(CategoryMappingDao dao);
  Future<void> recordMapping(String title, int categoryId) async;
  Future<int?> suggestCategory(String title) async;
}
```

From lib/shared/providers/background_ai_provider.dart:
```dart
final categorizationLearningServiceProvider = Provider<CategorizationLearningService>(...);
```

From lib/shared/providers/chat_provider.dart (lines 155-164):
```dart
final chatActionExecutorProvider = Provider<ChatActionExecutor>((ref) {
  return ChatActionExecutor(
    goalRepo: ref.watch(goalRepositoryProvider),
    txRepo: ref.watch(transactionRepositoryProvider),
    budgetRepo: ref.watch(budgetRepositoryProvider),
    recurringRepo: ref.watch(recurringRuleRepositoryProvider),
    walletRepo: ref.watch(walletRepositoryProvider),
    transferRepo: ref.watch(transferRepositoryProvider),
  );
});
```

From lib/core/constants/app_icons.dart:
```dart
static const IconData expense = PhosphorIconsBold.arrowDown;  // line 42
static const IconData income = PhosphorIconsBold.arrowUp;     // line 43
```

From lib/domain/entities/wallet_entity.dart:
```dart
final bool isArchived;     // line 32
final bool isSystemWallet; // line 41
```

From lib/shared/widgets/feedback/snack_helper.dart:
```dart
abstract final class SnackHelper {
  static void showError(BuildContext context, String message, {...});
}
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Wire category learning into voice + AI chat, delete orphans (H-1, H-2)</name>
  <files>
    lib/features/voice_input/presentation/screens/voice_confirm_screen.dart,
    lib/core/services/ai/chat_action_executor.dart,
    lib/shared/providers/chat_provider.dart,
    lib/shared/providers/smart_defaults_provider.dart,
    lib/core/constants/app_sizes.dart,
    lib/core/constants/app_durations.dart
  </files>
  <action>
**H-1a — voice_confirm_screen.dart:**
1. Add import: `import '../../../../shared/providers/background_ai_provider.dart';`
2. In `_confirmAll()`, after the `txRepo.createBatch()` call succeeds (around line 577, after the closing `);`), add a loop to record category mappings for each saved transaction draft:
```dart
// H-1: Wire category learning for voice transactions.
final learningService = ref.read(categorizationLearningServiceProvider);
for (final draft in txDrafts) {
  if (draft.categoryId != null) {
    final title = draft.noteController.text.trim().isNotEmpty
        ? draft.noteController.text.trim()
        : draft.rawText;
    learningService.recordMapping(title, draft.categoryId!);
  }
}
```
Place this AFTER the `createBatch()` call (line ~577) but BEFORE the `if (!mounted) return;` check at line 580. Fire-and-forget is acceptable (no await needed), but `await` is fine for data consistency.

**H-1b — chat_action_executor.dart:**
1. Add import: `import 'categorization_learning_service.dart';`
2. Add `CategorizationLearningService` as a constructor parameter:
   - Add `required CategorizationLearningService learningService,` to the named parameters in `ChatActionExecutor` constructor
   - Add `_learningService = learningService` to the initializer list
   - Add field: `final CategorizationLearningService _learningService;`
3. In `_executeTransaction()`, after the `await _txRepo.create(...)` call (line ~164), BEFORE the subscription detection block, add:
```dart
// H-1: Record category mapping for learning.
await _learningService.recordMapping(action.title, matched.id);
```

**H-1c — chat_provider.dart (call site):**
1. Add import: `import '../../core/services/ai/categorization_learning_service.dart';` (if not already imported)
2. Add import: `import 'background_ai_provider.dart';` (if not already imported)
3. In `chatActionExecutorProvider` (line 155-164), add the new parameter:
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
  );
});
```

**H-2 — Delete orphaned code:**
1. In `smart_defaults_provider.dart`: Remove the entire `FrequentTransaction` class (lines 21-39), the `frequentTransactionsProvider` (lines 42-93), and the `_FreqGroup` class (lines 95-109). Keep `categoryFrequencyServiceProvider` (lines 13-18). Remove now-unused imports: `app_durations.dart`, `app_sizes.dart`, `transaction_provider.dart`. Check if `category_provider.dart` is still needed — it is NOT used by `categoryFrequencyServiceProvider`, so remove it too. Final file should only have: `flutter_riverpod` import, `category_frequency_service` import, `preferences_service` import, `theme_provider` import, and the `categoryFrequencyServiceProvider` definition.
2. In `app_sizes.dart`: Remove lines 235-236 (`quickAddMinOccurrences` and `quickAddMaxItems`). Keep the comment line 233 ("Smart defaults / Quick Add") only if `borderWidthEmphasis` or `categoryChipMaxVisible` remain in that section.
3. In `app_durations.dart`: Remove line 77 (`quickAddLookback`). Keep the "Smart defaults" comment and `transactionDedupeWindow` on line 78.
  </action>
  <verify>
    <automated>flutter analyze lib/</automated>
  </verify>
  <done>
    - Voice _confirmAll records category mappings for each saved transaction draft
    - ChatActionExecutor._executeTransaction records category mapping after create
    - ChatActionExecutor constructor accepts learningService; chat_provider.dart passes it
    - frequentTransactionsProvider, FrequentTransaction, _FreqGroup fully removed
    - quickAddMinOccurrences, quickAddMaxItems, quickAddLookback constants removed
    - Zero analyzer warnings
  </done>
</task>

<task type="auto">
  <name>Task 2: Fix design tokens, type safety, wallet filtering (H-3, H-4, H-5/H-8)</name>
  <files>
    lib/features/dashboard/presentation/widgets/month_summary_inline.dart,
    lib/features/dashboard/presentation/widgets/filter_bar.dart,
    lib/features/wallets/presentation/screens/transfer_screen.dart
  </files>
  <action>
**H-3 — month_summary_inline.dart:**
1. Verify `app_icons.dart` is imported. It is NOT currently imported — add: `import '../../../../core/constants/app_icons.dart';`
2. Line 57: Replace `Icons.arrow_upward` with `AppIcons.income`.
3. Line 71: Replace `Icons.arrow_downward` with `AppIcons.expense`.
Note: `AppIcons.income` = `PhosphorIconsBold.arrowUp`, `AppIcons.expense` = `PhosphorIconsBold.arrowDown` — semantically correct for income=up, expense=down.

**H-4 — filter_bar.dart:**
1. Add import: `import '../../../../domain/entities/category_entity.dart';`
2. Line 178: Change return type from `List<dynamic>` to `List<CategoryEntity>`.
3. The method body already produces `List<CategoryEntity>` from `categoriesProvider` — no other changes needed.

**H-5 + H-8 — transfer_screen.dart:**
1. In `_showWalletPicker()` (line 59), change line 63 from:
   ```dart
   final wallets = allWallets.where((w) => w.id != excludeId).toList();
   ```
   To:
   ```dart
   final wallets = allWallets
       .where((w) => w.id != excludeId && !w.isArchived && !w.isSystemWallet)
       .toList();
   ```
   This filters out archived wallets AND the Cash system wallet from the transfer picker.
  </action>
  <verify>
    <automated>flutter analyze lib/</automated>
  </verify>
  <done>
    - month_summary_inline uses AppIcons.income and AppIcons.expense (zero Icons.* references)
    - filter_bar._topCategories returns List<CategoryEntity> (zero List<dynamic>)
    - transfer_screen wallet picker excludes archived and system wallets
    - Zero analyzer warnings
  </done>
</task>

<task type="auto">
  <name>Task 3: Fix trial expiry mid-session + chat SnackHelper (H-6, H-7)</name>
  <files>
    lib/shared/providers/subscription_provider.dart,
    lib/features/ai_chat/presentation/screens/chat_screen.dart
  </files>
  <action>
**H-6 — subscription_provider.dart:**
The problem: `hasProAccessProvider` reads `service.hasProAccess` once and only invalidates on `proStatusStream` events (purchase completions). If a trial expires at midnight while the app is open, nothing triggers re-evaluation.

Solution: Add a `_dailyTickProvider` that computes milliseconds until next midnight and schedules invalidation via a Timer. `hasProAccessProvider` watches this tick to force re-evaluation at day boundaries.

1. Add import at top: `import 'dart:async';`
2. After `subscriptionServiceProvider` (after line 15), add:
```dart
/// Ticks once at midnight to trigger re-evaluation of trial status.
/// Returns current date as (year, month, day) tuple — changes at midnight.
final _dailyTickProvider = Provider<(int, int, int)>((ref) {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final msUntilMidnight = tomorrow.difference(now).inMilliseconds;

  // Schedule invalidation at midnight so providers re-evaluate.
  final timer = Timer(Duration(milliseconds: msUntilMidnight + 100), () {
    ref.invalidateSelf();
  });
  ref.onDispose(timer.cancel);

  return (now.year, now.month, now.day);
});
```
3. In `hasProAccessProvider` (line 21), add `ref.watch(_dailyTickProvider);` as the first line inside the provider body, BEFORE the `ref.watch(subscriptionServiceProvider)` call:
```dart
final hasProAccessProvider = Provider<bool>(
  (ref) {
    final service = ref.watch(subscriptionServiceProvider);

    // H-6: Re-evaluate at midnight when trial may expire.
    ref.watch(_dailyTickProvider);

    // Listen for purchase completions and invalidate self to re-read.
    final sub = service.proStatusStream.listen((_) {
      ref.invalidateSelf();
    });
    ref.onDispose(sub.cancel);

    return service.hasProAccess;
  },
);
```

**H-7 — chat_screen.dart:**
1. Add import: `import '../../../../shared/widgets/feedback/snack_helper.dart';`
2. Replace lines 205-210 (the ScaffoldMessenger block):
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(errorGeneric),
    duration: AppDurations.snackbarShort,
  ),
);
```
With:
```dart
SnackHelper.showError(context, errorGeneric);
```
The default error duration (4s) is better UX for errors than the original 2s.
  </action>
  <verify>
    <automated>flutter analyze lib/</automated>
  </verify>
  <done>
    - hasProAccessProvider watches _dailyTickProvider, forcing re-evaluation at midnight
    - Timer schedules invalidation ~100ms after midnight to catch trial expiry
    - Chat screen uses SnackHelper.showError instead of raw ScaffoldMessenger
    - Zero analyzer warnings
  </done>
</task>

</tasks>

<verification>
```bash
flutter analyze lib/
```
Must return "No issues found!" confirming all 8 fixes compile cleanly with no analyzer warnings.

Grep confirmations:
- `grep -n "Icons\." lib/features/dashboard/presentation/widgets/month_summary_inline.dart` returns NO results
- `grep -n "List<dynamic>" lib/features/dashboard/presentation/widgets/filter_bar.dart` returns NO results
- `grep -rn "frequentTransactionsProvider\|_FreqGroup\|quickAddMinOccurrences\|quickAddMaxItems\|quickAddLookback" lib/shared/providers/smart_defaults_provider.dart lib/core/constants/app_sizes.dart lib/core/constants/app_durations.dart` returns NO results
- `grep -n "ScaffoldMessenger" lib/features/ai_chat/presentation/screens/chat_screen.dart` returns NO results
- `grep -n "categorizationLearningServiceProvider" lib/features/voice_input/presentation/screens/voice_confirm_screen.dart` returns a match
- `grep -n "learningService" lib/shared/providers/chat_provider.dart` returns a match
- `grep -n "isArchived" lib/features/wallets/presentation/screens/transfer_screen.dart` returns a match
- `grep -n "_dailyTickProvider" lib/shared/providers/subscription_provider.dart` returns a match
</verification>

<success_criteria>
All 8 high-priority audit bugs (H-1 through H-8) fixed:
- H-1: Category learning wired into voice confirm + AI chat executor (+ chat_provider call site)
- H-2: Orphaned frequentTransactionsProvider + constants deleted
- H-3: Material Icons replaced with AppIcons in month_summary_inline
- H-4: FilterBar._topCategories returns List<CategoryEntity>
- H-5+H-8: Transfer wallet picker filters archived + system wallets
- H-6: Trial expiration detected mid-session via daily tick provider
- H-7: Chat screen uses SnackHelper.showError
- `flutter analyze lib/` reports zero issues
</success_criteria>

<output>
After completion, create `.planning/quick/260328-omm-fix-high-priority-audit-bugs-wave-a-h1-h/260328-omm-SUMMARY.md`
</output>
