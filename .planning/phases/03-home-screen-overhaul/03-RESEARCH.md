# Phase 3: Home Screen Overhaul - Research

**Researched:** 2026-03-27
**Domain:** Flutter UI Architecture (CustomScrollView + Slivers + Glassmorphism)
**Confidence:** MEDIUM-HIGH

## Summary

This phase replaces the current `SingleChildScrollView` + `Column` dashboard with a `CustomScrollView` + Slivers architecture, transforms the `AccountCarousel` (PageView) into a compact Wise/Revolut-style balance header with account chips, and makes the home screen the sole transaction browsing experience with full filtering, search, sort, and swipe actions.

The core technical challenge is integrating glassmorphism (BackdropFilter) with SliverAppBar's collapsing behavior. Since **Impeller is disabled** on Android and the project already limits BackdropFilter to `GlassTier.background` only (sheets/dialogs), the SliverAppBar must rely on translucent surface colors rather than real-time blur. This is not a limitation -- the existing `GlassCard` already handles this fallback gracefully. The `GlassConfig.shouldBlur()` check ensures low-end devices get solid surfaces.

The second major concern is performance with 500+ transactions in a `SliverList`. The current `recentActivityProvider` streams ALL transactions from Drift. For the new lazy SliverList, filtering and search must happen at the provider level (Dart-side filtering of the stream), not at the DAO level, because the unified activity stream merges transactions + transfers via Rx.combineLatest. A client-side filter on the merged stream is the correct pattern here -- the stream is already reactive, and adding DAO-level search would miss synthetic transfer entries.

**Primary recommendation:** Build the new home screen as a `CustomScrollView` with 4 sliver zones (SliverAppBar for balance header, SliverToBoxAdapter for insights, SliverPersistentHeader for pinned filter bar, SliverList.builder for transactions). Use provider-level filtering with `StateProvider` for filter/search/sort state. Do NOT use BackdropFilter on the SliverAppBar -- use translucent glass surfaces instead.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Replace the current `AccountCarousel` (PageView with bulky cards) with a compact summary header -- total balance prominently displayed, horizontal row of account chips below. No more swiping between cards.
- **D-02:** Account chips show mini-balances (e.g., "CIB 12.5k"). Tapping a chip filters the entire transaction list below to that account. "All" chip shows total balance.
- **D-03:** "All Accounts" state vs individual account selection is distinguished by chip highlighting -- "All" chip gets filled/primary color when active. Individual account chips show their style when selected. The balance number in the header updates to reflect the selected account.
- **D-04:** Month summary (income/expense/net) rendered inline under the balance number as a compact single row: "up-arrow 12,500  down-arrow 8,200  Net +4,300". Not a separate zone -- part of the balance header.
- **D-05:** The entire balance header area uses glassmorphism -- glass background tier (sigma 20) that collapses into a compact 1-line bar on scroll. Account chips use inset glass tier (sigma 8).
- **D-06:** Replace `SingleChildScrollView` with `CustomScrollView` using Slivers: SliverAppBar (collapsing balance header), SliverToBoxAdapter (insight cards), SliverPersistentHeader (pinned filter bar), SliverList (lazy transaction list with date group headers).
- **D-07:** Insight cards positioned between balance header and filter bar. They scroll away when user scrolls down.
- **D-08:** All phantom whitespace eliminated by sliver-based architecture.
- **D-09:** Filter bar contains: search icon (left), quick filter chips (center: All/Expenses/Income/Transfers), sort button (right). Pinned via SliverPersistentHeader.
- **D-10:** Quick filter chips are radio behavior (one active at a time). Combined with account chip selection for 2-dimensional filtering.
- **D-11:** Search: tapping search icon expands inline search bar replacing balance header. Debounced 300ms. Result count shown. Matching text highlighted. Cancel to return.
- **D-12:** Sort: tapping sort icon opens bottom sheet with Date (newest/oldest) and Amount (high/low) options. Sort persists until changed.
- **D-13:** Transaction list shows ALL transactions (lazy-loaded via SliverList), grouped by date with sticky date headers. Each date header shows daily net subtotal.
- **D-14:** When both account filter and type filter are active, show filter badge below filter bar.
- **D-15:** Wallet name shown on each transaction card when viewing "All Accounts". Hidden when specific account selected.
- **D-16:** Add notes/memo/description field to AddTransactionScreen if not already present.
- **D-17:** Swipe-to-edit and swipe-to-delete on all transaction types using flutter_slidable. Transfer transactions get 2-step "Delete both legs?" confirmation.
- **D-18:** Swipe action visual design is Claude's discretion -- glassmorphic and minimal-effort.
- **D-19:** VoiceConfirmScreen full redesign as full-screen GlassCard form.
- **D-20:** Missing amount handling with highlighting and disabled Save button.
- **D-21:** Multi-draft review approach is Claude's discretion -- optimize for fewest taps.
- **D-22:** RTL Arabic rendering must be correct.
- **D-23:** Glassmorphism 3-tier system applied throughout.
- **D-24:** Premium look -- hero screenshot for Play Store.
- **D-25:** Both light and dark themes polished. GlassConfig.deviceFallback on low-end GPUs.
- **D-26:** 6 adaptive states: new user, light, active, power user, filtered, search.

