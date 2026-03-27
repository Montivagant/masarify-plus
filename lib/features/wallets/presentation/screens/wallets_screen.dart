import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/wallet_entity.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/confirm_dialog.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class WalletsScreen extends ConsumerWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use allWalletsProvider to show both active and archived wallets.
    final walletsAsync = ref.watch(allWalletsProvider);
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
          // 2A: Filter out system wallets (Cash) from the list.
          final userWallets = wallets.where((w) => !w.isSystemWallet).toList();

          if (userWallets.isEmpty) {
            return EmptyState(
              title: context.l10n.wallets_empty_title,
              subtitle: context.l10n.wallets_empty_sub,
              ctaLabel: context.l10n.wallets_add,
              onCta: () => context.push(AppRoutes.walletAdd),
            );
          }

          // 2C: Split into active and archived sections.
          final activeWallets =
              userWallets.where((w) => !w.isArchived).toList();
          final archivedWallets =
              userWallets.where((w) => w.isArchived).toList();

          var animIndex = 0;

          return ListView(
            padding:
                const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
            children: [
              // Total header still shows total balance (all non-archived).
              _TotalHeader(totalAsync: totalAsync),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSizes.screenHPadding,
                  AppSizes.xs,
                  AppSizes.screenHPadding,
                  AppSizes.md,
                ),
                child: OutlinedButton.icon(
                  onPressed: () => context.push(AppRoutes.transfer),
                  icon: const Icon(AppIcons.transfer, size: AppSizes.iconSm),
                  label: Text(context.l10n.wallets_transfer_button),
                ),
              ),
              // Active wallet cards
              for (final wallet in activeWallets)
                _buildAnimatedCard(
                  context,
                  index: animIndex++,
                  child: _WalletCard(
                    wallet: wallet,
                    onTap: () =>
                        context.push(AppRoutes.walletDetailPath(wallet.id)),
                    onEdit: () =>
                        context.push(AppRoutes.editWalletPath(wallet.id)),
                    onArchive: wallet.isDefaultAccount
                        ? null
                        : () => _confirmArchive(context, ref, wallet),
                  ),
                ),
              // 2C: Archived section (only shown if any exist).
              if (archivedWallets.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(
                    AppSizes.screenHPadding,
                    AppSizes.lg,
                    AppSizes.screenHPadding,
                    AppSizes.sm,
                  ),
                  child: Text(
                    context.l10n.wallet_archived_section,
                    style: context.textStyles.titleSmall?.copyWith(
                      color: context.colors.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (final wallet in archivedWallets)
                  _buildAnimatedCard(
                    context,
                    index: animIndex++,
                    child: _WalletCard(
                      wallet: wallet,
                      isArchived: true,
                      onTap: () =>
                          context.push(AppRoutes.walletDetailPath(wallet.id)),
                      onEdit: () =>
                          context.push(AppRoutes.editWalletPath(wallet.id)),
                      onUnarchive: () =>
                          _confirmUnarchive(context, ref, wallet),
                    ),
                  ),
              ],
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

  // ── 2D: Archive — 2-step confirmation ──────────────────────────────────

  Future<void> _confirmArchive(
    BuildContext context,
    WidgetRef ref,
    WalletEntity wallet,
  ) async {
    // 2G: Guard — prevent archiving default or system accounts.
    if (wallet.isDefaultAccount || wallet.isSystemWallet) return;

    // Step 1: Info dialog explaining consequences.
    final proceed = await ConfirmDialog.show(
      context,
      title: context.l10n.wallet_archive_title,
      message: context.l10n.wallet_archive_info,
      confirmLabel: context.l10n.common_continue_label,
    );
    if (!proceed || !context.mounted) return;

    // Step 2: Confirm with account name.
    final confirmed = await ConfirmDialog.show(
      context,
      title: context.l10n.wallet_archive_action,
      message: context.l10n.wallet_archive_confirm(wallet.name),
      confirmLabel: context.l10n.wallet_archive_action,
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    await ref.read(walletRepositoryProvider).archive(wallet.id);
    HapticFeedback.mediumImpact();
  }

  // ── 2E: Unarchive — single confirmation ────────────────────────────────

  Future<void> _confirmUnarchive(
    BuildContext context,
    WidgetRef ref,
    WalletEntity wallet,
  ) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: context.l10n.wallet_unarchive_action,
      message: context.l10n.wallet_unarchive_confirm(wallet.name),
    );
    if (!confirmed || !context.mounted) return;

    await ref.read(walletRepositoryProvider).unarchive(wallet.id);
    HapticFeedback.mediumImpact();
  }
}

