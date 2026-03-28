---
phase: quick
plan: 260328-omm
subsystem: core, voice, ai-chat, dashboard, wallets, monetization
tags: [bugfix, audit, design-tokens, type-safety, category-learning, subscription]
dependency_graph:
  requires: []
  provides: [category-learning-voice, category-learning-ai-chat, daily-tick-provider]
  affects: [voice_confirm_screen, chat_action_executor, chat_provider, smart_defaults_provider, month_summary_inline, filter_bar, transfer_screen, subscription_provider, chat_screen, app_sizes, app_durations]
tech_stack:
  added: []
  patterns: [fire-and-forget-learning, timer-based-invalidation]
key_files:
  created: []
  modified:
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
decisions:
  - "H-1 learning calls are fire-and-forget in voice (no await) for UX responsiveness, awaited in chat executor for data consistency"
  - "H-6 daily tick uses 100ms offset past midnight to avoid race with date boundary"
  - "H-7 removal of ScaffoldMessenger also removes unused AppDurations import (auto-fix Rule 1)"
metrics:
  duration_seconds: 528
  completed: "2026-03-28T15:59:26Z"
  tasks_completed: 3
  tasks_total: 3
  files_modified: 11
---

# Quick Task 260328-omm: Fix High-Priority Audit Bugs Wave A (H-1 through H-8) Summary

Category learning wired into voice confirm and AI chat executor; orphaned Quick Start providers and constants deleted; Material Icons replaced with Phosphor design tokens; filter bar type safety fixed; transfer wallet picker filters archived and system wallets; trial expiry detected mid-session via daily tick provider; chat screen error snackbar uses SnackHelper.

## Commits

| # | Hash | Message | Files |
|---|------|---------|-------|
| 1 | 8231179 | fix(quick-260328-omm): wire category learning into voice + AI chat, delete orphans (H-1, H-2) | voice_confirm_screen, chat_action_executor, chat_provider, smart_defaults_provider, app_sizes, app_durations |
| 2 | 844b36a | fix(quick-260328-omm): fix design tokens, type safety, wallet filtering (H-3, H-4, H-5/H-8) | month_summary_inline, filter_bar, transfer_screen |
| 3 | e618d26 | fix(quick-260328-omm): fix trial expiry mid-session + chat SnackHelper (H-6, H-7) | subscription_provider, chat_screen |

## Bug Fixes Applied

### H-1: Category learning wired into voice + AI chat
- **Voice:** After `createBatch()` succeeds, loops through saved `txDrafts` and calls `learningService.recordMapping()` for each draft with a categoryId.
- **AI Chat:** `ChatActionExecutor` constructor now accepts `CategorizationLearningService`. After `_txRepo.create()` in `_executeTransaction()`, calls `_learningService.recordMapping(action.title, matched.id)`.
- **Provider:** `chatActionExecutorProvider` passes `categorizationLearningServiceProvider` as the new `learningService` parameter.

### H-2: Orphaned Quick Start code deleted
- **smart_defaults_provider.dart:** Removed `FrequentTransaction` class (lines 21-39), `frequentTransactionsProvider` (lines 43-93), `_FreqGroup` class (lines 95-109), and 4 unused imports (`app_durations`, `app_sizes`, `category_provider`, `transaction_provider`). File reduced from 110 lines to 15.
- **app_sizes.dart:** Removed `quickAddMinOccurrences` and `quickAddMaxItems` constants.
- **app_durations.dart:** Removed `quickAddLookback` duration constant.

### H-3: Material Icons replaced with design tokens
- **month_summary_inline.dart:** `Icons.arrow_upward` replaced with `AppIcons.income`, `Icons.arrow_downward` replaced with `AppIcons.expense`. Added `app_icons.dart` import.

### H-4: FilterBar type safety
- **filter_bar.dart:** `_topCategories()` return type changed from `List<dynamic>` to `List<CategoryEntity>`. Added `category_entity.dart` import.

### H-5 + H-8: Transfer wallet picker filtering
- **transfer_screen.dart:** `_showWalletPicker()` now filters `!w.isArchived && !w.isSystemWallet` in addition to excluding the other side's wallet. Prevents archived accounts and the Cash system wallet from appearing in transfer picker.

### H-6: Trial expiry detected mid-session
- **subscription_provider.dart:** Added `_dailyTickProvider` that computes milliseconds until midnight and schedules `ref.invalidateSelf()` via a `Timer`. `hasProAccessProvider` watches this tick to force re-evaluation at day boundaries, catching trial expiry without app restart.

### H-7: Chat error uses SnackHelper
- **chat_screen.dart:** Replaced `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` with `SnackHelper.showError(context, errorGeneric)`. Removed unused `AppDurations` import.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unused import after H-7 fix**
- **Found during:** Task 3
- **Issue:** Removing `ScaffoldMessenger` block left `AppDurations` import unused, which would cause analyzer warning.
- **Fix:** Removed the unused import.
- **Files modified:** chat_screen.dart
- **Commit:** e618d26

**2. [Rule 3 - Blocking] Main repo code differs from plan assumptions**
- **Found during:** Task 1 initial read
- **Issue:** Plan's `<interfaces>` section was based on worktree code (behind main). The main repo had significant differences: `ChatActionExecutor` already had `transferRepo` parameter, `execute()` returns `ExecutionResult` not `String`, `_showWalletPicker` in `transfer_screen.dart` already had more filtering. Plan assumed 5-param constructor; actual had 6 params.
- **Fix:** Adapted all edits to the actual current code state in the main repo instead of the stale worktree.
- **Files modified:** All files in all 3 tasks

## Verification Results

- `flutter analyze lib/` -- No issues found
- No `Icons.*` references in month_summary_inline.dart (only `AppIcons.*`)
- No `List<dynamic>` in filter_bar.dart
- No `frequentTransactionsProvider`, `_FreqGroup`, `quickAddMinOccurrences`, `quickAddMaxItems`, `quickAddLookback` in cleaned files
- No `ScaffoldMessenger` in chat_screen.dart
- `categorizationLearningServiceProvider` confirmed in voice_confirm_screen.dart
- `learningService` confirmed in chat_provider.dart
- `isArchived` confirmed in transfer_screen.dart
- `_dailyTickProvider` confirmed in subscription_provider.dart

## Known Stubs

None -- all changes are complete implementations with no placeholders.

## Self-Check: PASSED

- All 11 modified files exist on disk
- All 3 task commits found in git history (8231179, 844b36a, e618d26)
- SUMMARY.md created at expected path
