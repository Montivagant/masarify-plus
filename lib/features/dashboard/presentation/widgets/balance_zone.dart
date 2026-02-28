import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/hide_balances_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/balance_card.dart';
import '../../../../shared/widgets/lists/empty_state.dart';

/// Zone 1: Hero balance card — watches only balance-related providers.
class BalanceZone extends ConsumerWidget {
  const BalanceZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);
    final lastMonthKey = now.month == 1
        ? (now.year - 1, 12)
        : (now.year, now.month - 1);

    final totalBalance = ref.watch(totalBalanceProvider);
    final income = ref.watch(monthlyIncomeProvider(monthKey));
    final expense = ref.watch(monthlyExpenseProvider(monthKey));
    final lastMonthExpense = ref.watch(monthlyExpenseProvider(lastMonthKey));
    final hidden = ref.watch(hideBalancesProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSizes.screenHPadding),
      child: totalBalance.when(
        data: (total) => BalanceCard(
          totalPiastres: total,
          monthlyIncomePiastres: income,
          monthlyExpensePiastres: expense,
          lastMonthExpensePiastres: lastMonthExpense,
          hidden: hidden,
          onToggleHide: () =>
              ref.read(hideBalancesProvider.notifier).toggle(),
        ),
        loading: () => const _BalanceCardShimmer(),
        error: (_, __) => EmptyState(
          title: context.l10n.dashboard_failed_balance,
        ),
      ),
    );
  }
}

class _BalanceCardShimmer extends StatelessWidget {
  const _BalanceCardShimmer();

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHighest,
      highlightColor: cs.surfaceContainerLow,
      child: Container(
        height: AppSizes.chartHeightSm,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        ),
      ),
    );
  }
}
