import 'package:flutter/material.dart';

import '../../../app/theme/app_theme_extension.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/insight_engine.dart';
import 'glass_card.dart';

/// Displays a single financial insight with icon, title, body, CTA, and optional dismiss.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.insight,
    required this.title,
    required this.body,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
  });

  final Insight insight;
  final String title;
  final String body;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final iconData = _iconForType(insight.type);
    final iconColor = _colorForType(insight.type, cs, context.appTheme);

    return GlassCard(
      showShadow: true,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      child: Container(
        // WS-12: accent stripe on start edge
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          border: BorderDirectional(
            start: BorderSide(color: iconColor, width: 3),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(width: AppSizes.xs),
            Container(
              width: AppSizes.iconContainerMd,
              height: AppSizes.iconContainerMd,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: AppSizes.opacityLight),
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
              child: Icon(iconData, size: AppSizes.iconSm, color: iconColor),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    body,
                    style: context.textStyles.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (onAction != null && actionLabel != null) ...[
                    const SizedBox(height: AppSizes.sm),
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(actionLabel!),
                    ),
                  ],
                ],
              ),
            ),
            if (onDismiss != null)
              IconButton(
                icon: const Icon(AppIcons.close, size: AppSizes.iconXs),
                onPressed: onDismiss,
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  static IconData _iconForType(InsightType type) {
    return switch (type) {
      InsightType.categoryOverspend => AppIcons.expense,
      InsightType.budgetForecast => AppIcons.budget,
      InsightType.topSpendingDay => AppIcons.trendingUp,
      InsightType.savingsUp => AppIcons.income,
      InsightType.savingsDown => AppIcons.expense,
      InsightType.topCategory => AppIcons.category,
      InsightType.transactionStreak => AppIcons.check,
      InsightType.noIncomeRecorded => AppIcons.income,
    };
  }

  static Color _colorForType(
    InsightType type,
    ColorScheme cs,
    AppThemeExtension appTheme,
  ) {
    return switch (type) {
      InsightType.categoryOverspend => appTheme.expenseColor,
      InsightType.budgetForecast => appTheme.warningColor,
      InsightType.topSpendingDay => cs.primary,
      InsightType.savingsUp => appTheme.incomeColor,
      InsightType.savingsDown => appTheme.expenseColor,
      InsightType.topCategory => cs.primary,
      InsightType.transactionStreak => appTheme.incomeColor,
      InsightType.noIncomeRecorded => appTheme.warningColor,
    };
  }
}