### Claude's Discretion
- Swipe action visual design (direction, colors, icons, animation)
- Multi-draft voice review implementation approach
- Exact SliverAppBar collapse animation and transition behavior
- Loading skeleton design for initial data fetch
- Error state handling
- Whether date headers use sticky positioning or are visual separators
- Exact search debounce timing and search-match algorithm

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HOME-01 | Full home screen revamp -- replace bulky hero cards with modern design | CustomScrollView + SliverAppBar pattern; compact balance header with chips replaces PageView carousel |
| HOME-02 | "All Accounts" balance visually distinct from individual account cards | Account chips with "All" chip highlighted differently; balance header updates per selection |
| HOME-03 | Filter and search actions for transactions on home screen | SliverPersistentHeader pinned filter bar; provider-level search filtering with debounce |
| HOME-04 | Quick filter chips (Expense/Income/Transfer/All) on home transaction list | ChoiceChip/FilterChip row in pinned header; radio behavior via StateProvider |
| HOME-05 | Eliminate whitespace and blank areas from home screen layout | Sliver architecture produces zero space for empty conditional zones |
| HOME-06 | Remove Transactions tab entirely -- merge into home | Already done in prior phase; this phase completes the merge by showing ALL transactions in SliverList |
| HOME-07 | Upcoming bills/subscriptions displayed on home screen | InsightCardsZone already handles this (upcomingBillsProvider); relocate to SliverToBoxAdapter |
| TXN-01 | Swipe actions (edit/delete) on ALL transaction types including transfers | flutter_slidable already in pubspec (3.1.1); TransactionCard already supports Slidable wrapper; need to wire delete/edit callbacks from new SliverList |
| TXN-06 | Transaction description field (notes/memo support) | Already exists: TransactionEntity has `note` field, AddTransactionScreen has `_noteController`, DB table has `note` column. Verify it's visible and working -- may need no code changes. |
| TXN-07 | Review/confirm transaction screen -- full UX/UI revamp | VoiceConfirmScreen rewrite as full-screen GlassCard form; existing screen is ~400 lines; revamp to match D-19 through D-22 |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

These directives are mandatory and must be followed by the planner:

1. **Money = INTEGER piastres.** `100 EGP = 10000`. Use `MoneyFormatter` for display. Never double.
2. **100% offline-first.** No internet for core features. Search/filter must be local.
3. **RTL-first.** Every screen validated in Arabic RTL. Use `EdgeInsetsDirectional`, never hardcoded left/right.
4. **Design tokens are LAW.** `context.colors`, `AppIcons.*`, `AppSizes.*`, `context.appTheme.*` -- NEVER hardcode colors, spacing, radii, durations.
5. **MasarifyDS components always.** Use `GlassCard`, `EmptyState`, `SnackHelper`, `AppButton`, etc.
6. **ConsumerWidget or ConsumerStatefulWidget** for all screens. Never raw StatefulWidget.
7. **Navigation:** `context.go()` / `context.push()` only. Never `Navigator.push()`.
8. **Provider flow:** StreamProvider/FutureProvider -> Repository -> DAO -> Drift.
9. **No Flutter/Drift imports in domain/ layer.**
10. **Import ordering:** `../../` before `../`.
11. **All user-facing strings via `context.l10n.*`.** New keys in BOTH `app_en.arb` AND `app_ar.arb`.
12. **Protected files:** Never edit `*.g.dart`, `*.freezed.dart`, `app_localizations*.dart`, `pubspec.lock` directly.
13. **Impeller disabled** on Android -- BackdropFilter causes grey overlay. Only `GlassTier.background` uses BackdropFilter (and only when `GlassConfig.shouldBlur()` returns true).

