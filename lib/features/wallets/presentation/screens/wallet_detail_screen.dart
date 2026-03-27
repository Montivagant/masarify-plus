import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_resolver.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/transaction_grouper.dart';
import '../../../../domain/adapters/transfer_adapter.dart';
import '../../../../shared/providers/activity_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/confirm_dialog.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/lists/transaction_list_section.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class WalletDetailScreen extends ConsumerWidget {
  const WalletDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletByIdProvider(id));
    final txAsync = ref.watch(activityByWalletProvider(id));
    final categories = ref.watch(categoriesProvider);
    final allWallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final walletMap = {for (final w in allWallets) w.id: w};

    ResolvedCategory resolveCat(int catId) {
      if (catId == 0) {
        return (
          icon: AppIcons.transfer,
          color: context.appTheme.transferColor,
          name: context.l10n.transaction_type_transfer,
        );
      }
      return resolveCategory(
        categoryId: catId,
        categories: categories.valueOrNull ?? [],
        fallbackColor: context.colors.outline,
        languageCode: context.languageCode,
      );
    }

    return walletAsync.when(
      data: (wallet) {
        if (wallet == null) {
          return Scaffold(
            appBar: AppAppBar(title: context.l10n.wallet_detail_title),
            body: EmptyState(title: context.l10n.wallet_not_found),
          );
        }

        final color = ColorUtils.fromHex(wallet.colorHex);

        return Scaffold(
          appBar: AppAppBar(
            title: wallet.name,
            actions: [
              IconButton(
                icon: const Icon(AppIcons.edit),
                tooltip: context.l10n.common_edit,
                onPressed: () =>
                    context.push(AppRoutes.editWalletPath(wallet.id)),
              ),
              // 2B: Hide delete button for default and system accounts.
              if (!wallet.isDefaultAccount && !wallet.isSystemWallet)
                IconButton(
                  icon: const Icon(AppIcons.delete),
                  tooltip: context.l10n.common_delete,
                  onPressed: () => _confirmDelete(context, ref, wallet.id),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding:
                const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance header
                GlassCard(
                  showShadow: true,
                  margin: const EdgeInsets.all(AppSizes.screenHPadding),
                  padding: const EdgeInsets.all(AppSizes.lg),
                  tintColor: color.withValues(alpha: AppSizes.opacityXLight),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        Icon(
                          AppIcons.wallet,
                          color: color,
                          size: AppSizes.iconLg,
                        ),
                        const SizedBox(height: AppSizes.sm),
                        Text(
                          MoneyFormatter.format(wallet.balance),
                          style: context.textStyles.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: AppSizes.xs),
                        Text(
                          context.l10n.wallet_current_balance,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Transfer shortcut
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenHPadding,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push(AppRoutes.transfer),
                    icon: const Icon(AppIcons.transfer, size: AppSizes.iconSm),
                    label: Text(context.l10n.wallets_transfer),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),

                // Transactions for this wallet
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenHPadding,
                  ),
                  child: Text(
                    context.l10n.wallet_transactions_header,
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xs),

                txAsync.when(
                  data: (txList) {
                    if (txList.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSizes.xl),
                        child: EmptyState(
                          title: context.l10n.transactions_empty_title,
                          subtitle: context.l10n.wallet_no_transactions_sub,
                        ),
                      );
                    }
                    final grouped = groupTransactionsByDate(context, txList);
                    return Column(
                      children: grouped.entries
                          .map(
                            (e) => TransactionListSection(
                              dateLabel: e.key,
                              transactions: e.value,
                              categoryResolver: resolveCat,
                              walletInfoResolver: (walletId) {
                                final w = walletMap[walletId];
                                if (w == null) return null;
                                return (
                                  icon: AppIcons.walletType(w.type),
                                  name: w.name,
                                );
                              },
                              onTransactionTap: (tx) {
                                if (tx.id < 0) return;
                                context.push(
                                  AppRoutes.transactionDetailPath(tx.id),
                                );
                              },
                              onTransactionDelete: (tx) async {
                                if (tx.id < 0) {
                                  final transferId = transferIdFromTxId(tx.id);
                                  final confirmed =
                                      await ConfirmDialog.confirmDelete(
                                    context,
                                    title: context.l10n.transfer_delete_title,
                                    message:
                                        context.l10n.transfer_delete_confirm,
                                  );
                                  if (!confirmed || !context.mounted) {
                                    return;
                                  }
                                  try {
                                    await ref
                                        .read(transferRepositoryProvider)
                                        .delete(transferId);
                                  } catch (_) {
                                    if (context.mounted) {
                                      SnackHelper.showError(
                                        context,
                                        context.l10n.common_error_generic,
                                      );
                                    }
                                    return;
                                  }
                                  if (context.mounted) {
                                    HapticFeedback.mediumImpact();
                                    SnackHelper.showSuccess(
                                      context,
                                      context.l10n.transfer_deleted_message,
                                    );
                                  }
                                } else {
                                  final confirmed =
                                      await ConfirmDialog.confirmDelete(
                                    context,
                                    title:
                                        context.l10n.transaction_delete_title,
                                    message:
                                        context.l10n.transaction_delete_confirm,
                                  );
                                  if (!confirmed || !context.mounted) {
                                    return;
                                  }
                                  try {
                                    await ref
                                        .read(transactionRepositoryProvider)
                                        .delete(tx.id);
                                  } catch (_) {
                                    if (context.mounted) {
                                      SnackHelper.showError(
                                        context,
                                        context.l10n.common_error_generic,
                                      );
                                    }
                                    return;
                                  }
                                  if (context.mounted) {
                                    HapticFeedback.mediumImpact();
                                    SnackHelper.showSuccess(
                                      context,
                                      context.l10n.transaction_deleted_message(
                                        tx.title,
                                      ),
                                    );
                                  }
                                }
                              },
                              onTransactionEdit: (tx) {
                                if (tx.id < 0) {
                                  context.push(AppRoutes.transfer);
                                } else {
                                  context.push('/transactions/${tx.id}/edit');
                                }
                              },
                            ),
                          )
                          .toList(),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSizes.screenHPadding),
                    child: ShimmerList(itemCount: 5),
                  ),
                  error: (_, __) =>
                      EmptyState(title: context.l10n.common_error_title),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppAppBar(title: context.l10n.wallet_detail_title),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppAppBar(title: context.l10n.wallet_detail_title),
        body: EmptyState(title: context.l10n.common_error_title),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int walletId,
  ) async {
    // H9/H10 fix: check for references via repository
    final hasReferences =
        await ref.read(walletRepositoryProvider).hasReferences(walletId);

    if (hasReferences) {
      if (!context.mounted) return;
      await ConfirmDialog.show(
        context,
        title: context.l10n.wallet_cannot_delete_title,
        message: context.l10n.wallet_cannot_delete_body,
        confirmLabel: context.l10n.common_ok,
      );
      return;
    }

    if (!context.mounted) return;

    // IM-19 fix: warn if wallet has non-zero balance
    final wallet = await ref.read(walletRepositoryProvider).getById(walletId);
    if (!context.mounted) return;
    final balanceWarning = (wallet != null && wallet.balance != 0)
        ? '\n\n${context.l10n.wallet_archive_balance_warning}'
        : '';

    final confirmed = await ConfirmDialog.confirmDelete(
      context,
      title: context.l10n.wallet_delete_title,
      message: '${context.l10n.wallet_delete_confirm}$balanceWarning',
    );

    if (confirmed && context.mounted) {
      await ref.read(walletRepositoryProvider).archive(walletId);
      HapticFeedback.mediumImpact();
      if (context.mounted) context.pop();
    }
  }
}
