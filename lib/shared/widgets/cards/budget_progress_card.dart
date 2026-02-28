import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/utils/money_formatter.dart';

/// Budget category card with an animated progress bar.
///
/// Bar colour: green (0–70%) → amber (70–90%) → red (90%+).
class BudgetProgressCard extends StatelessWidget {
  const BudgetProgressCard({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.limitPiastres,
    required this.spentPiastres,
    this.onTap,
    this.currencyCode = 'EGP',
  });

  final String categoryName;
  final IconData categoryIcon;
  final int limitPiastres;
  final int spentPiastres;
  final VoidCallback? onTap;
  final String currencyCode;

  double get _fraction =>
      limitPiastres > 0 ? (spentPiastres / limitPiastres).clamp(0.0, 1.1) : 0;

  Color _barColor(BuildContext context) {
    final theme = context.appTheme;
    if (_fraction >= 0.9) return theme.expenseColor;
    if (_fraction >= 0.7) return theme.warningColor;
    return theme.incomeColor;
  }

  @override
  Widget build(BuildContext context) {
    final barColor = _barColor(context);
    final isOver = spentPiastres > limitPiastres;
    final pct = (_fraction * 100).clamp(0, 100).round();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(categoryIcon, size: AppSizes.iconSm),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Text(
                      categoryName,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    isOver ? context.l10n.budget_exceeded : '$pct%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: barColor,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              Semantics(
                label: '$categoryName: $pct%',
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _fraction.clamp(0.0, 1.0)),
                  duration: context.reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusFull),
                    child: LinearProgressIndicator(
                      value: value,
                      minHeight: AppSizes.progressBarHeight,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(barColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    MoneyFormatter.formatCompact(
                      spentPiastres,
                      currency: currencyCode,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: barColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    MoneyFormatter.formatCompact(
                      limitPiastres,
                      currency: currencyCode,
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
