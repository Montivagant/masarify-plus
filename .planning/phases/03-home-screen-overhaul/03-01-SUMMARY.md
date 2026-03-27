---
phase: 03-home-screen-overhaul
plan: 01
subsystem: ui
tags: [flutter, slivers, riverpod, glassmorphism, customscrollview, account-chips]

# Dependency graph
requires:
  - phase: 02-verification-sweep
    provides: Verified foundation (transfer adapter, account selection, category resolution)
provides:
  - HomeFilter model and filteredActivityProvider for filter/search/sort state
  - Direct wallet-ID selectedAccountIdProvider (replaces index-based)
  - BalanceHeader with compact account chips (replaces AccountCarousel)
  - MonthSummaryInline for compact income/expense/net row
  - FilterBar with type chips and sort button
  - FilterBarDelegate for pinned SliverPersistentHeader
  - CustomScrollView + Slivers dashboard shell (replaces SingleChildScrollView + Column)
  - 12 new l10n keys for filter/sort/search/net in EN and AR
affects: [03-02-PLAN, 03-03-PLAN, 05-monetization-onboarding]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Provider-level filtering (not DAO-level) for merged transaction+transfer streams"
    - "CustomScrollView + SliverToBoxAdapter/SliverPersistentHeader composition"
    - "Direct wallet-ID selection (StateProvider<int?>) replacing index-based carousel selection"
    - "Translucent glass surfaces instead of BackdropFilter on slivers (Impeller disabled)"

key-files:
  created:
    - lib/shared/providers/home_filter_provider.dart
    - lib/features/dashboard/presentation/widgets/balance_header.dart
    - lib/features/dashboard/presentation/widgets/account_chip.dart
    - lib/features/dashboard/presentation/widgets/month_summary_inline.dart
    - lib/features/dashboard/presentation/widgets/filter_bar.dart
    - lib/features/dashboard/presentation/widgets/filter_bar_delegate.dart
  modified:
    - lib/shared/providers/selected_account_provider.dart
    - lib/features/dashboard/presentation/screens/dashboard_screen.dart
    - lib/features/dashboard/presentation/widgets/account_carousel.dart
    - lib/l10n/app_en.arb
    - lib/l10n/app_ar.arb
    - lib/l10n/app_localizations.dart
    - lib/l10n/app_localizations_ar.dart
    - lib/l10n/app_localizations_en.dart

key-decisions:
  - "Used SliverToBoxAdapter for balance header instead of SliverAppBar — simpler and avoids expandedHeight dynamic calculation issues"
  - "Filter bar watches providers internally — delegate shouldRebuild is always false"
  - "Sort button cycles through sort orders inline (bottom sheet deferred to Plan 02)"
  - "TransferAdapter negative-ID detection for transfer type filter"

patterns-established:
  - "CustomScrollView sliver composition: SliverToBoxAdapter → SliverPersistentHeader → SliverList"
  - "Account chip selection via direct StateProvider<int?> (null = all accounts)"
  - "Inline month summary row replacing card-based summary zones"

requirements-completed: [HOME-01, HOME-02, HOME-04, HOME-05, HOME-06, HOME-07]

# Metrics
duration: 11min
completed: 2026-03-27
---

# Phase 03 Plan 01: Home Screen Architecture Summary

**CustomScrollView + Slivers dashboard shell with compact balance header, account chips, inline month summary, and pinned filter bar replacing the old SingleChildScrollView + AccountCarousel layout**

## Performance

- **Duration:** 11 min
- **Started:** 2026-03-27T20:42:01Z
- **Completed:** 2026-03-27T20:52:49Z
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments
- Replaced SingleChildScrollView + Column dashboard with CustomScrollView + Slivers for lazy rendering and pinned header support
- Built compact Wise/Revolut-style balance header with horizontally scrollable account chips replacing the bulky PageView carousel
- "All Accounts" chip is visually distinct via filled primary color (D-03)
- Month summary inlined under balance as a compact single row (D-04)
- Filter bar pinned via SliverPersistentHeader with type chips (All/Expenses/Income/Transfers) and sort cycling
- Created provider infrastructure: HomeFilter model, filteredActivityProvider, direct selectedAccountIdProvider

