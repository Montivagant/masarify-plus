import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/hide_balances_provider.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import 'account_chip.dart';
import 'account_manage_sheet.dart';
import 'month_summary_inline.dart';

/// Compact Wise/Revolut-style balance header with account chips (D-01 to D-05).
///
/// Replaces the previous PageView [AccountCarousel] + [BalanceCard].
/// Displays the total balance (or selected account balance), an inline month
/// summary, and a horizontally scrollable row of account chips.
///
/// Uses translucent glass surface colors instead of BackdropFilter to avoid
/// GPU compositing overload on Android (Impeller disabled).
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

    // All non-archived wallets for chips (includes system Cash wallet per D-06).
    final userWallets = wallets.where((w) => !w.isArchived).toList();

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
                hidden ? '------' : MoneyFormatter.format(displayBalance),
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

          // ── Inline month summary (D-04) ─────────────────────────────
          MonthSummaryInline(walletId: selectedId, hidden: hidden),
          const SizedBox(height: AppSizes.md),

          // ── Account chips (horizontal scroll, D-02/D-03) + manage gear (D-08)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AccountChip(
                        label: context.l10n.dashboard_all_accounts,
                        balance: totalBalance,
                        isSelected: selectedId == null,
                        isAllAccounts: true,
                        hidden: hidden,
                        onTap: () => ref
                            .read(selectedAccountIdProvider.notifier)
                            .state = null,
                      ),
                      ...userWallets.map(
                        (w) => AccountChip(
                          label: w.name,
                          balance: w.balance,
                          isSelected: selectedId == w.id,
                          hidden: hidden,
                          onTap: () => ref
                              .read(selectedAccountIdProvider.notifier)
                              .state = w.id,
                        ),
                      ),
                      // Quick-add account chip
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
                          onPressed: () => context.push(AppRoutes.walletAdd),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Manage accounts gear icon (D-08)
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
      ),
    );
  }
}
