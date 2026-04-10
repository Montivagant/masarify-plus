# Hero / Balance Section — Pixel-Perfect Requirements

**Reference:** Stitch screen `f49245c25e03429bacbebbb41c21c8bb`
**Files:**
- `lib/features/dashboard/presentation/widgets/balance_header.dart`
- `lib/features/dashboard/presentation/widgets/month_summary_inline.dart`

---

## What's Wrong (Stitch Design vs Current App)

| Element | Stitch Design | Current App | Fix Required |
|---------|--------------|-------------|--------------|
| Balance text size | Very large, ~32sp display weight, centered | `displaySmall` (already changed) | May be OK — verify on device |
| Balance format | "EGP 12,450.00" with space before amount | Uses `MoneyFormatter.formatTrailing` which may not have space | Verify format includes "EGP " prefix |
| Eye toggle icon | Small, grey, inline right of balance | Already correct | OK |
| "Net +4,300" | Green pill badge below balance, centered, with green background tint | Currently plain text row with info icon | **Change to a tinted pill badge** |
| Income pill | Oval/rounded pill, LEFT side, green tint bg, up-arrow icon + "INCOME" label + "12,500" amount | Currently rectangular card with icon + label + amount column | **Reshape to horizontal oval pill** |
| Expense pill | Oval/rounded pill, RIGHT side, coral tint bg, down-arrow icon + "EXPENSE" label + "8,200" amount | Same as income — rectangular | **Reshape to horizontal oval pill** |
| Pill shape | Highly rounded (borderRadiusFull or near-full), horizontal layout: icon + label + amount all in one row | Current pills are rectangular cards with column layout (label above, amount below) | **Major reshape — make pills horizontal ovals** |
| Cash wallet card | Full-width standalone card with green tint, coin icon in green circle, "Cash" bold + "Physical Wallet" subtitle, "EGP 2,100" right-aligned | Small pill-shaped banner, no "Physical Wallet" subtitle, cramped | **Enlarge to full-width card with icon circle + two-line text** |
| Account selector | "All Accounts" with dropdown caret + gear icon on right | Already exists, mostly correct | Verify spacing |
| Wallet cards row | Horizontal cards with wallet icon on top, name below, balance below name | Cards have accent bar + icon + name + balance | **Remove accent bar, stack icon → name → balance vertically** |
| Wallet card layout | Icon centered top, "CIB Bank" centered middle, "5,400" centered bottom | Current: accent bar left, icon + name right, balance below | **Restructure to centered vertical stack** |
| Overall spacing | Very generous whitespace between sections | Moderate spacing | **Increase vertical gaps** |

---

## Exact Layout Specification (Top to Bottom)

### 1. Container
- Background: `theme.glassCardSurface`
- Bottom border: `BorderSide(color: theme.glassCardBorder)`
- Padding: `EdgeInsetsDirectional.only(start: screenHPadding, end: screenHPadding, top: AppSizes.xl, bottom: AppSizes.md)`

### 2. Balance Display (Center-aligned Column)
- **Amount text:** `displaySmall` (32sp), `fontWeight: w700`, `cs.onSurface`
  - Format: `MoneyFormatter.formatTrailing(displayBalance)` — should show "EGP 12,450.00"
  - If hidden: show "------"
- **Eye toggle:** `IconButton` inline right of amount, `AppIcons.eye` / `AppIcons.eyeOff`, `iconSm`, `opacityMedium`
- **Layout:** `Row(mainAxisAlignment: center)` with amount + eye button
- No changes needed here — current implementation matches Stitch

### 3. Net Badge (NEW — replace current plain text row)
- **Current:** Plain text row with "Net" label + info icon + "+4,300" text. Info icon triggers a popover tooltip explaining what "Net" means.
- **Stitch:** Simple green pill badge centered below balance, no info icon visible.
- **Decision:** Remove the info icon and popover from the Net row. Replace the entire Row with a single pill badge. The popover tooltip can be triggered by tapping the pill itself if we want to keep the info functionality (optional — not in Stitch).
- **Implementation in `month_summary_inline.dart`:**
  - Replace the current `Row` (lines 137-174) containing the Net label + info icon + amount with:
  - `Center` > `Container` with:
    - Background: `netColor.withValues(alpha: AppSizes.opacityLight2)` — green tint for positive, coral for negative
    - BorderRadius: `borderRadiusFull` — fully rounded pill
    - Padding: `EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xs)`
  - Inside Container: `Text` showing `"Net ${isPositive ? '+' : '-'}${MoneyFormatter.formatTrailing(net.abs())}"` in `labelMedium`, `fontWeight: w600`, color `netColor`
  - If hidden: show "Net ••••" inside the pill