## Standard Stack

### Core (already in project)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter | 3.38.6 | UI framework | Project's runtime |
| flutter_riverpod | ^2.6.1 | State management | Project standard; all providers follow this |
| go_router | ^14.3.0 | Navigation | Project standard; context.go/push only |
| drift | ^2.20.0 | SQLite ORM | Reactive streams for transaction data |
| rxdart | ^0.28.0 | Rx operators | combineLatest for merging txn+transfer streams |
| flutter_slidable | ^3.1.1 | Swipe actions | Already in pubspec; used in TransactionCard |
| flutter_animate | ^4.5.0 | Entry animations | List item stagger animations |
| phosphor_flutter | ^2.1.0 | Icons | AppIcons.* centralized icons |

### Supporting (already in project)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| intl | ^0.20.0 | Date formatting | Date group headers, month labels |
| shimmer | ^3.0.0 | Loading skeletons | Initial data fetch placeholder |

### No New Dependencies Required
This phase does not require any new packages. All needed libraries are already in pubspec.yaml.

## Architecture Patterns

### Recommended New File Structure
```
lib/features/dashboard/presentation/
  screens/
    dashboard_screen.dart          # REWRITE: CustomScrollView + slivers shell
  widgets/
    balance_header.dart            # NEW: Compact balance + account chips (replaces AccountCarousel + BalanceCard)
    account_chip.dart              # NEW: Single account chip widget
    month_summary_inline.dart      # NEW: Compact income/expense/net row (replaces MonthSummaryZone)
    filter_bar.dart                # NEW: Pinned filter bar (search icon + chips + sort)
    filter_bar_delegate.dart       # NEW: SliverPersistentHeaderDelegate for filter bar
    transaction_sliver_list.dart   # NEW: SliverList.builder for transactions with date headers
    date_group_header.dart         # NEW: Sticky/visual date header with daily net subtotal
    filter_badge.dart              # NEW: Active filter indicator below filter bar
    search_header.dart             # NEW: Inline search bar (replaces balance header during search)
    sort_bottom_sheet.dart         # NEW: Sort options bottom sheet
    insight_cards_zone.dart        # KEEP: Relocate inside SliverToBoxAdapter
    quick_add_zone.dart            # EVALUATE: May integrate into filter bar or remove
    quick_start_tip_card.dart      # KEEP: Integrate into new-user empty state

lib/shared/providers/
    home_filter_provider.dart      # NEW: Filter state (account, type, search, sort)

lib/features/voice_input/presentation/screens/
    voice_confirm_screen.dart      # REWRITE: Full GlassCard form revamp
```

### Pattern 1: CustomScrollView Sliver Composition
**What:** Replace SingleChildScrollView + Column with CustomScrollView + typed slivers
**When to use:** When the screen has a collapsing header, a pinned sub-header, and a long scrollable list

```dart
// Verified pattern from Flutter SDK and project conventions
CustomScrollView(
  slivers: [
    // 1. Collapsing balance header
    SliverAppBar(
      expandedHeight: 200.0,  // Expanded: balance + stats + chips
      collapsedHeight: 56.0,  // Collapsed: 1-line balance
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        // Custom layout that transitions between expanded/collapsed
        background: BalanceHeader(...),
      ),
    ),
    // 2. Insight cards (scroll away)
    SliverToBoxAdapter(child: InsightCardsZone()),
    // 3. Pinned filter bar
    SliverPersistentHeader(
      pinned: true,
      delegate: FilterBarDelegate(...),
    ),
    // 4. Lazy transaction list
    SliverList.builder(
      itemCount: groupedTransactions.length,
      itemBuilder: (context, index) => ...,
    ),
  ],
)
```

