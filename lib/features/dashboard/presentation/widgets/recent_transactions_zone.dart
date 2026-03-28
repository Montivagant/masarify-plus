import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_resolver.dart';
import '../../../../core/utils/transaction_grouper.dart';
import '../../../../shared/providers/activity_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/lists/transaction_list_section.dart';

/// Zone 3: Recent 5 transactions — watches only recentTransactions + categories.
///
/// When [filterWalletId] is non-null, only transactions for that account
/// are shown.
class RecentTransactionsZone extends ConsumerWidget {
  const RecentTransactionsZone({super.key, this.filterWalletId});

  /// When set, only transactions with this walletId are displayed.
  final int? filterWalletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use unified activity providers that merge transactions + transfers.
    final recentTxs = filterWalletId != null
        ? ref.watch(activityByWalletProvider(filterWalletId!))
        : ref.watch(recentActivityProvider);
    final categories = ref.watch(categoriesProvider);
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];

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
                    style: context.textStyles.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.dashboard),
                    label: Text(context.l10n.dashboard_see_all),
                    icon: Icon(
                      context.isRtl
                          ? AppIcons.chevronLeft
                          : AppIcons.chevronRight,
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
                walletInfoResolver: (walletId) {
                  final wallet =
                      wallets.where((w) => w.id == walletId).firstOrNull;
                  if (wallet == null) return null;
                  return (
                    icon: AppIcons.walletType(wallet.type),
                    name: wallet.name,
                  );
                },
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
        child: Column(
          children: [
            EmptyState(title: context.l10n.dashboard_failed_transactions),
            const SizedBox(height: AppSizes.sm),
            TextButton.icon(
              onPressed: () {
                if (filterWalletId != null) {
                  ref.invalidate(
                    activityByWalletProvider(filterWalletId!),
                  );
                } else {
                  ref.invalidate(recentActivityProvider);
                }
              },
              icon: const Icon(AppIcons.refresh, size: AppSizes.iconSm),
              label: Text(context.l10n.common_retry),
            ),
          ],
        ),
      ),
    );
  }
}
