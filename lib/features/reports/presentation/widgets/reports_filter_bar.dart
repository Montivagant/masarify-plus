import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/analytics_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';

/// Horizontal filter bar for Reports: wallet dropdown + income/expense chips.
class ReportsFilterBar extends ConsumerWidget {
  const ReportsFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final activeWallets = wallets.where((w) => !w.isArchived).toList();
    final selectedWalletId = ref.watch(reportsWalletFilterProvider);
    final selectedType = ref.watch(reportsTypeFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      child: Row(
        children: [
          // Wallet filter dropdown
          Flexible(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int?>(
                value: selectedWalletId,
                isDense: true,
                isExpanded: true,
                style: context.textStyles.bodySmall
                    ?.copyWith(color: context.colors.onSurface),
                items: [
                  DropdownMenuItem<int?>(
                    child: Text(context.l10n.reports_all_accounts),
                  ),
                  ...activeWallets.map(
                    (w) => DropdownMenuItem<int?>(
                      value: w.id,
                      child: Text(w.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) =>
                    ref.read(reportsWalletFilterProvider.notifier).state = v,
              ),
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          // Type filter chips
          ...['expense', 'income'].map(
            (type) => Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSizes.xs),
              child: FilterChip(
                label: Text(
                  type == 'expense'
                      ? context.l10n.dashboard_expense
                      : context.l10n.dashboard_income,
                  style: context.textStyles.labelSmall,
                ),
                selected: selectedType == type,
                onSelected: (on) => ref
                    .read(reportsTypeFilterProvider.notifier)
                    .state = on ? type : null,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
