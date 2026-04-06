# Review Transactions — List View Revamp

**Date:** 2026-04-04
**Scope:** Revamp the list view mode of `voice_confirm_screen.dart` and `draft_list_item.dart`
**Goals:** Scannability, visual consistency, interaction polish, premium aesthetic

---

## 1. Row Anatomy (New Layout)

Replace the current `[CategoryIcon | Title+Subtitle | Amount/Checkbox stacked]` with:

```
┌──▌ [Checkbox] [CategoryIcon] Title              -150.00 EGP ─┐
│  ▌                           Category * Wallet                │
│  ▌             ┌──────────────────────────┐                   │  <- only if suggestion
│  ▌             │ icon  Suggestion text     │                   │
│  ▌             └──────────────────────────┘                   │
└───────────────────────────────────────────────────────────────┘
```

### Token Mapping

| Element | Token | Value |
|---------|-------|-------|
| **Card** | `GlassCard` | existing widget, no change |
| Card margin H | `AppSizes.screenHPadding` | 16dp |
| Card margin V | `AppSizes.xs` | 4dp |
| Card inner padding | `AppSizes.sm` | 8dp |
| Card border radius | `AppSizes.borderRadiusMd` | 16dp |
| Card tap | `InkWell` with `borderRadius: AppSizes.borderRadiusMd` | opens DraftEditSheet |
| **Left-edge accent bar** | NEW: 3dp width, full card height | uses `ClipRRect` + positioned `Container` |
| Accent bar width | `AppSizes.voiceBarWidth` | 3dp (reuse existing) |
| Accent bar color | `theme.incomeColor` / `theme.expenseColor` / `theme.transferColor` | per type |
| Accent bar radius | `AppSizes.borderRadiusMd` on leading corners only | 16dp TL/BL (LTR) or TR/BR (RTL) |
| Accent bar RTL | Use `AlignmentDirectional.centerStart` | auto-flips for Arabic |
| **Leading checkbox** | `Checkbox` in `SizedBox` | standard Material checkbox |
| Checkbox container | `AppSizes.minTapTarget` | 48dp (accessibility compliant) |
| Checkbox to icon gap | `AppSizes.sm` | 8dp |
| **Category icon container** | `Container` with `BoxShape.circle` | unchanged |
| Icon container size | `AppSizes.iconContainerMd` | 40dp (upgrade from 32dp `iconContainerSm`) |
| Icon size | `AppSizes.iconSm` | 20dp (upgrade from 18dp `iconSm2`) |
| Icon bg color | `categoryColor.withValues(alpha: AppSizes.opacityLight)` | 15% opacity |
| Icon to text gap | `AppSizes.sm` | 8dp |
| **Title text** | `textStyles.bodyMedium` | `FontWeight.w600`, default color |
| Title max lines | 1 | `TextOverflow.ellipsis` |
| Title to subtitle gap | `AppSizes.xxs` | 2dp |
| **Subtitle text** | `textStyles.bodySmall` | `color: colors.outline` |
| Subtitle format | `'categoryName * walletName'` | unchanged |
| **Amount text** | `textStyles.titleSmall` | upgrade from `bodyMedium` for prominence |
| Amount weight | `FontWeight.w700` | bold |
| Amount color | `typeColor` (income/expense/transfer) | via `theme.incomeColor` etc. |
| Amount prefix | `+` income/deposit, `-` expense/withdrawal, none for transfer | unchanged |
| Amount font features | `[FontFeature.tabularFigures()]` | NEW: aligns decimals vertically |
| **Dimmed state** | `Opacity` wrapper | `isIncluded ? 1.0 : AppSizes.opacityLight5` (0.4) |

## 2. Suggestion Chip (Replaces Inline Banners)

Replace the 3 variable-height banner rows with a single compact chip.

### Priority Order (max 1 chip per item)
1. **Unmatched wallet** (highest — actionable, blocks save)
2. **Subscription hint** (medium — value-add)
3. **Goal match** (lowest — informational)

### Chip Token Mapping

| Element | Token | Value |
|---------|-------|-------|
| Chip container | `Container` with `BoxDecoration` | pill shape |
| Chip top margin | `AppSizes.xs` | 4dp |
| Chip H padding | `AppSizes.sm` | 8dp |
| Chip V padding | `AppSizes.xxs` | 2dp |
| Chip border radius | `AppSizes.borderRadiusFull` | 100dp (pill) |
| Chip icon size | `AppSizes.iconXxs2` | 14dp |
| Chip icon-to-text gap | `AppSizes.xs` | 4dp |
| Chip text style | `textStyles.labelSmall` | system label small |
| Chip max lines | 1 | `TextOverflow.ellipsis` |
| Chip tap | `GestureDetector` with `onTap` | per-type callback |

### Chip Color Per Type

