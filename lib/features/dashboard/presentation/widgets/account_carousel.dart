import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/hide_balances_provider.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/balance_card.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Swipeable account carousel: page 0 = total balance, pages 1-N = accounts.
///
/// Updates [selectedAccountIndexProvider] on page change, which cascades
/// filtering to the rest of the dashboard.
class AccountCarousel extends ConsumerStatefulWidget {
  const AccountCarousel({super.key});

  @override
  ConsumerState<AccountCarousel> createState() => _AccountCarouselState();
}

class _AccountCarouselState extends ConsumerState<AccountCarousel> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialPage = ref.read(selectedAccountIndexProvider);
    _pageController = PageController(
      viewportFraction: AppSizes.carouselViewportFraction,
      initialPage: initialPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Map wallet type string to its Phosphor icon.
  static IconData _typeIcon(String type) => switch (type) {
        'physical_cash' => AppIcons.physicalCash,
        'bank' => AppIcons.bank,
        'mobile_wallet' => AppIcons.phone,
        'credit_card' => AppIcons.creditCard,
        'prepaid_card' => AppIcons.prepaidCard,
        'investment' => AppIcons.investmentAccount,
        _ => AppIcons.wallet,
      };

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final totalBalanceAsync = ref.watch(totalBalanceProvider);
    final hidden = ref.watch(hideBalancesProvider);
    final selectedIndex = ref.watch(selectedAccountIndexProvider);
    final inGoals = ref.watch(totalInGoalsProvider);
    final systemWalletAsync = ref.watch(systemWalletProvider);

    final now = DateTime.now();
    final monthKey = (now.year, now.month);

    final monthTxs =
        ref.watch(transactionsByMonthProvider(monthKey)).valueOrNull ?? [];

    final allWallets = walletsAsync.valueOrNull ?? [];
    final totalBalance = totalBalanceAsync.valueOrNull ?? 0;
    final systemWallet = systemWalletAsync.valueOrNull;

    // Filter out the system wallet from per-account pages.
    final userWallets = allWallets.where((w) => !w.isSystemWallet).toList();

    // +1 for total balance, +1 for "Add Account" card at the end.
    final pageCount = 1 + userWallets.length + 1;

    // Clamp selected index if wallets were removed.
    final safeIndex = selectedIndex.clamp(0, pageCount - 1);
    if (selectedIndex >= pageCount) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(selectedAccountIndexProvider.notifier).state = 0;
        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
      });
    }

    // Pre-compute aggregates once.
    int totalIncome = 0;
    int totalExpense = 0;
    for (final t in monthTxs) {
      if (t.type == 'income') {
        totalIncome += t.amount;
      } else if (t.type == 'expense') {
        totalExpense += t.amount;
      }
    }
    final cs = context.colors;

    return Column(
      children: [
        Stack(
          children: [
            SizedBox(
              height: AppSizes.carouselHeight,
              child: PageView.builder(
                controller: _pageController,
                itemCount: pageCount,
                onPageChanged: (index) {
                  // Don't update selection when swiping to the "Add Account" card.
                  if (index < pageCount - 1) {
                    ref.read(selectedAccountIndexProvider.notifier).state =
                        index;
                  }
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    // Page 0: Total balance across all accounts (hero variant).
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.xs,
                        vertical: AppSizes.xs,
                      ),
                      child: BalanceCard(
                        accountName: context.l10n.dashboard_all_accounts,
                        totalPiastres: totalBalance,
                        monthlyIncomePiastres: totalIncome,
                        monthlyExpensePiastres: totalExpense,
                        hidden: hidden,
                        inGoalsPiastres: inGoals,
                        cashPiastres: systemWallet?.balance ?? 0,
                      ),
                    );
                  }

                  // Last page: "Add Account" card.
                  if (index == pageCount - 1) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.xs,
                        vertical: AppSizes.xs,
                      ),
                      child: _AddAccountCard(
                        onTap: () => context.push(AppRoutes.walletAdd),
                      ),
                    );
                  }

                  // Pages 1-N: Individual account cards (account variant).
                  if (index - 1 >= userWallets.length) {
                    return const SizedBox.shrink();
                  }
                  final wallet = userWallets[index - 1];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xs,
                      vertical: AppSizes.xs,
                    ),
                    child: GestureDetector(
                      onLongPress: () =>
                          context.push(AppRoutes.editWalletPath(wallet.id)),
                      child: BalanceCard(
                        variant: BalanceCardVariant.account,
                        accountName: wallet.name,
                        totalPiastres: wallet.balance,
                        currencyCode: wallet.currencyCode,
                        hidden: hidden,
                        walletTypeIcon: _typeIcon(wallet.type),
                        walletColorHex: wallet.colorHex,
                      ),
                    ),
                  );
                },
              ),
            ),
            // Global eye icon for hide/show balances
            PositionedDirectional(
              top: AppSizes.sm,
              end: AppSizes.md,
              child: IconButton(
                icon: Icon(
                  hidden ? AppIcons.eyeOff : AppIcons.eye,
                  color: cs.onPrimary.withValues(alpha: AppSizes.opacityStrong),
                  size: AppSizes.iconSm,
                ),
                onPressed: () =>
                    ref.read(hideBalancesProvider.notifier).toggle(),
              ),
            ),
          ],
        ),

        // Page indicator dots + quick add button.
        // Dots exclude the "Add Account" card (last page) — the "+" button
        // replaces its dot, avoiding visual confusion when swiping to it.
        if (pageCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(pageCount - 1, (i) {
                  final isActive = i == safeIndex;
                  return Container(
                    width: AppSizes.indicatorDotSize,
                    height: AppSizes.indicatorDotSize,
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSizes.indicatorDotGap,
                    ),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? context.colors.primary
                          : context.colors.outline
                              .withValues(alpha: AppSizes.opacityLight4),
                    ),
                  );
                }),
                // WS6: Quick add "+" button next to dots.
                const SizedBox(width: AppSizes.sm),
                GestureDetector(
                  onTap: () => context.push(AppRoutes.walletAdd),
                  child: Container(
                    width: AppSizes.iconSm,
                    height: AppSizes.iconSm,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.primary
                          .withValues(alpha: AppSizes.opacityLight),
                    ),
                    child: Icon(
                      AppIcons.add,
                      size: AppSizes.iconXxs,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Dashed-border "+" card at the end of the carousel for quick account creation.
class _AddAccountCard extends StatelessWidget {
  const _AddAccountCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        tintColor:
            cs.primaryContainer.withValues(alpha: AppSizes.opacityLight4),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.add,
                size: AppSizes.iconLg,
                color: cs.primary,
              ),
              const SizedBox(height: AppSizes.sm),
              Text(
                context.l10n.wallet_add_title,
                style: context.textStyles.titleSmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
