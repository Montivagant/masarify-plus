import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/wallet_entity.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/feedback/confirm_dialog.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';

/// Modal sheet for reordering and managing account cards.
class AccountManageSheet extends ConsumerStatefulWidget {
  const AccountManageSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const AccountManageSheet(),
    );
  }

  @override
  ConsumerState<AccountManageSheet> createState() => _AccountManageSheetState();
}

class _AccountManageSheetState extends ConsumerState<AccountManageSheet> {
  List<WalletEntity>? _wallets;

  @override
  void initState() {
    super.initState();
    _loadWallets();
  }

  Future<void> _loadWallets() async {
    final wallets =
        await ref.read(walletRepositoryProvider).getAllIncludingArchived();
    if (!mounted) return;
    // Sort by sortOrder then id.
    final userWallets = wallets.toList()
      ..sort((a, b) {
        final cmp = a.sortOrder.compareTo(b.sortOrder);
        return cmp != 0 ? cmp : a.id.compareTo(b.id);
      });
    setState(() => _wallets = userWallets);
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final wallets = _wallets;
    if (wallets == null) return;

    if (newIndex > oldIndex) newIndex--;
    final item = wallets.removeAt(oldIndex);
    wallets.insert(newIndex, item);

    setState(() {}); // update UI immediately

    // Persist new order.
    final updates = <({int id, int sortOrder})>[];
    for (var i = 0; i < wallets.length; i++) {
      updates.add((id: wallets[i].id, sortOrder: i));
    }
    await ref.read(walletRepositoryProvider).updateSortOrders(updates);
  }

  Future<void> _toggleArchive(WalletEntity wallet) async {
    if (wallet.isSystemWallet) return;
    final repo = ref.read(walletRepositoryProvider);

    if (wallet.isArchived) {
      // Unarchive — single confirmation
      final confirmed = await ConfirmDialog.show(
        context,
        title: context.l10n.wallet_unarchive_action,
        message: context.l10n.wallet_unarchive_confirm(wallet.name),
      );
      if (!confirmed || !mounted) return;
      await repo.unarchive(wallet.id);
      HapticFeedback.mediumImpact();
    } else {
      // Prevent archiving the default account.
      if (wallet.isDefaultAccount) {
        if (!mounted) return;
        SnackHelper.showError(
          context,
          context.l10n.wallet_cannot_archive_default,
        );
        return;
      }

      // Step 1: Info dialog explaining consequences.
      final proceed = await ConfirmDialog.show(
        context,
        title: context.l10n.wallet_archive_title,
        message: context.l10n.wallet_archive_info,
        confirmLabel: context.l10n.common_continue_label,
      );
      if (!proceed || !mounted) return;

      // Step 2: Confirm with account name.
      final confirmed = await ConfirmDialog.show(
        context,
        title: context.l10n.wallet_archive_action,
        message: context.l10n.wallet_archive_confirm(wallet.name),
        confirmLabel: context.l10n.wallet_archive_action,
        destructive: true,
      );
      if (!confirmed || !mounted) return;

      await repo.archive(wallet.id);
      HapticFeedback.mediumImpact();
    }
    await _loadWallets(); // refresh
  }

  Future<void> _setAsDefault(WalletEntity wallet) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: context.l10n.wallet_set_default_title,
      message: context.l10n.wallet_set_default_confirm(wallet.name),
    );
    if (!confirmed || !mounted) return;
    await ref.read(walletRepositoryProvider).setAsDefault(wallet.id);
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    SnackHelper.showSuccess(
      context,
      context.l10n.wallet_set_default_success(wallet.name),
    );
    await _loadWallets();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final wallets = _wallets;

    return DraggableScrollableSheet(
      initialChildSize: AppSizes.sheetInitialSize,
      minChildSize: AppSizes.sheetMinSize,
      maxChildSize: AppSizes.sheetMaxSize,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              child: Container(
                width: AppSizes.dragHandleWidth,
                height: AppSizes.dragHandleHeight,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
                vertical: AppSizes.xs,
              ),
              child: Text(
                context.l10n.wallet_manage_title,
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.sm),
            // Reorderable list
            if (wallets == null)
              const Expanded(
                child: Center(child: CircularProgressIndicator.adaptive()),
              )
            else if (wallets.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    context.l10n.wallet_add_title,
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: cs.outline,
                    ),
                  ),
                ),
              )
            else
              Expanded(
                child: ReorderableListView.builder(
                  scrollController: scrollController,
                  itemCount: wallets.length,
                  onReorder: _onReorder,
                  proxyDecorator: (child, index, animation) {
                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) => Material(
                        elevation: AppSizes.elevationHigh,
                        color: cs.surface,
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusMd),
                        child: child,
                      ),
                      child: child,
                    );
                  },
                  itemBuilder: (context, index) {
                    final w = wallets[index];
                    return _WalletTile(
                      key: ValueKey(w.id),
                      wallet: w,
                      index: index,
                      onToggleArchive: () => _toggleArchive(w),
                      onSetDefault: w.isDefaultAccount || w.isArchived
                          ? null
                          : () => _setAsDefault(w),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _WalletTile extends StatelessWidget {
  const _WalletTile({
    super.key,
    required this.wallet,
    required this.index,
    required this.onToggleArchive,
    this.onSetDefault,
  });

  final WalletEntity wallet;
  final int index;
  final VoidCallback onToggleArchive;
  final VoidCallback? onSetDefault;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final isArchived = wallet.isArchived;
    final isDefault = wallet.isDefaultAccount;

    return ListTile(
      leading: ReorderableDragStartListener(
        index: index,
        child: Icon(
          AppIcons.dragHandle,
          color: cs.outline,
          size: AppSizes.iconSm,
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              wallet.name,
              style: context.textStyles.bodyMedium?.copyWith(
                color: isArchived ? cs.outline : null,
                decoration: isArchived ? TextDecoration.lineThrough : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isDefault) ...[
            const SizedBox(width: AppSizes.xs),
            Icon(AppIcons.star, size: AppSizes.iconXs, color: cs.primary),
          ],
        ],
      ),
      subtitle: Text(
        MoneyFormatter.format(wallet.balance),
        style: context.textStyles.bodySmall?.copyWith(
          color: cs.outline,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onSetDefault != null)
            IconButton(
              icon: Icon(
                AppIcons.star,
                size: AppSizes.iconSm,
                color: cs.outline,
              ),
              onPressed: onSetDefault,
              tooltip: context.l10n.wallet_set_default_title,
            ),
          Opacity(
            opacity: wallet.isSystemWallet ? AppSizes.opacityLight4 : 1.0,
            child: IconButton(
              icon: Icon(
                isArchived ? AppIcons.unarchive : AppIcons.archive,
                size: AppSizes.iconSm,
                color: isArchived ? cs.primary : cs.outline,
              ),
              onPressed: onToggleArchive,
              tooltip: isArchived
                  ? context.l10n.wallet_unarchive_action
                  : context.l10n.wallet_archive_action,
            ),
          ),
        ],
      ),
    );
  }
}
