import 'package:flutter/material.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/utils/money_formatter.dart';
import 'glass_card.dart';

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

    return GlassCard(
      showShadow: true,
      onTap: onTap,
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
                  style: context.textStyles.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                isOver ? context.l10n.budget_exceeded : MoneyFormatter.formatPercent(pct),
                style: context.textStyles.bodySmall?.copyWith(
                      color: barColor,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          RepaintBoundary(
            child: Semantics(
              label: '$categoryName: ${MoneyFormatter.formatPercent(pct)}',
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _fraction.clamp(0.0, 1.0)),
                duration: context.reduceMotion
                    ? Duration.zero
                    : AppDurations.countUp,
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => ClipRRect(
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusFull),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: AppSizes.progressBarHeight,
                    backgroundColor: context.colors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
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
                style: context.textStyles.bodySmall?.copyWith(
                      color: barColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                MoneyFormatter.formatCompact(
                  limitPiastres,
                  currency: currencyCode,
                ),
                style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.outline,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
