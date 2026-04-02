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
      CreateTransferAction() => (
          AppIcons.transfer,
          context.l10n.chat_action_transfer_title,
          theme.transferColor,
        ),
      DeleteTransactionAction() => (
          AppIcons.delete,
          context.l10n.chat_action_delete_title,
          theme.expenseColor,
        ),
      UpdateTransactionAction() => (
          AppIcons.edit,
          context.l10n.chat_action_update_tx_title,
          cs.primary,
        ),
      UpdateBudgetAction() => (
          AppIcons.budget,
          context.l10n.chat_action_update_budget_title,
          cs.tertiary,
        ),
      DeleteBudgetAction() => (
          AppIcons.delete,
          context.l10n.chat_action_delete_budget_title,
          theme.expenseColor,
        ),
      DeleteGoalAction() => (
          AppIcons.delete,
          context.l10n.chat_action_delete_goal_title,
          theme.expenseColor,
        ),
      DeleteRecurringAction() => (
          AppIcons.delete,
          context.l10n.chat_action_delete_recurring_title,
          theme.expenseColor,
        ),
      UpdateWalletAction() => (
          AppIcons.wallet,
          context.l10n.chat_action_update_wallet_title,
          cs.primary,
        ),
      UpdateGoalAction() => (
          AppIcons.goals,
          context.l10n.chat_action_update_goal_title,
          cs.primary,
        ),
      UpdateRecurringAction() => (
          AppIcons.recurring,
          context.l10n.chat_action_update_recurring_title,
          cs.secondary,
        ),
      UpdateCategoryAction() => (
          AppIcons.edit,
          context.l10n.chat_action_update_category_title,
          cs.tertiary,
        ),
      CreateCategoryAction() => (
          AppIcons.add,
          context.l10n.chat_action_create_category_title,
          cs.tertiary,
        ),
      DeleteWalletAction() => (
          AppIcons.delete,
          context.l10n.chat_action_delete_wallet_title,
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
            valueStyle: valueStyle,
          ),
          _DetailLine(
            label: context.l10n.goal_target_label,
            value: MoneyFormatter.format(targetAmountPiastres),
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          if (deadline != null)
            _DetailLine(
              label: context.l10n.goal_deadline,
              value: _formatDeadline(context, deadline),
              labelStyle: labelS,
              valueStyle: valueStyle,
            ),
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
            valueStyle: valueStyle,
          ),
          _DetailLine(
            label: context.l10n.common_amount,
            value: MoneyFormatter.format(amountPiastres),
            labelStyle: labelS,
            valueStyle: valueStyle?.copyWith(
              color: type == 'income'
                  ? context.appTheme.incomeColor
                  : context.appTheme.expenseColor,
            ),
          ),
          _DetailLine(
            label: context.l10n.transaction_category,
            value: categoryName,
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          if (date != null)
            _DetailLine(
              label: context.l10n.transaction_date,
              value: _formatDate(context, date),
              labelStyle: labelS,
              valueStyle: valueStyle,
            ),
        ],
      CreateBudgetAction(:final categoryName, :final limitPiastres) => [
          _DetailLine(
            label: context.l10n.transaction_category,
            value: categoryName,
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          _DetailLine(
            label: context.l10n.budget_limit,
            value: MoneyFormatter.format(limitPiastres),
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
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
            valueStyle: valueStyle,
          ),
          _DetailLine(
            label: context.l10n.common_amount,
            value: MoneyFormatter.format(amountPiastres),
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          _DetailLine(
            label: context.l10n.recurring_frequency_label,
            value: _localizeFrequency(context, frequency),
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          _DetailLine(
            label: context.l10n.transaction_category,
            value: categoryName,
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
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
            valueStyle: valueStyle,
          ),
          _DetailLine(
            label: context.l10n.wallet_type_label,
            value: _localizeWalletType(context, type),
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          _DetailLine(
            label: context.l10n.wallet_initial_balance,
            value: MoneyFormatter.format(initialBalancePiastres),
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
        ],
      CreateTransferAction(
        :final amountPiastres,
        :final fromWalletName,
        :final toWalletName,
      ) =>
        [
          _DetailLine(
            label: context.l10n.voice_transfer_from,
            value: fromWalletName,
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          _DetailLine(
            label: context.l10n.voice_transfer_to,
            value: toWalletName,
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          _DetailLine(
            label: context.l10n.common_amount,
            value: MoneyFormatter.format(amountPiastres),
            labelStyle: labelS,
            valueStyle: valueStyle?.copyWith(
              color: context.appTheme.transferColor,
            ),
          ),
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
            valueStyle: valueStyle,
          ),
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
              valueStyle: valueStyle,
            ),
        ],
      UpdateTransactionAction(
        :final title,
        :final amountPiastres,
        :final newTitle,
        :final newAmountPiastres,
        :final newCategory,
      ) =>
        [
          _DetailLine(
            label: context.l10n.transaction_title_label,
            value: title,
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          _DetailLine(
            label: context.l10n.common_amount,
            value: MoneyFormatter.format(amountPiastres),
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          if (newTitle != null)
            _DetailLine(
              label: '→ ${context.l10n.transaction_title_label}',
              value: newTitle,
              labelStyle: labelS,
              valueStyle: valueStyle?.copyWith(color: cs.primary),
            ),
          if (newAmountPiastres != null)
            _DetailLine(
              label: '→ ${context.l10n.common_amount}',
              value: MoneyFormatter.format(newAmountPiastres),
              labelStyle: labelS,
              valueStyle: valueStyle?.copyWith(color: cs.primary),
            ),
          if (newCategory != null)
            _DetailLine(
              label: '→ ${context.l10n.transaction_category}',
              value: newCategory,
              labelStyle: labelS,
              valueStyle: valueStyle?.copyWith(color: cs.primary),
            ),
        ],
      UpdateBudgetAction(:final categoryName, :final newLimitPiastres) => [
          _DetailLine(
            label: context.l10n.transaction_category,
            value: categoryName,
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          _DetailLine(
            label: '→ ${context.l10n.budget_limit}',
            value: MoneyFormatter.format(newLimitPiastres),
            labelStyle: labelS,
            valueStyle: valueStyle?.copyWith(color: cs.primary),
          ),
        ],
      DeleteBudgetAction(:final categoryName) => [
          _DetailLine(
            label: context.l10n.transaction_category,
            value: categoryName,
            labelStyle: labelS,
            valueStyle:
                valueStyle?.copyWith(color: context.appTheme.expenseColor),
          ),
        ],
      DeleteGoalAction(:final name) => [
          _DetailLine(
            label: context.l10n.transaction_title_label,
            value: name,
            labelStyle: labelS,
            valueStyle:
                valueStyle?.copyWith(color: context.appTheme.expenseColor),
          ),
        ],
      DeleteRecurringAction(:final title) => [
          _DetailLine(
            label: context.l10n.transaction_title_label,
            value: title,
            labelStyle: labelS,
            valueStyle:
                valueStyle?.copyWith(color: context.appTheme.expenseColor),
          ),
        ],
      UpdateWalletAction(:final name, :final newName, :final newType) => [
          _DetailLine(
            label: context.l10n.wallet_name_label,
            value: name,
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          if (newName != null)
            _DetailLine(
              label: '→ ${context.l10n.wallet_name_label}',
              value: newName,
              labelStyle: labelS,
              valueStyle: valueStyle?.copyWith(color: cs.primary),
            ),
          if (newType != null)
            _DetailLine(
              label: '→ ${context.l10n.wallet_type_label}',
              value: _localizeWalletType(context, newType),
              labelStyle: labelS,
              valueStyle: valueStyle?.copyWith(color: cs.primary),
            ),
        ],
      UpdateGoalAction(
        :final name,
        :final newName,
        :final newTargetAmountPiastres,
        :final newDeadline,
      ) =>
        [
          _DetailLine(
            label: context.l10n.transaction_title_label,
            value: name,
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          if (newName != null)
            _DetailLine(
              label: '→ ${context.l10n.transaction_title_label}',
              value: newName,
              labelStyle: labelS,
              valueStyle: valueStyle?.copyWith(color: cs.primary),
            ),
          if (newTargetAmountPiastres != null)
            _DetailLine(
              label: '→ ${context.l10n.goal_target_label}',
              value: MoneyFormatter.format(newTargetAmountPiastres),
              labelStyle: labelS,
              valueStyle: valueStyle?.copyWith(color: cs.primary),
            ),
          if (newDeadline != null)
            _DetailLine(
              label: '→ ${context.l10n.goal_deadline}',
              value: _formatDeadline(context, newDeadline),
              labelStyle: labelS,
              valueStyle: valueStyle?.copyWith(color: cs.primary),
            ),
        ],
      UpdateRecurringAction(
        :final title,
        :final newTitle,
        :final newAmountPiastres,
        :final newFrequency,
      ) =>
        [
          _DetailLine(
            label: context.l10n.transaction_title_label,
            value: title,
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          if (newTitle != null)
            _DetailLine(
              label: '→ ${context.l10n.transaction_title_label}',
              value: newTitle,
              labelStyle: labelS,
              valueStyle: valueStyle?.copyWith(color: cs.primary),
            ),
          if (newAmountPiastres != null)
            _DetailLine(
              label: '→ ${context.l10n.common_amount}',
              value: MoneyFormatter.format(newAmountPiastres),
              labelStyle: labelS,
              valueStyle: valueStyle?.copyWith(color: cs.primary),
            ),
          if (newFrequency != null)
            _DetailLine(
              label: '→ ${context.l10n.recurring_frequency_label}',
              value: _localizeFrequency(context, newFrequency),
              labelStyle: labelS,
              valueStyle: valueStyle?.copyWith(color: cs.primary),
            ),
        ],
      UpdateCategoryAction(:final name, :final newName, :final newNameAr) => [
          _DetailLine(
            label: context.l10n.transaction_category,
            value: name,
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          if (newName != null)
            _DetailLine(
              label: '→ ${context.l10n.transaction_category}',
              value: newName,
              labelStyle: labelS,
              valueStyle: valueStyle?.copyWith(color: cs.primary),
            ),
          if (newNameAr != null)
            _DetailLine(
              label: '→ AR',
              value: newNameAr,
              labelStyle: labelS,
              valueStyle: valueStyle?.copyWith(color: cs.primary),
            ),
        ],
      CreateCategoryAction(:final name, :final nameAr, :final type) => [
          _DetailLine(
            label: context.l10n.transaction_category,
            value: '$name ($nameAr)',
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
          _DetailLine(
            label: context.l10n.wallet_type_label,
            value: type,
            labelStyle: labelS,
            valueStyle: valueStyle,
          ),
        ],
      DeleteWalletAction(:final name) => [
          _DetailLine(
            label: context.l10n.wallet_name_label,
            value: name,
            labelStyle: labelS,
            valueStyle:
                valueStyle?.copyWith(color: context.appTheme.expenseColor),
          ),
        ],
    };
  }

  Widget _buildFooter(BuildContext context, Color tint) {
    final cs = context.colors;

    return switch (status) {
      ChatActionStatus.confirmed => Row(
          children: [
            Icon(
              AppIcons.check,
              size: AppSizes.iconSm,
              color: context.appTheme.incomeColor,
            ),
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
            Icon(
              AppIcons.warning,
              size: AppSizes.iconXs,
              color: context.appTheme.expenseColor,
            ),
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

  /// Localize a frequency value from the AI JSON (always English).
  String _localizeFrequency(BuildContext context, String freq) =>
      switch (freq.toLowerCase()) {
        'daily' => context.l10n.recurring_frequency_daily,
        'weekly' => context.l10n.recurring_frequency_weekly,
        'monthly' => context.l10n.recurring_frequency_monthly,
        'yearly' => context.l10n.recurring_frequency_yearly,
        'once' => context.l10n.recurring_frequency_once,
        'custom' => context.l10n.recurring_frequency_custom,
        _ => freq,
      };

  /// Localize a wallet type value from the AI JSON (always English).
  String _localizeWalletType(BuildContext context, String type) =>
      switch (type.toLowerCase()) {
        'bank' => context.l10n.wallet_type_bank_short,
        'mobile_wallet' => context.l10n.wallet_type_mobile_wallet_short,
        'credit_card' => context.l10n.wallet_type_credit_card_short,
        'prepaid_card' => context.l10n.wallet_type_prepaid_card_short,
        'investment' => context.l10n.wallet_type_investment_short,
        _ => type,
      };
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
