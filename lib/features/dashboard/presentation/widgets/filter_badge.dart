import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/home_filter_provider.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';

/// Active filter badge shown below the filter bar when BOTH an account AND
/// a type filter are active simultaneously (D-14).
///
/// Displays a compact chip: "CIB + Expenses only -- Clear all".
/// Tapping "Clear all" resets both filters.
class FilterBadge extends ConsumerWidget {
  const FilterBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletId = ref.watch(selectedAccountIdProvider);
    final filter = ref.watch(homeFilterProvider);

    // Only show when BOTH filters are active.
    final hasAccountFilter = walletId != null;
    final hasTypeFilter = filter.typeFilter != TransactionTypeFilter.all;
    if (!hasAccountFilter || !hasTypeFilter) {
      return const SizedBox.shrink();
    }

    // Resolve wallet name.
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final walletName =
        wallets.where((w) => w.id == walletId).firstOrNull?.name ?? '...';

    final typeName = _typeLabel(context, filter.typeFilter);
    final cs = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: AppSizes.opacityLight4),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        ),
        child: Row(
          children: [
            Icon(AppIcons.bank, size: AppSizes.iconXs, color: cs.primary),
            const SizedBox(width: AppSizes.xs),
            Flexible(
              child: Text(
                '$walletName + $typeName',
                style: context.textStyles.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            // Clear all button
            GestureDetector(
              onTap: () {
                ref.read(selectedAccountIdProvider.notifier).state = null;
                ref.read(homeFilterProvider.notifier).state =
                    const HomeFilter();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.home_clear_filters,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: cs.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: AppSizes.xxs),
                  Icon(AppIcons.close, size: AppSizes.iconXxs, color: cs.error),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel(BuildContext context, TransactionTypeFilter type) {
    return switch (type) {
      TransactionTypeFilter.all => context.l10n.home_filter_all,
      TransactionTypeFilter.expenses => context.l10n.home_filter_expenses,
      TransactionTypeFilter.income => context.l10n.home_filter_income,
      TransactionTypeFilter.transfers => context.l10n.home_filter_transfers,
    };
  }
}
