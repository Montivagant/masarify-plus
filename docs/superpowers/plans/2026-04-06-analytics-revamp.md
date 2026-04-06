# Analytics Feature Revamp — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete redesign of the 3-tab analytics (Reports) feature — new per-tab filters with custom date range, richer Overview/Categories/Trends tabs with modern charts, insight cards, spending heatmap, and velocity tracking. Fixes the Overview default-showing-expenses-only bug.

**Architecture:** Each tab gets its own filter state (time period + type + wallet) instead of the current global filter bar. New providers handle per-tab filter state and custom date ranges. Existing `monthlyTotalsProvider`, `categoryBreakdownProvider`, and `dailySpendingProvider` are extended with date-range support. New widgets: `TabFilterRow`, `DateRangePickerSheet`, `InsightCard`, `SpendingHeatmap`, `SpendingVelocityChart`.

**Tech Stack:** Flutter/Dart, Riverpod 2.x, fl_chart 0.69, Drift (SQLite), Material Design 3

**Design Reference:** Stitch project `11551203136628161887` — 3 screens generated with Gemini 3.1 Pro ("Masarify Mint" design system)

---

## File Map

### New Files
| File | Responsibility |
|------|---------------|
| `lib/features/reports/presentation/widgets/tab_filter_row.dart` | Per-tab horizontal filter chip row (time presets, custom date, type toggle, account) |
| `lib/features/reports/presentation/widgets/date_range_sheet.dart` | Bottom sheet with calendar date range picker + quick presets |
| `lib/features/reports/presentation/widgets/insight_card.dart` | Glassmorphic insight banner with icon + text |
| `lib/features/reports/presentation/widgets/spending_heatmap.dart` | GitHub-style 5x7 calendar heatmap (Trends tab) |
| `lib/features/reports/presentation/widgets/spending_velocity_chart.dart` | Cumulative area chart with projection line (Trends tab) |

### Modified Files
| File | Changes |
|------|---------|
| `lib/shared/providers/analytics_provider.dart` | New per-tab filter providers, custom date range support, new data models |
| `lib/features/reports/presentation/screens/reports_screen.dart` | Remove global ReportsFilterBar, simplify to just tabs |
| `lib/features/reports/presentation/widgets/overview_tab.dart` | Complete rewrite — net cash flow hero, sparkline, income/expense cards, bar chart, insight banner, 2x2 grid |
| `lib/features/reports/presentation/widgets/categories_tab.dart` | Complete rewrite — per-tab filters, income/expense toggle, donut chart, ranked list with budget markers + deltas |
| `lib/features/reports/presentation/widgets/trends_tab.dart` | Complete rewrite — area chart with comparison line, velocity chart, heatmap, weekly breakdown |
| `lib/features/reports/presentation/widgets/reports_filter_bar.dart` | DELETE this file (replaced by per-tab TabFilterRow) |
| `lib/core/constants/app_sizes.dart` | New analytics constants |
| `lib/core/constants/app_durations.dart` | Heatmap/chart animation durations |
| `lib/l10n/app_en.arb` | ~30 new l10n keys |
| `lib/l10n/app_ar.arb` | Arabic translations |

### Reuse (DO NOT recreate)
| File | What to reuse |
|------|--------------|
| `lib/shared/widgets/cards/glass_card.dart` | `GlassCard(tier: .inset/.card)` for all cards |
| `lib/shared/widgets/lists/empty_state.dart` | `EmptyState` for no-data states |
| `lib/core/utils/money_formatter.dart` | `MoneyFormatter.format()`, `.formatAmount()`, `.formatCompact()` |
| `lib/core/utils/color_utils.dart` | `ColorUtils.fromHex()` for category colors |
| `lib/domain/repositories/i_transaction_repository.dart` | `sumByTypeAndMonth()`, `getByDateRange()` — already available |

---

## Task 1: Foundation — New Constants, L10n Strings, Provider Infrastructure