### Pattern 2: SliverPersistentHeaderDelegate for Pinned Filter Bar
**What:** Custom delegate that pins the filter bar at a fixed height
**When to use:** For any bar that must remain visible during scrolling

```dart
class FilterBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  FilterBarDelegate({required this.child, this.height = 56.0});

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;  // Same = no shrinking, just pins

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant FilterBarDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}
```

### Pattern 3: Provider-Level Filtering (Not DAO-Level)
**What:** Filter the merged activity stream in Dart using derived providers
**When to use:** When the data source merges multiple streams (transactions + transfers)

```dart
// Filter state
final homeFilterProvider = StateProvider<HomeFilter>((ref) => const HomeFilter());

// Derived filtered activity
final filteredHomeActivityProvider = Provider<AsyncValue<List<TransactionEntity>>>((ref) {
  final filter = ref.watch(homeFilterProvider);
  final walletId = ref.watch(selectedAccountIdProvider);

  // Choose base stream
  final baseActivity = walletId != null
      ? ref.watch(activityByWalletProvider(walletId))
      : ref.watch(recentActivityProvider);

  return baseActivity.whenData((items) {
    var result = items;

    // Type filter
    if (filter.type != null) {
      result = result.where((tx) => tx.type == filter.type).toList();
    }

    // Search filter
    if (filter.searchQuery.isNotEmpty) {
      final q = filter.searchQuery.toLowerCase();
      result = result.where((tx) =>
        tx.title.toLowerCase().contains(q) ||
        (tx.note?.toLowerCase().contains(q) ?? false)
      ).toList();
    }

    // Sort
    switch (filter.sort) {
      case SortOrder.dateDesc: result.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      case SortOrder.dateAsc: result.sort((a, b) => a.transactionDate.compareTo(b.transactionDate));
      case SortOrder.amountDesc: result.sort((a, b) => b.amount.compareTo(a.amount));
      case SortOrder.amountAsc: result.sort((a, b) => a.amount.compareTo(b.amount));
    }

    return result;
  });
});
```

### Pattern 4: Date Grouping Within SliverList
**What:** Interleave date headers with transaction items in a single flat SliverList
**When to use:** For date-grouped lists within a CustomScrollView

```dart
// Build a flat list of (DateHeader | TransactionItem) entries
final flatItems = <_ListItem>[];
for (final entry in grouped.entries) {
  flatItems.add(_DateHeaderItem(entry.key, dailyNet: computeNet(entry.value)));
  for (final tx in entry.value) {
    flatItems.add(_TransactionItem(tx));
  }
}

// In SliverList.builder
SliverList.builder(
  itemCount: flatItems.length,
  itemBuilder: (context, index) {
    final item = flatItems[index];
    return switch (item) {
      _DateHeaderItem() => DateGroupHeader(label: item.label, net: item.dailyNet),
      _TransactionItem() => TransactionCard(..., transaction: item.tx),
    };
  },
)
```