- **Remove:** The `_infoKey`, `_popoverEntry`, `_togglePopover`, `_dismissPopover` methods, and the entire `_NetPopover` class (lines 245-302) — they are no longer needed.
- **Spacing:** `SizedBox(height: AppSizes.sm)` above the pill, `SizedBox(height: AppSizes.md)` below

### 4. Income / Expense Pills (RESHAPE to match Stitch)
- **Current:** Two `Expanded` rectangular cards (`borderRadiusMd`) in a Row, each with icon + column(label, amount)
- **Stitch:** Two OVAL pills (`borderRadiusFull`), each with icon LEFT + vertical stack (label above, amount below) RIGHT
- **Key change:** ONLY the border radius changes from `borderRadiusMd` (16) to `borderRadiusFull` (100). The internal layout (icon left, label+amount stacked right) STAYS THE SAME as current — Stitch confirms this is correct.
- **New `_GlassPill` layout:**
  - Container shape: `borderRadiusFull` (100) — NOT `borderRadiusMd` (16) — this makes the rectangular card into an oval pill
  - Background: `color.withValues(alpha: AppSizes.opacityLight2)` — keep same
  - Padding: `EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm)` — keep same
  - Content: `Row` with:
    - Icon: `icon`, size `AppSizes.iconSm`, color `color` — keep same
    - SizedBox(width: AppSizes.xs)
    - `Expanded` > `Column(children: [label, amount])`:
      - Label: "INCOME" / "EXPENSE" — `labelSmall` (or `bodySmall`), color `labelColor` — keep same
      - Amount: "12,500" — `bodyMedium`, `fontWeight: bold`, color `color` — keep same
  - Each pill: `Expanded` in the parent Row — keep same
- **Gap between pills:** `SizedBox(width: AppSizes.sm)` — keep same
- **Summary: The ONLY change is `borderRadiusMd` → `borderRadiusFull` in `_GlassPill.build()`**

### 5. Cash Wallet Card (ENLARGE to match Stitch)
- **Current:** Small pill-shaped banner with icon + name + balance + chevron all cramped
- **Stitch:** Full-width standalone card with:
  - Left: Coin icon inside a 44px green-tinted circle
  - Center: Two lines — "Cash" (bold, bodyLarge) + "Physical Wallet" (bodySmall, muted)
  - Right: "EGP 2,100" (titleMedium, bold)
- **New implementation:**
  - Container: `GlassCard(tier: GlassTier.inset)` with `tintColor: cs.primaryContainer.withValues(alpha: AppSizes.opacityLight3)`
  - Padding: `EdgeInsets.all(AppSizes.md)`
  - Margin: `SizedBox(height: AppSizes.md)` above and below
  - Content Row:
    - Leading: 44px circle (`iconContainerLg`) with `cs.primaryContainer.withValues(alpha: 0.2)` bg, `AppIcons.walletType('physical_cash')` icon in `cs.primary` color
    - SizedBox(width: AppSizes.md)
    - Center (Expanded): Column(crossAxisAlignment: start):
      - "Cash" — `bodyLarge`, `fontWeight: w600`, color = selected ? `cs.primary` : `cs.onSurface`
      - "Physical Wallet" — `bodySmall`, `cs.outline` — **NEW label, needs l10n key**
    - Right: Balance text — `titleMedium`, `fontWeight: w700`, `cs.onSurface`
  - **Remove:** the chevron icon (`AppIcons.chevronRight`) currently on the far right — Stitch doesn't show it
  - onTap: select/deselect cash wallet (keep existing logic)
  - onDoubleTap: open edit sheet (keep existing behavior)
  - **Selection state:**
    - Unselected: `tintColor: cs.primaryContainer.withValues(alpha: AppSizes.opacityLight3)` — subtle green wash
    - Selected: `tintColor: cs.primaryContainer.withValues(alpha: AppSizes.opacityLight5)` — stronger green wash + text/icon color shifts to `cs.primary`

