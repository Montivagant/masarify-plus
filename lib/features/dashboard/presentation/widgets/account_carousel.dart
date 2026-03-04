import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/hide_balances_provider.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/balance_card.dart';

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
      viewportFraction: 0.92,
      initialPage: initialPage,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final walletsAsync = ref.watch(walletsProvider);
    final totalBalanceAsync = ref.watch(totalBalanceProvider);
    final hidden = ref.watch(hideBalancesProvider);
    final selectedIndex = ref.watch(selectedAccountIndexProvider);

    final now = DateTime.now();
    final monthKey = (now.year, now.month);
    final lastMonthKey =
        now.month == 1 ? (now.year - 1, 12) : (now.year, now.month - 1);

    final monthTxs =
        ref.watch(transactionsByMonthProvider(monthKey)).valueOrNull ?? [];
    final lastMonthTxs =
        ref.watch(transactionsByMonthProvider(lastMonthKey)).valueOrNull ?? [];

    final wallets = walletsAsync.valueOrNull ?? [];
    final totalBalance = totalBalanceAsync.valueOrNull ?? 0;
    final pageCount = 1 + wallets.length;

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

    // Pre-compute aggregates once (avoid O(wallets * transactions) in itemBuilder).
    final incomeByWallet = <int, int>{};
    final expenseByWallet = <int, int>{};
    int totalIncome = 0;
    int totalExpense = 0;
    for (final t in monthTxs) {
      if (t.type == 'income') {
        totalIncome += t.amount;
        incomeByWallet[t.walletId] = (incomeByWallet[t.walletId] ?? 0) + t.amount;
      } else if (t.type == 'expense') {
        totalExpense += t.amount;
        expenseByWallet[t.walletId] = (expenseByWallet[t.walletId] ?? 0) + t.amount;
      }
    }
    final lastExpenseByWallet = <int, int>{};
    int lastMonthExpenseTotal = 0;
    for (final t in lastMonthTxs) {
      if (t.type == 'expense') {
        lastMonthExpenseTotal += t.amount;
        lastExpenseByWallet[t.walletId] = (lastExpenseByWallet[t.walletId] ?? 0) + t.amount;
      }
    }

    return Column(
      children: [
        SizedBox(
          height: AppSizes.carouselHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: pageCount,
            onPageChanged: (index) {
              ref.read(selectedAccountIndexProvider.notifier).state = index;
            },
            itemBuilder: (context, index) {
              if (index == 0) {
                // Page 0: Total balance across all accounts.
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
                    lastMonthExpensePiastres:
                        lastMonthExpenseTotal > 0 ? lastMonthExpenseTotal : null,
                    hidden: hidden,
                    onToggleHide: () =>
                        ref.read(hideBalancesProvider.notifier).toggle(),
                  ),
                );
              }

              // Pages 1-N: Individual account cards.
              if (index - 1 >= wallets.length) {
                return const SizedBox.shrink();
              }
              final wallet = wallets[index - 1];

              final walletIncome = incomeByWallet[wallet.id] ?? 0;
              final walletExpense = expenseByWallet[wallet.id] ?? 0;
              final walletLastExpense = lastExpenseByWallet[wallet.id] ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.xs,
                  vertical: AppSizes.xs,
                ),
                child: BalanceCard(
                  accountName: wallet.name,
                  totalPiastres: wallet.balance,
                  monthlyIncomePiastres: walletIncome,
                  monthlyExpensePiastres: walletExpense,
                  lastMonthExpensePiastres:
                      walletLastExpense > 0 ? walletLastExpense : null,
                  currencyCode: wallet.currencyCode,
                  hidden: hidden,
                  onToggleHide: () =>
                      ref.read(hideBalancesProvider.notifier).toggle(),
                ),
              );
            },
          ),
        ),

        // Page indicator dots.
        if (pageCount > 1)
          Padding(
            padding: const EdgeInsets.only(top: AppSizes.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageCount, (i) {
                final isActive = i == safeIndex;
                return Container(
                  width: AppSizes.indicatorDotSize,
                  height: AppSizes.indicatorDotSize,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSizes.xs / 2 + 1, // ~3dp spacing
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
            ),
          ),
      ],
    );
  }
}
