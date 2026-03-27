# Phase 3: Home Screen Overhaul - Context

**Gathered:** 2026-03-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Redesign the home screen into a modern, high-density layout that becomes the app's hero screenshot — merging all transaction functionality into a single view. Requirements: HOME-01, HOME-02, HOME-03, HOME-04, HOME-05, HOME-06, HOME-07, TXN-01, TXN-06, TXN-07.

The Transactions tab was already removed from the bottom nav in a prior phase (current tabs: Home | Subscriptions | Analytics | Planning). This phase makes the home screen the **sole** transaction browsing experience.

</domain>

<decisions>
## Implementation Decisions

### Balance & Card Design (HOME-01, HOME-02, HOME-05)
- **D-01:** Replace the current `AccountCarousel` (PageView with bulky cards) with a **compact summary header** — total balance prominently displayed, horizontal row of account chips below. No more swiping between cards.
- **D-02:** Account chips show mini-balances (e.g., "CIB 12.5k"). Tapping a chip filters the entire transaction list below to that account. "All" chip shows total balance.
- **D-03:** "All Accounts" state vs individual account selection is distinguished by **chip highlighting** — "All" chip gets filled/primary color when active. Individual account chips show their style when selected. The balance number in the header updates to reflect the selected account.
- **D-04:** Month summary (income/expense/net) rendered **inline under the balance number** as a compact single row: "▲ 12,500  ▼ 8,200  Net +4,300". Not a separate zone — part of the balance header.
- **D-05:** The entire balance header area uses **glassmorphism** — glass background tier (σ20) that collapses into a compact 1-line bar on scroll. Account chips use inset glass tier (σ8).

### Home Screen Architecture (HOME-05, HOME-06)
- **D-06:** Replace `SingleChildScrollView` with **`CustomScrollView`** using Slivers for performance with large transaction lists (500+ items):
  - `SliverAppBar` — Balance header that collapses on scroll (expanded: balance + stats + chips; collapsed: 1-line balance + compact stats)
  - `SliverToBoxAdapter` — Insight cards zone (scrolls away with the header, not pinned)
  - `SliverPersistentHeader` (pinned) — Filter bar with search icon, type chips, and sort button. **Always visible** regardless of scroll position.
  - `SliverList` — Transaction list with lazy rendering (only visible items built). Date group headers are sticky within the list.
- **D-07:** Insight cards (budget at risk, spending predictions, recurring detected) remain on the home screen, positioned **between the balance header and filter bar**. They scroll away when the user scrolls down — they're contextual nudges, not permanent fixtures.
- **D-08:** All phantom whitespace eliminated by the zone-based → sliver-based architecture. Conditional zones (empty insights, no quick start) produce zero blank space.

### Transaction List & Filtering (HOME-03, HOME-04)
- **D-09:** Filter bar contains: search icon (left), quick filter chips (center: All/Expenses/Income/Transfers), sort button (right). The filter bar is **pinned** via `SliverPersistentHeader` — always accessible regardless of scroll position.
- **D-10:** Quick filter chips are type-based: All | Expenses | Income | Transfers. Active chip gets filled dark color. Only one active at a time (radio behavior). Combined with account chip selection, this gives 2-dimensional filtering (account × type).
- **D-11:** Search: tapping the 🔍 icon expands an inline search bar that replaces the balance header. Results update as user types (debounced 300ms). Result count shown ("3 results for 'Netflix'"). Matching text highlighted in accent color. Cancel button to return to normal view.
- **D-12:** Sort: tapping the ↕ icon opens a bottom sheet with sort options — Date (newest first, default), Date (oldest first), Amount (high to low), Amount (low to high). Sort persists until changed.
- **D-13:** Transaction list shows ALL transactions (lazy-loaded via SliverList), grouped by date with sticky date headers. Each date header shows the day label and **daily net subtotal** (colored green/red).
- **D-14:** When both account filter and type filter are active, show a **filter badge** below the filter bar: "🏦 CIB + 💸 Expenses only — Clear all". Tapping "Clear all" resets both filters.
- **D-15:** Wallet name shown on each transaction card when viewing "All Accounts". Hidden when a specific account is selected (redundant).

### Transaction Notes/Memo (TXN-06)
- **D-16:** Add a notes/memo/description field to `AddTransactionScreen` if not already present. This is a simple text field below the existing form fields. Optional, not required for saving.

