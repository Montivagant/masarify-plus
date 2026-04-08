import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/brand_registry.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../domain/adapters/transfer_adapter.dart';
import '../../../domain/entities/transaction_entity.dart';
import 'brand_logo.dart';

/// Single transaction row for TransactionListSection and Dashboard.
///
/// Callers must pre-resolve category data (icon, color, name) to keep
/// this widget pure/stateless and avoid duplicate provider lookups.
///
/// When [brandInfo] is provided, a brand icon (colored circle with initial)
/// is shown instead of the category icon.
///
/// When [transferCounterpartIcon] is provided (for transfer entries), it
/// replaces the category icon to show the counterpart wallet type.
///
/// When [onDelete] or [onEdit] are provided, the card becomes swipeable
/// via flutter_slidable (left-swipe to delete, right-swipe to edit).
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    required this.categoryIcon,
    required this.categoryColor,
    required this.categoryName,
    this.brandInfo,
    this.transferCounterpartIcon,
    this.walletName,
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  final TransactionEntity transaction;
  final IconData categoryIcon;
  final Color categoryColor;
  final String categoryName;
  final BrandInfo? brandInfo;

  /// Counterpart wallet icon for transfer entries (e.g., bank or mobile wallet).
  final IconData? transferCounterpartIcon;

  /// Wallet/account name shown on the card in All Accounts view (D-15).
  /// When non-null, displays as a small label after the title.
  final String? walletName;

  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  String get _amountPrefix => switch (transaction.type) {
        'income' => '+',
        'transfer' => isTransferSender(transaction.tags) ? '\u2212' : '+',
        _ => '\u2212',
      };

  IconData? get _sourceIcon => switch (transaction.source) {
        'voice' => AppIcons.mic,
        'sms' || 'notification' => AppIcons.notification,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final appTheme = context.appTheme;
    final hasSlidable = onDelete != null || onEdit != null;

    final amountColor = switch (transaction.type) {
      'income' => appTheme.incomeColor,
      'expense' => appTheme.expenseColor,
      _ => appTheme.transferColor,
    };

    final card = _CardContent(
      transaction: transaction,
      categoryIcon: transferCounterpartIcon ?? categoryIcon,
      categoryColor: categoryColor,
      categoryName: categoryName,
      brandInfo: brandInfo,
      walletName: walletName,
      amountColor: amountColor,
      amountPrefix: _amountPrefix,
      sourceIcon: _sourceIcon,
      onTap: onTap,
    );

    if (!hasSlidable) return card;

    return Slidable(
      key: ValueKey(transaction.id),
      // Swipe right → edit
      startActionPane: onEdit != null
          ? ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) => onEdit!(),
                  backgroundColor: appTheme.transferColor,
                  foregroundColor: context.appTheme.onTransferColor,
                  icon: AppIcons.edit,
                  label: context.l10n.common_edit,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
              ],
            )
          : null,
      // Swipe left → delete
      endActionPane: onDelete != null
          ? ActionPane(
              motion: const BehindMotion(),
              extentRatio: 0.25,
              children: [
                SlidableAction(
                  onPressed: (_) => onDelete!(),
                  backgroundColor: appTheme.expenseColor,
                  foregroundColor: cs.onError,
                  icon: AppIcons.delete,
                  label: context.l10n.common_delete,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
              ],
            )
          : null,
      child: card,
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({
    required this.transaction,
    required this.categoryIcon,
    required this.categoryColor,
    required this.categoryName,
    this.brandInfo,
    this.walletName,
    required this.amountColor,
    required this.amountPrefix,
    required this.sourceIcon,
    this.onTap,
  });

  final TransactionEntity transaction;
  final IconData categoryIcon;
  final Color categoryColor;
  final String categoryName;
  final BrandInfo? brandInfo;
  final String? walletName;
  final Color amountColor;
  final String amountPrefix;
  final IconData? sourceIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final amountLabel =
        '$amountPrefix ${MoneyFormatter.format(transaction.amount, currency: transaction.currencyCode)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusMdSm),
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMdSm),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Left accent bar ──
              Container(
                width: AppSizes.xs,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: const BorderRadiusDirectional.only(
                    topStart: Radius.circular(AppSizes.borderRadiusMdSm),
                    bottomStart: Radius.circular(AppSizes.borderRadiusMdSm),
                  ),
                ),
              ),
              // ── Card body ──
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm,
                  ),
                  child: Row(
                    children: [
                      // Icon (brand or category)
                      if (brandInfo != null)
                        BrandLogo(brand: brandInfo!)
                      else
                        Icon(
                          categoryIcon,
                          size: AppSizes.iconMd,
                          color: categoryColor,
                        ),
                      const SizedBox(width: AppSizes.md),
                      // Text column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Row 1: Category name
                            Text(
                              categoryName,
                              style: context.textStyles.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            // Row 2: Transaction title
                            if (transaction.title.isNotEmpty) ...[
                              const SizedBox(height: AppSizes.xxs),
                              Text(
                                transaction.title,
                                style: context.textStyles.bodySmall?.copyWith(
                                  color: cs.outline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            // Row 3: Wallet + source
                            if (walletName != null || sourceIcon != null) ...[
                              const SizedBox(height: AppSizes.xxs),
                              Row(
                                children: [
                                  if (walletName != null)
                                    Flexible(
                                      child: Text(
                                        walletName!,
                                        style: context.textStyles.labelSmall
                                            ?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  if (sourceIcon != null) ...[
                                    if (walletName != null)
                                      const SizedBox(width: AppSizes.xs),
                                    Icon(
                                      sourceIcon!,
                                      size: AppSizes.iconXxs,
                                      color: cs.outline,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      // Amount
                      Semantics(
                        label: amountLabel,
                        excludeSemantics: true,
                        child: Text(
                          '$amountPrefix ${MoneyFormatter.formatAmount(transaction.amount)}',
                          style: context.textStyles.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: amountColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