**Files:**
- Modify: `lib/core/constants/app_sizes.dart`
- Modify: `lib/core/constants/app_durations.dart`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`
- Modify: `lib/shared/providers/analytics_provider.dart`

### Step 1.1: Add analytics constants to AppSizes

- [ ] Add after the `aiThinkingTextHeight` line in `app_sizes.dart`:

```dart
  // ── Analytics / Reports ──────────────────────────────────────────
  static const double sparklineHeight = 40.0;
  static const double heatmapCellSize = 20.0;
  static const double heatmapCellGap = 3.0;
  static const double heatmapCellRadius = 4.0;
  static const double velocityChartHeight = 160.0;
  static const double weeklyBarHeight = 28.0;
  static const double insightCardIconSize = 36.0;
  static const double donutChartSize = 180.0;
  static const double donutCenterRadius = 55.0;
  static const double categoryProgressHeight = 6.0;
```

- [ ] Add animation durations to `app_durations.dart` after the voice section:

```dart
  // Analytics
  static const Duration chartMorph = Duration(milliseconds: 300);
```

### Step 1.2: Add all l10n strings

- [ ] Add to `app_en.arb` before the closing `}`:

```json
  "reports_net_cash_flow": "Net Cash Flow",
  "reports_vs_last_month_pct": "{arrow} {pct}% vs last month",
  "@reports_vs_last_month_pct": { "placeholders": { "arrow": { "type": "String" }, "pct": { "type": "int" } } },
  "reports_this_month": "This Month",
  "reports_last_month": "Last Month",
  "reports_3_months": "3 Months",
  "reports_6_months": "6 Months",
  "reports_custom": "Custom...",
  "reports_all_types": "All",
  "reports_clear_filters": "Clear",
  "reports_income_by_category": "Income by Category",
  "reports_spending_by_category": "Spending by Category",
  "reports_category_count": "{count} categories",
  "@reports_category_count": { "placeholders": { "count": { "type": "int" } } },
  "reports_budget_label": "Budget: {amount}",
  "@reports_budget_label": { "placeholders": { "amount": { "type": "String" } } },
  "reports_insight_savings": "You saved {rate}% of your income this month — {qualifier}!",
  "@reports_insight_savings": { "placeholders": { "rate": { "type": "int" }, "qualifier": { "type": "String" } } },
  "reports_insight_best_rate": "your best rate in 3 months",
  "reports_insight_good_rate": "keep it up",
  "reports_total_expenses_period": "Total Expenses",
  "reports_total_income_period": "Total Income",
  "reports_vs_previous_pct": "{arrow} {pct}% vs previous period",
  "@reports_vs_previous_pct": { "placeholders": { "arrow": { "type": "String" }, "pct": { "type": "String" } } },
  "reports_spending_pace": "Spending Pace",
  "reports_pace_label": "Avg {amount}/day — projected {projected} by month end",
  "@reports_pace_label": { "placeholders": { "amount": { "type": "String" }, "projected": { "type": "String" } } },
  "reports_daily_activity": "Daily Activity",
  "reports_weekly_breakdown": "Weekly Breakdown",
  "reports_week_n": "Week {n}",
  "@reports_week_n": { "placeholders": { "n": { "type": "int" } } },
  "reports_current_period": "Current Period",
  "reports_previous_period": "Previous Period",
  "reports_lowest_day": "Lowest Day",
  "reports_transactions_count": "Transactions",
  "reports_net_label": "Net",
  "reports_last_6_months": "Last 6 Months",
  "reports_date_range": "{start} - {end}",
  "@reports_date_range": { "placeholders": { "start": { "type": "String" }, "end": { "type": "String" } } },
  "reports_select_range": "Select Date Range",
  "reports_quick_presets": "Quick Presets",
  "reports_last_7_days": "Last 7 Days",
  "reports_last_30_days": "Last 30 Days",
  "reports_this_quarter": "This Quarter",
  "reports_last_quarter": "Last Quarter",
  "reports_apply": "Apply"