### Anti-Patterns to Avoid
- **BackdropFilter on SliverAppBar:** Never use BackdropFilter on the collapsing header -- it causes GPU compositing overload and grey overlay on Android (Impeller disabled). Use translucent `glassCardSurface` / `glassSheetSurface` colors from AppThemeExtension instead.
- **DAO-level search:** Don't add search to TransactionDao -- it would miss synthetic transfer entries created by TransferAdapter. Filter at the provider level after Rx.combineLatest merge.
- **Nested ScrollViews:** Don't put a ListView inside a SliverToBoxAdapter. Use SliverList directly.
- **Single massive build method:** Don't put all slivers inline in DashboardScreen. Extract each sliver into its own widget for maintainability and targeted rebuilds.
- **setState for filter state:** Use Riverpod StateProvider, not setState. Filter state must survive rebuilds and be accessible from multiple widgets.
- **Hardcoded heights for SliverAppBar:** Use `MediaQuery` or calculated values based on content, not magic numbers. The expanded height depends on whether account chips wrap to 2 lines.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Swipe actions | Custom GestureDetector swipe detection | `flutter_slidable` (already in pubspec) | Handles thresholds, animations, auto-close, RTL, accessibility |
| Date grouping | Manual list index math | `groupTransactionsByDate()` (existing util) | Already handles localized labels, RTL, today/yesterday |
| Money formatting | String interpolation | `MoneyFormatter.format()` / `.formatCompact()` | Handles piastres-to-display, currency, compact (12.5k) |
| Glass surfaces | Manual BackdropFilter + decoration | `GlassCard` with `GlassTier` enum | Handles device fallback, blur detection, themed colors |
| Empty states | Ad-hoc Column with icon+text | `EmptyState` widget (existing) | Consistent styling, compact mode, optional CTA |
| Toast feedback | ScaffoldMessenger.showSnackBar | `SnackHelper.showSuccess/showError` | Modern compact toast, positioned above nav bar |
| Category resolution | Inline provider reads per card | `resolveCategory()` helper (existing) | Single function, handles fallback color/icon |
| Transfer display | Manual tag parsing | `TransferAdapter` / `counterpartWalletId()` | Handles synthetic IDs, sender/receiver detection, route labels |

**Key insight:** The project has extensive reusable infrastructure. Almost every primitive needed for this phase already exists -- the task is composing them into the new sliver architecture, not building new utilities.

## Common Pitfalls

### Pitfall 1: BackdropFilter + SliverAppBar = Grey Overlay on Android
**What goes wrong:** Using BackdropFilter inside FlexibleSpaceBar or SliverAppBar causes GPU compositing overload on Android with Impeller disabled. Screen goes grey or freezes.
**Why it happens:** BackdropFilter requires compositing every frame. Stacking multiple BackdropFilters in a scrollable container multiplies the GPU cost. Impeller (disabled in this project) was supposed to fix this.
**How to avoid:** Use translucent surface colors from `AppThemeExtension` (glassCardSurface, glassSheetSurface) instead of real BackdropFilter. The existing GlassCard already does this for card/inset tiers -- only `GlassTier.background` uses actual blur, and only in sheets/dialogs.
**Warning signs:** Grey overlay, frozen screen, dropped frames on Android during scroll.

### Pitfall 2: SliverList Performance with Large Datasets
**What goes wrong:** Using `SliverList.list` (builds all children immediately) instead of `SliverList.builder` (builds lazily) causes memory spikes and jank with 500+ items.
**Why it happens:** `.list` constructor materializes all children upfront. `.builder` only builds visible items plus a buffer.
**How to avoid:** Always use `SliverList.builder` with `itemCount` and `itemBuilder`. For the flat list of date headers + transactions, pre-compute the flat list but let the builder lazily create widgets.
**Warning signs:** Slow initial render, memory usage growing linearly with transaction count, scrolling jank.

### Pitfall 3: SliverAppBar expandedHeight Must Account for Dynamic Content
**What goes wrong:** Setting a fixed `expandedHeight` that doesn't account for variable content (e.g., account chips wrapping to 2 lines) causes overflow or clipping.
**Why it happens:** The number of accounts varies per user. A user with 5 accounts needs more chip space than one with 2.
**How to avoid:** Calculate expandedHeight dynamically based on account count, or use a maximum with horizontal scrolling for chips that don't fit. Consider `SingleChildScrollView(scrollDirection: Axis.horizontal)` for the chip row to avoid wrapping entirely.
**Warning signs:** Chip text cut off, overflow errors in debug mode, inconsistent header heights across users.

### Pitfall 4: Search Mode Must Replace Slivers, Not Stack on Top
**What goes wrong:** Trying to overlay a search bar on top of the SliverAppBar without rebuilding the sliver list causes z-index and interaction conflicts.
**Why it happens:** Slivers are positioned by the scroll physics. You can't just Stack a TextField over them.
**How to avoid:** When search is activated, conditionally swap the SliverAppBar for a simpler `SliverToBoxAdapter` containing the search field. The `SliverPersistentHeader` (filter bar) stays pinned. The `SliverList` re-renders with filtered results.
**Warning signs:** Search field not receiving focus, taps passing through to slivers behind, visual glitches.

