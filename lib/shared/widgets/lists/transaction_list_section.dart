import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/brand_registry.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/utils/money_formatter.dart';
import '../../../domain/adapters/transfer_adapter.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../cards/transaction_card.dart';

/// Groups a list of [TransactionCard]s under a sticky date header.
///
/// Used in DashboardScreen (unified dashboard with full transaction list).
class TransactionListSection extends StatelessWidget {
  const TransactionListSection({
    super.key,
    required this.dateLabel,
    required this.transactions,
    required this.categoryResolver,
    this.walletNameResolver,
    this.walletInfoResolver,
    this.onSeeAll,
    this.onTransactionTap,
    this.onTransactionDelete,
    this.onTransactionEdit,
  });

  /// e.g. "اليوم", "أمس", "الثلاثاء 25 فبراير"
  final String dateLabel;

  final List<TransactionEntity> transactions;

  /// Resolves display data for each transaction.
  /// Returns (icon, color, categoryName) given a categoryId.
  final ({IconData icon, Color color, String name}) Function(int categoryId)
      categoryResolver;

  /// Optional resolver that maps walletId → wallet name.
  /// When provided, the wallet name is shown on each transaction card.
  final String? Function(int walletId)? walletNameResolver;

  /// For transfers: resolves counterpart wallet → (icon, name).
  /// Used to show the counterpart wallet's type icon and direction-aware label.
  final ({IconData icon, String name})? Function(int walletId)?
      walletInfoResolver;

  /// If non-null, shows a "See All →" button in the header.
  final VoidCallback? onSeeAll;

  final void Function(TransactionEntity)? onTransactionTap;
  final void Function(TransactionEntity)? onTransactionDelete;
  final void Function(TransactionEntity)? onTransactionEdit;

  @override
  Widget build(BuildContext context) {
    // Compute daily net subtotal for the date group header.
    int dayIncome = 0;
    int dayExpense = 0;
    for (final tx in transactions) {
      if (tx.type == 'income') {
        dayIncome += tx.amount;
      } else if (tx.type == 'expense') {
        dayExpense += tx.amount;
      }
    }
    final dayNet = dayIncome - dayExpense;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header + daily subtotal + optional "See All"
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
            vertical: AppSizes.xs,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateLabel,
                style: context.textStyles.labelLarge?.copyWith(
                  color: context.colors.outline,
                ),
              ),
              if (onSeeAll != null)
                TextButton.icon(
                  onPressed: onSeeAll,
                  label: Text(context.l10n.common_all),
                  icon: Icon(
                    context.isRtl
                        ? AppIcons.chevronLeft
                        : AppIcons.chevronRight,
                    size: AppSizes.iconXs,
                  ),
                  iconAlignment: IconAlignment.end,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                )
              else if (dayNet != 0)
                Text(
                  '${dayNet > 0 ? '+' : '\u2212'}${MoneyFormatter.formatCompact(dayNet.abs())}',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: dayNet > 0
                        ? context.appTheme.incomeColor
                        : context.appTheme.expenseColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        // Transaction rows
        ...transactions.map((tx) {
          final cat = categoryResolver(tx.categoryId);

          // For transfers, resolve counterpart wallet icon and direction label.
          IconData? transferIcon;
          String? transferLabel;
          if (tx.type == 'transfer' && walletInfoResolver != null) {
            final cpId = counterpartWalletId(tx.tags);
            if (cpId != null) {
              final info = walletInfoResolver!(cpId);
              if (info != null) {
                transferIcon = info.icon;
                transferLabel = isTransferSender(tx.tags)
                    ? context.l10n.transfer_to_account(tx.title)
                    : context.l10n.transfer_from_account(tx.title);
              }
            }
          }

          return TransactionCard(
            transaction: tx,
            categoryIcon: cat.icon,
            categoryColor: cat.color,
            categoryName: cat.name,
            brandInfo: BrandRegistry.match(tx.title),
            walletName: walletNameResolver?.call(tx.walletId),
            transferCounterpartIcon: transferIcon,
            transferDisplayName: transferLabel,
            onTap:
                onTransactionTap != null ? () => onTransactionTap!(tx) : null,
            onDelete: onTransactionDelete != null
                ? () => onTransactionDelete!(tx)
                : null,
            onEdit:
                onTransactionEdit != null ? () => onTransactionEdit!(tx) : null,
          );
        }),
      ],
    );
  }
}
