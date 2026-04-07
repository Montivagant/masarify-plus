# Transaction Card & Hub Screen Revamp — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Revamp transaction cards with category-color accent bars and richer layout, and redesign the Hub/Planning screen as a flat 2-column grid of icon cards.

**Architecture:** Two independent UI-only changes. Feature 1 modifies the existing `TransactionCard` widget in-place — all consumers automatically get the new style. Feature 2 replaces the Hub screen's section-based `ListView` with a flat `GridView.count(crossAxisCount: 2)` of `GlassCard` items.

**Tech Stack:** Flutter, Riverpod, GlassCard (existing), flutter_slidable (existing), Phosphor Icons, go_router

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `lib/shared/widgets/cards/transaction_card.dart` | Modify | Add accent bar, increase padding, restructure layout |
| `lib/features/hub/presentation/screens/hub_screen.dart` | Modify | Replace sections with flat grid |

No new files needed. Both features modify existing widgets.

---

## Task 1: Revamp TransactionCard with category accent bar

**Files:**
- Modify: `lib/shared/widgets/cards/transaction_card.dart`

- [ ] **Step 1: Restructure `_CardContent` to use accent bar + card container**

Replace the entire `_CardContent.build` method. The new layout wraps content in a subtle surface container with a 4px left accent bar in the category color.

```dart
// In _CardContent, replace the build method (currently lines 164–264):

@override
Widget build(BuildContext context) {
  final cs = context.colors;
  final amountLabel =
      '$amountPrefix ${MoneyFormatter.format(transaction.amount, currency: transaction.currencyCode)}';

  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppSizes.borderRadiusMdSm),
    child: Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMdSm),
      ),
      child: Row(
        children: [
          // ── Left accent bar ──
          Container(
            width: 4,
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: BorderRadiusDirectional.only(
                topStart: Radius.circular(AppSizes.borderRadiusMdSm),
                bottomStart: Radius.circular(AppSizes.borderRadiusMdSm),
              ),
            ),
          ),
          // ── Card body ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Row(
                children: [
                  // Icon (brand or category)
                  if (brandInfo != null)
                    BrandLogo(brand: brandInfo!)
                  else
                    Icon(
                      categoryIcon,
                      size: AppSizes.iconMd,
                      color: categoryColor,
                    ),
                  const SizedBox(width: AppSizes.md),
                  // Text column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Category name
                        Text(
                          categoryName,
                          style: context.textStyles.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Row 2: Transaction title
                        if (transaction.title.isNotEmpty) ...[
                          const SizedBox(height: AppSizes.xxs),
                          Text(
                            transaction.title,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: cs.outline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        // Row 3: Wallet + source
                        if (walletName != null || sourceIcon != null) ...[
                          const SizedBox(height: AppSizes.xxs),
                          Row(
                            children: [
                              if (walletName != null)
                                Flexible(
                                  child: Text(
                                    walletName!,
                                    style:
                                        context.textStyles.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (sourceIcon != null) ...[
                                if (walletName != null)
                                  const SizedBox(width: AppSizes.xs),
                                Icon(
                                  sourceIcon!,
                                  size: AppSizes.iconXxs,
                                  color: cs.outline,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  // Amount
                  Semantics(
                    label: amountLabel,
                    excludeSemantics: true,
                    child: Text(
                      '$amountPrefix ${MoneyFormatter.formatAmount(transaction.amount)}',
                      style: context.textStyles.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
```

Key changes from the original:
- Added `Container` with `surfaceContainerLow` background and `borderRadiusMdSm` corners
- Added `margin` for visual separation between cards
- Added 4px left accent bar with `categoryColor`
- Wallet name and source icon moved to a dedicated Row 3 (separate from title)
- The accent bar height stretches with `IntrinsicHeight` via the `Row` — the Container has no fixed height, so the accent bar will fill the row height naturally. If the Row doesn't stretch the bar, wrap the outer Row in `IntrinsicHeight`:

```dart
child: IntrinsicHeight(
  child: Row(
    children: [
      // accent bar ...
      // card body ...
    ],
  ),
),
```

- [ ] **Step 2: Ensure the accent bar stretches to full card height**

The left accent `Container` needs a height constraint. Since it's in a `Row`, it needs `IntrinsicHeight` as parent or `crossAxisAlignment: CrossAxisAlignment.stretch`. Use `CrossAxisAlignment.stretch` on the outer Row — it's more performant than `IntrinsicHeight`:

In the `Row` that contains the accent bar and card body, set:
```dart
child: Row(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    // accent bar Container...
    // Expanded card body...
  ],
),
```

- [ ] **Step 3: Remove old horizontal padding from the parent Slidable area**

The old `_CardContent` had `padding: EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm)` at the top level. The new version has `margin` on the Container instead. Verify that the `Slidable` wrapper in `TransactionCard.build` doesn't add conflicting padding. The current code passes `card` directly to `Slidable(child: card)` — no extra padding, so this should be clean.

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze lib/shared/widgets/cards/transaction_card.dart`
Expected: No issues found

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/cards/transaction_card.dart
git commit -m "feat: revamp TransactionCard with category accent bar and rich layout"
```

---

## Task 2: Revamp Hub screen to flat 2-column grid

**Files:**
- Modify: `lib/features/hub/presentation/screens/hub_screen.dart`

- [ ] **Step 1: Replace Hub screen body with GridView**

Replace the entire `build` method body (keep the class declaration and providers). The new layout uses a flat `GridView.count` with 7 card items.

```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final cs = context.colors;
  final now = DateTime.now();
  final monthKey = (now.year, now.month);

  // Watch providers for badges
  final budgets = ref.watch(budgetsByMonthProvider(monthKey));
  final activeGoals = ref.watch(activeGoalsProvider);
  final activeBudgetCount = budgets.valueOrNull?.length ?? 0;
  final activeGoalCount = activeGoals.valueOrNull?.length ?? 0;

  final pendingCount = AppConfig.kSmsEnabled
      ? (ref.watch(pendingCountProvider).valueOrNull ?? 0)
      : 0;

  final items = <_HubCardData>[
    _HubCardData(
      icon: AppIcons.wallet,
      label: context.l10n.hub_wallets,
      route: AppRoutes.wallets,
    ),
    _HubCardData(
      icon: AppIcons.category,
      label: context.l10n.settings_categories_label,
      route: AppRoutes.categories,
    ),
    _HubCardData(
      icon: AppIcons.budget,
      label: context.l10n.budgets_title,
      route: AppRoutes.budgets,
      badge: activeBudgetCount > 0
          ? '$activeBudgetCount ${context.l10n.hub_active}'
          : null,
    ),
    _HubCardData(
      icon: AppIcons.goals,
      label: context.l10n.goals_title,
      route: AppRoutes.goals,
      badge: activeGoalCount > 0
          ? '$activeGoalCount ${context.l10n.hub_in_progress}'
          : null,
    ),
    _HubCardData(
      icon: AppIcons.ai,
      label: context.l10n.chat_title,
      route: AppRoutes.chat,
    ),
    if (AppConfig.kSmsEnabled)
      _HubCardData(
        icon: AppIcons.inbox,
        label: context.l10n.auto_detected_transactions,
        route: AppRoutes.parserReview,
        badge: pendingCount > 0
            ? context.l10n.sms_new_found(pendingCount)
            : null,
      ),
    _HubCardData(
      icon: AppIcons.settings,
      label: context.l10n.settings_title,
      route: AppRoutes.settings,
    ),
  ];

  return Scaffold(
    appBar: AppAppBar(
      title: context.l10n.hub_planning_title,
      showBack: false,
    ),
    body: GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.md,
      ),
      mainAxisSpacing: AppSizes.sm,
      crossAxisSpacing: AppSizes.sm,
      children: items.map((item) => _HubGridCard(
        icon: item.icon,
        label: item.label,
        badge: item.badge,
        onTap: () => context.push(item.route),
      )).toList(),
    ),
  );
}
```

- [ ] **Step 2: Add `_HubCardData` model and `_HubGridCard` widget**

Add these at the bottom of the file, replacing the old `_section` and `_tile` methods:

