import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/home_filter_provider.dart';
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

          // ── Filter chips ──────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TransactionTypeFilter.values.map((type) {
                  final isActive = filter.typeFilter == type;
                  return Padding(
                    padding: const EdgeInsetsDirectional.only(end: AppSizes.xs),
                    child: ChoiceChip(
                      label: Text(_chipLabel(context, type)),
                      selected: isActive,
                      onSelected: (_) {
                        ref.read(homeFilterProvider.notifier).state =
                            filter.copyWith(typeFilter: type);
                      },
                      selectedColor: cs.primary,
                      labelStyle: TextStyle(
                        color: isActive ? cs.onPrimary : cs.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: isActive
                          ? BorderSide.none
                          : BorderSide(
                              color: cs.outline
                                  .withValues(alpha: AppSizes.opacityLight4),
                            ),
                    ),
                  );
                }).toList(),
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
