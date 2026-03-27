import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';

/// Editable draft model passed into [DraftCard].
/// Kept separate from VoiceTransactionDraft so fields can be mutated.
class EditableDraft {
  EditableDraft({
    required this.rawText,
    required this.amountPiastres,
    this.categoryHint,
    this.walletHint,
    this.note,
    required this.type,
    required this.transactionDate,
  }) : noteController = TextEditingController(text: note ?? rawText);

  final String rawText;
  int amountPiastres;
  String? categoryHint;
  String? walletHint;
  String? note;
  int? categoryId;
  int? walletId;
  int? toWalletId;
  int? goalId;
  String? matchedGoalName;
  String type;
  DateTime transactionDate;
  bool isIncluded = true;

  /// Set when wallet hint had no match — transaction defaulted to Default account.
  String? unmatchedHint;

  /// Editable title/note for refining the transaction description.
  final TextEditingController noteController;
}

/// A single voice-parsed draft rendered as a glassmorphic form card.
///
/// Displays: type chips, prominent amount with type coloring, category picker,
/// account picker (with dual account for transfers), date picker, notes field,
/// and subscription suggestion — all using design tokens exclusively.
class DraftCard extends StatelessWidget {
  const DraftCard({
    super.key,
    required this.draft,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    this.walletName,
    this.toWalletName,
    this.matchedGoalName,
    required this.showSubscriptionSuggestion,
    required this.amountMissing,
    required this.onAmountChanged,
    required this.onTypeChanged,
    required this.onCategoryTap,
    required this.onWalletTap,
    this.onToWalletTap,
    required this.onDateChanged,
    required this.onNotesChanged,
    this.onSubscriptionSuggestionAccepted,
    this.onSubscriptionSuggestionDismissed,
    this.onCreateWalletFromHint,
  });

  final EditableDraft draft;
  final String? categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final String? walletName;
  final String? toWalletName;
  final String? matchedGoalName;
  final bool showSubscriptionSuggestion;
  final bool amountMissing;
  final ValueChanged<int> onAmountChanged;
  final ValueChanged<String> onTypeChanged;
  final VoidCallback onCategoryTap;
  final VoidCallback onWalletTap;
  final VoidCallback? onToWalletTap;
  final ValueChanged<DateTime> onDateChanged;
  final ValueChanged<String> onNotesChanged;
  final VoidCallback? onSubscriptionSuggestionAccepted;
  final VoidCallback? onSubscriptionSuggestionDismissed;
  final VoidCallback? onCreateWalletFromHint;

  /// Returns the semantic color for the given transaction type.
  Color _typeColor(BuildContext context) => switch (draft.type) {
        'income' => context.appTheme.incomeColor,
        'cash_withdrawal' ||
        'cash_deposit' ||
        'transfer' =>
          context.appTheme.transferColor,
        _ => context.appTheme.expenseColor,
      };

  /// Returns true for cash withdrawal or deposit types.
  bool get _isCashType =>
      draft.type == 'cash_withdrawal' || draft.type == 'cash_deposit';

  /// Returns true for transfer-like types (transfer, cash_withdrawal, cash_deposit).
  bool get _isTransferLike =>
      draft.type == 'transfer' ||
      draft.type == 'cash_withdrawal' ||
      draft.type == 'cash_deposit';

  /// Returns the sign prefix for the amount display.
  String get _signPrefix => switch (draft.type) {
        'income' || 'cash_deposit' => '+ ',
        'transfer' => '\u2194 ', // ↔
        'cash_withdrawal' => '- ',
        _ => '- ',
      };

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final typeColor = _typeColor(context);

