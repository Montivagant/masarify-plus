---
phase: 02-verification-sweep
plan: 04
subsystem: ui
tags: [snackbar, toast, ux, design-tokens, material-design-3]

requires:
  - phase: 02-verification-sweep
    provides: Plans 02-1/02-2/02-3 verified foundation
provides:
  - Unified SnackHelper with modern compact toast design
  - Zero raw SnackBar constructors outside snack_helper.dart
  - SnackBar design tokens in AppSizes
affects: [all-screens-with-feedback]

tech-stack:
  added: []
  patterns:
    - "SnackHelper.buildSnackBar() for pre-building styled SnackBars"
    - "showSuccessAndReturn/showInfoAndReturn for .closed callback patterns"

key-files:
  created: []
  modified:
    - lib/shared/widgets/feedback/snack_helper.dart
    - lib/core/constants/app_sizes.dart
    - lib/features/wallets/presentation/screens/transfer_screen.dart
    - lib/features/wallets/presentation/screens/add_wallet_screen.dart
    - lib/features/dashboard/presentation/widgets/quick_add_zone.dart
    - lib/features/budgets/presentation/screens/set_budget_screen.dart
    - lib/features/categories/presentation/screens/add_category_screen.dart
    - lib/features/goals/presentation/screens/goal_detail_screen.dart
    - lib/features/goals/presentation/screens/add_goal_screen.dart
    - lib/features/ai_chat/presentation/screens/chat_screen.dart
    - lib/features/transactions/presentation/screens/add_transaction_screen.dart

key-decisions:
  - "Added showSuccessAndReturn/showInfoAndReturn for undo-then-record patterns needing .closed future"
  - "Pre-build error SnackBar for deferred callbacks where context is defunct after screen pop"
  - "Kept snackbarBottomMargin (104dp) for nav bar clearance; new snackHorizontalMargin (24dp) for side margins"

patterns-established:
  - "All SnackBar feedback goes through SnackHelper — no raw SnackBar() constructors in feature code"
  - "Use buildSnackBar() when a pre-built SnackBar is needed for deferred display (e.g., after screen pop)"

requirements-completed: []

duration: 17min
completed: 2026-03-27
---

# Phase 02 Plan 4: App-Wide UX Fixes -- SnackBar Revamp Summary

**Unified SnackHelper with compact 13pt toast design, swipe-to-dismiss, design tokens, and zero raw SnackBar constructors across 9 feature files**

## Performance

- **Duration:** 17 min
- **Started:** 2026-03-27T18:47:03Z
- **Completed:** 2026-03-27T19:04:11Z
- **Tasks:** 4
- **Files modified:** 11

## Accomplishments
- Revamped SnackHelper _show method: smaller icon (20dp), smaller text (13pt), tighter padding (10dp vertical), swipe-to-dismiss, explicit elevation and border radius
- Added 5 new design tokens to AppSizes: snackTextSize, snackBorderRadius, snackVerticalPadding, snackHorizontalMargin, snackElevation
- Replaced 13 raw ScaffoldMessenger.showSnackBar callsites across 9 feature files
- Added showSuccessAndReturn/showInfoAndReturn methods for .closed callback patterns (undo-then-record)
- Added buildSnackBar static method for pre-building SnackBars when context will be defunct at display time

## Task Commits

Each task was committed atomically:

1. **Task 1: Revamp SnackHelper Styling** - `b2c1fb9` (feat)
2. **Task 2: Replace Raw ScaffoldMessenger Calls** - `fa9dec2` (refactor)
3. **Task 3: Verify SnackBar Behavior** - verification only, no code changes
4. **Task 4: Run Full Analysis** - verification only, no code changes

