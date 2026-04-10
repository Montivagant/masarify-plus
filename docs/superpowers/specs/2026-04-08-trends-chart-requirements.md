# Trends Tab — Total Expenses Chart Dimension Fix

**File:** `lib/features/reports/presentation/widgets/trends_tab.dart`
**Issue:** Total Expenses chart has tight internal padding and X-axis date labels can overlap on narrow screens.

---

## Only 2 Things to Fix

### 1. GlassCard Internal Padding — Too Tight

**Current (line ~193):**
```dart
padding: const EdgeInsets.all(AppSizes.sm),  // 8px uniform — chart touches edges
```

**Fix — match the velocity chart's padding pattern:**
```dart
padding: const EdgeInsetsDirectional.fromSTEB(
  AppSizes.sm,    // 8px start — keeps chart data area wide
  AppSizes.md,    // 16px top — breathing room above chart line
  AppSizes.md,    // 16px end — prevents rightmost data point touching card edge
  AppSizes.sm,    // 8px bottom — room for X-axis labels below the chart line
),
```

### 2. X-Axis Date Labels — Can Overlap

**Current (inside `_MainAreaChart`, lines ~397-417):**
```dart
interval: data.length <= 14 ? 3 : (data.length <= 31 ? 7 : 14),
reservedSize: 24,
// labels use DateFormat('M/d') which produces "4/14" — 3-5 chars wide
```

**Fix — use explicit filtering + smaller font:**
```dart
sideTitles: SideTitles(
  showTitles: true,
  interval: 1,          // call getTitlesWidget for every index
  reservedSize: 28,     // more vertical room (was 24)
  getTitlesWidget: (value, _) {
    final idx = value.toInt();
    if (idx < 0 || idx >= data.length) {
      return const SizedBox.shrink();
    }
    // Show max ~5 labels: first, last, and evenly-spaced midpoints
    final len = data.length;
    final step = (len / 4).ceil().clamp(1, len);
    final show = idx == 0 || idx == len - 1 || (idx > 0 && idx < len - 1 && idx % step == 0);
    if (!show) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSizes.xs),
      child: Text(
        DateFormat('M/d', context.languageCode).format(data[idx].date),
        style: context.textStyles.labelSmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontSize: 10,        // explicit smaller font (was default ~11sp)
        ),
        textAlign: TextAlign.center,
      ),
    );
  },
),
```

---

## What NOT to Change
- Everything else in the chart (data logic, tooltips, grid, line style, gradient, legend, hero metric)
- Other charts in the tab
- No structural changes (no Column wrapper, no title addition, no legend move)