### Pitfall 5: flutter_slidable Works with Any Widget, Including SliverList Items
**What goes wrong:** Developers assume flutter_slidable only works with ListView and don't use it in SliverList.
**Why it happens:** Most examples show Slidable inside ListView.builder.
**How to avoid:** `Slidable` wraps a child widget -- it doesn't care about the parent list type. Use it in SliverList.builder's itemBuilder exactly as in ListView. The key requirement is wrapping with `SlidableAutoCloseBehavior` at the CustomScrollView level to auto-close other slidables when one opens.
**Warning signs:** Multiple slidables open simultaneously, which is solved by `SlidableAutoCloseBehavior`.

### Pitfall 6: selectedAccountIdProvider Derivation Must Change
**What goes wrong:** The current `selectedAccountIdProvider` derives wallet ID from carousel page index (`selectedAccountIndexProvider`). The new chip-based UI selects by wallet ID directly, not by index.
**Why it happens:** The carousel used page indices (0 = all, 1 = first wallet, etc.). Chips should select by wallet ID.
**How to avoid:** Replace `selectedAccountIndexProvider` (index-based) with a direct `selectedAccountIdProvider` that stores `int?` (null = all accounts). This simplifies the derivation chain.
**Warning signs:** Account filter not matching expected wallet, off-by-one errors, "All Accounts" not clearing filter.

### Pitfall 7: SliverPersistentHeader Delegate shouldRebuild
**What goes wrong:** Filter bar doesn't update when filter state changes because `shouldRebuild` returns false.
**Why it happens:** The delegate compares old vs new, but if the delegate instance doesn't change (e.g., const constructor), rebuilds are skipped.
**How to avoid:** Pass the filter state into the delegate and compare it in `shouldRebuild`, OR make the filter bar a `ConsumerWidget` that watches providers internally (preferred -- keeps the delegate simple).
**Warning signs:** Chip selection doesn't visually update, filter badge doesn't appear/disappear.

## Code Examples

### Balance Header with Account Chips (Compact Wise/Revolut Style)
```dart
// Conceptual structure for the new balance header
class BalanceHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final selectedId = ref.watch(selectedAccountIdProvider);
    final totalBalance = ref.watch(totalBalanceProvider).valueOrNull ?? 0;
    final hidden = ref.watch(hideBalancesProvider);

    final displayBalance = selectedId == null
        ? totalBalance
        : wallets.where((w) => w.id == selectedId).firstOrNull?.balance ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large balance number
        Text(
          hidden ? '------' : MoneyFormatter.format(displayBalance),
          style: context.textStyles.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSizes.xs),
        // Inline month summary: up 12,500  down 8,200  Net +4,300
        MonthSummaryInline(walletId: selectedId, hidden: hidden),
        const SizedBox(height: AppSizes.md),
        // Account chips (horizontal scroll)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              AccountChip(
                label: context.l10n.dashboard_all_accounts,
                balance: totalBalance,
                isSelected: selectedId == null,
                onTap: () => ref.read(selectedAccountIdProvider.notifier).state = null,
              ),
              ...wallets.where((w) => !w.isSystemWallet && !w.isArchived).map(
                (w) => AccountChip(
                  label: w.name,
                  balance: w.balance,
                  isSelected: selectedId == w.id,
                  onTap: () => ref.read(selectedAccountIdProvider.notifier).state = w.id,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

### Pinned Filter Bar in SliverPersistentHeader
```dart
class FilterBarDelegate extends SliverPersistentHeaderDelegate {
  const FilterBarDelegate({required this.child});
  final Widget child;