### 6. Account Selector Row
- **Current:** "All Accounts ▾" button + gear icon — already matches Stitch
- **No changes needed**

### 7. Wallet Cards Row (ALREADY RESTRUCTURED — fix remaining bug)
- **Status:** The `AccountChip` has already been restructured to the centered vertical layout (icon → name → balance, no accent bar). The accent bar, `_CardBody`, `_ChipStyle`, and `_buildContent` have been removed.
- **File:** `lib/features/dashboard/presentation/widgets/account_chip.dart`
- **Current layout matches Stitch:** ✅ Centered Column with icon, name, balance. Width 110, height 80, borderRadiusMdSm.

**BUG TO FIX:** Lines 55-57 — both selected AND unselected states use the same `bgColor`:
```dart
// CURRENT (broken — both states identical):
final bgColor = isSelected
    ? walletColor.withValues(alpha: AppSizes.opacityLight2)
    : walletColor.withValues(alpha: AppSizes.opacityLight2);  // ← SAME!
```

**Fix to:**
```dart
final bgColor = isSelected
    ? walletColor.withValues(alpha: AppSizes.opacityLight2)
    : cs.surfaceContainerLow;  // ← unselected = neutral, no wallet color tint
```

This makes unselected cards neutral (subtle grey lift) and selected cards tinted with the wallet's personal color — matching the Stitch design where each selected card has a distinct color tone.

- **Everything else in AccountChip is correct:** icon, name, balance layout, sizing, padding, gestures.

---

## Design Tokens

| Property | Token |
|----------|-------|
| Balance text | `displaySmall` (32sp) |
| Income/Expense pill radius | `borderRadiusFull` (100) |
| Income/Expense pill padding | horizontal `AppSizes.md`, vertical `AppSizes.sm` |
| Cash card icon circle | `iconContainerLg` (44px) |
| Wallet card size | ~100w x 80h |
| Net badge radius | `borderRadiusFull` |
| Vertical gaps between sections | `AppSizes.md` (16) minimum |

---

## L10n Keys Needed

- `wallet_physical_wallet` — "Physical Wallet" / "محفظة نقدية" (subtitle for Cash wallet card)

---

## Existing Code to Reuse

| What | Where |
|------|-------|
| `MoneyFormatter.formatTrailing()` | `lib/core/utils/money_formatter.dart` |
| `AppIcons.walletType(type)` | `lib/core/constants/app_icons.dart` |
| `GlassCard` | `lib/shared/widgets/cards/glass_card.dart` |
| `HorizontalReorderableRow` | `lib/shared/widgets/lists/horizontal_reorderable_row.dart` |
| `showEditWalletSheet` | `lib/shared/widgets/sheets/show_wallet_sheet.dart` |
| `hideBalancesProvider` | `lib/shared/providers/hide_balances_provider.dart` |
| `selectedAccountIdProvider` | `lib/shared/providers/selected_account_provider.dart` |

---

---

## NEW FEATURE: Scroll-to-Expand Transaction List

### Pain Point
The transaction list on the Home screen is cramped — the Hero section (balance + accounts) occupies most of the viewport, leaving limited vertical space for browsing transactions. Users must scroll within a small window.

### Solution: Progressive Hero Collapse
As the user scrolls down through the transaction list, after a scroll threshold, the Hero section smoothly collapses/fades away and the transaction list expands to full-screen — seamlessly transitioning into the same layout the user sees when they tap the search icon.

### Current Architecture (DO NOT break)
```
dashboard_screen.dart layout:
├── Column (fixed zone — never scrolls)
│   ├── OfflineBanner (conditional)
│   └── BalanceHeader (OR SearchHeader when filter.isSearchActive)
└── Expanded
    └── RefreshIndicator > CustomScrollView (scrollable zone)
        ├── SliverToBoxAdapter: InsightCardsZone
        ├── SliverToBoxAdapter: DueSoonSection
        ├── SliverPersistentHeader: FilterBarDelegate (pinned)
        └── TransactionSliverList
```

