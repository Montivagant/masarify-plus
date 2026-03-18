import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/ai/chat_action.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Renders an action preview card in the chat with Confirm / Cancel buttons.
class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.action,
    required this.status,
    this.onConfirm,
    this.onCancel,
  });

  final ChatAction action;
  final ChatActionStatus status;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;

    final (icon, label, tint) = switch (action) {
      CreateGoalAction() => (
          AppIcons.goals,
          context.l10n.chat_action_goal_title,
          cs.primary,
        ),
      CreateTransactionAction(type: 'income') => (
          AppIcons.income,
          context.l10n.chat_action_tx_title,
          theme.incomeColor,
        ),
      CreateTransactionAction() => (
          AppIcons.expense,
          context.l10n.chat_action_tx_title,
          theme.expenseColor,
        ),
      CreateBudgetAction() => (
          AppIcons.budget,
          context.l10n.chat_action_budget_title,
          cs.tertiary,
        ),
      CreateRecurringAction() => (
          AppIcons.recurring,
          context.l10n.chat_action_recurring_title,
          cs.secondary,
        ),
      CreateWalletAction() => (
          AppIcons.wallet,
          context.l10n.chat_action_wallet_title,
          cs.primary,
        ),
      DeleteTransactionAction() => (
          AppIcons.delete,
          context.l10n.chat_action_delete_title,
          theme.expenseColor,
        ),
    };

    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.screenWidth * AppSizes.chatBubbleMaxWidthFraction,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start:
                AppSizes.iconXs + AppSizes.xs, // align with bubble after avatar
            bottom: AppSizes.sm,
          ),
          child: GlassCard(
            tintColor: tint.withValues(alpha: AppSizes.opacitySubtle),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(icon, size: AppSizes.iconSm, color: tint),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        label,
                        style: context.textStyles.labelLarge?.copyWith(
                          color: tint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),

                // Details
                ..._buildDetails(context),
                const SizedBox(height: AppSizes.md),

                // Action buttons / status
                _buildFooter(context, tint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDetails(BuildContext context) {
    final cs = context.colors;
    final detailStyle = context.textStyles.bodySmall;
    final valueStyle = context.textStyles.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    final labelS = detailStyle?.copyWith(color: cs.outline);
    return switch (action) {
      CreateGoalAction(
        :final name,
        :final targetAmountPiastres,
        :final deadline
      ) =>
        [
          _DetailLine(
              label: context.l10n.transaction_title_label,
              value: name,
              labelStyle: labelS,
              valueStyle: valueStyle,),
          _DetailLine(
              label: context.l10n.goal_target_label,
              value: MoneyFormatter.format(targetAmountPiastres),
              labelStyle: labelS,
              valueStyle: valueStyle,),
          if (deadline != null)
            _DetailLine(
                label: context.l10n.goal_deadline,
                value: _formatDeadline(context, deadline),
                labelStyle: labelS,
                valueStyle: valueStyle,),
        ],
      CreateTransactionAction(
        :final title,
        :final amountPiastres,
        :final type,
        :final categoryName,
        :final date
      ) =>
        [
          _DetailLine(
              label: context.l10n.transaction_title_label,
              value: title,
              labelStyle: labelS,
              valueStyle: valueStyle,),
          _DetailLine(
            label: context.l10n.common_amount,
            value: MoneyFormatter.format(amountPiastres),
            labelStyle: labelS,
            valueStyle: valueStyle?.copyWith(
                color: type == 'income'
                    ? context.appTheme.incomeColor
                    : context.appTheme.expenseColor,),
          ),
          _DetailLine(
              label: context.l10n.transaction_category,
              value: categoryName,
              labelStyle: labelS,
              valueStyle: valueStyle,),
          if (date != null)
            _DetailLine(
                label: context.l10n.transaction_date,
                value: _formatDate(context, date),
                labelStyle: labelS,
                valueStyle: valueStyle,),
        ],
      CreateBudgetAction(:final categoryName, :final limitPiastres) => [
          _DetailLine(
              label: context.l10n.transaction_category,
              value: categoryName,
              labelStyle: labelS,
              valueStyle: valueStyle,),
          _DetailLine(
              label: context.l10n.budget_limit,
              value: MoneyFormatter.format(limitPiastres),
              labelStyle: labelS,
              valueStyle: valueStyle,),
        ],
      CreateRecurringAction(
        :final title,
        :final amountPiastres,
        :final frequency,
        :final categoryName
      ) =>
        [
          _DetailLine(
              label: context.l10n.transaction_title_label,
              value: title,
              labelStyle: labelS,
              valueStyle: valueStyle,),
          _DetailLine(
              label: context.l10n.common_amount,
              value: MoneyFormatter.format(amountPiastres),
              labelStyle: labelS,
              valueStyle: valueStyle,),
          _DetailLine(
              label: context.l10n.recurring_frequency_label,
              value: frequency,
              labelStyle: labelS,
              valueStyle: valueStyle,),
          _DetailLine(
              label: context.l10n.transaction_category,
              value: categoryName,
              labelStyle: labelS,
              valueStyle: valueStyle,),
        ],
      CreateWalletAction(
        :final name,
        :final type,
        :final initialBalancePiastres
      ) =>
        [
          _DetailLine(
              label: context.l10n.wallet_name_label,
              value: name,
              labelStyle: labelS,
              valueStyle: valueStyle,),
          _DetailLine(
              label: context.l10n.wallet_type_label,
              value: type,
              labelStyle: labelS,
              valueStyle: valueStyle,),
          _DetailLine(
              label: context.l10n.wallet_initial_balance,
              value: MoneyFormatter.format(initialBalancePiastres),
              labelStyle: labelS,
              valueStyle: valueStyle,),
        ],
      DeleteTransactionAction(
        :final title,
        :final amountPiastres,
        :final date
      ) =>
        [
          _DetailLine(
              label: context.l10n.transaction_title_label,
              value: title,
              labelStyle: labelS,
              valueStyle: valueStyle,),
          _DetailLine(
            label: context.l10n.common_amount,
            value: MoneyFormatter.format(amountPiastres),
            labelStyle: labelS,
            valueStyle:
                valueStyle?.copyWith(color: context.appTheme.expenseColor),
          ),
          if (date != null)
            _DetailLine(
                label: context.l10n.transaction_date,
                value: _formatDate(context, date),
                labelStyle: labelS,
                valueStyle: valueStyle,),
        ],
    };
  }

  Widget _buildFooter(BuildContext context, Color tint) {
    final cs = context.colors;

    return switch (status) {
      ChatActionStatus.confirmed => Row(
          children: [
            Icon(AppIcons.check,
                size: AppSizes.iconSm, color: context.appTheme.incomeColor,),
            const SizedBox(width: AppSizes.xs),
            Text(
              context.l10n.chat_action_confirmed,
              style: context.textStyles.labelMedium?.copyWith(
                color: context.appTheme.incomeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ChatActionStatus.cancelled => Text(
          context.l10n.chat_action_cancelled,
          style: context.textStyles.labelMedium?.copyWith(
            color: cs.outline,
          ),
        ),
      ChatActionStatus.failed => Row(
          children: [
            Icon(AppIcons.warning,
                size: AppSizes.iconXs, color: context.appTheme.expenseColor,),
            const SizedBox(width: AppSizes.xs),
            Expanded(
              child: Text(
                context.l10n.chat_action_failed,
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.appTheme.expenseColor,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            TextButton(
              onPressed: onConfirm,
              child: Text(context.l10n.chat_action_retry),
            ),
          ],
        ),
      ChatActionStatus.pending => Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: onCancel,
              child: Text(context.l10n.chat_action_cancel),
            ),
            const SizedBox(width: AppSizes.sm),
            FilledButton(
              onPressed: onConfirm,
              style: FilledButton.styleFrom(backgroundColor: tint),
              child: Text(context.l10n.chat_action_confirm),
            ),
          ],
        ),
    };
  }

  String _formatDeadline(BuildContext context, String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    return DateFormat.yMMMd(context.languageCode).format(parsed);
  }

  String _formatDate(BuildContext context, String isoDate) {
    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;
    return DateFormat.yMd(context.languageCode).format(parsed);
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSizes.chatActionLabelWidth,
            child: Text(label, style: labelStyle),
          ),
          const SizedBox(width: AppSizes.xs),
          Expanded(child: Text(value, style: valueStyle)),
        ],
      ),
    );
  }
}
