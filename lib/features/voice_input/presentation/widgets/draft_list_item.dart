import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Substantial glassmorphic card for the voice transaction review screen
/// (list-view mode). Matches the visual weight of the Tinder-style swipe cards.
///
/// Layout (stacked vertically):
///   Row 1: Category icon circle + category name + amount (right-aligned)
///   Row 2: Transaction title + raw transcript (muted italic)
///   Row 3: Detail pills (wallet, date, type)
///   Suggestion chip (if any)
///   Row 4: Include checkbox + Edit button
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
    this.rawTranscript,
    this.transactionDate,
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
  final String? rawTranscript;
  final DateTime? transactionDate;

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
        showShadow: true,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.screenHPadding,
          vertical: AppSizes.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Row 1: Category icon + name + amount ──────────────
            Row(
              children: [
                // Category icon in colored circle
                Container(
                  width: AppSizes.minTapTarget,
                  height: AppSizes.minTapTarget,
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
                // Category name
                Expanded(
                  child: Text(
                    categoryName ?? '\u2014',
                    style: textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                // Amount (right-aligned, color-coded, tabular figures)
                Text(
                  formattedAmount,
                  style: textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: typeColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSizes.sm),

            // ── Row 2: Title + raw transcript ─────────────────────
            Text(
              title,
              style: textStyles.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (rawTranscript != null && rawTranscript != title) ...[
              const SizedBox(height: AppSizes.xxs),
              Text(
                rawTranscript!,
                style: textStyles.bodySmall?.copyWith(
                  color: colors.outline,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            const SizedBox(height: AppSizes.sm),

            // ── Row 3: Detail pills ───────────────────────────────
            Wrap(
              spacing: AppSizes.xs,
              runSpacing: AppSizes.xs,
              children: [
                if (walletName != null)
                  _detailPill(
                    context,
                    walletName!,
                    colors.secondaryContainer,
                  ),
                if (transactionDate != null)
                  _detailPill(
                    context,
                    DateFormat('MMM d').format(transactionDate!),
                    colors.tertiaryContainer,
                  ),
                _detailPill(
                  context,
                  _typeLabel(context),
                  typeColor.withValues(alpha: AppSizes.opacityLight),
                ),
              ],
            ),

            // ── Suggestion chip (if any) ──────────────────────────
            if (suggestionChip != null) ...[
              const SizedBox(height: AppSizes.sm),
              suggestionChip,
            ],

            const SizedBox(height: AppSizes.sm),

            // ── Row 4: Include checkbox + Edit button ─────────────
            Row(
              children: [
                SizedBox(
                  width: AppSizes.iconMd,
                  height: AppSizes.iconMd,
                  child: Checkbox(
                    value: isIncluded,
                    onChanged: (_) => onToggle(),
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                Text(
                  context.l10n.voice_include,
                  style: textStyles.bodySmall,
                ),
                const Spacer(),
                TextButton(
                  onPressed: onEdit,
                  child: Text(context.l10n.common_edit),
                ),
              ],
            ),
          ],
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

  // ── Helper: detail pill ───────────────────────────────────────────
  Widget _detailPill(BuildContext context, String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xxs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
      ),
      child: Text(
        text,
        style: context.textStyles.labelSmall,
      ),
    );
  }

  // ── Helper: localized type label ──────────────────────────────────
  String _typeLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (type) {
      'income' => l10n.transaction_type_income,
      'expense' => l10n.transaction_type_expense,
      'transfer' => l10n.transaction_type_transfer,
      'cash_withdrawal' => l10n.transaction_type_cash_withdrawal_short,
      'cash_deposit' => l10n.transaction_type_cash_deposit_short,
      _ => type,
    };
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
    return GestureDetector(
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
    );
  }
}