### Swipe Actions (TXN-01)
- **D-17:** Swipe-to-edit and swipe-to-delete on all transaction types using `flutter_slidable` (already in pubspec). Regular transactions get a single-step delete confirmation. Transfer transactions get a 2-step "Delete both legs?" confirmation dialog.
- **D-18:** Visual style, swipe direction, and action layout are **Claude's discretion** — should follow glassmorphism design, be clean and modern. Priority is minimal steps and effort (ease of access).

### Voice Confirm Screen Revamp (TXN-07)
- **D-19:** Full redesign as a **full-screen form card** inside a GlassCard. All fields visible and editable:
  - Amount: large, prominent, colored by type (red for expense, green for income, blue for transfer). "+/-" sign clearly displayed.
  - Category: icon + name, tappable to change via category picker.
  - Account: wallet name, tappable to change via account selector.
  - Date: tappable to change via date picker.
  - Notes: editable text field for parsed merchant/description.
  - Subscription suggestion: "Add to Subscriptions & Bills?" when detected.
- **D-20:** When amount is missing from voice input, the amount field is highlighted/focused, a prominent message shown ("Amount not detected — please enter"), and the Save button is disabled until amount > 0 (decision carried from Phase 2 D-12).
- **D-21:** Multi-draft review (when voice parses multiple transactions): use whichever approach requires **fewest steps and least effort**. Priority is agile UX — minimize taps to save. Claude's discretion on implementation (swipeable cards vs stacked list).
- **D-22:** Screen must render cleanly in **Arabic RTL** with correct amount signs, no text overflow, and clear labels. Transfer type must show both accounts with directional arrow that flips in RTL.

### Visual Design System
- **D-23:** The entire home screen overhaul must follow the **glassmorphism design system** — 3-tier glass hierarchy (Background σ20, Card σ12, Inset σ8), existing `GlassCard`/`GlassTier` components, design tokens from `AppThemeExtension`.
- **D-24:** Modern, clean, sleek, and visually appealing. This is the hero screenshot for Play Store — it must look premium. Apply glassmorphism consistently across all new components.
- **D-25:** Both light (Minty Fresh) and dark (Gothic Noir) themes must look polished. The `GlassConfig.deviceFallback` must activate on low-end GPUs.

### Adaptive States
- **D-26:** The home screen must handle 6 distinct states gracefully:
  1. **New user (0 transactions)**: Empty state with friendly CTA, no filter bar.
  2. **Light user (5-30)**: Full layout, all features available.
  3. **Active user (100+)**: Lazy loading essential, filters critical.
  4. **Power user (500+)**: Sort + search + lazy loading. Performance must stay 60fps.
  5. **Filtered view**: Active filter badge, result count, easy reset.
  6. **Search active**: Search replaces header, debounced results, highlight matches.

### Claude's Discretion
- Swipe action visual design (direction, colors, icons, animation) — just make it glassmorphic and minimal-effort
- Multi-draft voice review implementation approach — optimize for fewest taps
- Exact SliverAppBar collapse animation and transition behavior
- Loading skeleton design for initial data fetch
- Error state handling (database errors, empty results from filter)
- Whether date headers use sticky positioning within the SliverList or are just visual separators
- Exact search debounce timing and search-match algorithm (title, category, amount, notes)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Home Screen & Dashboard
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — Current 6-zone SingleChildScrollView layout (to be replaced with CustomScrollView + Slivers)
- `lib/features/dashboard/presentation/widgets/account_carousel.dart` — Current PageView carousel (to be replaced with compact chip-based header)
- `lib/features/dashboard/presentation/widgets/recent_transactions_zone.dart` — Current 5-item list (to be replaced with full lazy SliverList)
- `lib/features/dashboard/presentation/widgets/month_summary_zone.dart` — Current separate zone (to be inlined into balance header)
- `lib/features/dashboard/presentation/widgets/insight_cards_zone.dart` — Insight cards (stays, moves to SliverToBoxAdapter)
- `lib/features/dashboard/presentation/widgets/quick_add_zone.dart` — QuickAddZone (evaluate if still needed with new layout)
- `lib/features/dashboard/presentation/widgets/quick_start_tip_card.dart` — New user tip (integrate into empty state)

### Navigation & Routing
- `lib/core/constants/app_navigation.dart` — 4-tab nav (Home | Subscriptions | Analytics | Planning). No Transactions tab exists.
- `lib/app/router/app_router.dart` — Route configuration (verify no orphaned transactions tab route)
- `lib/shared/widgets/navigation/app_nav_bar.dart` — Glassmorphic bottom nav bar

