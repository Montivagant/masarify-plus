import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme_extension.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/utils/money_formatter.dart';

/// Visual variant for [BalanceCard].
enum BalanceCardVariant {
  /// Full gradient hero card with income/expense summary and info chips.
  hero,

  /// Simpler per-account card with glass surface background.
  account,
}

/// Balance card used in the Dashboard carousel.
///
/// [BalanceCardVariant.hero] (default): Gradient background with decorative
/// circles, income/expense summary, cash/goals chips, and trend indicator.
///
/// [BalanceCardVariant.account]: Glass surface card showing account name,
/// wallet type icon, and balance only — no summary rows or chips.
class BalanceCard extends StatelessWidget {
  const BalanceCard({
    super.key,
    required this.totalPiastres,
    this.monthlyIncomePiastres = 0,
    this.monthlyExpensePiastres = 0,
    this.lastMonthExpensePiastres,
    this.currencyCode = 'EGP',
    this.hidden = false,
    this.onToggleHide,
    this.accountName,
    this.inGoalsPiastres = 0,
    this.cashPiastres = 0,
    this.variant = BalanceCardVariant.hero,
    this.walletTypeIcon,
    this.walletColorHex,
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

  /// Amount allocated to active savings goals (piastres). Shows chip when > 0.
  final int inGoalsPiastres;

  /// Physical cash balance (piastres). Shows chip when > 0 in hero variant.
  final int cashPiastres;

  /// Controls the visual style of the card.
  final BalanceCardVariant variant;

  /// Optional wallet type icon shown in account variant.
  final IconData? walletTypeIcon;

  /// Hex color string (e.g. '#3DA37A') for per-account tinting in account variant.
  final String? walletColorHex;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      BalanceCardVariant.hero => _buildHero(context),
      BalanceCardVariant.account => _buildAccount(context),
    };
  }

  // ── Hero variant ────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;

