import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/wallet_entity.dart';
import '../../../../shared/providers/hide_balances_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/lists/horizontal_reorderable_row.dart';
import '../../../../shared/widgets/sheets/show_wallet_sheet.dart';
import 'account_chip.dart';
import 'account_manage_sheet.dart';
import 'month_summary_inline.dart';

/// Compact Wise/Revolut-style balance header with account dropdown selector.
///
/// Displays the total balance (or selected account balance), an inline month
/// summary, and a tappable account selector. When a specific wallet is selected,
/// a horizontally scrollable row of account chips appears for quick switching.
class BalanceHeader extends ConsumerWidget {
  const BalanceHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final selectedId = ref.watch(selectedAccountIdProvider);
    final totalBalance = ref.watch(totalBalanceProvider).valueOrNull ?? 0;
    final hidden = ref.watch(hideBalancesProvider);

    // Display balance for selected account or total.
    final displayBalance = selectedId == null
        ? totalBalance
        : wallets.where((w) => w.id == selectedId).firstOrNull?.balance ?? 0;

    // Separate Cash (system) wallet from regular wallets.
    final cashWallet =
        wallets.where((w) => w.isSystemWallet && !w.isArchived).firstOrNull;
    final userWallets =
        wallets.where((w) => !w.isArchived && !w.isSystemWallet).toList();

    // Current selection label.
    final selectionLabel = selectedId == null
        ? context.l10n.dashboard_all_accounts
        : wallets.where((w) => w.id == selectedId).firstOrNull?.name ??
            context.l10n.dashboard_all_accounts;