When `filter.isSearchActive == true`, the `BalanceHeader` is already replaced by `SearchHeader` (smaller header with search field + result count). This is the target "expanded" state we want to transition into.

### Implementation Approach

**Option A (Recommended): Scroll-aware AnimatedCrossFade**
- Add a `ScrollController` to the `CustomScrollView`
- Listen to scroll position in the dashboard state
- When `scrollController.offset > threshold` (e.g., 300px or after ~5-6 transactions):
  - Smoothly animate the `BalanceHeader` height to 0 (collapse it)
  - Show a compact mini-header instead (just the balance amount + search icon, single line)
  - The `CustomScrollView` naturally expands to fill the freed space
- When user scrolls back to top (offset < threshold/2):
  - Smoothly restore the full `BalanceHeader`
- **Transition:** Use `AnimatedContainer` with height animation on the BalanceHeader wrapper, or `AnimatedSwitcher` between full header and compact header

**Mini-header (collapsed state) layout:**
- Single row, height ~56px (AppSizes.minTapTarget + padding)
- Content: Balance amount (titleMedium, bold) + "|" separator + search icon button + filter icon button
- Background: same `glassCardSurface` as full header
- This gives the user quick balance visibility + search access without the full hero taking space

### Key Details

| Property | Value |
|----------|-------|
| Collapse threshold | `300.0` pixels of scroll offset (roughly 5-6 transaction cards) |
| Restore threshold | `150.0` pixels (scroll back to top area — hysteresis to prevent flickering) |
| Animation duration | `AppDurations.animMedium` (250ms) |
| Animation curve | `Curves.easeOutCubic` |
| Mini-header height | `AppSizes.minTapTarget + AppSizes.md` (~64px) |

### State Management
- Add `bool _heroCollapsed = false` to `_DashboardScreenState`
- Add `final _scrollController = ScrollController()` (dispose in `dispose()`)
- In `initState`, add listener:
  ```dart
  _scrollController.addListener(() {
    final collapsed = _scrollController.offset > 300;
    if (collapsed != _heroCollapsed) {
      setState(() => _heroCollapsed = collapsed);
    }
  });
  ```
- Pass `_scrollController` to `CustomScrollView(controller: _scrollController)`
- In the fixed zone, wrap header in `AnimatedCrossFade`:
  ```dart
  if (filter.isSearchActive)
    SearchHeader(resultCount: resultCount)
  else
    AnimatedCrossFade(
      firstChild: const BalanceHeader(),
      secondChild: _MiniBalanceHeader(balance: displayBalance, hidden: hidden),
      crossFadeState: _heroCollapsed
          ? CrossFadeState.showSecond
          : CrossFadeState.showFirst,
      duration: AppDurations.animMedium,
    ),
  ```

### Mini Balance Header Widget
```
_MiniBalanceHeader:
  Container(height: 64, padding: screenHPadding)
    Row:
      - Text(balance, titleMedium, bold)
      - Spacer
      - IconButton(search icon → activate search mode)
      - IconButton(filter icon → open filter sheet)
```

### What This Achieves
1. User starts at full hero view with balance, income/expense, accounts
2. As they scroll down browsing transactions, hero collapses smoothly
3. Transaction list gets full screen height — comfortable browsing
4. Mini-header keeps balance visible + quick search/filter access
5. Scrolling back to top restores full hero — no information lost
6. If user taps search, it enters the existing `SearchHeader` mode (unchanged)

---

## What NOT to Change
- Account selector dropdown logic (picker, selection state)
- HorizontalReorderableRow drag-to-reorder behavior
- Double-tap to edit gesture
- Balance hide/show toggle logic
- MonthSummaryInline income/expense calculation logic
- Net popover info tooltip
- SearchHeader behavior (already works correctly when filter.isSearchActive)
- RefreshIndicator + CustomScrollView structure
- TransactionSliverList rendering