## Files Created/Modified
- `lib/shared/widgets/feedback/snack_helper.dart` - Revamped _show, added buildSnackBar, showSuccessAndReturn, showInfoAndReturn
- `lib/core/constants/app_sizes.dart` - Added 5 SnackBar design tokens
- `lib/features/wallets/presentation/screens/transfer_screen.dart` - 3 raw SnackBar calls replaced
- `lib/features/wallets/presentation/screens/add_wallet_screen.dart` - 1 raw SnackBar call replaced
- `lib/features/dashboard/presentation/widgets/quick_add_zone.dart` - Undo pattern converted to showSuccessAndReturn
- `lib/features/budgets/presentation/screens/set_budget_screen.dart` - 1 raw SnackBar call replaced
- `lib/features/categories/presentation/screens/add_category_screen.dart` - 1 raw SnackBar call replaced
- `lib/features/goals/presentation/screens/goal_detail_screen.dart` - 3 raw SnackBar calls replaced
- `lib/features/goals/presentation/screens/add_goal_screen.dart` - 2 raw SnackBar calls replaced
- `lib/features/ai_chat/presentation/screens/chat_screen.dart` - 1 raw SnackBar call replaced
- `lib/features/transactions/presentation/screens/add_transaction_screen.dart` - Goal-link prompt converted to showInfoAndReturn with pre-built error SnackBar

## Decisions Made
- Added showSuccessAndReturn/showInfoAndReturn for patterns needing the .closed future (quick_add_zone undo-then-record)
- Pre-build error SnackBar via buildSnackBar() for deferred callbacks where context is defunct after screen pop (add_transaction_screen goal-link action)
- Kept existing snackbarBottomMargin (104dp) which properly clears nav bar + FAB; added separate snackHorizontalMargin (24dp) for side padding

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] env.dart stub missing in worktree**
- **Found during:** Task 1 (flutter analyze)
- **Issue:** env.dart is gitignored, doesn't exist in worktree, causing 3 analyzer errors
- **Fix:** Copied env.dart stub from main repo to worktree
- **Files modified:** lib/core/config/env.dart (worktree only, gitignored)
- **Verification:** flutter analyze passes with zero issues
- **Committed in:** not committed (gitignored file)

**2. [Rule 2 - Missing Critical] Added showSuccessAndReturn/showInfoAndReturn methods**
- **Found during:** Task 2 (quick_add_zone uses .closed callback on SnackBar)
- **Issue:** SnackHelper._show used cascade (no return value), but quick_add_zone needs ScaffoldFeatureController for .closed future
- **Fix:** Added showSuccessAndReturn and showInfoAndReturn that return ScaffoldFeatureController; also added buildSnackBar for pre-building
- **Files modified:** lib/shared/widgets/feedback/snack_helper.dart
- **Verification:** quick_add_zone and add_transaction_screen compile and work correctly
- **Committed in:** fa9dec2 (Task 2 commit)

**3. [Rule 1 - Bug] Pre-built error SnackBar for defunct context**
- **Found during:** Task 2 (add_transaction_screen goal-link action fires after screen pop)
- **Issue:** Inner error SnackBar in onPressed callback couldn't use SnackHelper.showError because context is defunct after context.pop()
- **Fix:** Pre-build error SnackBar via SnackHelper.buildSnackBar while context is still valid; pass pre-built SnackBar to captured messenger
- **Files modified:** lib/features/transactions/presentation/screens/add_transaction_screen.dart
- **Verification:** flutter analyze passes, no runtime context access after pop
- **Committed in:** fa9dec2 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (1 blocking, 1 missing critical, 1 bug)
**Impact on plan:** All auto-fixes necessary for correctness. No scope creep. The added methods (showSuccessAndReturn, showInfoAndReturn, buildSnackBar) are natural extensions of the SnackHelper API needed to handle real-world patterns.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 02 (verification-sweep) is now complete with all 4 plans executed
- All SnackBars use unified styling through SnackHelper
- Zero analyzer issues, 203 tests passing
- Ready for Phase 03 (Home Screen Overhaul) or Phase 04 (AI, Voice & Subscriptions Polish)

---
*Phase: 02-verification-sweep*
*Completed: 2026-03-27*
