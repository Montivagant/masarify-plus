import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Compact list row for the voice transaction review screen (list-view mode).
///
/// Layout: [AccentBar | Checkbox | CategoryIcon | Title+Subtitle | Amount]
/// With optional single suggestion chip below the main row.
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
    this.onDecline,
    this.matchedGoalName,
    this.isSubscriptionLike = false,
    this.subscriptionAdded = false,
    this.unmatchedHint,
    this.unmatchedToHint,
    this.onSubscriptionTap,
    this.onCreateWallet,
    this.onCreateToWallet,
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
  final bool subscriptionAdded;
  final String? unmatchedHint;
  final String? unmatchedToHint;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onDecline;
  final VoidCallback? onSubscriptionTap;
  final VoidCallback? onCreateWallet;
  final VoidCallback? onCreateToWallet;

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

    // ── Determine suggestion chip (max 1, priority order) ───────────
    final suggestionChip =
        _buildSuggestionChip(context, colors, textStyles, theme);

    final cardBody = Opacity(
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
          child: Row(
            children: [
              // ── Left-edge accent bar ───────────────────────────
              Container(
                width: AppSizes.voiceBarWidth,
                decoration: BoxDecoration(
                  color: typeColor,
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(AppSizes.borderRadiusMd),
                    bottomStart: Radius.circular(AppSizes.borderRadiusMd),
                  ),
                ),
              ),

              // ── Card content ───────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Leading checkbox
                          SizedBox(
                            width: AppSizes.minTapTarget,
                            height: AppSizes.minTapTarget,
                            child: Checkbox(
                              value: isIncluded,
                              onChanged: (_) => onToggle(),
                            ),
                          ),

                          // Category icon
                          Container(
                            width: AppSizes.iconContainerMd,
                            height: AppSizes.iconContainerMd,
                            decoration: BoxDecoration(
                              color: categoryColor.withValues(
                                alpha: AppSizes.opacityLight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              categoryIcon,
                              size: AppSizes.iconSm,
                              color: categoryColor,
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),

                          // Title + subtitle
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
                                Text(
                                  '${categoryName ?? '\u2014'} \u2022 ${walletName ?? '\u2014'}',
                                  style: textStyles.bodySmall?.copyWith(
                                    color: colors.outline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSizes.sm),

                          // Amount (right-aligned)
                          Text(
                            formattedAmount,
                            style: textStyles.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: typeColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Suggestion chip (if any)
                      if (suggestionChip != null) suggestionChip,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Wrap with Slidable if decline callback provided
    if (onDecline == null) return cardBody;

    return Slidable(
      key: ValueKey('draft_$id'),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.2,
        children: [
          SlidableAction(
            onPressed: (_) => onEdit(),
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            icon: AppIcons.edit,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.2,
        children: [
          SlidableAction(
            onPressed: (_) => onDecline?.call(),
            backgroundColor: theme.expenseColor,
            foregroundColor: colors.surface,
            icon: AppIcons.close,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          ),
        ],
      ),
      child: cardBody,
    );
  }

  /// Builds the highest-priority suggestion chip, or null.
  /// Priority: wallet create > subscription > goal match.
  Widget? _buildSuggestionChip(
    BuildContext context,
    ColorScheme colors,
    TextTheme textStyles,
    dynamic theme,
  ) {
    // Priority 1: Unmatched wallet
    if (unmatchedHint != null) {
      return _chip(
        context: context,
        icon: AppIcons.add,
        label: context.l10n.voice_create_wallet_instead(unmatchedHint!),
        bgColor: colors.primary.withValues(alpha: AppSizes.opacityXLight),
        fgColor: colors.primary,
        onTap: onCreateWallet,
      );
    }

    // Priority 1b: Unmatched destination wallet (transfers)
    if (unmatchedToHint != null) {
      return _chip(
        context: context,
        icon: AppIcons.add,
        label: context.l10n.voice_create_wallet_instead(unmatchedToHint!),
        bgColor: colors.tertiary.withValues(alpha: AppSizes.opacityXLight),
        fgColor: colors.tertiary,
        onTap: onCreateToWallet,
      );
    }

    // Priority 2: Subscription suggestion
    if (isSubscriptionLike && !subscriptionAdded) {
      return _chip(
        context: context,
        icon: AppIcons.recurring,
        label: context.l10n.voice_confirm_subscription_suggest,
        bgColor: colors.tertiaryContainer,
        fgColor: colors.onTertiaryContainer,
        onTap: onSubscriptionTap,
      );
    }

    // Priority 3: Goal match
    if (matchedGoalName != null) {
      return _chip(
        context: context,
        icon: AppIcons.goals,
        label: matchedGoalName!,
        bgColor: (theme as dynamic)
            .incomeColor
            .withValues(alpha: AppSizes.opacityXLight) as Color,
        fgColor: (theme as dynamic).incomeColor as Color,
        // informational — tap card to edit
      );
    }

    return null;
  }

  Widget _chip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
    VoidCallback? onTap,
  }) {
    final textStyles = context.textStyles;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        top: AppSizes.xs,
        start: AppSizes.minTapTarget, // align with text, past checkbox
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xxs,
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppSizes.iconXxs2, color: fgColor),
              const SizedBox(width: AppSizes.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyles.labelSmall?.copyWith(color: fgColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