    final cs = context.colors;
    final theme = context.appTheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.glassCardSurface,
        border: Border(
          bottom: BorderSide(
            color: theme.glassCardBorder,
          ),
        ),
      ),
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.md,
      ),
      child: Column(
        children: [
          // ── Balance row with eye toggle ──────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hidden
                    ? '------'
                    : MoneyFormatter.formatTrailing(displayBalance),
                style: context.textStyles.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(width: AppSizes.xs),
              IconButton(
                tooltip: hidden
                    ? context.l10n.balance_show
                    : context.l10n.balance_hide,
                icon: Icon(
                  hidden ? AppIcons.eyeOff : AppIcons.eye,
                  color: cs.onSurface.withValues(alpha: AppSizes.opacityMedium),
                  size: AppSizes.iconSm,
                ),
                onPressed: () =>
                    ref.read(hideBalancesProvider.notifier).toggle(),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),

          // ── Inline month summary ────────────────────────────────────
          MonthSummaryInline(walletId: selectedId, hidden: hidden),
          const SizedBox(height: AppSizes.sm),

          // ── Cash wallet banner (always visible) ─────────────────
          if (cashWallet != null) ...[
            GestureDetector(
              onTap: () => ref.read(selectedAccountIdProvider.notifier).state =
                  selectedId == cashWallet.id ? null : cashWallet.id,
              onLongPress: () => showEditWalletSheet(context, cashWallet.id),
              child: Container(
                height: AppSizes.minTapTarget,
                padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: AppSizes.md,
                ),
                decoration: BoxDecoration(
                  color: theme.glassCardSurface,
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusFull),
                  border: selectedId == cashWallet.id
                      ? Border.all(
                          color: cs.primary.withValues(
                            alpha: AppSizes.opacityMedium,
                          ),
                        )
                      : Border.all(
                          color: theme.glassCardBorder,
                          width: AppSizes.glassBorderWidthSubtle,
                        ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      AppIcons.walletType('physical_cash'),
                      size: AppSizes.iconXs,
                      color: selectedId == cashWallet.id
                          ? cs.primary
                          : cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Text(
                      cashWallet.name,
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: selectedId == cashWallet.id
                            ? cs.primary
                            : cs.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      hidden
                          ? '---'
                          : MoneyFormatter.formatTrailing(cashWallet.balance),
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: AppSizes.xs),
                    Icon(
                      AppIcons.chevronRight,
                      size: AppSizes.iconXxs,
                      color: cs.onSurfaceVariant.withValues(
                        alpha: AppSizes.opacityMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
          ],

          // ── Account selector dropdown ───────────────────────────────
          Semantics(
            button: true,
            label: context.l10n.dashboard_account_selector(selectionLabel),
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
                onTap: () => _showAccountPicker(
                  context,
                  ref,
                  userWallets,
                  selectedId,
                  totalBalance,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusFull),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        selectionLabel,
                        style: context.textStyles.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSizes.xxs),
                      Icon(
                        AppIcons.expandMore,
                        size: AppSizes.iconXs,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Account chips (only when a specific wallet is selected) ─
          if (selectedId != null) ...[
            const SizedBox(height: AppSizes.md),
            Row(
              children: [
                Expanded(
                  child: HorizontalReorderableRow<WalletEntity>(
                    items: userWallets,
                    onReorder: (oldIndex, newIndex) {
                      final reordered = [...userWallets];
                      if (newIndex > oldIndex) newIndex--;
                      final item = reordered.removeAt(oldIndex);
                      reordered.insert(newIndex, item);
                      final updates = <({int id, int sortOrder})>[];
                      for (var i = 0; i < reordered.length; i++) {
                        updates.add((id: reordered[i].id, sortOrder: i));
                      }
                      ref
                          .read(walletRepositoryProvider)
                          .updateSortOrders(updates);
                    },
                    itemBuilder: (context, w, isDragging) => AccountChip(
                      label: w.name,
                      balance: w.balance,
                      isSelected: selectedId == w.id,
                      hidden: hidden,
                      walletType: w.type,
                      colorHex: w.colorHex,
                      onTap: isDragging
                          ? () {}
                          : () => ref
                              .read(selectedAccountIdProvider.notifier)
                              .state = w.id,
                      onLongPress: isDragging
                          ? null
                          : () => showEditWalletSheet(context, w.id),
                    ),
                    trailing: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(
                          end: AppSizes.sm,
                        ),
                        child: ActionChip(
                          avatar: Icon(
                            AppIcons.add,
                            size: AppSizes.iconXs,
                            color: cs.primary,
                          ),
                          label: Text(
                            context.l10n.wallet_add_short,
                            style: context.textStyles.labelSmall?.copyWith(
                              color: cs.primary,
                            ),
                          ),
                          side: BorderSide(
                            color: cs.primary.withValues(
                              alpha: AppSizes.opacityLight4,
                            ),
                          ),
                          backgroundColor: cs.surface,
                          onPressed: () => showWalletSheet(context),
                        ),
                      ),
                    ],
                  ),
                ),
                // Manage accounts gear icon
                IconButton(
                  icon: Icon(
                    AppIcons.settings,
                    size: AppSizes.iconSm,
                    color: cs.outline,
                  ),
                  tooltip: context.l10n.wallet_manage_title,
                  onPressed: () => AccountManageSheet.show(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showAccountPicker(
    BuildContext context,
    WidgetRef ref,
    List wallets,
    int? selectedId,
    int totalBalance,
  ) {
    final cs = context.colors;
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // "All Accounts" option
            ListTile(
              leading: Icon(AppIcons.wallet, color: cs.primary),
              title: Text(context.l10n.dashboard_all_accounts),
              subtitle: Text(MoneyFormatter.format(totalBalance)),
              trailing: selectedId == null
                  ? Icon(AppIcons.check, color: cs.primary)
                  : null,
              onTap: () {
                ref.read(selectedAccountIdProvider.notifier).state = null;
                context.pop();
              },
            ),
            // Individual wallets
            ...wallets.map(
              (w) => ListTile(
                leading: Icon(
                  AppIcons.walletType(w.type),
                  color: ColorUtils.fromHex(w.colorHex),
                ),
                title: Text(w.name),
                subtitle: Text(MoneyFormatter.format(w.balance)),
                trailing: selectedId == w.id
                    ? Icon(AppIcons.check, color: cs.primary)
                    : null,
                onTap: () {
                  ref.read(selectedAccountIdProvider.notifier).state = w.id;
                  context.pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