    return GlassCard(
      padding: EdgeInsetsDirectional.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Type indicator chips ─────────────────────────────────
          _buildTypeChips(context, typeColor),

          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSizes.md,
              0,
              AppSizes.md,
              AppSizes.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Amount section (prominent) ────────────────────────
                _buildAmountSection(context, typeColor),
                const SizedBox(height: AppSizes.md),

                // ── Category field ────────────────────────────────────
                if (!_isCashType) ...[
                  _buildFieldRow(
                    context,
                    icon: categoryIcon,
                    iconColor: categoryColor,
                    label: categoryName ??
                        context.l10n.voice_confirm_select_category,
                    labelColor:
                        categoryName != null ? cs.onSurface : cs.outline,
                    onTap: onCategoryTap,
                  ),
                  const SizedBox(height: AppSizes.sm),
                ],

                // ── Account field(s) ──────────────────────────────────
                if (_isTransferLike)
                  _buildTransferAccountFields(context)
                else ...[
                  _buildFieldRow(
                    context,
                    icon: AppIcons.wallet,
                    iconColor: cs.primary,
                    label:
                        walletName ?? context.l10n.voice_confirm_select_account,
                    labelColor: walletName != null ? cs.onSurface : cs.outline,
                    onTap: onWalletTap,
                  ),
                  if (draft.unmatchedHint != null)
                    _buildCreateWalletHint(context),
                ],
                const SizedBox(height: AppSizes.sm),

                // ── Date field ────────────────────────────────────────
                _buildDateField(context),
                const SizedBox(height: AppSizes.sm),

                // ── Notes field ───────────────────────────────────────
                _buildNotesField(context),

                // ── Goal suggestion ───────────────────────────────────
                if (matchedGoalName != null) ...[
                  const SizedBox(height: AppSizes.sm),
                  _buildGoalSuggestion(context),
                ],

                // ── Subscription suggestion ───────────────────────────
                if (showSubscriptionSuggestion) ...[
                  const SizedBox(height: AppSizes.sm),
                  _buildSubscriptionSuggestion(context),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Type chips row ──────────────────────────────────────────────────────

  Widget _buildTypeChips(BuildContext context, Color activeColor) {
    final types = <String, String>{
      'expense': context.l10n.transaction_type_expense,
      'income': context.l10n.transaction_type_income,
      'transfer': context.l10n.transaction_type_transfer,
    };

    // Cash types are not user-changeable but still displayed.
    if (_isCashType) {
      final label = draft.type == 'cash_withdrawal'
          ? context.l10n.transaction_type_cash_withdrawal_short
          : context.l10n.transaction_type_cash_deposit_short;
      return Padding(
        padding: const EdgeInsetsDirectional.all(AppSizes.md),
        child: Wrap(
          spacing: AppSizes.sm,
          children: [
            _TypeChip(
              label: label,
              isActive: true,
              activeColor: activeColor,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSizes.md),
      child: Wrap(
        spacing: AppSizes.sm,
        children: types.entries.map((entry) {
          final isActive = draft.type == entry.key;
          final chipColor = switch (entry.key) {
            'income' => context.appTheme.incomeColor,
            'transfer' => context.appTheme.transferColor,
            _ => context.appTheme.expenseColor,
          };
          return _TypeChip(
            label: entry.value,
            isActive: isActive,
            activeColor: chipColor,
            onTap: isActive ? null : () => onTypeChanged(entry.key),
          );
        }).toList(),
      ),
    );
  }

  // ── Amount section ──────────────────────────────────────────────────────

  Widget _buildAmountSection(BuildContext context, Color typeColor) {
    final cs = context.colors;

    if (amountMissing) {
      // Missing amount: highlighted error field
      return GlassCard(
        tier: GlassTier.inset,
        padding: const EdgeInsetsDirectional.all(AppSizes.md),
        tintColor: cs.errorContainer.withValues(alpha: AppSizes.opacityLight3),
        child: Column(
          children: [
            Text(
              context.l10n.voice_confirm_amount_missing,
              style: context.textStyles.bodySmall?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            AmountInput(
              onAmountChanged: onAmountChanged,
              textColor: typeColor,
            ),
          ],
        ),
      );
    }

    // Normal amount display — large, prominent, type-colored
    return GlassCard(
      tier: GlassTier.inset,
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Column(
        children: [
          Text(
            '$_signPrefix${MoneyFormatter.format(draft.amountPiastres)}',
            style: context.textStyles.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: typeColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.xs),
          // Tappable hint to edit amount
          AmountInput(
            onAmountChanged: onAmountChanged,
            initialPiastres: draft.amountPiastres,
            autofocus: false,
            compact: true,
            textColor: typeColor,
          ),
        ],
      ),
    );
  }

  // ── Generic tappable field row ──────────────────────────────────────────

  Widget _buildFieldRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    Color? labelColor,
    required VoidCallback onTap,
  }) {
    final cs = context.colors;
    return GlassCard(
      tier: GlassTier.inset,
      padding: EdgeInsetsDirectional.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          child: Row(
            children: [
              Container(
                width: AppSizes.iconContainerSm,
                height: AppSizes.iconContainerSm,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: AppSizes.opacityLight2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: AppSizes.iconSm, color: iconColor),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  label,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: labelColor ?? cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                AppIcons.chevronRight,
                size: AppSizes.iconSm,
                color: cs.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Transfer account fields (From → To) ────────────────────────────────

  Widget _buildTransferAccountFields(BuildContext context) {
    final cs = context.colors;
    final isRtl = context.isRtl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // From account
        _buildFieldRow(
          context,
          icon: AppIcons.wallet,
          iconColor: cs.primary,
          label:
              '${context.l10n.voice_confirm_from_account}: ${walletName ?? context.l10n.voice_confirm_select_account}',
          labelColor: walletName != null ? cs.onSurface : cs.outline,
          onTap: onWalletTap,
        ),
        if (draft.unmatchedHint != null) _buildCreateWalletHint(context),

        // Directional arrow — flips in RTL
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            vertical: AppSizes.xs,
          ),
          child: Center(
            child: Transform.flip(
              flipX: isRtl,
              child: Icon(
                AppIcons.expense,
                size: AppSizes.iconMd,
                color: context.appTheme.transferColor,
              ),
            ),
          ),
        ),

        // To account
        _buildFieldRow(
          context,
          icon: AppIcons.wallet,
          iconColor: context.appTheme.transferColor,
          label:
              '${context.l10n.voice_confirm_to_account}: ${toWalletName ?? context.l10n.voice_confirm_select_account}',
          labelColor: toWalletName != null ? cs.onSurface : cs.outline,
          onTap: onToWalletTap ?? onWalletTap,
        ),
      ],
    );
  }

  // ── Create wallet hint for unmatched wallet ────────────────────────────

  Widget _buildCreateWalletHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSizes.sm,
        top: AppSizes.xs,
      ),
      child: TextButton(
        onPressed: onCreateWalletFromHint,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          context.l10n.voice_create_wallet_instead(draft.unmatchedHint!),
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.primary,
          ),
        ),
      ),
    );
  }

  // ── Date field ──────────────────────────────────────────────────────────

  Widget _buildDateField(BuildContext context) {
    final cs = context.colors;
    final formattedDate =
        DateFormat.yMMMd(context.languageCode).format(draft.transactionDate);

    return GlassCard(
      tier: GlassTier.inset,
      padding: EdgeInsetsDirectional.zero,
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: draft.transactionDate,
            firstDate: DateTime(2000),
            lastDate: DateTime.now().add(AppDurations.datePickerMaxOffset),
          );
          if (picked != null) onDateChanged(picked);
        },
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppSizes.md,
            vertical: AppSizes.sm,
          ),
          child: Row(
            children: [
              Container(
                width: AppSizes.iconContainerSm,
                height: AppSizes.iconContainerSm,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: AppSizes.opacityLight2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.calendar,
                  size: AppSizes.iconSm,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                formattedDate,
                style: context.textStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Notes field ─────────────────────────────────────────────────────────

  Widget _buildNotesField(BuildContext context) {
    return GlassCard(
      tier: GlassTier.inset,
      padding: EdgeInsetsDirectional.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: AppSizes.sm),
              child: Icon(
                AppIcons.edit,
                size: AppSizes.iconSm,
                color: context.colors.outline,
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: TextField(
                controller: draft.noteController,
                onChanged: onNotesChanged,
                style: context.textStyles.bodyMedium,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: context.l10n.voice_confirm_add_notes,
                  hintStyle: context.textStyles.bodyMedium?.copyWith(
                    color: context.colors.outline,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: AppSizes.sm,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Goal suggestion ─────────────────────────────────────────────────────

  Widget _buildGoalSuggestion(BuildContext context) {
    final cs = context.colors;
    return Row(
      children: [
        Icon(AppIcons.goals, size: AppSizes.iconXxs2, color: cs.tertiary),
        const SizedBox(width: AppSizes.xs),
        Flexible(
          child: Text(
            context.l10n.goal_link_prompt(matchedGoalName!),
            style: context.textStyles.bodySmall?.copyWith(
              color: cs.tertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ── Subscription suggestion ─────────────────────────────────────────────

  Widget _buildSubscriptionSuggestion(BuildContext context) {
    final cs = context.colors;
    return GlassCard(
      tier: GlassTier.inset,
      tintColor: context.appTheme.transferColor
          .withValues(alpha: AppSizes.opacityXLight),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSizes.md,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          Icon(
            AppIcons.recurring,
            size: AppSizes.iconSm,
            color: context.appTheme.transferColor,
          ),
          const SizedBox(width: AppSizes.sm),
          Expanded(
            child: Text(
              context.l10n.voice_confirm_subscription_suggest,
              style: context.textStyles.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: onSubscriptionSuggestionDismissed,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
            ),
            child: Text(
              context.l10n.common_dismiss,
              style: context.textStyles.bodySmall?.copyWith(
                color: cs.outline,
              ),
            ),
          ),
          FilledButton(
            onPressed: onSubscriptionSuggestionAccepted,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
            ),
            child: Text(
              context.l10n.common_save,
              style: context.textStyles.bodySmall?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Type chip (private) ───────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isActive,
    required this.activeColor,
    this.onTap,
  });

  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.animQuick,
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: AppSizes.opacityLight3)
              : context.colors.surfaceContainerHighest
                  .withValues(alpha: AppSizes.opacityLight2),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
          border: Border.all(
            color: isActive ? activeColor : context.colors.outlineVariant,
            width: isActive ? AppSizes.borderWidthFocus : AppSizes.borderWidth,
          ),
        ),
        child: Text(
          label,
          style: context.textStyles.bodySmall?.copyWith(
            color: isActive ? activeColor : context.colors.outline,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
