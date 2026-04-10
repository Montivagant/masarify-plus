# Planning Grid Screen — Pixel-Perfect Requirements

**Reference:** Stitch screen `15d2c66e64f54a6ab5074649dc03ffea`
**File:** `lib/features/hub/presentation/screens/hub_screen.dart`

---

## What's Wrong (Stitch Design vs Current App)

| Element | Stitch Design | Current App | Fix Required |
|---------|--------------|-------------|--------------|
| App bar left | Avatar/profile icon | No avatar | **Add avatar or keep as-is (minor)** |
| App bar right | Search icon | No search icon | **Add search icon (optional — only if search exists)** |
| Editorial headline | "Curate your capital." large bold below app bar | Missing entirely | **Add editorial headline + subtitle** |
| Subtitle text | "Organize your financial future with precision and clarity" muted | Missing entirely | **Add subtitle below headline** |
| Icon circle shape | CIRCLE (fully round `BoxShape.circle`) | Rounded SQUARE (`borderRadiusMd` = 16px) | **Change icon container from rounded square to circle** |
| Icon circle color | Solid green tint (not glass tier) | `GlassCard(tier: inset)` with `borderRadiusMd` | **Replace GlassCard with simple Container circle** |
| Grid spacing | More generous gap between cards | `AppSizes.sm` (8px) both axes | **Increase to `AppSizes.md` (16px)** |
| Grid aspect ratio | Cards appear taller than square | Default `GridView.count` (1:1 aspect) | **May need `childAspectRatio` adjustment** |
| "OPTIMIZATION" label | Small caps section label above insights card | Missing | **Add section label** |
| Insights card | "Saving Insights" card with headline + body + "View Details" button + "Dismiss" | Missing entirely | **Add insights card at bottom** |
| Card background | Very subtle, almost flat white, barely visible glass | `GlassCard` with default glass | **May be OK — verify on device** |

---

## Exact Layout Specification (Top to Bottom)

### 1. App Bar
- **Current:** `AppAppBar(title: context.l10n.hub_planning_title, showBack: false)`
- **Stitch shows:** Avatar icon left, "Planning" center, search icon right
- **Changes:**
  - Keep `showBack: false` and title
  - **Optional:** Add search `IconButton` in `actions` — only if a search feature exists for hub items. If not, skip.
  - **Skip avatar** — not part of the standard app bar pattern in Masarify

### 2. Editorial Header (NEW — above the grid)
- **Stitch shows:** Two lines of editorial text between app bar and grid
- **Implementation:** Change from `GridView.count` (which is the body) to a `ListView` containing the header + grid:
  ```
  body: ListView(
    padding: EdgeInsets.symmetric(horizontal: screenHPadding, vertical: md),
    children: [
      // Editorial header
      _EditorialHeader(),
      SizedBox(height: lg),
      // Grid (wrapped in GridView or Wrap)
      ...gridCards,
      SizedBox(height: lg),
      // Insights card
      _InsightsCard(),
      SizedBox(height: bottomScrollPadding),
    ],
  )
  ```
- **Note:** Can't use `GridView.count` as the body anymore since we need non-grid widgets above and below. Use a `Wrap` widget or a manual 2-column layout instead.

#### Editorial Header Widget:
```
Column(crossAxisAlignment: start):
  - "Curate your capital." — displaySmall (or headlineMedium), fontWeight w700, cs.onSurface
  - SizedBox(height: xs)
  - "Organize your financial future with precision and clarity" — bodyMedium, cs.outline
```

**L10n keys needed:**
- `hub_headline` — "Curate your capital." / "نظّم رأس مالك."
- `hub_subtitle` — "Organize your financial future with precision and clarity" / "نظّم مستقبلك المالي بدقة ووضوح"

### 3. Grid Cards (FIX icon shape + spacing)

**Current structure:** `GridView.count(crossAxisCount: 2)` with `_HubGridCard` children.

**Since we're moving to ListView body:** Replace `GridView.count` with a `Wrap` widget:
```dart
Wrap(
  spacing: AppSizes.md,        // horizontal gap (increased from sm)
  runSpacing: AppSizes.md,     // vertical gap (increased from sm)
  children: items.map((item) => SizedBox(
    width: (MediaQuery.sizeOf(context).width - AppSizes.screenHPadding * 2 - AppSizes.md) / 2,
    child: _HubGridCard(...),
  )).toList(),
)
```

Or alternatively, use pairs of `Row` widgets with 2 cards each.

#### _HubGridCard Changes:

**Icon container — change from rounded square to CIRCLE:**
```dart
// CURRENT (rounded square):
GlassCard(
  tier: GlassTier.inset,
  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),  // 16px = square-ish
  ...
)

// NEW (circle):
Container(
  width: AppSizes.iconContainerXl,     // 56px
  height: AppSizes.iconContainerXl,
  decoration: BoxDecoration(
    color: cs.primaryContainer.withValues(alpha: AppSizes.opacityLight4),
    shape: BoxShape.circle,            // ← CIRCLE, not rounded rect
  ),
  child: Icon(
    icon,
    size: AppSizes.iconLg,             // 32px
    color: cs.onPrimaryContainer,
  ),
)
```

**This is the most visible change** — Stitch clearly shows round circles, current app has rounded squares.

**Badge position and styling:** Current implementation is already correct (top-end positioned pill with primary color tint). Keep as-is.

**Card label:** `titleSmall`, `fontWeight: w600`, centered — already correct. Keep.

**Card container:** `GlassCard(onTap: onTap)` — keep, but verify the default padding is appropriate. Current uses default `EdgeInsets.all(AppSizes.md)`.

**Card background tint for badge cards:** Stitch shows cards with badges (Budgets, Goals) have a slightly green-tinted background compared to non-badge cards (Wallets, Categories). Add conditional tint:
```dart
tintColor: badge != null
    ? cs.primaryContainer.withValues(alpha: AppSizes.opacitySubtle)
    : null,
```
This gives badge cards a subtle green wash — matching Stitch where Budgets/Goals cards are slightly greener than Wallets/Categories.

### 4. "OPTIMIZATION" Section Label (NEW)
- **Stitch shows:** "OPTIMIZATION" in small caps above the insights card
- **Implementation:**
  ```dart
  Padding(
    padding: EdgeInsetsDirectional.only(start: xs, top: lg, bottom: sm),
    child: Text(
      context.l10n.hub_optimization_label.toUpperCase(),
      style: context.textStyles.labelSmall?.copyWith(
        color: cs.outline,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    ),
  )
  ```
- **L10n key:** `hub_optimization_label` — "Optimization" / "تحسين"

### 5. Saving Insights Card (NEW)
- **Stitch shows:** A card at the bottom with:
  - "Saving Insights" headline (titleMedium, bold)
  - Body text: "You could save an additional **$120/mo** by consolidating your streaming subscriptions." (bodySmall, muted, with bold amount)
  - Small chart/sparkle icon top-right of the card (decorative)
  - Two buttons at bottom: "View Details" (green filled pill) + "Dismiss" (text button)

- **Implementation:**
  ```dart
  GlassCard(
    showShadow: true,
    tintColor: cs.primaryContainer.withValues(alpha: AppSizes.opacitySubtle),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title row with decorative icon
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.hub_saving_insights_title,
                style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Icon(AppIcons.trendingUp, size: AppSizes.iconMd, color: cs.outline.withValues(alpha: opacityLight5)),
          ],
        ),
        SizedBox(height: sm),
        // Body text — Stitch shows "$120/mo" in bold within the sentence.
        // Use RichText with TextSpan for the bold portion:
        Text.rich(
          TextSpan(
            style: context.textStyles.bodySmall?.copyWith(color: cs.outline),
            children: [
              TextSpan(text: context.l10n.hub_saving_insights_prefix), // "You could save an additional "
              TextSpan(
                text: context.l10n.hub_saving_insights_amount, // "EGP 120/mo"
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: context.l10n.hub_saving_insights_suffix), // " by consolidating..."
            ],
          ),
        ),
        // NOTE: Alternatively, use a single l10n key with the amount embedded
        // and skip RichText if bold formatting isn't critical. Plain text is simpler.
        SizedBox(height: md),
        // Action buttons
        Row(
          children: [
            FilledButton(
              onPressed: () { /* TODO: navigate to insights detail */ },
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                shape: StadiumBorder(),
                padding: EdgeInsets.symmetric(horizontal: md, vertical: sm),
              ),
              child: Text(context.l10n.hub_view_details),
            ),
            SizedBox(width: sm),
            TextButton(
              onPressed: () { /* dismiss / hide card */ },
              child: Text(context.l10n.common_dismiss),
            ),
          ],
        ),
      ],
    ),
  )
  ```

- **Note:** This is a static/placeholder insight card for now. Real AI-driven insights can be wired later via the existing `backgroundAiProvider` system.

