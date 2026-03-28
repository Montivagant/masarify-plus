---
phase: quick
plan: 260328-phz
subsystem: data-integrity, voice-input, dashboard, ai-chat, startup
tags: [audit, bug-fix, medium-priority, M-1, M-2, M-3, M-4, M-5, M-6, M-7, M-8, M-9, M-10]
dependency_graph:
  requires: []
  provides:
    - archived-wallet-name-resolution-in-transfers
    - wallet-archive-recurring-cascade
    - category-archive-mapping-purge
    - date-only-isDue-comparison
    - pull-to-refresh-insight-invalidation
    - voice-per-draft-error-handling
    - voice-same-wallet-validation
    - startup-cash-wallet-resilience
    - ai-recurring-frequency-nextDueDate
  affects:
    - activity_provider.dart
    - wallet_repository_impl.dart
    - category_repository_impl.dart
    - recurring_rule_entity.dart
    - voice_confirm_screen.dart
    - dashboard_screen.dart
    - main.dart
    - chat_action_executor.dart
tech_stack:
  added: []
  patterns:
    - per-draft-error-handling-with-partial-success
    - date-only-comparison-for-due-checks
    - cascade-deactivation-in-db-transactions
key_files:
  created: []
  modified:
    - lib/shared/providers/activity_provider.dart
    - lib/data/repositories/wallet_repository_impl.dart
    - lib/data/repositories/category_repository_impl.dart
    - lib/domain/entities/recurring_rule_entity.dart
    - lib/features/voice_input/presentation/screens/voice_confirm_screen.dart
    - lib/features/dashboard/presentation/screens/dashboard_screen.dart
    - lib/main.dart
    - lib/core/services/ai/chat_action_executor.dart
decisions:
  - "M-6 (atomic batch save) superseded by M-10 (per-draft error handling) -- partial success is better UX than all-or-nothing"
  - "Reused existing l10n key chat_action_transfer_same_wallet for voice same-wallet validation instead of adding new keys"
  - "CreateRecurringAction has no date field -- nextDueDate computed from frequency using now as base"
metrics:
  duration: "8m 35s"
  completed: "2026-03-28T16:34:38Z"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 8
---

# Quick Task 260328-phz: Fix Medium-Priority Audit Bugs Wave A (M-1 through M-10) Summary

**One-liner:** Data integrity cascades on wallet/category archive, date-only isDue comparison, per-draft voice save with partial success reporting, dashboard pull-to-refresh insight invalidation, startup Cash wallet resilience, and frequency-aware AI recurring nextDueDate.

## Commits

| # | Hash | Message | Files |
|---|------|---------|-------|
| 1 | 296376e | fix(260328-phz): data integrity cascades and date fix (M-1, M-2, M-3, M-4) | 4 |
| 2 | 6b219c6 | fix(260328-phz): voice confirm robustness (M-6, M-8, M-10) | 1 |
| 3 | 6792473 | fix(260328-phz): dashboard refresh, startup resilience, AI recurring date (M-5, M-7, M-9) | 3 |

## Bug Fix Details

### Task 1: Data Integrity Cascades and Date Fix (M-1, M-2, M-3, M-4)

**M-1: Archived wallet names in transfer labels** -- `activity_provider.dart` now uses `allWalletsProvider` (includes archived) instead of `walletsProvider` (non-archived only) for building `walletNames` map. Transfer labels like "CIB -> NBE" now resolve correctly even if NBE is archived.

**M-2: Wallet archive cascade for recurring rules** -- `wallet_repository_impl.dart` archive method now wraps the DAO call in a `_db.transaction()` that first deactivates all recurring rules for the wallet via `customStatement('UPDATE recurring_rules SET is_active = 0 WHERE wallet_id = ?')`.

**M-3: Purge category mappings on archive** -- `category_repository_impl.dart` archive transaction now includes `DELETE FROM category_mappings WHERE category_id = ?` to purge stale learning data when a category is archived, preventing the categorization learning service from suggesting archived categories.

**M-4: isDue date-only comparison** -- `recurring_rule_entity.dart` isDue getter now normalizes both `now` and `nextDueDate` to date-only values before comparison using `!dueDate.isAfter(todayDate)`, matching the date-only approach already used by `isOverdue`.

### Task 2: Voice Confirm Robustness (M-6, M-8, M-10)

**M-8: Same-wallet transfer validation** -- Added guard in `_confirmAll` validation loop that rejects transfers where `walletId == toWalletId`, using existing l10n key `chat_action_transfer_same_wallet`.

**M-10: Per-draft error handling** -- Replaced `txRepo.createBatch()` with individual `txRepo.create()` calls per draft, each wrapped in try/catch. Cash and transfer drafts similarly wrapped individually. Partial success reporting: shows "Saved X of Y transactions" when some drafts fail but others succeed. Category learning only fires for successfully saved drafts.

**M-6: Atomic batch save** -- Superseded by M-10. Per-draft error handling provides better UX than all-or-nothing atomicity. Each individual `create()` call is already atomic at the DB level.

### Task 3: Dashboard, Startup, AI Recurring (M-5, M-7, M-9)

**M-5: Insight provider invalidation on pull-to-refresh** -- Added invalidation for all 5 background AI insight providers (`spendingPredictionsProvider`, `detectedPatternsProvider`, `budgetSuggestionsProvider`, `budgetSavingsProvider`, `upcomingBillsProvider`) in the `RefreshIndicator.onRefresh` callback.

**M-7: Cash wallet ensured at startup** -- Added fire-and-forget `unawaited(container.read(walletRepositoryProvider).ensureSystemWalletExists())` call after `runApp()` in `main.dart`. The method is idempotent (checks for existing system wallet first).

**M-9: AI recurring nextDueDate calculation** -- Replaced hardcoded `nextDueDate: now` with frequency-aware computation: daily=+1 day, weekly=+7 days, monthly=next month same day, yearly=next year same day/month, once/custom=now.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Trailing comma lint fix in main.dart**
- **Found during:** Task 3
- **Issue:** Formatter lint `require_trailing_commas` triggered on the `unawaited()` call
- **Fix:** Reformatted to multi-line with trailing comma
- **Files modified:** lib/main.dart
- **Commit:** 6792473

**2. [Rule 1 - Bug] Removed unused import in voice_confirm_screen.dart**
- **Found during:** Task 2
- **Issue:** Switching from `createBatch` to individual `create` calls made `i_transaction_repository.dart` import unused (which exported `CreateTransactionParams`)
- **Fix:** Removed the unused import
- **Files modified:** lib/features/voice_input/presentation/screens/voice_confirm_screen.dart
- **Commit:** 6b219c6

## Verification

- `flutter analyze lib/` -- No issues found (with env.dart stub in place; env.dart is gitignored)
- Per-task analysis passed for all 8 modified files
- No new l10n keys added (reused existing `chat_action_transfer_same_wallet`)
- No breaking changes to public APIs

## Known Stubs

None -- all fixes are complete implementations with no placeholder data.

## Self-Check: PASSED

All 8 modified files exist. All 3 commit hashes verified.
