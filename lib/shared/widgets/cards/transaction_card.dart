import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/brand_registry.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../domain/adapters/transfer_adapter.dart';
import '../../../domain/entities/transaction_entity.dart';

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
            // Brand icon (colored circle + initial) or category icon fallback.
            if (brandInfo != null)
              _BrandIconCircle(brand: brandInfo!)
            else
              Icon(
                categoryIcon,
                size: AppSizes.iconMd,
                color: categoryColor,
              ),
            const SizedBox(width: AppSizes.md),
            // Category (primary, bold) + title (secondary, muted)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName,
                    style: context.textStyles.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (transaction.title.isNotEmpty) ...[
                    const SizedBox(height: AppSizes.xxs),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            transaction.title,
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.outline,
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
                            color: context.colors.outline,
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
                '$amountPrefix $formatted',
                style: context.textStyles.bodyMedium?.copyWith(
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

/// Colored circle with brand initial — used as leading icon when a brand match
/// is found. Sized to match the category icon (AppSizes.iconMd = 24).
class _BrandIconCircle extends StatelessWidget {
  const _BrandIconCircle({required this.brand});

  final BrandInfo brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.iconLg,
      height: AppSizes.iconLg,
      decoration: BoxDecoration(
        color: brand.color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        brand.displayInitial,
        style: context.textStyles.labelSmall?.copyWith(
          color: ThemeData.estimateBrightnessForColor(brand.color) ==
                  Brightness.dark
              ? AppColors.white
              : AppColors.black,
          fontWeight: FontWeight.w800,
          fontSize: brand.displayInitial.length > 2
              ? AppSizes.brandIconFontSmall
              : AppSizes.brandIconFontLarge,
        ),
      ),
    );
  }
}