```

- [ ] Add equivalent Arabic strings to `app_ar.arb`:

```json
  "reports_net_cash_flow": "صافي التدفق النقدي",
  "reports_vs_last_month_pct": "{arrow} {pct}% مقارنة بالشهر الماضي",
  "@reports_vs_last_month_pct": { "placeholders": { "arrow": { "type": "String" }, "pct": { "type": "int" } } },
  "reports_this_month": "هذا الشهر",
  "reports_last_month": "الشهر الماضي",
  "reports_3_months": "3 أشهر",
  "reports_6_months": "6 أشهر",
  "reports_custom": "مخصص...",
  "reports_all_types": "الكل",
  "reports_clear_filters": "مسح",
  "reports_income_by_category": "الدخل حسب الفئة",
  "reports_spending_by_category": "المصاريف حسب الفئة",
  "reports_category_count": "{count} فئة",
  "@reports_category_count": { "placeholders": { "count": { "type": "int" } } },
  "reports_budget_label": "الميزانية: {amount}",
  "@reports_budget_label": { "placeholders": { "amount": { "type": "String" } } },
  "reports_insight_savings": "وفرت {rate}% من دخلك هذا الشهر — {qualifier}!",
  "@reports_insight_savings": { "placeholders": { "rate": { "type": "int" }, "qualifier": { "type": "String" } } },
  "reports_insight_best_rate": "أفضل معدل في 3 أشهر",
  "reports_insight_good_rate": "استمر",
  "reports_total_expenses_period": "إجمالي المصاريف",
  "reports_total_income_period": "إجمالي الدخل",
  "reports_vs_previous_pct": "{arrow} {pct}% مقارنة بالفترة السابقة",
  "@reports_vs_previous_pct": { "placeholders": { "arrow": { "type": "String" }, "pct": { "type": "String" } } },
  "reports_spending_pace": "وتيرة الإنفاق",
  "reports_pace_label": "متوسط {amount}/يوم — متوقع {projected} بنهاية الشهر",
  "@reports_pace_label": { "placeholders": { "amount": { "type": "String" }, "projected": { "type": "String" } } },
  "reports_daily_activity": "النشاط اليومي",
  "reports_weekly_breakdown": "التفصيل الأسبوعي",
  "reports_week_n": "الأسبوع {n}",
  "@reports_week_n": { "placeholders": { "n": { "type": "int" } } },
  "reports_current_period": "الفترة الحالية",
  "reports_previous_period": "الفترة السابقة",
  "reports_lowest_day": "أقل يوم",
  "reports_transactions_count": "المعاملات",
  "reports_net_label": "الصافي",
  "reports_last_6_months": "آخر 6 أشهر",
  "reports_date_range": "{start} - {end}",
  "@reports_date_range": { "placeholders": { "start": { "type": "String" }, "end": { "type": "String" } } },
  "reports_select_range": "اختر نطاق التاريخ",
  "reports_quick_presets": "اختيارات سريعة",
  "reports_last_7_days": "آخر 7 أيام",
  "reports_last_30_days": "آخر 30 يوم",
  "reports_this_quarter": "هذا الربع",
  "reports_last_quarter": "الربع الماضي",
  "reports_apply": "تطبيق"
```

- [ ] Run: `flutter gen-l10n`

### Step 1.3: Restructure analytics providers

- [ ] Rewrite `lib/shared/providers/analytics_provider.dart` with per-tab filter architecture:

**Key changes:**
- Keep existing `reportsWalletFilterProvider` and `reportsTypeFilterProvider` (used by old code — keep for backwards compat during migration, remove at end)
- Add new per-tab filter state classes and providers
- Add `DateRange` helper class for custom date ranges
- Add `overviewFilterProvider`, `categoriesFilterProvider`, `trendsFilterProvider` — each a `StateNotifierProvider` holding its own time/type/wallet state
- Extend `monthlyTotalsProvider` to support custom date ranges
- Add `previousPeriodDailyProvider` for comparison lines in Trends
- Add `weeklyBreakdownProvider` for weekly bars in Trends
- Keep existing `MonthlyTotal`, `CategorySpending`, `DailySpending` data classes unchanged

**New data model:**
```dart
class ReportFilter {
  final String timePreset; // 'this_month', 'last_month', '3_months', '6_months', 'custom'
  final String typeFilter; // 'all', 'expense', 'income'
  final int? walletId;
  final DateTime? customStart;
  final DateTime? customEnd;
}
```

**New providers:**
```dart
// Per-tab filters
final overviewFilterProvider = StateNotifierProvider<ReportFilterNotifier, ReportFilter>(...);
final categoriesFilterProvider = StateNotifierProvider<ReportFilterNotifier, ReportFilter>(...);
final trendsFilterProvider = StateNotifierProvider<ReportFilterNotifier, ReportFilter>(...);

