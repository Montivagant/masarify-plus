import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Compact list row for the voice transaction review screen (list-view mode).
class DraftListItem extends StatelessWidget {
  const DraftListItem({
    super.key,
    required this.id,
    required this.categoryIcon,
    required this.categoryColor,
    required this.categoryName,
    required this.walletName,
    required this.amount,
    required this.type,
    required this.title,
    required this.isIncluded,
    required this.onToggle,
    required this.onEdit,
    this.onAccept,
    this.onDecline,
    this.matchedGoalName,
    this.isSubscriptionLike = false,
    this.unmatchedHint,
  });

  final int id;
  final IconData categoryIcon;
  final Color categoryColor;
  final String? categoryName;
  final String? walletName;
  final int amount;
  final String type;
  final String title;
  final bool isIncluded;
  final String? matchedGoalName;
  final bool isSubscriptionLike;
  final String? unmatchedHint;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final theme = context.appTheme;

    final typeColor = switch (type) {
      'income' || 'cash_deposit' => theme.incomeColor,
      'transfer' => theme.transferColor,
      _ => theme.expenseColor,
    };

    final prefix = switch (type) {
      'income' || 'cash_deposit' => '+',
      'expense' || 'cash_withdrawal' => '-',
      _ => '',
    };

    final formattedAmount = '$prefix${MoneyFormatter.formatAmount(amount)}';

    final cardContent = Opacity(
      opacity: isIncluded ? 1.0 : AppSizes.opacityLight5,
      child: GlassCard(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenHPadding,
          vertical: AppSizes.xs,
        ),
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.sm),
            child: Row(
              children: [
                // ── Left: Category icon ────────────────────────────
                Container(
                  width: AppSizes.iconContainerSm,
                  height: AppSizes.iconContainerSm,
                  decoration: BoxDecoration(
                    color:
                        categoryColor.withValues(alpha: AppSizes.opacityLight),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    categoryIcon,
                    size: AppSizes.iconSm2,
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),

                // ── Middle: Title + subtitle ───────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSizes.xxs),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${categoryName ?? '—'} \u2022 ${walletName ?? '—'}',
                              style: textStyles.bodySmall?.copyWith(
                                color: colors.outline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (matchedGoalName != null) ...[
                            const SizedBox(width: AppSizes.xs),
                            Icon(
                              AppIcons.goals,
                              size: AppSizes.iconXxs,
                              color: colors.outline,
                            ),
                          ],
                          if (isSubscriptionLike) ...[
                            const SizedBox(width: AppSizes.xs),
                            Icon(
                              AppIcons.recurring,
                              size: AppSizes.iconXxs,
                              color: colors.outline,
                            ),
                          ],
                          if (unmatchedHint != null) ...[
                            const SizedBox(width: AppSizes.xs),
                            Icon(
                              AppIcons.warning,
                              size: AppSizes.iconXxs,
                              color: colors.error,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSizes.sm),

                // ── Right: Amount + checkbox ───────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      formattedAmount,
                      style: textStyles.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                    SizedBox(
                      width: AppSizes.iconContainerSm,
                      height: AppSizes.iconContainerSm,
                      child: Checkbox(
                        value: isIncluded,
                        onChanged: (_) => onToggle(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // If no swipe callbacks provided, return the plain card.
    if (onAccept == null && onDecline == null) return cardContent;

    return Dismissible(
      key: ValueKey('draft_$id'),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onAccept?.call();
        } else {
          onDecline?.call();
        }
        // Return true so Dismissible runs its exit animation.
        return true;
      },
      background: Container(
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsetsDirectional.only(start: AppSizes.xl),
        decoration: BoxDecoration(
          color: theme.incomeColor,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        ),
        child: Icon(
          AppIcons.check,
          color: colors.surface,
          size: AppSizes.iconLg,
        ),
      ),
      secondaryBackground: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppSizes.xl),
        decoration: BoxDecoration(
          color: theme.expenseColor,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        ),
        child: Icon(
          AppIcons.close,
          color: colors.surface,
          size: AppSizes.iconLg,
        ),
      ),
      child: cardContent,
    );
  }
}