### Transaction Display
- `lib/shared/widgets/cards/transaction_card.dart` — TransactionCard (category-first bold display, verified Phase 2)
- `lib/shared/widgets/lists/transaction_list_section.dart` — Transaction grouping/date headers
- `lib/shared/widgets/cards/glass_card.dart` — GlassCard component (reuse for new cards)
- `lib/shared/widgets/cards/balance_card.dart` — Current balance card (to be replaced)
- `lib/domain/adapters/transfer_adapter.dart` — Transfer display logic (synthetic IDs, route labels)

### Voice Confirm
- `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart` — Current ~400 line screen (full revamp)
- `lib/core/utils/voice_transaction_parser.dart` — VoiceTransactionDraft model
- `lib/core/utils/subscription_detector.dart` — Subscription detection for suggestions

### State Management
- `lib/shared/providers/activity_provider.dart` — Rx.combineLatest merge (transactions + transfers)
- `lib/shared/providers/selected_account_provider.dart` — Account selection state (reuse for chip filtering)
- `lib/shared/providers/wallet_provider.dart` — Wallet list, balances
- `lib/shared/providers/transaction_provider.dart` — Transaction queries

### Design System
- `lib/app/theme/app_theme.dart` — Light & dark ThemeData
- `lib/app/theme/app_theme_extension.dart` — Glass tokens, custom theme extension
- `lib/core/constants/app_sizes.dart` — Spacing, radius tokens
- `lib/core/constants/app_icons.dart` — Phosphor icons
- `lib/core/constants/app_durations.dart` — Animation durations
- `lib/core/services/glass_config_service.dart` — Device fallback for low-end GPUs

### Research Artifacts
- `.firecrawl/home-mockup.html` — Interactive HTML mockup showing all 7 states (reference for visual direction)
- `.firecrawl/banking-app-ux-2026.md` — UX patterns from top 15 banking apps
- `.firecrawl/mobile-filter-patterns.md` — Mobile filter UX best practices

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `GlassCard` / `GlassTier` / `GlassConfig` — 3-tier glass system, ready to use for all new cards
- `TransactionCard` — Category-first bold display, verified in Phase 2. Reuse in SliverList.
- `TransactionListSection` — Date grouping logic, reuse for sticky date headers
- `EmptyState` widget — Existing empty state component in `shared/widgets/lists/`
- `flutter_slidable` — Already in pubspec, ready for swipe actions
- `selectedAccountIdProvider` — Already manages account selection state. Reuse for chip filtering.
- `BalanceCard` — Existing but will be replaced; extract useful formatting logic
- `MoneyFormatter` — Int piastres → display string (use everywhere)
- `SnackHelper` — Modern compact toast (Phase 2 revamp)

### Established Patterns
- Zone-based dashboard architecture — each zone is independently reactive via Riverpod. Slivers will follow the same principle: each sliver watches only its own providers.
- `ref.watch()` for reactive state, `ref.read()` for one-shot actions — all new providers follow this pattern
- `TransferAdapter` converts Transfer records → TransactionEntity pairs with negative synthetic IDs
- `activityByWalletProvider(walletId)` and `recentActivityProvider` — unified activity streams merging txns + transfers via Rx.combineLatest

### Integration Points
- `DashboardScreen` — The main file being overhauled (139 lines → likely 200-300 with slivers)
- `AppNavBar` — No changes needed (Transactions tab already absent)
- `AppRouter` — Verify no orphaned `/transactions` route; add route for voice confirm if needed
- `AddTransactionScreen` — Add notes/memo field (TXN-06)
- `VoiceConfirmScreen` — Full revamp (TXN-07)
- Provider layer may need new providers: `filteredActivityProvider`, `searchActivityProvider`, `sortOrderProvider`

</code_context>

<specifics>
## Specific Ideas

- **Wise/Revolut inspiration**: Compact balance header with account chips — user explicitly chose this over keeping the carousel
- **Glassmorphism everywhere**: User emphasized this must follow the glass morphism theme, modern, clean, sleek, and visually appealing. This is the hero screenshot for Play Store.
- **Ease of access**: User's guiding principle for voice confirm and multi-draft is "whichever takes less steps and effort" — agile UX, not feature-rich UX
- **HTML mockup**: `.firecrawl/home-mockup.html` shows the approved layout direction with all 7 states. Implementation should match this conceptual layout while applying glass design tokens.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 03-home-screen-overhaul*
*Context gathered: 2026-03-27*
