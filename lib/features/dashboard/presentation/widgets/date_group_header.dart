import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';

/// Date group header for the transaction list (D-13).
///
/// Shows a localized date label on the left and a daily net subtotal on the
/// right, colored by sign (green for positive, red for negative).
///
/// NOT sticky — visual separator only (per research recommendation).
class DateGroupHeader extends StatelessWidget {
  const DateGroupHeader({
    super.key,
    required this.dateLabel,
    required this.dailyNet,
  });

  /// Localized date label from [transactionDateLabel] — "Today", "Yesterday",
  /// or a formatted date string.
  final String dateLabel;

  /// Daily net subtotal in piastres (income - expenses).
  final int dailyNet;

  @override
  Widget build(BuildContext context) {
    final appTheme = context.appTheme;

    final netColor = dailyNet > 0
        ? appTheme.incomeColor
        : dailyNet < 0
            ? appTheme.expenseColor
            : context.colors.outline;

    final netPrefix = dailyNet > 0 ? '+' : '';
    final netFormatted = MoneyFormatter.formatCompact(dailyNet.abs());

    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSizes.screenHPadding,
        end: AppSizes.screenHPadding,
        top: AppSizes.md,
        bottom: AppSizes.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateLabel,
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (dailyNet != 0)
            Text(
              '$netPrefix$netFormatted',
              style: context.textStyles.bodySmall?.copyWith(
                color: netColor,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
