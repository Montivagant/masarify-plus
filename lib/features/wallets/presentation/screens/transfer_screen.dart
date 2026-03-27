import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/wallet_entity.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../../../../shared/widgets/sheets/drag_handle.dart';

/// Transfer between wallets — Rule #8: never income/expense.
class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key});

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  int? _fromWalletId;
  int? _toWalletId;
  int _amountPiastres = 0;
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initWallets();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _initWallets() async {
    final wallets = await ref.read(walletRepositoryProvider).getAll();
    if (!mounted || wallets.isEmpty) return;
    setState(() {
      _fromWalletId = wallets.first.id;
      _toWalletId = wallets.length > 1 ? wallets[1].id : null;
    });
  }

  void _showWalletPicker({required bool isFrom}) {
    final allWallets = ref.read(walletsProvider).valueOrNull ?? [];
    // IM-29 fix: exclude the other side's wallet from the picker
    final excludeId = isFrom ? _toWalletId : _fromWalletId;
    final wallets = allWallets.where((w) => w.id != excludeId).toList();
    final current = isFrom ? _fromWalletId : _toWalletId;
    final pickerTitle = isFrom
        ? context.l10n.transfer_from_wallet
        : context.l10n.transfer_to_wallet;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight:
                MediaQuery.sizeOf(ctx).height * AppSizes.bottomSheetHeightRatio,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DragHandle(),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSizes.screenHPadding,
                  AppSizes.md,
                  AppSizes.screenHPadding,
                  AppSizes.sm,
                ),
                child: Text(pickerTitle, style: ctx.textStyles.titleMedium),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ...wallets.map(
                      (w) => ListTile(
                        leading: const Icon(AppIcons.wallet),
                        title: Text(w.name),
                        subtitle: Text(MoneyFormatter.format(w.balance)),
                        trailing:
                            current == w.id ? const Icon(AppIcons.check) : null,
                        onTap: () {
                          setState(() {
                            if (isFrom) {
                              _fromWalletId = w.id;
                            } else {
                              _toWalletId = w.id;
                            }
                          });
                          ctx.pop();
                        },
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final from = _fromWalletId;
    final to = _toWalletId;
    if (from == null || to == null || _amountPiastres <= 0) return;
    if (from == to) {
      SnackHelper.showError(context, context.l10n.transfer_different_wallets);
      return;
    }
    // M6 fix: warn (but don't block) if source wallet has insufficient funds
    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    final sourceWallet = wallets.where((w) => w.id == from).firstOrNull;
    if (sourceWallet != null && sourceWallet.balance < _amountPiastres) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(context.l10n.transfer_insufficient_title),
          content: Text(context.l10n.transfer_insufficient_body),
          actions: [
            TextButton(
              onPressed: () => ctx.pop(false),
              child: Text(context.l10n.common_cancel),
            ),
            TextButton(
              onPressed: () => ctx.pop(true),
              child: Text(context.l10n.common_confirm),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(transferRepositoryProvider).create(
            fromWalletId: from,
            toWalletId: to,
            amount: _amountPiastres,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
            transferDate: DateTime.now(),
          );
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      // L7 fix: show success feedback
      SnackHelper.showSuccess(context, context.l10n.transfer_success);
      context.pop();
    } catch (_) {
      // M1 fix: show error feedback instead of silently stopping spinner
      if (!mounted) return;
      setState(() => _loading = false);
      SnackHelper.showError(context, context.l10n.common_error_generic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final fromWallet = wallets.where((w) => w.id == _fromWalletId).firstOrNull;
    final toWallet = wallets.where((w) => w.id == _toWalletId).firstOrNull;
    final canSave = _fromWalletId != null &&
        _toWalletId != null &&
        _fromWalletId != _toWalletId &&
        _amountPiastres > 0;

    return Scaffold(
      appBar: AppAppBar(title: context.l10n.transfer_title),
      body: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.fromSTEB(
          AppSizes.screenHPadding,
          AppSizes.md,
          AppSizes.screenHPadding,
          AppSizes.bottomScrollPadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.transfer_from,
              style: context.textStyles.labelLarge
                  ?.copyWith(color: context.colors.outline),
            ),
            const SizedBox(height: AppSizes.xs),
            _WalletSelector(
              wallet: fromWallet,
              placeholder: context.l10n.transfer_select_wallet,
              onTap: () => _showWalletPicker(isFrom: true),
            ),
            const SizedBox(height: AppSizes.md),
            Center(
              child: IconButton.outlined(
                icon: const Icon(AppIcons.transfer),
                onPressed: () => setState(() {
                  final tmp = _fromWalletId;
                  _fromWalletId = _toWalletId;
                  _toWalletId = tmp;
                }),
                tooltip: context.l10n.transfer_swap,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              context.l10n.transfer_to,
              style: context.textStyles.labelLarge
                  ?.copyWith(color: context.colors.outline),
            ),
            const SizedBox(height: AppSizes.xs),
            _WalletSelector(
              wallet: toWallet,
              placeholder: context.l10n.transfer_select_wallet,
              onTap: () => _showWalletPicker(isFrom: false),
            ),
            const SizedBox(height: AppSizes.xl),
            Text(
              context.l10n.transfer_amount_label,
              style: context.textStyles.labelLarge
                  ?.copyWith(color: context.colors.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            AmountInput(
              onAmountChanged: (p) => setState(() => _amountPiastres = p),
            ),
            const SizedBox(height: AppSizes.lg),
            AppTextField(
              label: context.l10n.transfer_note_label,
              controller: _noteController,
              maxLines: 2,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.screenHPadding,
            AppSizes.sm,
            AppSizes.screenHPadding,
            AppSizes.md,
          ),
          child: AppButton(
            label: context.l10n.transfer_confirm_button,
            onPressed: canSave && !_loading ? _save : null,
            isLoading: _loading,
            icon: AppIcons.transfer,
          ),
        ),
      ),
    );
  }
}

class _WalletSelector extends StatelessWidget {
  const _WalletSelector({
    required this.wallet,
    required this.placeholder,
    required this.onTap,
  });
  final WalletEntity? wallet;
  final String placeholder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md,
          vertical: AppSizes.md,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outline),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        ),
        child: Row(
          children: [
            const Icon(AppIcons.wallet, size: AppSizes.iconSm),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: wallet != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(wallet!.name, style: context.textStyles.bodyLarge),
                        Text(
                          MoneyFormatter.format(wallet!.balance),
                          style: context.textStyles.bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                      ],
                    )
                  : Text(
                      placeholder,
                      style: context.textStyles.bodyMedium
                          ?.copyWith(color: cs.outline),
                    ),
            ),
            const Icon(AppIcons.expandMore, size: AppSizes.iconXs),
          ],
        ),
      ),
    );
  }
}
