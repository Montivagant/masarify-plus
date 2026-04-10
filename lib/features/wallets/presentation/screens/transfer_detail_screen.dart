import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/transfer_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import 'transfer_screen.dart';

/// Detail screen for a transfer, showing from/to wallets, amount, fee,
/// date, and note. Accessible by tapping a transfer entry on the dashboard.
class TransferDetailScreen extends ConsumerWidget {
  const TransferDetailScreen({super.key, required this.transferId});

  final int transferId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final cs = context.colors;
    final theme = context.appTheme;
    final transferAsync = ref.watch(transferByIdProvider(transferId));

    return transferAsync.when(
      loading: () => Scaffold(
        appBar: AppAppBar(title: context.l10n.transfer_detail_title),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppAppBar(title: context.l10n.transfer_detail_title),
        body: EmptyState(title: context.l10n.common_error_title),
      ),
      data: (transfer) {
        if (transfer == null) {
          return Scaffold(
            appBar: AppAppBar(title: context.l10n.transfer_detail_title),
            body: EmptyState(title: context.l10n.transfer_not_found),
          );
        }

        final fromWallet =
            wallets.where((w) => w.id == transfer.fromWalletId).firstOrNull;
        final toWallet =
            wallets.where((w) => w.id == transfer.toWalletId).firstOrNull;
        final fromName = fromWallet?.name ?? '?';
        final toName = toWallet?.name ?? '?';

        return Scaffold(
          appBar: AppAppBar(
            title: context.l10n.transfer_detail_title,
            actions: [
              IconButton(
                icon: Icon(AppIcons.edit, color: cs.primary),
                tooltip: context.l10n.common_edit,
                onPressed: () {
                  context.pop();
                  TransferScreen.showEdit(context, transferId);
                },
              ),
              IconButton(
                icon: Icon(AppIcons.delete, color: theme.expenseColor),
                tooltip: context.l10n.common_delete,
                onPressed: () => _confirmDelete(context, ref),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding:
                const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero card: dark gradient ──────────────────────────
                Container(
                  margin: const EdgeInsets.all(AppSizes.screenHPadding),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.lg,
                    vertical: AppSizes.xl,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        cs.inverseSurface,
                        cs.inverseSurface
                            .withValues(alpha: AppSizes.opacityDragging),
                      ],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusLg),
                    boxShadow: [
                      BoxShadow(
                        color: cs.onSurface
                            .withValues(alpha: AppSizes.opacityLight3),
                        blurRadius: AppSizes.heroShadowBlur,
                        offset: const Offset(0, AppSizes.heroShadowOffsetY),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        // Transfer icon badge — circle on dark bg
                        Container(
                          width: AppSizes.iconContainerXl,
                          height: AppSizes.iconContainerXl,
                          decoration: BoxDecoration(
                            color: theme.transferColor.withValues(
                              alpha: AppSizes.opacityLight4,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.transfer,
                            color: theme.transferColor,
                            size: AppSizes.iconLg,
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                        // Amount — white on dark
                        Text(
                          MoneyFormatter.format(transfer.amount),
                          style: context.textStyles.displaySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onInverseSurface,
                            fontFeatures: const [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                        if (transfer.fee > 0) ...[
                          const SizedBox(height: AppSizes.xs),
                          Text(
                            '${context.l10n.transfer_fee_label}: ${MoneyFormatter.format(transfer.fee)}',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: cs.onInverseSurface.withValues(
                                alpha: AppSizes.opacityStrong,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSizes.sm),
                        // Type + date badges
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _TypeBadge(
                              label: context.l10n.transaction_type_transfer,
                              color: theme.transferColor,
                            ),
                            const SizedBox(width: AppSizes.sm),
                            _TypeBadge(
                              label: DateFormat.yMMMd(context.languageCode)
                                  .format(transfer.transferDate),
                              color: cs.onInverseSurface,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── "DETAILED INFORMATION" section label ─────────────
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSizes.screenHPadding + AppSizes.xs,
                    AppSizes.lg,
                    AppSizes.screenHPadding,
                    AppSizes.sm,
                  ),
                  child: Text(
                    context.l10n.transaction_detailed_info.toUpperCase(),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: cs.outline,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                // ── Detail rows (no wrapping card) ──────────────────
                _DetailRow(
                  icon: AppIcons.calendar,
                  iconColor: cs.primary,
                  label: context.l10n.transaction_date,
                  value: DateFormat.yMMMd(context.languageCode)
                      .add_jm()
                      .format(transfer.transferDate),
                ),
                if (transfer.note != null && transfer.note!.isNotEmpty)
                  _DetailRow(
                    icon: AppIcons.edit,
                    iconColor: cs.primary,
                    label: context.l10n.transaction_note,
                    value: transfer.note!,
                  ),

                // ── "TRANSFER DETAILS" section label ─────────────────
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSizes.screenHPadding + AppSizes.xs,
                    AppSizes.lg,
                    AppSizes.screenHPadding,
                    AppSizes.sm,
                  ),
                  child: Text(
                    context.l10n.transaction_transfer_details.toUpperCase(),
                    style: context.textStyles.labelSmall?.copyWith(
                      color: cs.outline,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                // ── FROM / TO cards ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenHPadding,
                  ),
                  child: Row(
                    children: [
                      // FROM card
                      Expanded(
                        child: GlassCard(
                          tintColor: cs.primaryContainer.withValues(
                            alpha: AppSizes.opacitySubtle,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.transfer_from_label.toUpperCase(),
                                style: context.textStyles.labelSmall?.copyWith(
                                  color: cs.outline,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Row(
                                children: [
                                  Icon(
                                    fromWallet != null
                                        ? AppIcons.walletType(
                                            fromWallet.type,
                                          )
                                        : AppIcons.wallet,
                                    size: AppSizes.iconSm,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: AppSizes.xs),
                                  Expanded(
                                    child: Text(
                                      fromName,
                                      style: context.textStyles.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Arrow
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.sm,
                        ),
                        child: Icon(
                          context.isRtl
                              ? AppIcons.arrowBack
                              : AppIcons.arrowForward,
                          color: cs.primary,
                          size: AppSizes.iconMd,
                        ),
                      ),
                      // TO card
                      Expanded(
                        child: GlassCard(
                          tintColor: cs.primaryContainer.withValues(
                            alpha: AppSizes.opacitySubtle,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.transfer_to_label.toUpperCase(),
                                style: context.textStyles.labelSmall?.copyWith(
                                  color: cs.outline,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: AppSizes.xs),
                              Row(
                                children: [
                                  Icon(
                                    toWallet != null
                                        ? AppIcons.walletType(toWallet.type)
                                        : AppIcons.wallet,
                                    size: AppSizes.iconSm,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: AppSizes.xs),
                                  Expanded(
                                    child: Text(
                                      toName,
                                      style: context.textStyles.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
              style: ctx.textStyles.labelLarge?.copyWith(
                color: ctx.colors.error,
              ),
            ),
          ),
        ],
      ),
    ).then((confirmed) async {
      if (confirmed == true && context.mounted) {
        try {
          await ref.read(transferRepositoryProvider).delete(transferId);
          if (context.mounted) {
            SnackHelper.showSuccess(
              context,
              context.l10n.transfer_deleted_message,
            );
            context.pop();
          }
        } catch (e) {
          if (context.mounted) {
            SnackHelper.showError(
              context,
              context.l10n.common_error_generic,
            );
          }
        }
      }
    });
  }
}

// ── Type badge (small pill) ─────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: AppSizes.opacityLight2),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
        border: Border.all(
          color: color.withValues(alpha: AppSizes.opacityLight4),
        ),
      ),
      child: Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Detail row (standalone, green circle icons) ─────────────────────────────

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.colorSwatchSize,
            height: AppSizes.colorSwatchSize,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: AppSizes.opacityLight2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: AppSizes.iconSm, color: iconColor),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.outline,
                  ),
                ),
                const SizedBox(height: AppSizes.xxs),
                Text(
                  value,
                  style: context.textStyles.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
