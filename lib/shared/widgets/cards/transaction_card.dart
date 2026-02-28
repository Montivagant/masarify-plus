import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../domain/entities/transaction_entity.dart';

/// Single transaction row for TransactionListSection and Dashboard.
///
/// Callers must pre-resolve category data (icon, color, name) to keep
/// this widget pure/stateless and avoid duplicate provider lookups.
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
    this.onTap,
    this.onDelete,
    this.onEdit,
  });

  final TransactionEntity transaction;
  final IconData categoryIcon;
  final Color categoryColor;
  final String categoryName;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  String get _amountPrefix => transaction.type == 'income' ? '+' : '−';

  IconData? get _sourceIcon => switch (transaction.source) {
        'voice' => AppIcons.mic,
        'sms' || 'notification' => AppIcons.notification,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final appTheme = context.appTheme;
    final hasSlidable = onDelete != null || onEdit != null;

    final amountColor = switch (transaction.type) {
      'income' => appTheme.incomeColor,
      'expense' => appTheme.expenseColor,
      _ => appTheme.transferColor,
    };

    final card = _CardContent(
      transaction: transaction,
      categoryIcon: categoryIcon,
      categoryColor: categoryColor,
      categoryName: categoryName,
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
    required this.amountColor,
    required this.amountPrefix,
    required this.sourceIcon,
    this.onTap,
  });

  final TransactionEntity transaction;
  final IconData categoryIcon;
  final Color categoryColor;
  final String categoryName;
  final Color amountColor;
  final String amountPrefix;
  final IconData? sourceIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final formatted = MoneyFormatter.formatAmount(transaction.amount);
    final amountLabel =
        '$amountPrefix ${MoneyFormatter.format(transaction.amount, currency: transaction.currencyCode)}';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.sm,
        ),
        child: Row(
          children: [
            // Category icon badge
            Container(
              width: AppSizes.iconContainerLg,
              height: AppSizes.iconContainerLg,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: AppSizes.opacityLight),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
              child: Icon(
                categoryIcon,
                size: AppSizes.iconMd,
                color: categoryColor,
              ),
            ),
            const SizedBox(width: AppSizes.md),
            // Title + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                          categoryName,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (sourceIcon != null) ...[
                        const SizedBox(width: AppSizes.xs),
                        Icon(
                          sourceIcon!,
                          size: AppSizes.iconXxs,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            // Amount
            Semantics(
              label: amountLabel,
              excludeSemantics: true,
              child: Text(
                '$amountPrefix $formatted',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: amountColor,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