- **L10n keys needed:**
  - `hub_saving_insights_title` — "Saving Insights" / "نصائح التوفير"
  - `hub_saving_insights_body` — "You could save an additional $120/mo by consolidating your streaming subscriptions." / "يمكنك توفير ١٢٠ جنيه/شهر إضافية بدمج اشتراكات البث الخاصة بك." (single key version — simpler)
  - OR split into 3 keys for bold formatting:
    - `hub_saving_insights_prefix` — "You could save an additional " / "يمكنك توفير "
    - `hub_saving_insights_amount` — "EGP 120/mo" / "١٢٠ جنيه/شهر"
    - `hub_saving_insights_suffix` — " by consolidating your streaming subscriptions." / " إضافية بدمج اشتراكات البث الخاصة بك."
  - `hub_view_details` — "View Details" / "عرض التفاصيل"
  - `common_dismiss` — "Dismiss" / "تجاهل" (check if already exists)

---

## Design Tokens

| Property | Token |
|----------|-------|
| Icon circle size | `AppSizes.iconContainerXl` (56px) |
| Icon circle shape | `BoxShape.circle` (NOT borderRadiusMd) |
| Icon circle bg | `cs.primaryContainer.withValues(alpha: opacityLight4)` |
| Icon size | `AppSizes.iconLg` (32px) |
| Icon color | `cs.onPrimaryContainer` |
| Grid spacing | `AppSizes.md` (16) both axes — increased from sm (8) |
| Headline text | `displaySmall` or `headlineMedium` |
| Section label | `labelSmall`, uppercase, letterSpacing 1.5 |
| Insights button | `StadiumBorder()`, `cs.primary` bg |

---

## L10n Keys Needed

- `hub_headline` — "Curate your capital." / "نظّم رأس مالك."
- `hub_subtitle` — "Organize your financial future with precision and clarity" / "نظّم مستقبلك المالي بدقة ووضوح"
- `hub_optimization_label` — "Optimization" / "تحسين"
- `hub_saving_insights_title` — "Saving Insights" / "نصائح التوفير"
- `hub_saving_insights_body` — "You could save an additional EGP 120/mo by consolidating your streaming subscriptions." / "يمكنك توفير ١٢٠ جنيه/شهر إضافية بدمج اشتراكات البث الخاصة بك."
- `hub_view_details` — "View Details" / "عرض التفاصيل"
- `common_dismiss` — "Dismiss" / "تجاهل" (check if exists already)

---

## Structural Change: GridView → ListView + Wrap

The current `body` is a `GridView.count`. This must change to a `ListView` to support the editorial header above and insights card below the grid.

**Before:**
```dart
body: GridView.count(
  crossAxisCount: 2,
  ...
  children: items.map((_HubGridCard)).toList(),
)
```

**After:**
```dart
body: ListView(
  padding: EdgeInsets.symmetric(horizontal: screenHPadding, vertical: md),
  children: [
    // 1. Editorial header
    _EditorialHeader(),
    SizedBox(height: lg),
    // 2. Grid via Wrap
    LayoutBuilder(
      builder: (context, constraints) {
        // constraints.maxWidth already accounts for ListView's horizontal padding
        final cardWidth = (constraints.maxWidth - AppSizes.md) / 2;
        return Wrap(
          spacing: AppSizes.md,
          runSpacing: AppSizes.md,
          children: items.map((item) => SizedBox(
            width: cardWidth,
            child: _HubGridCard(...),
          )).toList(),
        );
      },
    ),
    SizedBox(height: lg),
    // 3. Optimization section
    _OptimizationLabel(),
    SizedBox(height: sm),
    _InsightsCard(),
    SizedBox(height: bottomScrollPadding),
  ],
)
```
**IMPORTANT:** Use `LayoutBuilder` to get the correct available width AFTER ListView padding is applied. Don't manually subtract `screenHPadding` — the ListView padding already handles it.

---

## Existing Code to Reuse

| What | Where |
|------|-------|
| `GlassCard` | `lib/shared/widgets/cards/glass_card.dart` |
| `AppAppBar` | `lib/shared/widgets/navigation/app_app_bar.dart` |
| `budgetsByMonthProvider` | `lib/shared/providers/budget_provider.dart` |
| `activeGoalsProvider` | `lib/shared/providers/goal_provider.dart` |
| Badge count logic | Already in `hub_screen.dart` — keep |

---

## What NOT to Change
- Badge logic (active budgets count, in-progress goals count) — keep
- `_HubCardData` model — keep
- Route navigation (`context.push(item.route)`) — keep
- AppConfig.kSmsEnabled conditional item — keep
- `showBack: false` on app bar — keep
