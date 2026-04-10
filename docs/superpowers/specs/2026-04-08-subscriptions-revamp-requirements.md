# Subscriptions & Bills Screen — Pixel-Perfect Requirements

**Reference:** Stitch screen `36ada30f21f349488a19e4f47fc96fe2`
**File:** `lib/features/recurring/presentation/screens/recurring_screen.dart`
**Current state:** Partially implemented — has summary card and section labels but visual design doesn't match Stitch.

---

## What's Wrong (Current App vs Stitch Design)

| Element | Stitch Design | Current App | Fix Required |
|---------|--------------|-------------|--------------|
| Summary card background | Subtle green gradient/tint, generous padding, elevated | Flat, no tint, cramped | Add gradient tint + more padding |
| Summary amount | "EGP 2,450" (large, no decimals) | "EGP27,000.00" (with decimals, no space) | Use `MoneyFormatter.formatAmount()` not `.format()` |
| "Due this week" badge | Orange dot + text, inside summary card below amount | Missing or not visible | Add as a Row with orange dot + text |
| Section labels | Dark green for active sections, red for overdue | Grey, not colored | Use semantic colors per section |
| Card accent bars | Thick (~6px), color matches section (coral/amber/green) | Thin (4px), all same blue/green color | Increase to 6px, use section-specific colors |
| Card icons | Colored circles matching brand/category (red for Netflix, purple for Spotify, green for Gym) | All grey/muted circles | Use category color for circle background, not muted |
| Card amount format | "EGP 250" (no sign prefix, no decimals) | "−2,000.00" (with sign, with decimals) | Show "EGP {amount}" format, no sign for bills |
| MARK PAID button | Red filled rounded pill with white text "MARK PAID" | Not visible (may be missing for bills with no overdue status) | Red filled pill button for overdue bills |
| Toggle switch position | Next to amount, vertically centered | Correct position but visually different | OK, keep current |
| Paid items | Strikethrough amount + green "✓ PAID" pill badge | Grey text with "PAID" text | Add green checkmark icon, make it a tinted pill |
| Insight cards | Two side-by-side cards at bottom: "POTENTIAL SAVINGS EGP 320/mo" (dark green bg, white text) + "SPENDING TREND +12.4%" | Completely missing | Add insight section at bottom |
| Card shape | Rounded cards with visible shadow, clear separation between cards | Cards exist but less pronounced | Increase shadow, add more vertical margin between cards |
| Section label style | Uppercase, letter-spaced, colored (green for active, red for overdue, grey for paid) | Uppercase but all grey | Color-code section labels |

---

## Exact Layout Specification (Top to Bottom)

### 1. App Bar
- Title: "Subscriptions & Bills" (l10n key exists)
- Actions: "View All" text button + "+" icon button
- No hamburger menu (use standard AppAppBar back/no-back)

### 2. Summary Card
- **Container:** `GlassCard` with `showShadow: true`
- **Background tint:** `cs.primaryContainer.withValues(alpha: 0.08)` — very subtle green wash, NOT flat white
- **Padding:** `EdgeInsets.all(AppSizes.lg)` (24px all around) — generous breathing room
- **Margin:** `EdgeInsets.symmetric(horizontal: screenHPadding, vertical: AppSizes.md)`
- **Content (Column, crossAxisAlignment: start):**
  - Line 1: "TOTAL MONTHLY SPEND" — `labelSmall`, uppercase, `letterSpacing: 1.2`, color `cs.outline`, fontWeight w600
  - SizedBox(height: AppSizes.sm)
  - Line 2: Amount — `displaySmall` (32sp), `fontWeight: w700`, `cs.onSurface` — use `MoneyFormatter.format(amount)` which shows "EGP 2,450" format
  - SizedBox(height: AppSizes.sm)
  - Line 3: Badge — a `Container` with `warningColor` at 12% opacity background, `borderRadiusFull`, horizontal padding sm, vertical padding xxs. Inside: `Row(mainAxisSize: min)` with:
    - Filled circle dot: `Container(width: 8, height: 8, decoration: BoxDecoration(shape: circle, color: warningColor))`
    - SizedBox(width: xs)
    - Text "3 due this week" — `labelSmall`, `warningColor`, fontWeight w600
  - Badge should only show when `dueThisWeek > 0`

### 3. Section Labels
- **Style:** `labelSmall`, uppercase, `letterSpacing: 1.5`, `fontWeight: w700`
- **Colors by section:**
  - ATTENTION REQUIRED (overdue): `theme.expenseColor` (coral red)
  - COMING SOON (upcoming): `cs.primary` (green)
  - ACTIVE SERVICES (active): `cs.primary` (green)
  - RECENTLY PAID: `cs.outline` (grey)
- **Padding:** `start: screenHPadding, top: AppSizes.lg, bottom: AppSizes.sm`