  @override
  double get maxExtent => 52.0; // Fixed height
  @override
  double get minExtent => 52.0; // Same = pinned, no shrinking

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: context.colors.surface, // Solid background when pinned
      elevation: overlapsContent ? AppSizes.elevationLow : AppSizes.elevationNone,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant FilterBarDelegate oldDelegate) => false;
  // Filter bar widget is a ConsumerWidget that watches providers internally
}
```

### SlidableAutoCloseBehavior with CustomScrollView
```dart
// Wrap the entire CustomScrollView to auto-close slidables
SlidableAutoCloseBehavior(
  child: CustomScrollView(
    slivers: [
      // ... SliverAppBar, SliverToBoxAdapter, SliverPersistentHeader ...
      SliverList.builder(
        itemCount: flatItems.length,
        itemBuilder: (context, index) {
          final item = flatItems[index];
          if (item is _DateHeaderItem) return DateGroupHeader(...);
          final tx = (item as _TransactionItem).tx;
          return Slidable(
            key: ValueKey(tx.id),
            groupTag: 'transactions',
            startActionPane: ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) => _editTransaction(tx),
                  backgroundColor: context.appTheme.transferColor,
                  foregroundColor: context.appTheme.onTransferColor,
                  icon: AppIcons.edit,
                  label: context.l10n.common_edit,
                ),
              ],
            ),
            endActionPane: ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) => _deleteTransaction(tx),
                  backgroundColor: context.appTheme.expenseColor,
                  foregroundColor: context.colors.onError,
                  icon: AppIcons.delete,
                  label: context.l10n.common_delete,
                ),
              ],
            ),
            child: TransactionCard(transaction: tx, ...),
          );
        },
      ),
    ],
  ),
)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| SliverAppBar with BackdropFilter | Translucent surface colors (no blur) on slivers | Project-specific (Impeller disabled) | Must use glass surface tokens, not real blur |
| SliverList() with children list | SliverList.builder() for lazy rendering | Flutter 3.x | Critical for 500+ item performance |
| Separate Transactions screen tab | All transactions on home screen | Phase 2 (Transactions tab removed) | This phase completes the merge |
| PageView carousel for accounts | Compact chip row | This phase (D-01) | Frees vertical space for transaction list |

**Deprecated/outdated:**
- `FloatingHeaderSnapConfiguration(vsync: ...)`: vsync moved to `SliverPersistentHeaderDelegate.vsync` (Flutter 2.5+)
- `SliverList(delegate: SliverChildListDelegate(...))`: Use named constructors `SliverList.builder`, `SliverList.list` instead

## Open Questions

1. **SliverAppBar expandedHeight with dynamic chip count**
   - What we know: Account count varies per user (1 to many). Horizontal scroll for chips avoids wrapping.
   - What's unclear: Exact expandedHeight value -- depends on text size, chip padding, number of summary items.
   - Recommendation: Use a calculated height based on fixed sections (balance text + summary row + chip row) with the chip row in a `SingleChildScrollView(scrollDirection: Axis.horizontal)` to avoid variable height.

2. **Sticky date headers vs visual separators**
   - What we know: True sticky headers within SliverList require custom sliver implementation or packages like `sliver_tools`.
   - What's unclear: Whether the visual benefit justifies the complexity.
   - Recommendation: Use visual separators (non-sticky) in the flat SliverList -- simpler, still clear, and the pinned filter bar already provides persistent context. Sticky headers would fight with the pinned filter bar for screen space.

3. **Search text highlighting in transaction cards**
   - What we know: D-11 requires matching text highlighted in accent color.
   - What's unclear: Whether to use RichText or a dedicated highlight widget.
   - Recommendation: Pass the search query to TransactionCard and use `TextSpan` with styled segments for highlighting. This keeps the card widget pure and the highlighting logic self-contained.

4. **TXN-06 already implemented?**
   - What we know: `TransactionEntity` has `note` field, `AddTransactionScreen` has `_noteController`, DB table has `note` column, the form already shows a note input in the "Optional" section.
   - What's unclear: Whether the note field is visible and functional in all transaction creation flows (manual, voice, AI chat).
   - Recommendation: Verify during implementation. If already working, TXN-06 becomes a verification task rather than a build task.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) |
