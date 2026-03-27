import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/budget_provider.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/home_filter_provider.dart';
import '../../../../shared/providers/transaction_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../widgets/balance_header.dart';
import '../widgets/filter_bar.dart';
import '../widgets/filter_bar_delegate.dart';
import '../widgets/insight_cards_zone.dart';
import '../widgets/quick_start_tip_card.dart';

/// Dashboard -- CustomScrollView + Slivers shell (Phase 03 overhaul).
///
/// Replaces the previous SingleChildScrollView + Column layout with a
/// sliver-based architecture for performance with large transaction lists
/// and pinned filter bar support.
///
/// Layout order:
/// 1. Offline banner (conditional)
/// 2. Quick start tip card (conditional)
/// 3. Balance header with account chips
/// 4. Insight cards zone (scroll away)
/// 5. Pinned filter bar
/// 6. Transaction list placeholder (Plan 02)
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final monthKey = (now.year, now.month);
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final filter = ref.watch(homeFilterProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.dashboard_title,
        showBack: false,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.ai),
            onPressed: () => context.push(AppRoutes.chat),
            tooltip: context.l10n.dashboard_chat_tooltip,
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
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Offline banner ────────────────────────────────────────
            if (!isOnline) SliverToBoxAdapter(child: _OfflineBanner()),

            // ── Quick start tip card (conditional) ────────────────────
            const SliverToBoxAdapter(child: QuickStartTipCard()),

            // ── Balance header with account chips (D-01 to D-05) ──────
            const SliverToBoxAdapter(child: BalanceHeader()),

            // ── Insight cards zone (scroll away, D-07) ────────────────
            if (!filter.isSearchActive)
              const SliverToBoxAdapter(child: InsightCardsZone()),

            // ── Pinned filter bar (D-09) ──────────────────────────────
            const SliverPersistentHeader(
              pinned: true,
              delegate: FilterBarDelegate(child: FilterBar()),
            ),

            // ── Transaction list placeholder (Plan 02) ────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Center(
                  child: Text(
                    context.l10n.dashboard_recent_transactions,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom padding for nav bar clearance ──────────────────
            const SliverPadding(
              padding: EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Offline banner ──────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