## Task Commits

Each task was committed atomically:

1. **Task 1: Create home filter provider and refactor selected account provider** - `26eac44` (feat)
2. **Task 2: Build balance header, filter bar, and rewrite dashboard shell** - `aa06afc` (feat)

## Files Created/Modified
- `lib/shared/providers/home_filter_provider.dart` - HomeFilter model, filteredActivityProvider, enums
- `lib/shared/providers/selected_account_provider.dart` - Simplified to direct StateProvider<int?>
- `lib/features/dashboard/presentation/widgets/balance_header.dart` - Compact header with chips
- `lib/features/dashboard/presentation/widgets/account_chip.dart` - Individual account chip widget
- `lib/features/dashboard/presentation/widgets/month_summary_inline.dart` - Compact income/expense/net row
- `lib/features/dashboard/presentation/widgets/filter_bar.dart` - Pinned filter with type chips + sort
- `lib/features/dashboard/presentation/widgets/filter_bar_delegate.dart` - SliverPersistentHeaderDelegate
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` - Full CustomScrollView rewrite
- `lib/features/dashboard/presentation/widgets/account_carousel.dart` - Updated to use new provider (to be replaced in Plan 02)
- `lib/l10n/app_en.arb` + `lib/l10n/app_ar.arb` - 12 new l10n keys

## Decisions Made
- Used `SliverToBoxAdapter` for balance header instead of `SliverAppBar` to avoid dynamic expandedHeight complexity and BackdropFilter issues. The header scrolls away naturally. Collapsing behavior can be added as refinement.
- Filter bar's `shouldRebuild` returns false because the `FilterBar` widget is a `ConsumerWidget` that watches `homeFilterProvider` internally -- the delegate doesn't need to track state changes.
- Sort button cycles through sort orders inline instead of opening a bottom sheet (deferred to Plan 02 which handles the full transaction list + sort UX).
- Transfer type filtering uses `tx.id < 0` to detect synthetic transfer entries from TransferAdapter, matching the established negative-ID convention.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Updated AccountCarousel to use new selectedAccountIdProvider**
- **Found during:** Task 1
- **Issue:** Removing `selectedAccountIndexProvider` broke `account_carousel.dart` which referenced it in 5 places
- **Fix:** Migrated carousel to use `selectedAccountIdProvider` directly with index derivation from wallet list. Carousel is being replaced in Task 2 but must compile.
- **Files modified:** `lib/features/dashboard/presentation/widgets/account_carousel.dart`
- **Verification:** `flutter analyze` zero issues
- **Committed in:** 26eac44

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** Necessary for compilation after provider refactor. No scope creep.

## Known Stubs

| File | Line | Stub | Reason | Resolved By |
|------|------|------|--------|-------------|
| `dashboard_screen.dart` | 91 | Transaction list placeholder | Plan 02 builds the full SliverList with date grouping, swipe actions | Plan 03-02 |
| `filter_bar.dart` | 79 | Sort cycles instead of bottom sheet | Plan 02 implements sort bottom sheet alongside transaction list | Plan 03-02 |

These stubs are intentional per the plan objective: "Transaction list is a placeholder pending Plan 02."

## Issues Encountered
- Pre-existing `env.dart` analyzer errors (3 errors in `ai_config.dart`) are unrelated to this plan. They exist because `env.dart` is gitignored and generated via `--dart-define`. Logged but not fixed (out of scope).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Balance header + filter bar + provider infrastructure complete and ready for Plan 02 (transaction SliverList + swipe actions)
- `filteredActivityProvider` is wired and ready to be consumed by the transaction list
- `homeFilterProvider` state flows into both the filter bar and the (future) transaction list
- InsightCardsZone works as-is inside SliverToBoxAdapter with zero-height empty state

---
*Phase: 03-home-screen-overhaul*
*Completed: 2026-03-27*
