import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/hide_balances_provider.dart';
import '../../../../shared/providers/selected_account_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../widgets/account_carousel.dart';
import '../widgets/budget_alerts_zone.dart';
import '../widgets/recent_transactions_zone.dart';
import '../widgets/spending_overview_zone.dart';

/// Dashboard — thin shell assembling 6 independently-reactive zones.
///
/// Each zone widget watches only the providers it needs, so a change
/// in (e.g.) budgets does NOT rebuild the balance card or transactions.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);
    final selectedWalletId = ref.watch(selectedAccountIdProvider);
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.dashboard_title,
        showBack: false,
        actions: [
          IconButton(
            icon: Icon(
              ref.watch(hideBalancesProvider)
                  ? AppIcons.eyeOff
                  : AppIcons.eye,
            ),
            onPressed: () =>
                ref.read(hideBalancesProvider.notifier).toggle(),
            tooltip: ref.watch(hideBalancesProvider)
                ? context.l10n.balance_show
                : context.l10n.balance_hide,
          ),
          IconButton(
            icon: const Icon(AppIcons.settings),
            onPressed: () => context.push(AppRoutes.settings),
            tooltip: context.l10n.settings_title,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalBalanceProvider);
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(transactionsByMonthProvider(monthKey));
          ref.invalidate(budgetsByMonthProvider(monthKey));
          await ref.read(recentTransactionsProvider.future);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding:
              const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Offline banner ──────────────────────────────────
              if (!isOnline)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenHPadding,
                    vertical: AppSizes.sm,
                  ),
                  color: context.colors.errorContainer,
                  child: Row(
                    children: [
                      Icon(
                        AppIcons.warning,
                        size: AppSizes.iconSm,
                        color: context.colors.onErrorContainer,
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: Text(
                          context.l10n.dashboard_offline_banner,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Zone 1: Account Carousel ─────────────────────────
              const AccountCarousel(),

              const SizedBox(height: AppSizes.sectionGap),

              // ── Zone 2: Quick Actions (glass styled) ────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _GlassQuickAction(
                        onTap: () => context.push(
                          AppRoutes.transactionAdd,
                          extra: {'type': 'expense'},
                        ),
                        icon: AppIcons.expense,
                        label: context.l10n.dashboard_quick_add_expense,
                        color: context.appTheme.expenseColor,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _GlassQuickAction(
                        onTap: () => context.push(
                          AppRoutes.transactionAdd,
                          extra: {'type': 'income'},
                        ),
                        icon: AppIcons.income,
                        label: context.l10n.dashboard_quick_add_income,
                        color: context.appTheme.incomeColor,
                      ),
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: _GlassQuickAction(
                        onTap: () => context.push(AppRoutes.transfer),
                        icon: AppIcons.transfer,
                        label: context.l10n.transfer_title,
                        color: context.colors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.sectionGap),

              // ── Zone 3: Recent transactions (filtered by account) ─
              RecentTransactionsZone(filterWalletId: selectedWalletId),

              // ── Zone 4: Spending Overview (filtered by account) ───
              SpendingOverviewZone(filterWalletId: selectedWalletId),

              // ── Zone 5: Budget alerts ───────────────────────────
              const BudgetAlertsZone(),
            ],
          ),
        ),
      ),
    );
  }

}

class _GlassQuickAction extends StatelessWidget {
  const _GlassQuickAction({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.color,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        vertical: AppSizes.sm,
        horizontal: AppSizes.xs,
      ),
      tintColor: color.withValues(alpha: AppSizes.opacityLight),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: AppSizes.iconXs, color: color),
          const SizedBox(width: AppSizes.xs),
          Flexible(
            child: Text(
              label,
              style: context.textStyles.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
