import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/home_filter_provider.dart';
import '../../../../shared/providers/smart_defaults_provider.dart';
import 'sort_bottom_sheet.dart';

/// Pinned filter bar with type chips, search icon, and sort button (D-09, D-10).
///
/// Watches [homeFilterProvider] internally so the [FilterBarDelegate] does
/// not need to track rebuild state.
class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(homeFilterProvider);
    final cs = context.colors;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSizes.sm,
      ),
      child: Row(
        children: [
          // ── Search icon ─────────────────────────────────────────────
          IconButton(
            icon: const Icon(AppIcons.search, size: AppSizes.iconSm),
            onPressed: () {
              ref.read(homeFilterProvider.notifier).state =
                  filter.copyWith(isSearchActive: !filter.isSearchActive);
            },
            tooltip: context.l10n.home_search_hint,
            visualDensity: VisualDensity.compact,
          ),

          // ── Filter chips (type + top categories) ──────────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Type filter chips
                  ...TransactionTypeFilter.values.map((type) {
                    final isActive =
                        filter.typeFilter == type && filter.categoryId == null;
                    return Padding(
                      padding:
                          const EdgeInsetsDirectional.only(end: AppSizes.xs),
                      child: ChoiceChip(
                        label: Text(_chipLabel(context, type)),
                        selected: isActive,
                        onSelected: (_) {
                          ref.read(homeFilterProvider.notifier).state =
                              filter.copyWith(
                            typeFilter: type,
                            clearCategory: true,
                          );
                        },
                        selectedColor: cs.primary,
                        labelStyle:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: isActive ? cs.onPrimary : cs.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: isActive
                            ? BorderSide.none
                            : BorderSide(
                                color: cs.outline.withValues(
                                  alpha: AppSizes.opacityLight4,
                                ),
                              ),
                      ),
                    );
                  }),

                  // Separator dot
                  if (_topCategories(ref).isNotEmpty)
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSizes.xs,
                      ),
                      child: Icon(
                        AppIcons.moreVert,
                        size: AppSizes.iconXxs,
                        color: cs.outline.withValues(
                          alpha: AppSizes.opacityLight4,
                        ),
                      ),
                    ),

                  // Top-used category chips
                  ..._topCategories(ref).indexed.map((entry) {
                    final (idx, cat) = entry;
                    final isActive = filter.categoryId == cat.id;
                    final catColor = ColorUtils.fromHex(cat.colorHex);
                    final isMostUsed = idx == 0;
                    return Padding(
                      padding:
                          const EdgeInsetsDirectional.only(end: AppSizes.xs),
                      child: ChoiceChip(
                        avatar: Icon(
                          CategoryIconMapper.fromName(cat.iconName),
                          size: AppSizes.iconXs,
                          color: isActive ? cs.onPrimary : catColor,
                        ),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              cat.displayName(
                                context.languageCode,
                              ),
                            ),
                            if (isMostUsed) ...[
                              const SizedBox(width: AppSizes.xxs),
                              Icon(
                                AppIcons.trendingUp,
                                size: AppSizes.iconXxs,
                                color: isActive ? cs.onPrimary : catColor,
                              ),
                            ],
                          ],
                        ),
                        selected: isActive,
                        onSelected: (_) {
                          ref.read(homeFilterProvider.notifier).state = isActive
                              ? filter.copyWith(clearCategory: true)
                              : filter.copyWith(categoryId: cat.id);
                        },
                        selectedColor: catColor,
                        labelStyle:
                            Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: isActive ? cs.onPrimary : cs.onSurface,
                                  fontWeight: FontWeight.w500,
                                ),
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: isActive
                            ? BorderSide.none
                            : BorderSide(
                                color: catColor.withValues(
                                  alpha: AppSizes.opacityLight4,
                                ),
                              ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // ── Sort button ──────────────────────────────────────────────
          IconButton(
            icon: const Icon(AppIcons.filter, size: AppSizes.iconSm),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => const SortBottomSheet(),
            ),
            tooltip: _sortLabel(context, filter.sortOrder),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  /// Returns up to 3 most-used categories based on frequency data.
  List<CategoryEntity> _topCategories(WidgetRef ref) {
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    if (categories.isEmpty) return [];

    final freqService = ref.read(categoryFrequencyServiceProvider);
    final expenseFreqs = freqService.getFrequencies('expense');
    final incomeFreqs = freqService.getFrequencies('income');

    // Merge frequencies across types.
    final merged = <int, int>{};
    for (final entry in expenseFreqs.entries) {
      merged[entry.key] = (merged[entry.key] ?? 0) + entry.value;
    }
    for (final entry in incomeFreqs.entries) {
      merged[entry.key] = (merged[entry.key] ?? 0) + entry.value;
    }
    if (merged.isEmpty) return [];

    // Sort categories by total frequency descending, take top 3.
    final sorted = categories.where((c) => merged.containsKey(c.id)).toList()
      ..sort((a, b) => (merged[b.id] ?? 0).compareTo(merged[a.id] ?? 0));

    return sorted.take(3).toList();
  }

  String _chipLabel(BuildContext context, TransactionTypeFilter type) {
    return switch (type) {
      TransactionTypeFilter.all => context.l10n.home_filter_all,
      TransactionTypeFilter.expenses => context.l10n.home_filter_expenses,
      TransactionTypeFilter.income => context.l10n.home_filter_income,
      TransactionTypeFilter.transfers => context.l10n.home_filter_transfers,
    };
  }

  String _sortLabel(BuildContext context, SortOrder order) {
    return switch (order) {
      SortOrder.dateDesc => context.l10n.home_sort_date_newest,
      SortOrder.dateAsc => context.l10n.home_sort_date_oldest,
      SortOrder.amountDesc => context.l10n.home_sort_amount_high,
      SortOrder.amountAsc => context.l10n.home_sort_amount_low,
    };
  }
}
