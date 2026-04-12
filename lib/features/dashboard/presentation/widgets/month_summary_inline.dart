import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/transaction_provider.dart';

/// Glass pill badges showing Income & Expense side-by-side.
///
/// Used inline under the balance number in the balance header.
/// Each pill has a tinted glass background matching its category colour.
/// The Net total lives on the Reports screen — it was removed from the
/// hero to free vertical space for the Cash card + account chips.
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

    final incomeColor = context.appTheme.incomeColor;
    final expenseColor = context.appTheme.expenseColor;
    final bodySmall = context.textStyles.bodySmall;
    final bodyMedium = context.textStyles.bodyMedium;

    const bullet = '\u2022\u2022\u2022\u2022';

    // ── Income / Expense glass pills ───────────────────────────────
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Income pill
        Expanded(
          child: _GlassPill(
            icon: AppIcons.income,
            label: context.l10n.dashboard_income,
            amount: hidden ? bullet : MoneyFormatter.formatAmount(income),
            color: incomeColor,
            labelStyle: bodySmall,
            amountStyle: bodyMedium,
            labelColor: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        // Expense pill
        Expanded(
          child: _GlassPill(
            icon: AppIcons.expense,
            label: context.l10n.dashboard_expense,
            amount: hidden ? bullet : MoneyFormatter.formatAmount(expense),
            color: expenseColor,
            labelStyle: bodySmall,
            amountStyle: bodyMedium,
            labelColor: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ── Glass pill badge ─────────────────────────────────────────────────────────

class _GlassPill extends StatelessWidget {
  const _GlassPill({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.labelStyle,
    required this.amountStyle,
    required this.labelColor,
  });

  final IconData icon;
  final String label;
  final String amount;
  final Color color;
  final TextStyle? labelStyle;
  final TextStyle? amountStyle;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppSizes.opacityLight2),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        child: Row(
          children: [
            Container(
              width: AppSizes.iconContainerMd,
              height: AppSizes.iconContainerMd,
              decoration: BoxDecoration(
                color: color.withValues(alpha: AppSizes.opacityLight2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: AppSizes.iconSm, color: color),
            ),
            const SizedBox(width: AppSizes.xs),
            Expanded(
              child: Column(
                children: [
                  Text(
                    label,
                    style: labelStyle?.copyWith(color: labelColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    amount,
                    style: amountStyle?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
