import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/transaction_provider.dart';

/// Compact single-row month summary: "^ 12,500  v 8,200  Net +4,300".
///
/// Used inline under the balance number in the new balance header (D-04).
/// Replaces the separate MonthSummaryZone card with a lightweight row.
class MonthSummaryInline extends ConsumerWidget {
  const MonthSummaryInline({
    super.key,
    this.walletId,
    this.hidden = false,
  });

  /// null = all accounts.
  final int? walletId;
  final bool hidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);
    final txs =
        ref.watch(transactionsByMonthProvider(monthKey)).valueOrNull ?? [];

    // Filter by wallet if needed.
    final filtered =
        walletId != null ? txs.where((t) => t.walletId == walletId) : txs;

    int income = 0;
    int expense = 0;
    for (final t in filtered) {
      if (t.type == 'income') income += t.amount;
      if (t.type == 'expense') expense += t.amount;
    }

    final net = income - expense;
    final isPositive = net >= 0;

    final incomeColor = context.appTheme.incomeColor;
    final expenseColor = context.appTheme.expenseColor;
    final netColor = isPositive ? incomeColor : expenseColor;
    final bodySmall = context.textStyles.bodySmall;

    const bullet = '\u2022\u2022\u2022\u2022';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Income
        Icon(
          AppIcons.income,
          size: AppSizes.iconXs,
          color: incomeColor,
        ),
        const SizedBox(width: AppSizes.xxs),
        Text(
          hidden ? bullet : MoneyFormatter.formatCompact(income),
          style: bodySmall?.copyWith(
            color: incomeColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSizes.md),
        // Expense
        Icon(
          AppIcons.expense,
          size: AppSizes.iconXs,
          color: expenseColor,
        ),
        const SizedBox(width: AppSizes.xxs),
        Text(
          hidden ? bullet : MoneyFormatter.formatCompact(expense),
          style: bodySmall?.copyWith(
            color: expenseColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSizes.md),
        // Net (with tooltip explaining the calculation)
        Tooltip(
          message: context.l10n.home_net_tooltip,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.home_net_label,
                style: bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppSizes.xxs),
              Icon(
                AppIcons.infoFilled,
                size: AppSizes.iconXxs,
                color: context.colors.onSurfaceVariant.withValues(
                  alpha: AppSizes.opacityMedium,
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                hidden
                    ? bullet
                    : '${isPositive ? '+' : '-'}${MoneyFormatter.formatCompact(net.abs())}',
                style: bodySmall?.copyWith(
                  color: netColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
