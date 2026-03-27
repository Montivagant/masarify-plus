---
phase: 03-home-screen-overhaul
plan: 02
subsystem: ui
tags: [flutter, slivers, riverpod, slidable, search, filter, date-grouping, swipe-actions]

# Dependency graph
requires:
  - phase: 03-home-screen-overhaul
    plan: 01
    provides: HomeFilter model, filteredActivityProvider, selectedAccountIdProvider, BalanceHeader, FilterBar, FilterBarDelegate, CustomScrollView shell
provides:
  - TransactionSliverList with lazy SliverList.builder and date grouping
  - DateGroupHeader with daily net subtotals colored by sign
  - SearchHeader with debounced 300ms inline search and result count
  - SortBottomSheet with 4 sort options replacing inline cycling
  - FilterBadge showing active account + type filters with "Clear all"
  - Swipe-to-edit (right) and swipe-to-delete (left) on all transaction types
  - 2-step transfer deletion confirmation ("Delete both legs?")
  - walletName display on TransactionCard for All Accounts view
  - SlidableAutoCloseBehavior wrapping the transaction list
  - 9 new l10n keys (EN + AR) for sort, filters, delete confirmations
affects: [03-03-PLAN, 05-monetization-onboarding]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Flat list interleaving date headers and transaction cards via _ListItem union type"
    - "SlidableAutoCloseBehavior wrapping CustomScrollView for auto-close on new swipe"
    - "Callback-based swipe actions delegated from TransactionSliverList to DashboardScreen"
    - "Synthetic transfer ID extraction: abs(id) ~/ 2 to recover original transfer ID"

key-files:
  created:
    - lib/features/dashboard/presentation/widgets/transaction_sliver_list.dart
    - lib/features/dashboard/presentation/widgets/date_group_header.dart
    - lib/features/dashboard/presentation/widgets/search_header.dart
    - lib/features/dashboard/presentation/widgets/sort_bottom_sheet.dart
    - lib/features/dashboard/presentation/widgets/filter_badge.dart
  modified:
    - lib/features/dashboard/presentation/screens/dashboard_screen.dart
    - lib/features/dashboard/presentation/widgets/filter_bar.dart
    - lib/shared/widgets/cards/transaction_card.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_ar.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_ar.dart
    - lib/l10n/app_localizations_en.dart
    - pubspec.yaml

key-decisions:
  - "Swipe actions wired in Task 1 alongside list creation (natural architecture fit)"
  - "TransactionCard already had Slidable support — callbacks delegated from dashboard"
  - "Notes field verified functional — no changes needed to AddTransactionScreen"
  - "SlidableAutoCloseBehavior wraps CustomScrollView for proper group behavior"

patterns-established:
  - "Flat _ListItem union: isHeader vs transaction for interleaved date-grouped lists"
  - "Dashboard delegates all transaction actions (tap/edit/delete) through callbacks"
  - "Transfer deletion extracts original ID via syntheticId ~/ 2"

requirements-completed: [HOME-03, TXN-01, TXN-06]

# Metrics
duration: 10min
completed: 2026-03-27
---

# Phase 03 Plan 02: Transaction SliverList Summary

**Lazy SliverList.builder with date grouping, inline search, sort bottom sheet, filter badge, swipe-to-edit/delete with 2-step transfer confirmation, and wallet names in All Accounts view**

## Performance

- **Duration:** 10 min
- **Started:** 2026-03-27T21:00:34Z
- **Completed:** 2026-03-27T21:10:03Z
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments
- Built TransactionSliverList with lazy SliverList.builder, date group headers interleaved via flat list, and daily net subtotals colored by sign
- Implemented inline search (SearchHeader) with 300ms debounce, result count, and cancel button
- Created SortBottomSheet with 4 sort options replacing the Plan 01 inline cycling stub
- Added FilterBadge showing combined account + type filter state with "Clear all" reset
- Wired swipe-to-edit (right) and swipe-to-delete (left) on all transaction types including 2-step transfer deletion
- Added walletName parameter to TransactionCard for All Accounts view
- Verified notes/memo field in AddTransactionScreen is fully functional (no changes needed)

## Task Commits

Each task was committed atomically:

1. **Task 1: Build transaction SliverList with date grouping, search, sort, and filter badge** - `fac355f` (feat)
2. **Task 2: Wire swipe-to-edit/delete with SlidableAutoCloseBehavior and verify notes field** - `debd623` (feat)

## Files Created/Modified
- `lib/features/dashboard/presentation/widgets/transaction_sliver_list.dart` - Lazy SliverList.builder with date group headers interleaved
- `lib/features/dashboard/presentation/widgets/date_group_header.dart` - Date header with daily net subtotal
- `lib/features/dashboard/presentation/widgets/search_header.dart` - Inline search bar with debounce and result count
- `lib/features/dashboard/presentation/widgets/sort_bottom_sheet.dart` - Modal bottom sheet with 4 sort options
- `lib/features/dashboard/presentation/widgets/filter_badge.dart` - Active filter indicator with clear-all
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` - Full wiring with edit/delete/tap callbacks, SlidableAutoCloseBehavior
- `lib/features/dashboard/presentation/widgets/filter_bar.dart` - Sort button now opens SortBottomSheet
- `lib/shared/widgets/cards/transaction_card.dart` - Added walletName parameter for All Accounts view
- `lib/l10n/app_en.arb` + `lib/l10n/app_ar.arb` - 9 new l10n keys

## Decisions Made
- Swipe-to-edit and swipe-to-delete wired in Task 1 alongside the TransactionSliverList creation rather than separated into Task 2, since the dashboard callbacks were part of the same wiring (callbacks passed from dashboard through TransactionSliverList to TransactionCard).
- Notes field in AddTransactionScreen verified fully functional (controller defined, save method includes note, edit mode populates note, optional section auto-expands). No changes needed.
- Used `SlidableAutoCloseBehavior` wrapping `CustomScrollView` rather than per-item group tags for cleaner architecture.
- Transfer deletion extracts original transfer ID from synthetic negative ID using `abs(id) ~/ 2` per the TransferAdapter convention (`fromEntry.id = -(transfer.id * 2)`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed duplicate flutter_markdown in pubspec.yaml**
- **Found during:** Task 1 (flutter gen-l10n)
- **Issue:** `flutter_markdown: ^0.7.4+3` was duplicated in pubspec.yaml causing YAML parse failure
- **Fix:** Removed the duplicate entry
- **Files modified:** `pubspec.yaml`
- **Verification:** `flutter gen-l10n` succeeded after fix
- **Committed in:** fac355f (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Pre-existing pubspec issue; necessary fix for any flutter command to work. No scope creep.

## Known Stubs

None - all widgets are fully functional with real data providers.

## Issues Encountered
- Pre-existing analyzer errors in `account_manage_sheet.dart` and `insight_cards_zone.dart` reference l10n keys that don't exist. These are out of scope (not modified by this plan). Logged as pre-existing.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Home screen transaction management is fully functional: list, search, sort, filter, swipe actions
- Plan 03-03 (VoiceConfirmScreen revamp) is the only remaining plan in Phase 03
- The filter bar, balance header, and transaction list work as a cohesive unit
- All 3 Plan 02 requirements (HOME-03, TXN-01, TXN-06) verified complete

## Self-Check: PASSED

All files verified present. All commits verified in history (fac355f, debd623). SUMMARY.md created.

---
*Phase: 03-home-screen-overhaul*
*Completed: 2026-03-27*