```dart
/// Data holder for hub grid items.
class _HubCardData {
  const _HubCardData({
    required this.icon,
    required this.label,
    required this.route,
    this.badge,
  });

  final IconData icon;
  final String label;
  final String route;
  final String? badge;
}

/// A single card in the hub grid.
class _HubGridCard extends StatelessWidget {
  const _HubGridCard({
    required this.icon,
    required this.label,
    required this.onTap,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return GlassCard(
      tier: GlassTier.card,
      padding: const EdgeInsets.all(AppSizes.md),
      onTap: onTap,
      child: Stack(
        children: [
          // ── Badge (top-end) ──
          if (badge != null)
            PositionedDirectional(
              top: 0,
              end: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.sm,
                  vertical: AppSizes.xxs,
                ),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: AppSizes.opacityLight2),
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusFull),
                ),
                child: Text(
                  badge!,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          // ── Icon + Label (centered) ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GlassCard(
                  tier: GlassTier.inset,
                  padding: EdgeInsets.zero,
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusMd),
                  tintColor: cs.primaryContainer
                      .withValues(alpha: AppSizes.opacityLight4),
                  child: SizedBox(
                    width: AppSizes.iconContainerXl,
                    height: AppSizes.iconContainerXl,
                    child: Icon(
                      icon,
                      size: AppSizes.iconLg,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Text(
                  label,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Remove unused imports and old helpers**

Remove from hub_screen.dart:
- `import '../../../../shared/widgets/cards/glass_section.dart';` (no longer used)
- Delete the `_section` method
- Delete the `_tile` method

Keep these imports (still needed):
- `glass_card.dart` (for `GlassCard`, `GlassTier`)
- `app_config.dart` (for `kSmsEnabled`)
- `pending_transactions_provider.dart` (for badge when SMS enabled)
- `budget_provider.dart`, `goal_provider.dart` (for badges)
- `app_app_bar.dart`, `app_icons.dart`, `app_routes.dart`, `app_sizes.dart`
- `build_context_extensions.dart`
- `go_router` and `flutter_riverpod`

- [ ] **Step 4: Handle the SMS auto-detect item conditionally**

The `AppConfig.kSmsEnabled` is currently `false`, so the auto-detect item won't appear. The `items` list uses `if (AppConfig.kSmsEnabled)` — this is a collection-if, valid in Dart. When SMS is disabled, the grid has 6 items (3 full rows). When enabled, 7 items (last row has 1 card, left-aligned by default).

Remove the `badgeProvider` field from `_HubCardData` — it's not needed since SMS is conditionally included. Instead, handle the pending count inline in the `items` list:

```dart
if (AppConfig.kSmsEnabled)
  Builder(
    builder: (context) {
      final pendingCount =
          ref.watch(pendingCountProvider).valueOrNull ?? 0;
      return _HubCardData(
        icon: AppIcons.inbox,
        label: context.l10n.auto_detected_transactions,
        route: AppRoutes.parserReview,
        badge: pendingCount > 0
            ? context.l10n.sms_new_found(pendingCount)
            : null,
      );
    },
  ),
```

Wait — `Builder` returns a Widget, not `_HubCardData`. Since we're building a data list, handle the pending count before the list:

```dart
final pendingCount = AppConfig.kSmsEnabled
    ? (ref.watch(pendingCountProvider).valueOrNull ?? 0)
    : 0;

// Then in the items list:
if (AppConfig.kSmsEnabled)
  _HubCardData(
    icon: AppIcons.inbox,
    label: context.l10n.auto_detected_transactions,
    route: AppRoutes.parserReview,
    badge: pendingCount > 0
        ? context.l10n.sms_new_found(pendingCount)
        : null,
  ),
```

- [ ] **Step 5: Run analyzer**

Run: `flutter analyze lib/features/hub/presentation/screens/hub_screen.dart`
Expected: No issues found

- [ ] **Step 6: Commit**

```bash
git add lib/features/hub/presentation/screens/hub_screen.dart
git commit -m "feat: revamp Hub screen to flat 2-column grid of icon cards"
```

---

## Task 3: Final verification

- [ ] **Step 1: Run full analyzer**

Run: `flutter analyze lib/`
Expected: No issues found (or only pre-existing warnings unrelated to these changes)

- [ ] **Step 2: Visual verification on device/emulator**

Check:
- Transaction cards: accent bar visible in category color, category name prominent, title below, wallet/source on Row 3
- Swipe left (delete) and right (edit) still work on transaction cards
- Hub screen: 2-column grid, all items have icons in tinted circles, titles below
- Hub badges: budget count and goal count display correctly
- RTL: accent bar on right side, text right-aligned
- Dark mode: glass tiers render correctly, accent colors visible

- [ ] **Step 3: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "fix: address visual polish from transaction card & hub revamp"
```