| Config file | None (standard Flutter test runner) |
| Quick run command | `flutter test test/unit/ -x` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HOME-01 | Balance header renders with total balance | widget | `flutter test test/widget/balance_header_test.dart -x` | No -- Wave 0 |
| HOME-02 | "All" chip visually distinct (filled primary) | widget | `flutter test test/widget/account_chip_test.dart -x` | No -- Wave 0 |
| HOME-03 | Filter state changes update transaction list | unit | `flutter test test/unit/home_filter_test.dart -x` | No -- Wave 0 |
| HOME-04 | Filter chips produce correct type filter | unit | `flutter test test/unit/home_filter_test.dart -x` | No -- Wave 0 |
| HOME-05 | Empty zones produce zero SliverToBoxAdapter height | widget | Manual verification (visual) | manual-only |
| HOME-06 | Transaction list shows all types (not just recent 5) | unit | `flutter test test/unit/home_filter_test.dart -x` | No -- Wave 0 |
| HOME-07 | Insight cards display in SliverToBoxAdapter | widget | Manual verification (visual) | manual-only |
| TXN-01 | Slidable edit/delete callbacks fire correctly | unit | `flutter test test/unit/transaction_actions_test.dart -x` | No -- Wave 0 |
| TXN-06 | Note field persists to DB and displays on card | unit | Verify in existing tests | Partial (transaction_validation_test.dart) |
| TXN-07 | VoiceConfirmScreen renders all draft fields | widget | `flutter test test/widget/voice_confirm_test.dart -x` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter analyze lib/` (must be zero issues)
- **Per wave merge:** `flutter test` (full suite)
- **Phase gate:** Full suite green + manual RTL check before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/unit/home_filter_test.dart` -- covers HOME-03, HOME-04, HOME-06 (filter/search/sort provider logic)
- [ ] `test/widget/balance_header_test.dart` -- covers HOME-01, HOME-02 (balance display, chip selection)
- [ ] `test/unit/transaction_actions_test.dart` -- covers TXN-01 (delete/edit callbacks, transfer 2-step)
- [ ] Framework: Already installed (flutter_test) -- no additional setup needed

## Sources

### Primary (HIGH confidence)
- **Codebase inspection** -- Read all 15+ files referenced in CONTEXT.md canonical_refs. DashboardScreen (139 lines), AccountCarousel (287 lines), BalanceCard (580 lines), GlassCard (150 lines), TransactionCard (272 lines), TransactionListSection (131 lines), activity_provider (62 lines), selected_account_provider (15 lines), transaction_provider (84 lines), transaction_dao (161 lines), i_transaction_repository (87 lines), app_sizes (268 lines), glass_config_service (42 lines), voice_confirm_screen (~400 lines), app_theme_extension (60+ lines).
- **Context7 /letsar/flutter_slidable** -- Confirmed: Slidable works with any widget tree (not just ListView). SlidableAutoCloseBehavior wraps parent. ActionPane with BehindMotion/DrawerMotion. DismissiblePane for swipe-to-dismiss. Version 1.0+ API with startActionPane/endActionPane.
- **Context7 /websites/flutter_dev** -- SliverAppBar.medium() pattern, CupertinoSliverNavigationBar.search with CustomScrollView, SliverList.list constructor, SliverPersistentHeaderDelegate vsync migration.

### Secondary (MEDIUM confidence)
- **Flutter API knowledge** -- SliverAppBar `pinned`, `floating`, `snap`, `expandedHeight`, `collapsedHeight`, `flexibleSpace` properties. SliverPersistentHeader with `pinned: true` for always-visible bar. SliverList.builder for lazy rendering. These are stable Flutter SDK APIs unchanged since Flutter 3.x.
- **Project MEMORY.md** -- Confirmed Impeller disabled, glass hierarchy decisions, transfer adapter patterns, phase history.

### Tertiary (LOW confidence)
- **Sticky date headers within SliverList** -- Training data suggests either custom sliver or `sliver_tools` package. Not verified against current package versions. Recommendation: skip sticky headers and use visual separators.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all libraries already in pubspec, no new dependencies
- Architecture: MEDIUM-HIGH -- CustomScrollView + Slivers is standard Flutter but the glass integration is project-specific. BackdropFilter avoidance is well-understood from existing GlassCard implementation.
- Pitfalls: HIGH -- well-documented from codebase inspection (Impeller disabled, GlassConfig fallback, existing patterns)
- Validation: MEDIUM -- test infrastructure exists but no home-screen-specific tests yet

**Research date:** 2026-03-27
**Valid until:** 2026-04-27 (stable Flutter APIs, no fast-moving dependencies)
