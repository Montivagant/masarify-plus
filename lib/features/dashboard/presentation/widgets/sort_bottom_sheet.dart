import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/home_filter_provider.dart';

/// Modal bottom sheet with 4 sort options for the home transaction list (D-12).
///
/// Show via `showModalBottomSheet(context: context, builder: (_) => const SortBottomSheet())`.
class SortBottomSheet extends ConsumerWidget {
  const SortBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(homeFilterProvider).sortOrder;
    final cs = context.colors;

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
                    context.l10n.home_sort_title,
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // ── Sort options ──────────────────────────────────────────
            ...SortOrder.values.map((order) {
              final isSelected = currentSort == order;
              return ListTile(
                leading: Icon(
                  isSelected ? AppIcons.checkCircle : _sortIcon(order),
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  size: AppSizes.iconMd,
                ),
                title: Text(
                  _sortLabel(context, order),
                  style: context.textStyles.bodyMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? cs.primary : cs.onSurface,
                  ),
                ),
                selected: isSelected,
                onTap: () {
                  ref.read(homeFilterProvider.notifier).state =
                      ref.read(homeFilterProvider).copyWith(sortOrder: order);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _sortIcon(SortOrder order) => switch (order) {
        SortOrder.dateDesc => AppIcons.trendingDown,
        SortOrder.dateAsc => AppIcons.trendingUp,
        SortOrder.amountDesc => AppIcons.trendingDown,
        SortOrder.amountAsc => AppIcons.trendingUp,
      };

  String _sortLabel(BuildContext context, SortOrder order) => switch (order) {
        SortOrder.dateDesc => context.l10n.home_sort_date_newest,
        SortOrder.dateAsc => context.l10n.home_sort_date_oldest,
        SortOrder.amountDesc => context.l10n.home_sort_amount_high,
        SortOrder.amountAsc => context.l10n.home_sort_amount_low,
      };
}