### 4. Subscription Cards
- **Container:** `GlassCard` with `showShadow: true`, `padding: EdgeInsets.zero`
- **Card background tint per section:**
  - Overdue cards: `tintColor: theme.expenseColor.withValues(alpha: 0.04)` — very subtle coral wash (visible in Stitch as pinkish card bg)
  - Upcoming cards: no extra tint (default glass)
  - Active cards: `tintColor: cs.primaryContainer.withValues(alpha: 0.04)` — very subtle green wash
  - Paid cards: no tint, but wrapped in `Opacity(opacity: 0.6)` for muted look
- **Margin:** `EdgeInsets.symmetric(horizontal: screenHPadding, vertical: AppSizes.sm)` — 8px vertical gap between cards
- **Structure:** `IntrinsicHeight` > `Row(crossAxisAlignment: stretch)`:

#### 4a. Left Accent Bar
- Width: **6px** (not 4px) — use a raw `6` or define constant
- Color: matches section (coral for overdue, amber for upcoming, green for active, grey for paid)
- Border radius: only top-start + bottom-start corners = `borderRadiusMd`

#### 4b. Card Body (inside Expanded > Padding)
- Padding: `EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.md)` — 16px all
- Row layout: [Icon] [Title Column] [Amount + Action Column]

#### 4c. Icon Circle
- Size: `iconContainerLg` (44px) — LARGER than current 40px
- Background: **category color at 15% opacity** (`catColor.withValues(alpha: AppSizes.opacityLight)`) — NOT grey/muted. Must use the actual category color.
- Icon: category icon, size `AppSizes.iconSm` (20), color = category color at full opacity
- If brand match: use `BrandLogo` at size `iconContainerLg` instead
- For overdue items: icon circle uses `theme.expenseColor` at 15% instead of category color
- Shape: `BoxShape.circle`

#### 4d. Title Column (Expanded, MainAxisAlignment.center)
- Line 1: Title — `bodyLarge` (16sp), `fontWeight: w600`, `maxLines: 1`, overflow ellipsis
- SizedBox(height: xxs)
- Line 2: Subtitle format: "{frequency} • {status}" where:
  - frequency = localized frequency label (e.g. "Monthly")
  - status depends on section:
    - Overdue: "Overdue" in `theme.expenseColor`
    - Upcoming bills: "Due {formatted date}" e.g. "Due Apr 15"
    - Active recurring: "Next bill {date}" e.g. "Next bill May 01"
    - Paid: "Paid {date} • Reference #{linkedTransactionId}" in `cs.outline`
  - Style: `bodySmall`, color `cs.outline` (unless overdue → `theme.expenseColor`)
  - Use bullet separator `\u2022` between parts

#### 4e. Amount + Action Column (CrossAxisAlignment.end, MainAxisAlignment.center)
- Amount: — `titleSmall` (14sp), `fontWeight: w700`
  - Format: `MoneyFormatter.format(rule.amount)` — shows "EGP 2,000" with currency prefix
  - Color: `typeColor` for active, `cs.outline` for paid
  - For paid: add `TextDecoration.lineThrough`
- SizedBox(height: AppSizes.xs)
- Action widget below amount:
  - **Overdue bills:** Red FILLED pill "MARK PAID" — `Container` with:
    - Background: `theme.expenseColor` (solid, NOT transparent)
    - Text: "MARK PAID" in `labelSmall`, `cs.onError` (white), fontWeight w700, uppercase
    - Padding: `EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xxs)`
    - Border radius: `borderRadiusFull`
    - On tap: confirm dialog → payBill
  - **Active recurring (not bill):** `Switch.adaptive` toggle with `materialTapTargetSize: shrinkWrap`
  - **Upcoming bills (not overdue):** `Switch.adaptive` toggle (same as active)
  - **Paid items:** Green tinted pill: `Container` with `incomeColor` at 12% bg, Row with:
    - `Icon(AppIcons.check, size: iconXxs, color: incomeColor)`
    - SizedBox(width: xxs)
    - Text "PAID" in `labelSmall`, `incomeColor`, fontWeight w600, uppercase
    - Padding + borderRadiusFull

### 5. Insight Cards (Bottom of List)
Two cards side by side in a `Row` at the bottom:

#### 5a. "POTENTIAL SAVINGS" Card
- Background: `cs.primary` (solid dark green)
- Border radius: `borderRadiusMd`
- Padding: `AppSizes.md`
- Content:
  - Piggy bank icon (top-left) — `AppIcons.savingsTransfer`, white, iconMd
  - "POTENTIAL SAVINGS" — `labelSmall`, white, uppercase, letterSpacing 1.0
  - "EGP 320/mo" — `titleMedium`, white, bold
- Width: Expanded (flex 1)

#### 5b. "SPENDING TREND" Card  
- Background: `cs.primary` (solid dark green)
- Border radius: `borderRadiusMd`
- Padding: `AppSizes.md`
- Content:
  - Chart icon (top-right) — `AppIcons.trendingUp`, white with opacity
  - "SPENDING TREND" — `labelSmall`, white, uppercase
  - "+12.4%" — `titleMedium`, white, bold
- Width: Expanded (flex 1)