// Derived date ranges from filter
final overviewDateRangeProvider = Provider<(DateTime start, DateTime end)>(...);
final categoriesDateRangeProvider = Provider<(DateTime start, DateTime end)>(...);
final trendsDateRangeProvider = Provider<(DateTime start, DateTime end)>(...);
```

- [ ] Run: `flutter analyze lib/shared/providers/analytics_provider.dart` — expect zero errors

### Step 1.4: Commit foundation

- [ ] `git add -A && git commit -m "feat(analytics): add foundation — constants, l10n, per-tab filter providers"`

---

## Task 2: Shared Widgets — TabFilterRow, DateRangeSheet, InsightCard

**Files:**
- Create: `lib/features/reports/presentation/widgets/tab_filter_row.dart`
- Create: `lib/features/reports/presentation/widgets/date_range_sheet.dart`
- Create: `lib/features/reports/presentation/widgets/insight_card.dart`

### Step 2.1: Build TabFilterRow widget

- [ ] Create `tab_filter_row.dart` — A horizontal scrollable row of Material 3 `FilterChip` widgets.

**Props:**
```dart
class TabFilterRow extends ConsumerWidget {
  const TabFilterRow({super.key, required this.filterProvider});
  final StateNotifierProvider<ReportFilterNotifier, ReportFilter> filterProvider;
}
```

**Structure:**
- Reads the filter provider to get current state
- Renders horizontal `SingleChildScrollView` with `Row`:
  - Time chips: "This Month", "Last Month", "3 Months", "6 Months"
    - Each is a `FilterChip(selected: filter.timePreset == preset)`
    - Tapping sets the timePreset via notifier
  - "Custom..." chip — tapping opens `DateRangeSheet` via `showModalBottomSheet`
    - If custom is active, chip label shows formatted date range instead of "Custom..."
  - Separator `SizedBox(width: sm)`
  - Type chips: "All", "Expenses", "Income"
    - `FilterChip(selected: filter.typeFilter == type)`
  - Account chip: `FilterChip` showing wallet name or "All Accounts"
    - Tapping shows dropdown menu of wallets
  - If any non-default filter active: "Clear" `TextButton` at end
- All chips use `visualDensity: VisualDensity.compact`
- Selected chips use `selectedColor: cs.primary`, unselected `backgroundColor: cs.surfaceContainerHighest`
- Wrap in `Padding(horizontal: screenHPadding, vertical: xs)`

### Step 2.2: Build DateRangeSheet

- [ ] Create `date_range_sheet.dart` — A modal bottom sheet with Flutter's `DateRangePickerDialog`.

**Props:**
```dart
class DateRangeSheet extends StatefulWidget {
  const DateRangeSheet({super.key, this.initialStart, this.initialEnd});
  final DateTime? initialStart;
  final DateTime? initialEnd;
  // Returns (start, end) via Navigator.pop
}
```

**Structure:**
- `DraggableScrollableSheet` with drag handle
- Title: `reports_select_range`
- Quick presets row: "Last 7 Days", "Last 30 Days", "This Quarter", "Last Quarter"
  - Each is a `ListTile` or `ActionChip` that sets the range and pops
- Below presets: embedded `CalendarDatePicker` or use `showDateRangePicker()` from Material
  - Actually, use Flutter's built-in `showDateRangePicker()` triggered from the "Custom..." chip directly — simpler than building a custom sheet
  - Fall back: if `showDateRangePicker` doesn't fit the design, build a sheet with two `CalendarDatePicker` widgets (start, end) + Apply button

**Decision:** Use `showDateRangePicker()` for the actual calendar. The sheet only shows quick presets. This is simpler and uses proven Material widgets.

### Step 2.3: Build InsightCard

- [ ] Create `insight_card.dart`:

```dart
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.text, this.icon});
  final String text;
  final IconData? icon;
}
```

**Structure:**
- `GlassCard(tier: GlassTier.inset)` with primary color tint
- Row: Phosphor lightbulb icon (or custom icon) + text
- Text styled `bodyMedium`, icon colored `primary`
- Padding: `md` all around

### Step 2.4: Commit shared widgets

- [ ] `git add -A && git commit -m "feat(analytics): add TabFilterRow, DateRangeSheet, InsightCard widgets"`

---

## Task 3: Overview Tab — Complete Redesign

**Files:**
- Rewrite: `lib/features/reports/presentation/widgets/overview_tab.dart`

### Step 3.1: Rewrite OverviewTab

- [ ] Complete rewrite of `overview_tab.dart`. Key changes from current:

**Bug fix:** Currently shows "Total Expense" hero by default even when no type filter is selected. New design shows "Net Cash Flow" (income - expense) as the default hero metric.

**New structure (top to bottom):**

1. `TabFilterRow(filterProvider: overviewFilterProvider)` — per-tab filters
2. `_HeroCard` — Glassmorphic card with:
   - Label: "Net Cash Flow" (or "Total Expenses"/"Total Income" when type-filtered)
   - Large number: formatted net/income/expense based on filter
   - Delta badge: percentage vs previous period
   - Mini sparkline area chart (~40dp) showing daily trend
3. `_IncomeExpenseRow` — Two side-by-side `GlassCard(tier: inset)`:
   - Left: Income with icon, amount, delta badge
   - Right: Expense with icon, amount, delta badge
4. `_BarChartSection` — "Income vs. Expenses · Last 6 Months"
   - Reuse existing `_IncomeExpenseBarChart` logic but update to read from overview filter
   - Below chart: `_ChartLegend` row with income/expense dots
5. `InsightCard` — Savings rate insight (conditional, only if savingsRate > 0)
6. `_SummaryGrid` — 2x2 grid:
   - Daily Average, Highest Day (new!), Savings Rate, Transactions count (new!)

**Provider reads:**
- `ref.watch(overviewFilterProvider)` — get current filter state
- `ref.watch(monthlyTotalsProvider(months))` — bar chart data
- Compute sparkline from last 30 days of `dailySpendingProvider`
- Compute transaction count from `transactionsByMonthProvider`

**Sparkline implementation:**
- Reuse `LineChart` from fl_chart with minimal config (no axes, no grid, no tooltips)
- Just a smooth curved line with area fill below
- Height: `AppSizes.sparklineHeight` (40dp)
- Color: primary for net, income/expense color when filtered

### Step 3.2: Verify Overview tab

- [ ] Run: `flutter analyze lib/features/reports/` — zero new warnings
- [ ] Manual verify: hot reload, check Overview tab shows "Net Cash Flow" by default

### Step 3.3: Commit

- [ ] `git add -A && git commit -m "feat(analytics): redesign Overview tab — net cash flow hero, sparkline, insight card, 2x2 grid"`

---

## Task 4: Categories Tab — Complete Redesign

**Files:**
- Rewrite: `lib/features/reports/presentation/widgets/categories_tab.dart`

### Step 4.1: Rewrite CategoriesTab

- [ ] Complete rewrite. Key changes:

**New features:**
- Per-tab filter with Income/Expense toggle (type filter switches between expense and income categories)
- Budget marker on progress bars
- Delta badges (vs last month) per category
- Better donut chart with center total

**New structure:**

1. `TabFilterRow(filterProvider: categoriesFilterProvider)` — filter with Expenses/Income toggle
2. `_HeroSection` — "Spending by Category" or "Income by Category" (dynamic based on type filter)
   - Large total, subtitle with month + category count
3. `_DonutChart` — Centered donut:
   - `PieChart` with `centerSpaceRadius: AppSizes.donutCenterRadius`
   - Center: formatted total amount
   - Segments colored by category `colorHex`
   - Size: `AppSizes.donutChartSize`
   - Below: horizontal legend row
4. `_CategoryRankedList` — For each category:
   - `GlassCard(tier: inset)` or `Padding` row
   - Left: colored circle icon container with category icon
   - Middle: name, amount, progress bar with budget marker
   - Right: percentage (bold, category-colored), delta badge vs last month
5. `InsightCard` — "Food & Dining is your #1 category — up 5% from last month"

**Delta calculation:** For each category, compute `(currentAmount - previousMonthAmount) / previousMonthAmount * 100`. Need to call `categoryBreakdownProvider` for previous month too.

**Budget marker:** Read `budgetsByMonthProvider` for the selected month. For categories with budgets, show a thin vertical line on the progress bar at `budgetLimit / totalExpense` position.

### Step 4.2: Verify Categories tab

- [ ] Run: `flutter analyze lib/features/reports/` — zero new warnings
- [ ] Manual verify: toggle between Expenses and Income views

### Step 4.3: Commit

- [ ] `git add -A && git commit -m "feat(analytics): redesign Categories tab — income/expense toggle, donut chart, ranked list with budget markers"`

---

## Task 5: Trends Tab — Complete Redesign with New Chart Widgets

**Files:**
- Create: `lib/features/reports/presentation/widgets/spending_heatmap.dart`
- Create: `lib/features/reports/presentation/widgets/spending_velocity_chart.dart`
- Rewrite: `lib/features/reports/presentation/widgets/trends_tab.dart`

### Step 5.1: Build SpendingHeatmap widget

- [ ] Create `spending_heatmap.dart`:

```dart
class SpendingHeatmap extends StatelessWidget {
  const SpendingHeatmap({super.key, required this.dailyData});
  final List<DailySpending> dailyData;
}
```

**Structure:**
- Title: "Daily Activity" with `AppIcons.calendar`
- 5 rows (weeks) x 7 columns (days) grid using `Wrap` or `Column` of `Row`s
- Day labels: S M T W T F S across top
- Each cell: `Container` with `borderRadius: heatmapCellRadius`
- Color: interpolate between `surfaceContainerHighest` (low/zero spending) → `primary` (medium) → `expenseColor` (high)
  - Use `Color.lerp` with normalized amount (0-1 scale based on max day)
- Cell size: `AppSizes.heatmapCellSize` with `heatmapCellGap` spacing
- Tooltip on tap: show date + amount (use `Tooltip` widget)

### Step 5.2: Build SpendingVelocityChart widget

- [ ] Create `spending_velocity_chart.dart`:

```dart
class SpendingVelocityChart extends StatelessWidget {
  const SpendingVelocityChart({
    super.key,
    required this.dailyData,
    required this.isIncome,
  });
  final List<DailySpending> dailyData;
  final bool isIncome;
}
```

**Structure:**
- Title: "Spending Pace"
- `LineChart` with:
  - Actual cumulative line (solid, expense/income color)
  - Projected line (dashed gray, extends from current day to month end at current rate)
  - X-axis: Day 1 to Day 30
  - Y-axis: Cumulative total
- Below chart: label text "Avg EGP X/day — projected EGP Y by month end"
- Cumulative calculation: `spots[i] = spots[i-1] + dailyData[i].amount`
- Projection: linear extrapolation from current avg rate

### Step 5.3: Rewrite TrendsTab

- [ ] Complete rewrite. Key changes:

**New structure:**

1. `TabFilterRow(filterProvider: trendsFilterProvider)` — with 7d/30d/90d/Custom presets and Expenses/Income/Net toggle
2. `_HeroMetric` — large total + delta badge (smart coloring: expense decrease = green, income decrease = red)
3. `_MainAreaChart` — Area chart with:
   - Smooth curved line in expense/income color
   - Gradient area fill below (15% opacity)
   - **Comparison dashed line** for previous period (gray)
   - X-axis: date labels every 7 days
   - Y-axis: amount labels
   - Legend: "Current Period" solid + "Previous Period" dashed
   - Tooltip example at one data point
4. `SpendingVelocityChart(dailyData: data, isIncome: isIncome)` — cumulative pace
5. `_SummaryRow` — 3 cards: Daily Average, Highest Day, Lowest Day (new!)
6. `SpendingHeatmap(dailyData: data)` — GitHub-style grid
7. `_WeeklyBreakdown` — 4 horizontal bars (Week 1-4)
   - Each bar: `Container` with width proportional to amount, coral/green color
   - Current week bar highlighted (primary)

**Comparison line data:** Call `dailySpendingProvider` for the previous period too. For "Last 30 days", the previous period is the 30 days before that. Overlay both on the same chart axes.

### Step 5.4: Verify Trends tab

- [ ] Run: `flutter analyze lib/features/reports/` — zero new warnings

### Step 5.5: Commit

- [ ] `git add -A && git commit -m "feat(analytics): redesign Trends tab — area chart with comparison, velocity, heatmap, weekly bars"`

---

## Task 6: Wire Everything Up — ReportsScreen + Cleanup

**Files:**
- Modify: `lib/features/reports/presentation/screens/reports_screen.dart`
- Delete: `lib/features/reports/presentation/widgets/reports_filter_bar.dart`

### Step 6.1: Update ReportsScreen

- [ ] Remove `ReportsFilterBar()` from the screen body (line 42 of current file)
- [ ] Remove import of `reports_filter_bar.dart`
- [ ] The `Column` wrapping `ReportsFilterBar` + `TabBarView` simplifies to just `TabBarView` filling the body
- [ ] Each tab now contains its own `TabFilterRow` at the top — no shared filter

### Step 6.2: Delete old filter bar

- [ ] Delete `lib/features/reports/presentation/widgets/reports_filter_bar.dart`
- [ ] Remove old per-provider state references (`reportsWalletFilterProvider`, `reportsTypeFilterProvider`) IF no other files depend on them
  - Search: `grep -r "reportsWalletFilterProvider\|reportsTypeFilterProvider" lib/` — if only analytics_provider.dart references them, remove
  - If other files reference them, keep as deprecated aliases

### Step 6.3: Run gen-l10n + full analyze

- [ ] Run: `flutter gen-l10n`
- [ ] Run: `flutter analyze lib/` — expect only the pre-existing notification_preferences warning
- [ ] Verify all 3 tabs work with hot reload

### Step 6.4: Final commit

- [ ] `git add -A && git commit -m "feat(analytics): wire up tabs, remove global filter bar, complete analytics revamp"`

---

## Verification Checklist

After all tasks complete, verify:

- [ ] **Overview tab**: Shows "Net Cash Flow" by default (not just Expenses) — BUG FIXED
- [ ] **Overview tab**: Sparkline renders below hero number
- [ ] **Overview tab**: Income and Expense side-by-side cards with delta badges
- [ ] **Overview tab**: Bar chart shows 6 months of grouped income/expense bars
- [ ] **Overview tab**: Insight banner shows savings rate
- [ ] **Overview tab**: 2x2 summary grid with Daily Avg, Highest Day, Savings Rate, Transactions
- [ ] **Categories tab**: Per-tab filter with Expenses/Income toggle
- [ ] **Categories tab**: Switching to "Income" shows income categories
- [ ] **Categories tab**: Donut chart with center total
- [ ] **Categories tab**: Ranked list with progress bars, budget markers, delta badges
- [ ] **Trends tab**: Area chart with comparison (previous period) dashed line
- [ ] **Trends tab**: Spending Velocity/Pace cumulative chart with projection
- [ ] **Trends tab**: GitHub-style heatmap showing daily intensity
- [ ] **Trends tab**: Weekly breakdown horizontal bars
- [ ] **All tabs**: Per-tab filter row with time presets + "Custom..." date range
- [ ] **All tabs**: "Custom..." opens date range picker and applies to that tab only
- [ ] **All tabs**: Account (wallet) filter per tab
- [ ] **RTL**: All layouts mirror correctly in Arabic
- [ ] **Dark mode**: All colors use semantic tokens (context.colors, context.appTheme)
- [ ] **Empty states**: All tabs handle zero-data gracefully
- [ ] `flutter analyze lib/` — zero new warnings
