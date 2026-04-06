import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Detail screen for a transfer, showing from/to wallets, amount, fee,
/// date, and note. Accessible by tapping a transfer entry on the dashboard.
class TransferDetailScreen extends ConsumerStatefulWidget {
  const TransferDetailScreen({super.key, required this.transferId});

  final int transferId;

  @override
  ConsumerState<TransferDetailScreen> createState() =>
      _TransferDetailScreenState();
}

class _TransferDetailScreenState extends ConsumerState<TransferDetailScreen> {
  late Future<dynamic> _transferFuture;

  @override
  void initState() {
    super.initState();
    _transferFuture =
        ref.read(transferRepositoryProvider).getById(widget.transferId);
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final cs = context.colors;
    final theme = context.appTheme;

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.transfer_detail_title,
        actions: [
          IconButton(
            icon: Icon(AppIcons.delete, color: theme.expenseColor),
            tooltip: context.l10n.common_delete,
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _transferFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }

          final transfer = snapshot.data;
          if (transfer == null) {
            return Center(
              child: Text(
                context.l10n.transfer_not_found,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: cs.outline,
                ),
              ),
            );
          }

          final fromWallet =
              wallets.where((w) => w.id == transfer.fromWalletId).firstOrNull;
          final toWallet =
              wallets.where((w) => w.id == transfer.toWalletId).firstOrNull;
          final fromName = fromWallet?.name ?? '?';
          final toName = toWallet?.name ?? '?';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              children: [
                // ── Hero card: amount + direction ──────────────────────
                GlassCard(
                  child: Column(
                    children: [
                      // Transfer icon
                      Container(
                        width: AppSizes.iconXl,
                        height: AppSizes.iconXl,
                        decoration: BoxDecoration(
                          color: theme.transferColor.withValues(
                            alpha: AppSizes.opacitySubtle,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          AppIcons.transfer,
                          color: theme.transferColor,
                          size: AppSizes.iconMd,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),
                      // Amount
                      Text(
                        MoneyFormatter.format(transfer.amount),
                        style: context.textStyles.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.transferColor,
                        ),
                      ),
                      if (transfer.fee > 0) ...[
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          '${context.l10n.transfer_fee_label}: ${MoneyFormatter.format(transfer.fee)}',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: cs.outline,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSizes.md),
                      // Direction: From → To
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _WalletBadge(
                            name: fromName,
                            icon: fromWallet != null
                                ? AppIcons.walletType(fromWallet.type)
                                : AppIcons.wallet,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.md,
                            ),
                            child: Icon(
                              context.isRtl
                                  ? AppIcons.arrowBack
                                  : AppIcons.arrowForward,
                              color: theme.transferColor,
                              size: AppSizes.iconMd,
                            ),
                          ),
                          _WalletBadge(
                            name: toName,
                            icon: toWallet != null
                                ? AppIcons.walletType(toWallet.type)
                                : AppIcons.wallet,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSizes.md),

                // ── Details card ──────────────────────────────────────
                GlassCard(
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: AppIcons.calendar,
                        label: context.l10n.transaction_date,
                        value: DateFormat.yMMMd(context.languageCode)
                            .add_jm()
                            .format(transfer.transferDate),
                      ),
                      if (transfer.note != null &&
                          transfer.note!.isNotEmpty) ...[
                        const Divider(height: AppSizes.md),
                        _DetailRow(
                          icon: AppIcons.edit,
                          label: context.l10n.voice_confirm_add_notes,
                          value: transfer.note!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.transfer_delete_confirm_title),
        content: Text(ctx.l10n.transfer_delete_confirm_body),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(ctx.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            child: Text(
              ctx.l10n.common_delete,
              style: TextStyle(color: ctx.colors.error),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        await ref.read(transferRepositoryProvider).delete(widget.transferId);
        if (context.mounted) {
          SnackHelper.showSuccess(context, context.l10n.transaction_deleted);
          context.pop();
        }
      }
    });
  }
}

class _WalletBadge extends StatelessWidget {
  const _WalletBadge({required this.name, required this.icon});

  final String name;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Column(
      children: [
        Container(
          width: AppSizes.iconContainerLg,
          height: AppSizes.iconContainerLg,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: cs.onSurface, size: AppSizes.iconSm),
        ),
        const SizedBox(height: AppSizes.xs),
        Text(
          name,
          style: context.textStyles.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: cs.outline),
        const SizedBox(width: AppSizes.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textStyles.labelSmall?.copyWith(
                  color: cs.outline,
                ),
              ),
              const SizedBox(height: AppSizes.xxs),
              Text(value, style: context.textStyles.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