- **Row:** `spacing: AppSizes.sm` between the two cards
- **Margin:** `EdgeInsets.symmetric(horizontal: screenHPadding, vertical: AppSizes.md)`
- **Note:** These can show hardcoded placeholder data for now — actual calculation can come later

### 6. Slidable Actions (Keep Current)
- Swipe right: Edit (transfer color)
- Swipe left: Delete (expense color)
- `extentRatio: 0.25`, `BehindMotion`

### 7. Stagger Animation (Keep Current)
- `fadeIn` + `slideY(0.03)` with stagger delay per item
- Skip if `reduceMotion` is true

---

## Design Tokens to Use

| Property | Token |
|----------|-------|
| Screen padding | `AppSizes.screenHPadding` (16) |
| Card radius | `AppSizes.borderRadiusMd` (16) |
| Icon circle size | `AppSizes.iconContainerLg` (44) |
| Icon size inside circle | `AppSizes.iconSm` (20) |
| Accent bar width | 6 (define as local constant) |
| Card vertical gap | `AppSizes.sm` (8) |
| Summary card padding | `AppSizes.lg` (24) |
| Section label spacing | letter-spacing 1.5 |
| Amount format | `MoneyFormatter.format(amount)` |
| Overdue color | `theme.expenseColor` |
| Upcoming color | `theme.warningColor` |
| Active color | `theme.incomeColor` or `cs.primary` |
| Paid color | `cs.outline` |

---

## L10n Keys Needed (check if they exist, add if missing)

- `recurring_total_monthly_spend` — "TOTAL MONTHLY SPEND" / "الإنفاق الشهري الإجمالي"
- `recurring_attention_required` — "ATTENTION REQUIRED" / "يتطلب الانتباه"
- `recurring_coming_soon` — "COMING SOON" / "قادم قريباً"
- `recurring_active_services` — "ACTIVE SERVICES" / "خدمات نشطة"
- `recurring_recently_paid` — "RECENTLY PAID" / "مدفوع مؤخراً"
- `recurring_potential_savings` — "POTENTIAL SAVINGS" / "وفورات محتملة"
- `recurring_spending_trend` — "SPENDING TREND" / "اتجاه الإنفاق"

---

## Existing Code to Reuse (DO NOT reinvent)

| What | Where | How to use |
|------|-------|-----------|
| GlassCard widget | `lib/shared/widgets/cards/glass_card.dart` | `GlassCard(showShadow: true, tintColor: ..., child: ...)` |
| BrandLogo widget | `lib/shared/widgets/cards/brand_logo.dart` | `BrandLogo(brand: BrandRegistry.match(title), size: ...)` |
| Brand matching | `lib/core/constants/brand_registry.dart` | `BrandRegistry.match(rule.title)` returns `BrandInfo?` |
| Category icon resolver | `lib/core/utils/category_icon_mapper.dart` | `CategoryIconMapper.fromName(cat.iconName)` |
| Color from hex | `lib/core/utils/color_utils.dart` | `ColorUtils.fromHex(cat.colorHex)` |
| Money formatting | `lib/core/utils/money_formatter.dart` | `MoneyFormatter.format(amount)` for "EGP 2,450", `formatAmount(amount)` for just "2,450" |
| Frequency label | `lib/core/extensions/frequency_label_extension.dart` | `context.l10n.frequencyLabel(rule.frequency)` |
| ConfirmDialog | `lib/shared/widgets/feedback/confirm_dialog.dart` | `ConfirmDialog.show(context, ...)` and `ConfirmDialog.confirmDelete(...)` |
| SnackHelper | `lib/shared/widgets/feedback/snack_helper.dart` | `SnackHelper.showSuccess(context, msg)` |
| AppAppBar | `lib/shared/widgets/navigation/app_app_bar.dart` | `AppAppBar(title: ..., actions: [...])` |
| payBill method | `recurringRuleRepositoryProvider` | `ref.read(recurringRuleRepositoryProvider).payBill(ruleId: ..., walletId: ..., categoryId: ..., amount: ..., type: ..., title: ...)` |
| Cancel notification | `notificationTriggerServiceProvider` | `ref.read(notificationTriggerServiceProvider).cancelBillReminder(rule.id)` |
| Invalidate list | `recurringRulesProvider` | `ref.invalidate(recurringRulesProvider)` after mutations |
| RecurringRuleEntity helpers | entity file | `rule.isOverdue`, `rule.isBill`, `rule.isActive`, `rule.isPaid` |

---

## Empty State (Keep Current)
When `rules.isEmpty`, show:
```dart
EmptyState(
  title: context.l10n.recurring_and_bills_title,
  subtitle: context.l10n.recurring_empty_sub,
  ctaLabel: context.l10n.recurring_add,
  onCta: () => AddRecurringScreen.show(context),
)
```

---

## What NOT to Change
- Slidable edit/delete gestures — keep exact same implementation
- Stagger animation — keep exact same implementation  
- ConfirmDialog usage for toggle/delete — keep exact same implementation
- Mark Paid business logic (payBill + cancelBillReminder + invalidate) — keep exact same implementation
- The `ConsumerStatefulWidget` with `_viewAll` state toggle — keep
