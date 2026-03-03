import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/wallet_entity.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(walletsProvider);
    final totalAsync = ref.watch(totalBalanceProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.wallets_title,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.add),
            tooltip: context.l10n.wallet_add_title,
            onPressed: () => context.push(AppRoutes.walletAdd),
          ),
        ],
      ),
      body: walletsAsync.when(
        data: (wallets) {
          if (wallets.isEmpty) {
            return EmptyState(
              title: context.l10n.wallets_empty_title,
              subtitle: context.l10n.wallets_empty_sub,
              ctaLabel: context.l10n.wallets_add,
              onCta: () => context.push(AppRoutes.walletAdd),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
            children: [
              _TotalHeader(totalAsync: totalAsync),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSizes.screenHPadding, AppSizes.xs,
                  AppSizes.screenHPadding, AppSizes.md,
                ),
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.transfer),
                  icon: const Icon(AppIcons.transfer, size: AppSizes.iconSm),
                  label: Text(context.l10n.wallets_transfer_button),
                ),
              ),
              ...wallets.map(
                (w) => _WalletCard(
                  wallet: w,
                  onTap: () => context.push(AppRoutes.walletDetailPath(w.id)),
                  onEdit: () => context.push(AppRoutes.editWalletPath(w.id)),
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSizes.screenHPadding),
          child: ShimmerList(itemCount: 4),
        ),
        error: (_, __) => EmptyState(title: context.l10n.common_error_title),
      ),
    );
  }
}

class _TotalHeader extends StatelessWidget {
  const _TotalHeader({required this.totalAsync});
  final AsyncValue<int> totalAsync;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return GlassCard(
      showShadow: true,
      margin: const EdgeInsets.all(AppSizes.screenHPadding),
      padding: const EdgeInsets.all(AppSizes.lg),
      tintColor: cs.primaryContainer.withValues(alpha: AppSizes.opacityLight4),
      child: Column(
        children: [
          Text(
            context.l10n.wallet_total_balance,
            // NB: alpha 0.8 on onPrimaryContainer yields marginal contrast
            // on some primaryContainer tints. Kept at opacityHeavy (0.8) as
            // the header background is strong enough; revisit if palette shifts.
            style: context.textStyles.bodyMedium?.copyWith(
                  color: cs.onPrimaryContainer
                      .withValues(alpha: AppSizes.opacityHeavy),
                ),
          ),
          const SizedBox(height: AppSizes.xs),
          totalAsync.when(
            data: (total) => Text(
              MoneyFormatter.format(total),
              style: context.textStyles.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer,
                  ),
            ),
            loading: () => const CircularProgressIndicator.adaptive(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _WalletCard extends StatelessWidget {
  const _WalletCard({
    required this.wallet,
    required this.onTap,
    required this.onEdit,
  });
  final WalletEntity wallet;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  String _typeLabel(BuildContext context, String type) => switch (type) {
        'bank' => context.l10n.wallet_type_bank_short,
        'mobile_wallet' => context.l10n.wallet_type_mobile_wallet_short,
        'credit_card' => context.l10n.wallet_type_credit_card_short,
        'savings' => context.l10n.wallet_type_savings_short,
        _ => context.l10n.wallet_type_cash_short,
      };

  static IconData _typeIcon(String type) => switch (type) {
        'bank' => AppIcons.bank,
        'mobile_wallet' => AppIcons.phone,
        'credit_card' => AppIcons.creditCard,
        'savings' => AppIcons.goals,
        _ => AppIcons.wallet,
      };

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.fromHex(wallet.colorHex);
    return GlassCard(
      showShadow: true,
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      child: ListTile(
        leading: GlassCard(
          tier: GlassTier.inset,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          tintColor: color.withValues(alpha: AppSizes.opacityLight2),
          child: SizedBox(
            width: AppSizes.iconContainerLg,
            height: AppSizes.iconContainerLg,
            child: Icon(_typeIcon(wallet.type), color: color, size: AppSizes.iconSm),
          ),
        ),
        title: Text(wallet.name),
        subtitle: Text(_typeLabel(context, wallet.type)),
        trailing: Text(
          MoneyFormatter.format(wallet.balance),
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        onTap: onTap,
        onLongPress: onEdit,
      ),
    );
  }
}