    return Container(
      decoration: BoxDecoration(
        gradient: theme.heroGradient,
        borderRadius: BorderRadius.circular(AppSizes.gradientBorderRadius),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: AppSizes.opacityLight4),
            blurRadius: AppSizes.heroShadowBlur,
            offset: const Offset(0, AppSizes.heroShadowOffsetY),
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
                color: cs.onPrimary
                    .withValues(alpha: AppSizes.decorCircleLgOpacity),
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
                color: cs.onPrimary
                    .withValues(alpha: AppSizes.decorCircleSmOpacity),
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
                        color: cs.onPrimary
                            .withValues(alpha: AppSizes.opacityHeavy),
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
                      tooltip: hidden
                          ? context.l10n.balance_show
                          : context.l10n.balance_hide,
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
                _CountUpBalance(
                  totalPiastres: totalPiastres,
                  currencyCode: currencyCode,
                  hidden: hidden,
                  style: context.textStyles.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimary,
                  ),
                ),
                // Trend indicator vs last month
                if (lastMonthExpensePiastres != null &&
                    lastMonthExpensePiastres! > 0 &&
                    !hidden) ...[
                  const SizedBox(height: AppSizes.xs),
                  _TrendIndicator(
                    monthlyExpensePiastres: monthlyExpensePiastres,
                    lastMonthExpensePiastres: lastMonthExpensePiastres!,
                  ),
                ],
                // Cash in Hand — prominent row
                if (!hidden && cashPiastres > 0) ...[
                  const SizedBox(height: AppSizes.sm),
                  _CashRow(
                    cashPiastres: cashPiastres,
                    currencyCode: currencyCode,
                  ),
                ],
                // In-Goals info chip
                if (!hidden && inGoalsPiastres > 0) ...[
                  const SizedBox(height: AppSizes.sm),
                  Row(
                    children: [
                      _InfoChip(
                        icon: AppIcons.goals,
                        label: context.l10n.balance_in_goals,
                        amountPiastres: inGoalsPiastres,
                        currencyCode: currencyCode,
                      ),
                    ],
                  ),
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

  // ── Account variant ─────────────────────────────────────────────────────

  Widget _buildAccount(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;
    final radius = BorderRadius.circular(AppSizes.gradientBorderRadius);

    // Parse wallet color for tinting, fallback to primary.
    final walletColor = walletColorHex != null && walletColorHex!.length >= 7
        ? Color(
            int.parse(walletColorHex!.substring(1), radix: 16) + 0xFF000000,
          )
        : cs.primary;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            walletColor.withValues(alpha: AppSizes.opacitySubtle),
            theme.glassCardSurface,
          ],
        ),
        borderRadius: radius,
        border: Border.all(
          color: walletColor.withValues(alpha: AppSizes.opacityLight),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.glassShadow,
            blurRadius: AppSizes.cardShadowBlur,
            offset: const Offset(0, AppSizes.cardShadowOffsetY),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored accent bar at top
          Container(
            height: AppSizes.xs,
            decoration: BoxDecoration(
              color: walletColor.withValues(alpha: AppSizes.opacityLight3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppSizes.gradientBorderRadius),
                topRight: Radius.circular(AppSizes.gradientBorderRadius),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.lg,
              AppSizes.md,
              AppSizes.lg,
              AppSizes.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account name + type icon + hide toggle
                Row(
                  children: [
                    if (walletTypeIcon != null) ...[
                      Container(
                        width: AppSizes.iconContainerMd,
                        height: AppSizes.iconContainerMd,
                        decoration: BoxDecoration(
                          color: walletColor.withValues(
                            alpha: AppSizes.opacityLight,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppSizes.borderRadiusMdSm),
                        ),
                        child: Icon(
                          walletTypeIcon,
                          size: AppSizes.iconMd,
                          color: walletColor,
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                    ],
                    Expanded(
                      child: Text(
                        accountName ?? '',
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        hidden ? AppIcons.eye : AppIcons.eyeOff,
                        size: AppSizes.iconSm,
                        color: cs.onSurfaceVariant,
                      ),
                      tooltip: hidden
                          ? context.l10n.balance_show
                          : context.l10n.balance_hide,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        onToggleHide?.call();
                      },
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.md),
                // Count-up balance animation
                _CountUpBalance(
                  totalPiastres: totalPiastres,
                  currencyCode: currencyCode,
                  hidden: hidden,
                  style: context.textStyles.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                // Currency code subtitle
                Text(
                  currencyCode,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant
                        .withValues(alpha: AppSizes.opacityStrong),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Count-up balance animation ──────────────────────────────────────────────

class _CountUpBalance extends StatelessWidget {
  const _CountUpBalance({
    required this.totalPiastres,
    required this.currencyCode,
    required this.hidden,
    required this.style,
  });

  final int totalPiastres;
  final String currencyCode;
  final bool hidden;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: totalPiastres),
      duration: context.reduceMotion ? Duration.zero : AppDurations.countUp,
      curve: Curves.easeOutCubic,
      builder: (_, value, __) {
        return Semantics(
          label:
              '${context.l10n.wallet_balance}: ${MoneyFormatter.format(totalPiastres, currency: currencyCode)}',
          child: Text(
            hidden
                ? '\u2022\u2022\u2022\u2022\u2022\u2022'
                : MoneyFormatter.format(value, currency: currencyCode),
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }
}

// ── Trend indicator ─────────────────────────────────────────────────────────

class _TrendIndicator extends StatelessWidget {
  const _TrendIndicator({
    required this.monthlyExpensePiastres,
    required this.lastMonthExpensePiastres,
  });

  final int monthlyExpensePiastres;
  final int lastMonthExpensePiastres;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final diff = monthlyExpensePiastres - lastMonthExpensePiastres;
    final pct = ((diff / lastMonthExpensePiastres) * 100).round();
    final isUp = diff > 0;

    return Row(
      children: [
        Icon(
          isUp ? AppIcons.trendingUp : AppIcons.trendingDown,
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
  }
}

// ── Cash row (prominent, hero card) ──────────────────────────────────────────

class _CashRow extends StatelessWidget {
  const _CashRow({
    required this.cashPiastres,
    required this.currencyCode,
  });

  final int cashPiastres;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.sm,
      ),
      decoration: BoxDecoration(
        color: cs.onPrimary.withValues(alpha: AppSizes.opacityLight2),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMdSm),
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.iconContainerXs,
            height: AppSizes.iconContainerXs,
            decoration: BoxDecoration(
              color: cs.onPrimary.withValues(alpha: AppSizes.opacityLight3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.physicalCash,
              size: AppSizes.iconXs,
              color: cs.onPrimary,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          Text(
            context.l10n.cash_in_hand,
            style: context.textStyles.bodySmall?.copyWith(
              color: cs.onPrimary.withValues(alpha: AppSizes.opacityHeavy),
            ),
          ),
          const Spacer(),
          Text(
            MoneyFormatter.format(cashPiastres, currency: currencyCode),
            style: context.textStyles.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info chip (cash / goals) ────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.amountPiastres,
    required this.currencyCode,
  });

  final IconData icon;
  final String label;
  final int amountPiastres;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      decoration: BoxDecoration(
        color: cs.onPrimary.withValues(alpha: AppSizes.opacityLight),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconXxs2, color: cs.onPrimary),
          const SizedBox(width: AppSizes.xs),
          Text(
            '$label: ${MoneyFormatter.formatCompact(amountPiastres, currency: currencyCode)}',
            style: context.textStyles.labelSmall?.copyWith(
              color: cs.onPrimary.withValues(alpha: AppSizes.opacityHeavy),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary item (income / expense) ─────────────────────────────────────────

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
                    ? '\u2022\u2022\u2022'
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
