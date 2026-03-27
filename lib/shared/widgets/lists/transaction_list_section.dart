import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/brand_registry.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../domain/adapters/transfer_adapter.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../cards/transaction_card.dart';

/// Wallet info returned by [walletInfoResolver] for counterpart display.
typedef WalletInfo = ({IconData icon, String name});

/// Groups a list of [TransactionCard]s under a sticky date header.
///
/// Used in both DashboardScreen (last 5 transactions) and
/// TransactionListScreen (full paginated list grouped by date).
class TransactionListSection extends StatelessWidget {
  const TransactionListSection({
    super.key,
    required this.dateLabel,
    required this.transactions,
    required this.categoryResolver,
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

  /// Resolves wallet info (icon, name) for a given walletId.
  /// Used to display counterpart wallet icon/name on transfer entries.
  final WalletInfo? Function(int walletId)? walletInfoResolver;

  /// If non-null, shows a "See All →" button in the header.
  final VoidCallback? onSeeAll;

  final void Function(TransactionEntity)? onTransactionTap;
  final void Function(TransactionEntity)? onTransactionDelete;
  final void Function(TransactionEntity)? onTransactionEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header + optional "See All"
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
                ),
            ],
          ),
        ),
        // Transaction rows
        ...transactions.map((tx) {
          final cat = categoryResolver(tx.categoryId);

          // Resolve counterpart info for transfer entries.
          IconData? transferCounterpartIcon;
          String? transferDisplayName;
          if (tx.type == 'transfer' && walletInfoResolver != null) {
            final cpId = counterpartWalletId(tx.tags);
            if (cpId != null) {
              final cpInfo = walletInfoResolver!(cpId);
              if (cpInfo != null) {
                transferCounterpartIcon = cpInfo.icon;
                final isSender = isTransferSender(tx.tags);
                transferDisplayName = isSender
                    ? '${context.l10n.common_transfer} → ${cpInfo.name}'
                    : '${context.l10n.common_transfer} ← ${cpInfo.name}';
              }
            }
          }

          return TransactionCard(
            transaction: tx,
            categoryIcon: cat.icon,
            categoryColor: cat.color,
            categoryName: transferDisplayName ?? cat.name,
            brandInfo:
                tx.type == 'transfer' ? null : BrandRegistry.match(tx.title),
            transferCounterpartIcon: transferCounterpartIcon,
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
