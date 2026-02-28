import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_resolver.dart';
import '../../../../core/utils/transaction_grouper.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/lists/transaction_list_section.dart';

/// Zone 3: Recent 5 transactions — watches only recentTransactions + categories.
class RecentTransactionsZone extends ConsumerWidget {
  const RecentTransactionsZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentTxs = ref.watch(recentTransactionsProvider);
    final categories = ref.watch(categoriesProvider);

    ResolvedCategory resolveCat(int catId) => resolveCategory(
          categoryId: catId,
          categories: categories.valueOrNull ?? [],
          fallbackColor: context.colors.outline,
          languageCode: context.languageCode,
        );

    return recentTxs.when(
      data: (txList) {
        final recent = txList.take(5).toList();
        if (recent.isEmpty) {
          return EmptyState(
            title: context.l10n.dashboard_no_transactions,
            subtitle: context.l10n.dashboard_start_tracking,
            compact: true,
          );
        }
        final grouped = groupTransactionsByDate(context, recent);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
                vertical: AppSizes.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.dashboard_recent_transactions,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.transactions),
                    label: Text(context.l10n.dashboard_see_all),
                    icon: Icon(
                      context.isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
                      size: AppSizes.iconXs,
                    ),
                    iconAlignment: IconAlignment.end,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            ...grouped.entries.map(
              (e) => TransactionListSection(
                dateLabel: e.key,
                transactions: e.value,
                categoryResolver: resolveCat,
                onTransactionTap: (tx) =>
                    context.push(AppRoutes.transactionDetailPath(tx.id)),
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSizes.screenHPadding),
        child: ShimmerList(itemCount: 5),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: EmptyState(title: context.l10n.dashboard_failed_transactions),
      ),
    );
  }
}
