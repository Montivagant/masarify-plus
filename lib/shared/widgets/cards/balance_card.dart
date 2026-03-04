import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme_extension.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/utils/money_formatter.dart';

/// Hero balance card for the Dashboard (Zone 1).
///
/// WS-7: Gradient background with decorative circles and glass-effect
/// income/expense row.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.totalPiastres,
    required this.monthlyIncomePiastres,
    required this.monthlyExpensePiastres,
    this.lastMonthExpensePiastres,
    this.currencyCode = 'EGP',
    this.hidden = false,
    this.onToggleHide,
    this.accountName,
  });

  final int totalPiastres;
  final int monthlyIncomePiastres;
  final int monthlyExpensePiastres;
  final int? lastMonthExpensePiastres;
  final String currencyCode;
  final bool hidden;
  final VoidCallback? onToggleHide;

  /// When non-null, displayed instead of the l10n "Total Balance" label.
  final String? accountName;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: theme.heroGradient,
        borderRadius: BorderRadius.circular(AppSizes.gradientBorderRadius),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: AppSizes.opacityLight4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative background circles
          PositionedDirectional(
            top: AppSizes.decorCircleLgOffset,
            end: AppSizes.decorCircleLgOffset,
            child: Container(
              width: AppSizes.decorCircleLg,
              height: AppSizes.decorCircleLg,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.onPrimary.withValues(alpha: AppSizes.decorCircleLgOpacity),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: AppSizes.decorCircleSmOffsetBottom,
            start: AppSizes.decorCircleSmOffsetStart,
            child: Container(
              width: AppSizes.decorCircleSm,
              height: AppSizes.decorCircleSm,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.onPrimary.withValues(alpha: AppSizes.decorCircleSmOpacity),
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label + hide toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      accountName ?? context.l10n.wallet_total_balance,
                      style: context.textStyles.bodyMedium?.copyWith(
                            color: cs.onPrimary.withValues(alpha: AppSizes.opacityHeavy),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    IconButton(
                      icon: Icon(
                        hidden ? AppIcons.eye : AppIcons.eyeOff,
                        size: AppSizes.iconSm,
                        color: cs.onPrimary,
                      ),
                      tooltip: hidden ? context.l10n.balance_show : context.l10n.balance_hide,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onToggleHide?.call();
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.xs),
                // Count-up balance animation
                TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: totalPiastres),
                  duration: context.reduceMotion
                      ? Duration.zero
                      : AppDurations.countUp,
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) {
                    return Semantics(
                      label: '${context.l10n.wallet_balance}: ${MoneyFormatter.format(totalPiastres, currency: currencyCode)}',
                      child: Text(
                        hidden
                            ? '••••••'
                            : MoneyFormatter.format(value, currency: currencyCode),
                        style: context.textStyles.displaySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: cs.onPrimary,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
                // Trend indicator vs last month
                if (lastMonthExpensePiastres != null &&
                    lastMonthExpensePiastres! > 0 &&
                    !hidden) ...[
                  const SizedBox(height: AppSizes.xs),
                  Builder(builder: (context) {
                    final diff = monthlyExpensePiastres -
                        lastMonthExpensePiastres!;
                    final pct =
                        ((diff / lastMonthExpensePiastres!) * 100).round();
                    final isUp = diff > 0;
                    return Row(
                      children: [
                        Icon(
                          isUp
                              ? AppIcons.trendingUp
                              : AppIcons.trendingDown,
                          size: AppSizes.iconXxs2,
                          color: isUp
                              ? context.appTheme.expenseColor
                              : context.appTheme.incomeColor,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          '${isUp ? '+' : ''}${MoneyFormatter.formatPercent(pct)} ${context.l10n.reports_vs_last_month}',
                          style: context.textStyles.bodySmall?.copyWith(
                                color: cs.onPrimary.withValues(alpha: AppSizes.opacityStrong),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    );
                  },),
                ],
                const SizedBox(height: AppSizes.lg),
                // Glass-effect income / expense row
                _GlassInsetRow(
                  theme: theme,
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        icon: AppIcons.income,
                        label: context.l10n.balance_income_label,
                        piastres: monthlyIncomePiastres,
                        color: context.appTheme.incomeColor,
                        hidden: hidden,
                        currencyCode: currencyCode,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: _SummaryItem(
                        icon: AppIcons.expense,
                        label: context.l10n.balance_expense_label,
                        piastres: monthlyExpensePiastres,
                        color: context.appTheme.expenseColor,
                        hidden: hidden,
                        currencyCode: currencyCode,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.piastres,
    required this.color,
    required this.hidden,
    required this.currencyCode,
  });

  final IconData icon;
  final String label;
  final int piastres;
  final Color color;
  final bool hidden;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Row(
      children: [
        Container(
          width: AppSizes.iconContainerXs,
          height: AppSizes.iconContainerXs,
          decoration: BoxDecoration(
            color: color.withValues(alpha: AppSizes.opacityLight3),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
          ),
          child: Icon(icon, size: AppSizes.iconXs, color: color),
        ),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textStyles.bodySmall?.copyWith(
                      color: cs.onPrimary.withValues(alpha: AppSizes.opacityStrong),
                    ),
              ),
              Text(
                hidden
                    ? '•••'
                    : MoneyFormatter.formatCompact(
                        piastres,
                        currency: currencyCode,
                      ),
                style: context.textStyles.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onPrimary,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Glass inset row that respects [GlassConfig] for blur fallback.
class _GlassInsetRow extends StatelessWidget {
  const _GlassInsetRow({
    required this.theme,
    required this.children,
  });

  final AppThemeExtension theme;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSizes.borderRadiusMd);
    final decoration = BoxDecoration(
      color: theme.glassInsetSurface,
      borderRadius: radius,
      border: Border.all(color: theme.glassInsetBorder),
    );

    final content = Container(
      padding: const EdgeInsets.all(AppSizes.sm),
      decoration: decoration,
      child: Row(children: children),
    );

    // Inset-tier blur (sigma 8) removed — imperceptible on small rows and
    // stacking multiple BackdropFilters in a scrollable body causes GPU
    // compositing overload (grey overlay / frozen screen).
    return ClipRRect(borderRadius: radius, child: content);
  }
}
