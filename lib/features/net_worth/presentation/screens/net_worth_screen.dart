import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/providers/net_worth_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class NetWorthScreen extends ConsumerWidget {
  const NetWorthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nwAsync = ref.watch(netWorthProvider);
    final walletsAsync = ref.watch(walletsProvider);

    return Scaffold(
      appBar: AppAppBar(title: context.l10n.net_worth_title),
      body: nwAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(context.l10n.common_error_generic),
        ),
        data: (nw) {
          final wallets = walletsAsync.valueOrNull ?? [];
          if (wallets.isEmpty) {
            return EmptyState(
              title: context.l10n.net_worth_title,
              subtitle: context.l10n.net_worth_no_wallets,
            );
          }

          final cs = Theme.of(context).colorScheme;
          final isPositive = nw.netWorth >= 0;

          return ListView(
            padding: const EdgeInsets.only(
              bottom: AppSizes.bottomScrollPadding,
            ),
            children: [
              // ── Hero net worth number ───────────────────────────────
              Container(
                width: double.infinity,
                margin: const EdgeInsetsDirectional.fromSTEB(
                  AppSizes.screenHPadding,
                  AppSizes.md,
                  AppSizes.screenHPadding,
                  AppSizes.lg,
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: AppSizes.xl,
                  horizontal: AppSizes.md,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusMd),
                ),
                child: Column(
                  children: [
                    Text(
                      context.l10n.net_worth_current,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: cs.onPrimaryContainer),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    Text(
                      MoneyFormatter.format(nw.netWorth.abs()),
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isPositive
                                ? context.appTheme.incomeColor
                                : context.appTheme.expenseColor,
                          ),
                    ),
                  ],
                ),
              ),

              // ── Assets / Liabilities summary ────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        label: context.l10n.net_worth_assets,
                        amount: nw.assets,
                        color: context.appTheme.incomeColor,
                        icon: AppIcons.income,
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: _SummaryCard(
                        label: context.l10n.net_worth_liabilities,
                        amount: nw.liabilities,
                        color: context.appTheme.expenseColor,
                        icon: AppIcons.expense,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSizes.lg),

              // ── Wallet breakdown ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                ),
                child: Text(
                  context.l10n.net_worth_wallet_breakdown,
                  style: Theme.of(context)
                      .textTheme
                      .labelLarge
                      ?.copyWith(color: cs.outline),
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              ...wallets.map(
                (w) => _WalletRow(
                  name: w.name,
                  balance: w.balance,
                  colorHex: w.colorHex,
                  isCreditCard: w.type == 'credit_card',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: AppSizes.iconXs, color: color),
              const SizedBox(width: AppSizes.xs),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.xs),
          Text(
            MoneyFormatter.format(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}

// ── Wallet row ────────────────────────────────────────────────────────────

class _WalletRow extends StatelessWidget {
  const _WalletRow({
    required this.name,
    required this.balance,
    required this.colorHex,
    required this.isCreditCard,
  });

  final String name;
  final int balance;
  final String colorHex;
  final bool isCreditCard;

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.fromHex(colorHex);
    final balanceColor = isCreditCard && balance > 0
        ? context.appTheme.expenseColor
        : Theme.of(context).colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.sm,
      ),
      child: Row(
        children: [
          Container(
            width: AppSizes.iconContainerMd,
            height: AppSizes.iconContainerMd,
            decoration: BoxDecoration(
              color: color.withValues(alpha: AppSizes.opacityLight2),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
            ),
            child: Icon(AppIcons.wallet, size: AppSizes.iconSm, color: color),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            MoneyFormatter.format(balance),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: balanceColor,
                ),
          ),
        ],
      ),
    );
  }
}