/// E4: Wraps a list item with staggered fade+slide animation.
/// Returns the child unchanged when user prefers reduced motion.
Widget _buildAnimatedCard(
  BuildContext context, {
  required int index,
  required Widget child,
}) {
  if (context.reduceMotion) return child;
  return child
      .animate()
      .fadeIn(duration: AppDurations.listItemEntry)
      .slideY(
        begin: 0.03,
        end: 0,
        duration: AppDurations.listItemEntry,
        curve: Curves.easeOutCubic,
      )
      .then(delay: AppDurations.staggerDelay * index);
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
    this.isArchived = false,
    this.onArchive,
    this.onUnarchive,
  });
  final WalletEntity wallet;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final bool isArchived;
  final VoidCallback? onArchive;
  final VoidCallback? onUnarchive;

  String _typeLabel(BuildContext context, String type) => switch (type) {
        'physical_cash' => context.l10n.wallet_type_physical_cash_short,
        'bank' => context.l10n.wallet_type_bank_short,
        'mobile_wallet' => context.l10n.wallet_type_mobile_wallet_short,
        'credit_card' => context.l10n.wallet_type_credit_card_short,
        'prepaid_card' => context.l10n.wallet_type_prepaid_card_short,
        'investment' => context.l10n.wallet_type_investment_short,
        _ => context.l10n.wallet_type_bank_short,
      };

  // Wallet type icon resolved via AppIcons.walletType() (single source).

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.fromHex(wallet.colorHex);
    final nameStyle = context.textStyles.bodyLarge;

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
            child: Icon(
              AppIcons.walletType(wallet.type),
              color: isArchived
                  ? color.withValues(alpha: AppSizes.opacityMedium)
                  : color,
              size: AppSizes.iconSm,
            ),
          ),
        ),
        title: Text(
          wallet.name,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          // 2C: Strikethrough for archived wallets.
          style: isArchived
              ? nameStyle?.copyWith(decoration: TextDecoration.lineThrough)
              : nameStyle,
        ),
        subtitle: Text(_typeLabel(context, wallet.type)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              MoneyFormatter.format(wallet.balance),
              style: context.textStyles.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            // Archive/Unarchive action via popup menu on long press.
            if (onArchive != null || onUnarchive != null)
              PopupMenuButton<String>(
                icon: Icon(
                  AppIcons.moreVert,
                  size: AppSizes.iconSm,
                  color: context.colors.outline,
                ),
                padding: EdgeInsets.zero,
                itemBuilder: (_) => [
                  if (!isArchived && onArchive != null)
                    PopupMenuItem<String>(
                      value: 'archive',
                      child: Row(
                        children: [
                          const Icon(AppIcons.archive, size: AppSizes.iconSm),
                          const SizedBox(width: AppSizes.sm),
                          Text(context.l10n.wallet_archive_action),
                        ],
                      ),
                    ),
                  if (isArchived && onUnarchive != null)
                    PopupMenuItem<String>(
                      value: 'unarchive',
                      child: Row(
                        children: [
                          const Icon(AppIcons.unarchive, size: AppSizes.iconSm),
                          const SizedBox(width: AppSizes.sm),
                          Text(context.l10n.wallet_unarchive_action),
                        ],
                      ),
                    ),
                ],
                onSelected: (value) {
                  if (value == 'archive') {
                    onArchive?.call();
                  } else if (value == 'unarchive') {
                    onUnarchive?.call();
                  }
                },
              ),
          ],
        ),
        onLongPress: onEdit,
      ),
    );
  }
}
