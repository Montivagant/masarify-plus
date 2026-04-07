# Transaction Card & Hub Screen Revamp

**Date:** 2026-04-07
**Scope:** 2 features — transaction card visual revamp + hub/planning screen grid redesign

---

## Feature 1: Transaction Card Revamp

### Context
The current `TransactionCard` displays transactions as compact list items (icon + title + amount). The user wants richer cards with category color accent bars and more visible information, while keeping the existing swipe-to-edit/delete behavior.

### Approach
Modify `TransactionCard` in-place (Approach A). All consumers get the new style automatically.

### File to Modify
- `lib/shared/widgets/cards/transaction_card.dart`

### Design

**Layout per card:**
```
┌─────────────────────────────────────┐
│▐ [icon]  Category Name      +500 EGP│
│▐         Transaction Title          │
│▐         Wallet · Source            │
└─────────────────────────────────────┘
 ▐ = 4px category-color accent bar
```

**Visual changes:**
- Add 4px left accent bar in the category's `colorHex` color (same pattern as `AccountChip._edgeStripWidth`)
- Wrap card content in a subtle surface container (light fill or `GlassCard(tier: inset)`) for visual separation between items
- Increase vertical padding from `AppSizes.sm` (8) to `AppSizes.md` (16)
- Border radius: `AppSizes.borderRadiusMdSm`

**Content layout (3 rows):**
1. **Row 1:** Category icon + category name (bold, `labelMedium`) + amount right-aligned (semantic color: income/expense/transfer)
2. **Row 2:** Transaction title (`bodySmall`, secondary color)
3. **Row 3:** Wallet name + source indicator (`labelSmall`, muted) — shown contextually

**Preserved behavior:**
- `Slidable` swipe actions (edit right, delete left) — no changes
- Brand logo 3-tier system — no changes
- Transfer counterpart display — no changes
- `onTap`, `onEdit`, `onDelete` callbacks — no changes

**Data flow:**
- Category color comes from `CategoryEntity.colorHex`, already resolved in parent widgets (`TransactionSliverList`, `TransactionListSection`)
- Category name already available via `resolveCategory()` utility
- The `TransactionCard` needs to accept `categoryColor` (Color) and `categoryName` (String) parameters if not already present

### Parent Widget Updates
- `TransactionSliverList` and `TransactionListSection` may need minor updates to pass category color/name to `TransactionCard`
- No structural changes to the list builders

---

## Feature 2: Hub/Planning Screen Revamp

### Context
The current Hub screen uses 4 grouped `GlassSection` containers with `ListTile`-style items. The user wants a flat 2-column grid of cards with clean icons — modern and visually distinct.

### File to Modify
- `lib/features/hub/presentation/screens/hub_screen.dart`

### Design

**Layout:**
```
┌─────────────┐  ┌─────────────┐
│    (icon)    │  │    (icon)    │
│   Wallets    │  │  Categories  │
└─────────────┘  └─────────────┘
┌─────────────┐  ┌─────────────┐
│    (icon)    │  │    (icon)    │
│   Budgets    │  │    Goals     │
└─────────────┘  └─────────────┘
       ...              ...
```

**Structure:**
- Remove all `GlassSection` groups and `_HubTile` widgets
- Replace with `GridView.count(crossAxisCount: 2)` or `SliverGrid`
- Horizontal padding: `AppSizes.screenHPadding`
- Grid spacing: `AppSizes.sm` (8) both axes

**Card spec:**
- Container: `GlassCard(tier: card)` with `onTap` for navigation
- Height: ~120px
- Border radius: `AppSizes.borderRadiusMd` (16)
- Icon: Phosphor icon inside a 48x48 tinted `GlassCard(tier: inset)` circle, centered
- Icon tint: `primaryContainer` with opacity, icon color: `onPrimaryContainer`
- Title: `titleSmall` (14sp medium), centered below icon, `AppSizes.sm` gap from icon
- Badge: optional count chip positioned top-right (reuse existing badge logic)

**Item order (flat, by importance):**

| # | Item | Icon | Badge | Route |
|---|------|------|-------|-------|
| 1 | Wallets | `AppIcons.wallet` | — | wallets route |
| 2 | Categories | `AppIcons.category` | — | categories route |
| 3 | Budgets | `AppIcons.budget` | active count | budgets route |
| 4 | Goals | `AppIcons.goal` | in-progress count | goals route |
| 5 | AI Chat | `AppIcons.chat` | — | chat route |
| 6 | Auto-detect | `AppIcons.notification` | pending count | parser route |
| 7 | Settings | `AppIcons.settings` | — | settings route |

**Badge logic:** Reuse existing providers for counts (active budgets, in-progress goals, pending SMS transactions).

**Odd item count:** 7 items means the last row has 1 card — it should be left-aligned (default GridView behavior).

---

## Verification

1. Run `flutter analyze lib/` — no analysis errors
2. Visual check on device/emulator:
   - Transaction cards show category color accent bar, category name, and proper spacing
   - Swipe-to-edit and swipe-to-delete still work on transaction cards
   - Hub screen shows 2-column grid with all 7 items
   - Hub grid cards navigate to correct routes on tap
   - Badges show correct counts
3. RTL check: accent bar on right side, text alignment correct
4. Dark mode: glass tiers render correctly, accent colors visible