| Type | Icon | BG Color | Text Color |
|------|------|----------|------------|
| **Goal match** | `AppIcons.goals` | `theme.incomeColor.withValues(alpha: AppSizes.opacityXLight)` (10%) | `theme.incomeColor` |
| **Subscription** | `AppIcons.recurring` | `colors.tertiaryContainer` | `colors.onTertiaryContainer` |
| **Wallet create** | `AppIcons.add` | `colors.primary.withValues(alpha: AppSizes.opacityXLight)` (10%) | `colors.primary` |

### L10n Keys (existing, reused)
- Goal: `matchedGoalName` (dynamic string)
- Subscription: `context.l10n.voice_confirm_subscription_suggest`
- Wallet: `context.l10n.voice_create_wallet_instead(unmatchedHint!)`

## 3. Swipe Interaction (Dismissible -> flutter_slidable)

Replace `Dismissible` with `Slidable` from `flutter_slidable` (already in deps).

### Slide Actions

| Direction | Action | Icon | Color | Callback |
|-----------|--------|------|-------|----------|
| **Start (right swipe)** | Edit | `AppIcons.edit` | `colors.primary` | `onEdit()` |
| **End (left swipe)** | Exclude/Remove | `AppIcons.close` | `theme.expenseColor` | `onDecline()` |

### Token Mapping

| Element | Token | Value |
|---------|-------|-------|
| Action pane type | `SlidableAction` | from flutter_slidable |
| Action icon size | `AppSizes.iconMd` | 24dp |
| Action border radius | `AppSizes.borderRadiusMd` | 16dp |
| Extent ratio | `0.2` | 20% of card width per action |
| Motion | `DrawerMotion()` | drawer-style reveal |
| Close on tap | `true` | auto-close after action |

## 4. Batch Selection Controls

New row between AppBar and list.

### Layout

```
┌─────────────────────────────────────────────────┐
│  Select All / Deselect All        5 of 7 selected│
└─────────────────────────────────────────────────┘
```

### Token Mapping

| Element | Token | Value |
|---------|-------|-------|
| Row padding H | `AppSizes.screenHPadding` | 16dp |
| Row padding V | `AppSizes.xs` | 4dp |
| Left: TextButton | `TextButton` | `colors.primary` text |
| Left text style | `textStyles.labelLarge` | standard label |
| Right: count text | `textStyles.bodySmall` | `color: colors.outline` |
| Toggle logic | if all selected -> "Deselect All", else -> "Select All" | dynamic |

### L10n Keys (NEW — to be added)
- `voice_select_all` / `voice_deselect_all`
- `voice_selected_count`: `"{selected} of {total} selected"` (parameterized)

## 5. Bottom Confirm Bar (Enhanced)

### Layout

```
┌─────────────────────────────────────────────────┐
│     [ Confirm N Transactions ]                   │
└─────────────────────────────────────────────────┘
```

### Token Mapping

| Element | Token | Value |
|---------|-------|-------|
| Bar padding H | `AppSizes.screenHPadding` | 16dp |
| Bar padding V | `AppSizes.md` | 16dp |
| Button | `FilledButton` | full width |
| Button border radius | `AppSizes.borderRadiusMdSm` | 12dp |
| Button text | `context.l10n.voice_confirm_count(includedCount)` | existing key |
| Disabled when | `includedCount == 0 || _saving` | unchanged |

## 6. Animation Details

| Animation | Token | Value |
|-----------|-------|-------|
| List item entry fade | `AppDurations.listItemEntry` | 350ms |
| List item entry slide | `slideY(begin: 0.03)` | `Curves.easeOutCubic` |
| Stagger delay per item | `AppDurations.staggerDelay` | 50ms * index |
| Reduce motion check | `context.reduceMotion` | skip animations if true |
| Slidable open/close | `AppDurations.animQuick` | 200ms |

## 7. Files to Modify

| File | Change |
|------|--------|
| `lib/features/voice_input/presentation/widgets/draft_list_item.dart` | Full rewrite: new layout, accent bar, leading checkbox, suggestion chip, flutter_slidable |
| `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart` | Add batch controls row, update `_buildListView()`, update `_buildListBottomBar()` |
| `lib/l10n/app_en.arb` | Add `voice_select_all`, `voice_deselect_all`, `voice_selected_count` |
| `lib/l10n/app_ar.arb` | Add matching Arabic keys |

## 8. What Does NOT Change

- Swipe card view (`_buildSwipeView`) — untouched
- `DraftEditSheet` — untouched
- `_EditableDraft` data model — untouched
- Save/confirm flow — untouched
- View toggle mechanism — untouched
- All existing callbacks (onToggle, onEdit, onAccept, onDecline, onSubscriptionTap, onCreateWallet) — signatures unchanged

## 9. New Dependencies

None. `flutter_slidable` is already in `pubspec.yaml`.

## 10. Stitch Mockups

Reference mockups in Stitch project `6415530836869561572`:
- Screen 1: Original baseline design
- Screen 2 (edited): Final design with compact suggestion chips
- Variants A-C: Layout explorations (compact, spacious, left-aligned)
