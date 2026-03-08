import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Compact this-month summary card: income | expense | net, with
/// a change indicator vs last month. Absorbs data from the removed
/// Comparison tab.
///
/// When [filterWalletId] is non-null, sums are scoped to that account.
class MonthSummaryZone extends ConsumerWidget {
  const MonthSummaryZone({super.key, this.filterWalletId});

  final int? filterWalletId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);
    final lastMonthKey =
        now.month == 1 ? (now.year - 1, 12) : (now.year, now.month - 1);

    final thisMonthTxs =
        ref.watch(transactionsByMonthProvider(monthKey)).valueOrNull ?? [];
    final lastMonthTxs =
        ref.watch(transactionsByMonthProvider(lastMonthKey)).valueOrNull ?? [];

    final wid = filterWalletId;
    final filteredThis =
        wid != null ? thisMonthTxs.where((t) => t.walletId == wid) : thisMonthTxs;
    final filteredLast =
        wid != null ? lastMonthTxs.where((t) => t.walletId == wid) : lastMonthTxs;

    int thisIncome = 0, thisExpense = 0;
    for (final t in filteredThis) {
      if (t.type == 'income') thisIncome += t.amount;
      if (t.type == 'expense') thisExpense += t.amount;
    }
    int lastExpenseTotal = 0;
    for (final t in filteredLast) {
      if (t.type == 'expense') lastExpenseTotal += t.amount;
    }

    final hasData = thisIncome > 0 || thisExpense > 0;
    if (!hasData) return const SizedBox.shrink();

    final net = thisIncome - thisExpense;
    final isPositive = net >= 0;

    final expenseChange = lastExpenseTotal > 0
        ? ((thisExpense - lastExpenseTotal) / lastExpenseTotal * 100).round()
        : 0;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSizes.screenHPadding,
      ),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.dashboard_month_summary,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (expenseChange != 0)
                  _ChangeChip(
                    change: expenseChange,
                    expenseColor: context.appTheme.expenseColor,
                    incomeColor: context.appTheme.incomeColor,
                  ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: context.l10n.dashboard_income,
                    amount: thisIncome,
                    color: context.appTheme.incomeColor,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: context.l10n.dashboard_expense,
                    amount: thisExpense,
                    color: context.appTheme.expenseColor,
                  ),
                ),
                Expanded(
                  child: _SummaryItem(
                    label: context.l10n.dashboard_month_net,
                    amount: net.abs(),
                    color: isPositive
                        ? context.appTheme.incomeColor
                        : context.appTheme.expenseColor,
                    prefix: isPositive ? '+' : '-',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
    this.prefix = '',
  });

  final String label;
  final int amount;
  final Color color;
  final String prefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSizes.xxs),
        Text(
          '$prefix${MoneyFormatter.formatCompact(amount)}',
          style: context.textStyles.bodyMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ChangeChip extends StatelessWidget {
  const _ChangeChip({
    required this.change,
    required this.expenseColor,
    required this.incomeColor,
  });

  final int change;
  final Color expenseColor;
  final Color incomeColor;

  @override
  Widget build(BuildContext context) {
    // For expense change: positive = spending more (bad), negative = spending less (good)
    final isUp = change > 0;
    final color = isUp ? expenseColor : incomeColor;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppSizes.opacityLight),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
      ),
      child: Text(
        '${isUp ? '+' : ''}$change% ${context.l10n.dashboard_vs_last_month}',
        style: context.textStyles.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
