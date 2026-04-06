import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/home_filter_provider.dart';

/// Modal bottom sheet with date range and category filters for the home
/// transaction list.
///
/// Show via `showModalBottomSheet(context: context, builder: (_) => const FilterBottomSheet())`.
class FilterBottomSheet extends ConsumerStatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  ConsumerState<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends ConsumerState<FilterBottomSheet> {
  DateTimeRange? _dateRange;
  Set<int> _selectedCategoryIds = {};

  @override
  void initState() {
    super.initState();
    final filter = ref.read(homeFilterProvider);
    _dateRange = filter.dateRange;
    if (filter.categoryId != null) {
      _selectedCategoryIds = {filter.categoryId!};
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ───────────────────────────────────────────
            const SizedBox(height: AppSizes.sm),
            Container(
              width: AppSizes.dragHandleWidth,
              height: AppSizes.dragHandleHeight,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant
                    .withValues(alpha: AppSizes.opacityLight4),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // ── Title ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.filter, size: AppSizes.iconSm),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    context.l10n.home_filter_title,
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // ── Date Range Section ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.home_filter_date_range,
                    style: context.textStyles.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: [
                      _datePresetChip(
                        context.l10n.home_filter_today,
                        _todayRange(),
                      ),
                      _datePresetChip(
                        context.l10n.home_filter_this_week,
                        _thisWeekRange(),
                      ),
                      _datePresetChip(
                        context.l10n.home_filter_this_month,
                        _thisMonthRange(),
                      ),
                      _datePresetChip(
                        context.l10n.home_filter_last_month,
                        _lastMonthRange(),
                      ),
                      ActionChip(
                        avatar: Icon(
                          AppIcons.calendar,
                          size: AppSizes.iconXs,
                          color:
                              _dateRange != null && !_isPresetRange(_dateRange!)
                                  ? cs.onPrimary
                                  : cs.onSurfaceVariant,
                        ),
                        label: Text(context.l10n.home_filter_custom_range),
                        backgroundColor:
                            _dateRange != null && !_isPresetRange(_dateRange!)
                                ? cs.primary
                                : null,
                        labelStyle: context.textStyles.labelLarge?.copyWith(
                          color:
                              _dateRange != null && !_isPresetRange(_dateRange!)
                                  ? cs.onPrimary
                                  : cs.onSurface,
                        ),
                        side: _dateRange != null && !_isPresetRange(_dateRange!)
                            ? BorderSide.none
                            : BorderSide(
                                color: cs.outline
                                    .withValues(alpha: AppSizes.opacityLight4),
                              ),
                        onPressed: _pickCustomRange,
                      ),
                    ],
                  ),
                  if (_dateRange != null) ...[
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      _formatDateRange(_dateRange!),
                      style: context.textStyles.bodySmall?.copyWith(
                        color: cs.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // ── Divider ──────────────────────────────────────────────
            const SizedBox(height: AppSizes.md),

            // ── Category Section ─────────────────────────────────────
            if (categories.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.home_filter_category,
                      style: context.textStyles.labelLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Wrap(
                      spacing: AppSizes.sm,
                      runSpacing: AppSizes.sm,
                      children: categories.map((cat) {
                        final isActive = _selectedCategoryIds.contains(cat.id);
                        final catColor = ColorUtils.fromHex(cat.colorHex);
                        return FilterChip(
                          avatar: Icon(
                            CategoryIconMapper.fromName(cat.iconName),
                            size: AppSizes.iconXs,
                            color: isActive ? cs.onPrimary : catColor,
                          ),
                          label: Text(
                            cat.displayName(context.languageCode),
                          ),
                          selected: isActive,
                          selectedColor: catColor,
                          labelStyle: context.textStyles.labelLarge?.copyWith(
                            color: isActive ? cs.onPrimary : cs.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: isActive
                              ? BorderSide.none
                              : BorderSide(
                                  color: catColor.withValues(
                                    alpha: AppSizes.opacityLight4,
                                  ),
                                ),
                          onSelected: (_) {
                            setState(() {
                              if (isActive) {
                                _selectedCategoryIds.remove(cat.id);
                              } else {
                                // Single select to match the existing
                                // homeFilterProvider.categoryId behavior.
                                _selectedCategoryIds = {cat.id};
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSizes.lg),

            // ── Bottom buttons ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
              ),
              child: Row(
                children: [
                  // Clear All
                  TextButton(
                    onPressed: _clearAll,
                    child: Text(context.l10n.home_filter_clear),
                  ),
                  const Spacer(),
                  // Apply Filters
                  FilledButton(
                    onPressed: _applyFilters,
                    child: Text(context.l10n.home_filter_apply),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Date preset helpers ──────────────────────────────────────────────

  Widget _datePresetChip(String label, DateTimeRange range) {
    final cs = context.colors;
    final isActive = _dateRange != null &&
        _dateRange!.start == range.start &&
        _dateRange!.end == range.end;

    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      selectedColor: cs.primary,
      labelStyle: context.textStyles.labelLarge?.copyWith(
        color: isActive ? cs.onPrimary : cs.onSurface,
        fontWeight: FontWeight.w500,
      ),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: isActive
          ? BorderSide.none
          : BorderSide(
              color: cs.outline.withValues(alpha: AppSizes.opacityLight4),
            ),
      onSelected: (_) {
        setState(() {
          _dateRange = isActive ? null : range;
        });
      },
    );
  }

  bool _isPresetRange(DateTimeRange range) {
    final presets = [
      _todayRange(),
      _thisWeekRange(),
      _thisMonthRange(),
      _lastMonthRange(),
    ];
    return presets.any((p) => p.start == range.start && p.end == range.end);
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (picked != null && mounted) {
      setState(() => _dateRange = picked);
    }
  }

  String _formatDateRange(DateTimeRange range) {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '${fmt(range.start)}  —  ${fmt(range.end)}';
  }

  // ── Actions ──────────────────────────────────────────────────────────

  void _clearAll() {
    setState(() {
      _dateRange = null;
      _selectedCategoryIds = {};
    });
    ref.read(homeFilterProvider.notifier).state =
        ref.read(homeFilterProvider).copyWith(
              clearDateRange: true,
              clearCategory: true,
            );
    context.pop();
  }

  void _applyFilters() {
    final current = ref.read(homeFilterProvider);
    ref.read(homeFilterProvider.notifier).state = current.copyWith(
      dateRange: _dateRange,
      clearDateRange: _dateRange == null,
      categoryId:
          _selectedCategoryIds.isNotEmpty ? _selectedCategoryIds.first : null,
      clearCategory: _selectedCategoryIds.isEmpty,
    );
    context.pop();
  }
}

// ── Date range presets ─────────────────────────────────────────────────────

DateTimeRange _todayRange() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return DateTimeRange(start: today, end: today);
}

DateTimeRange _thisWeekRange() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(Duration(days: today.weekday % 7));
  return DateTimeRange(start: weekStart, end: today);
}

DateTimeRange _thisMonthRange() {
  final now = DateTime.now();
  return DateTimeRange(
    start: DateTime(now.year, now.month),
    end: DateTime(now.year, now.month, now.day),
  );
}

DateTimeRange _lastMonthRange() {
  final now = DateTime.now();
  final lastMonth = DateTime(now.year, now.month - 1);
  final lastDay = DateTime(now.year, now.month, 0);
  return DateTimeRange(start: lastMonth, end: lastDay);
}
