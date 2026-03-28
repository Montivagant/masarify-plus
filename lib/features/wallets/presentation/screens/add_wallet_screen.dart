import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Add/Edit wallet screen.
///
/// Add mode: name, type, color, opening balance.
/// Edit mode: name, type, color only (balance changes via transfers/transactions).
class AddWalletScreen extends ConsumerStatefulWidget {
  const AddWalletScreen({super.key, this.editId});

  final int? editId;

  @override
  ConsumerState<AddWalletScreen> createState() => _AddWalletScreenState();
}

class _AddWalletScreenState extends ConsumerState<AddWalletScreen> {
  final _nameController = TextEditingController();
  final _senderController = TextEditingController();
  String _type = 'bank';
  String _colorHex = '#1A6B5E';
  int _balancePiastres = 0;
  List<String> _linkedSenders = [];
  String? _nameError;
  bool _loading = false;
  bool _isSystemWallet = false;

  static const _colorOptions = AppColors.pickerOptions;

  List<({String value, String label, IconData icon})> _walletTypes(
    BuildContext context,
  ) =>
      [
        (
          value: 'bank',
          label: context.l10n.wallet_type_bank_short,
          icon: AppIcons.bank
        ),
        (
          value: 'mobile_wallet',
          label: context.l10n.wallet_type_mobile_wallet_short,
          icon: AppIcons.phone
        ),
        (
          value: 'credit_card',
          label: context.l10n.wallet_type_credit_card_short,
          icon: AppIcons.creditCard
        ),
        (
          value: 'prepaid_card',
          label: context.l10n.wallet_type_prepaid_card_short,
          icon: AppIcons.prepaidCard
        ),
        (
          value: 'investment',
          label: context.l10n.wallet_type_investment_short,
          icon: AppIcons.investmentAccount
        ),
      ];

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) _loadWallet();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  Future<void> _loadWallet() async {
    final wallet =
        await ref.read(walletRepositoryProvider).getById(widget.editId!);
    if (!mounted || wallet == null) return;
    setState(() {
      _nameController.text = wallet.name;
      _type = wallet.type;
      _colorHex = wallet.colorHex;
      _balancePiastres = wallet.balance;
      _linkedSenders = List<String>.from(wallet.linkedSenders);
      _isSystemWallet = wallet.isSystemWallet;
    });
  }

  void _addSender() {
    final text = _senderController.text.trim();
    if (text.isEmpty || _linkedSenders.contains(text)) return;
    setState(() => _linkedSenders.add(text));
    _senderController.clear();
  }

  Future<void> _save() async {
    // I13 fix: prevent double-tap race condition
    if (_loading) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = context.l10n.error_name_required);
      return;
    }
    setState(() {
      _nameError = null;
      _loading = true;
    });

    try {
      final repo = ref.read(walletRepositoryProvider);
      // H5 fix: check for duplicate wallet name on both create AND edit
      final exists = await repo.existsByName(name);
      if (exists && mounted) {
        // On edit, allow keeping the same name (only block if it's a different wallet's name)
        final isSameName = widget.editId != null &&
            (await repo.getById(widget.editId!))?.name == name;
        if (!isSameName) {
          setState(() {
            _nameError = context.l10n.wallet_name_duplicate;
            _loading = false;
          });
          return;
        }
      }
      if (widget.editId != null) {
        final existing = await repo.getById(widget.editId!);
        if (existing != null) {
          await repo.update(
            existing.copyWith(
              name: name,
              type: _type,
              colorHex: _colorHex,
              linkedSenders: _linkedSenders,
            ),
          );
        }
      } else {
        await repo.create(
          name: name,
          type: _type,
          initialBalance: _balancePiastres,
          colorHex: _colorHex,
          linkedSenders: _linkedSenders,
        );
      }
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      context.pop();
    } on ArgumentError catch (_) {
      // IM-30 fix: catch duplicate name error specifically
      if (!mounted) return;
      setState(() {
        _nameError = context.l10n.wallet_name_duplicate;
        _loading = false;
      });
    } catch (_) {
      // M1 fix: show error feedback instead of silently stopping spinner
      if (!mounted) return;
      setState(() => _loading = false);
      SnackHelper.showError(context, context.l10n.common_error_generic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editId != null;
    final cs = context.colors;
    final types = _walletTypes(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppAppBar(
        title: isEdit
            ? context.l10n.wallet_edit_title
            : context.l10n.wallet_add_title,
      ),
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
            // ── Name & Type ─────────────────────────────────────────
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: context.l10n.wallet_name_label,
                    hint: context.l10n.wallet_name_hint_example,
                    controller: _nameController,
                    errorText: _nameError,
                    textInputAction: TextInputAction.next,
                    prefixIcon: const Icon(AppIcons.wallet),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Text(
                    context.l10n.wallet_type_label,
                    style: context.textStyles.labelLarge?.copyWith(
                      color: cs.outline,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  if (_isSystemWallet)
                    Text(
                      context.l10n.wallet_cannot_archive_system,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: cs.outline,
                      ),
                    )
                  else
                    Wrap(
                      spacing: AppSizes.sm,
                      runSpacing: AppSizes.sm,
                      children: types.map((t) {
                        final isSelected = t.value == _type;
                        return FilterChip(
                          selected: isSelected,
                          avatar: Icon(t.icon, size: AppSizes.iconXs),
                          label: Text(t.label),
                          onSelected: (_) => setState(() => _type = t.value),
                          showCheckmark: false,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // ── Color ────────────────────────────────────────────
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.wallet_color_label,
                    style: context.textStyles.labelLarge?.copyWith(
                      color: cs.outline,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: _colorOptions.map((hex) {
                      final color = ColorUtils.fromHex(hex);
                      final isSelected = hex == _colorHex;
                      return Semantics(
                        label: context.l10n.wallet_color_label,
                        selected: isSelected,
                        button: true,
                        child: SizedBox(
                          width: AppSizes.minTapTarget,
                          height: AppSizes.minTapTarget,
                          child: Center(
                            child: GestureDetector(
                              onTap: () => setState(() => _colorHex = hex),
                              child: Container(
                                width: AppSizes.colorSwatchSize,
                                height: AppSizes.colorSwatchSize,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected
                                      ? Border.all(
                                          color: cs.primary,
                                          width: AppSizes.colorSwatchBorder,
                                        )
                                      : Border.all(
                                          color: AppColors.transparent,
                                          width: AppSizes.colorSwatchBorder,
                                        ),
                                ),
                                child: isSelected
                                    ? Icon(
                                        AppIcons.check,
                                        color: ColorUtils.contrastColor(color),
                                        size: AppSizes.iconXs,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.md),

            // Linked SMS Senders (hidden when kSmsEnabled=false)
            if (AppConfig.kSmsEnabled) ...[
              Text(
                context.l10n.wallet_linked_senders_label,
                style: context.textStyles.labelLarge?.copyWith(
                  color: cs.outline,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                context.l10n.wallet_linked_senders_subtitle,
                style: context.textStyles.bodySmall?.copyWith(
                  color: cs.outline,
                ),
              ),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: AppSizes.sm,
                runSpacing: AppSizes.sm,
                children: [
                  ..._linkedSenders.map(
                    (s) => InputChip(
                      label: Text(s),
                      onDeleted: () => setState(
                        () => _linkedSenders.remove(s),
                      ),
                    ),
                  ),
                ],
              ),
              if (_linkedSenders.isNotEmpty)
                const SizedBox(height: AppSizes.sm),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: '',
                      controller: _senderController,
                      hint: context.l10n.wallet_linked_senders_hint,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _addSender(),
                    ),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  IconButton.filled(
                    onPressed: _addSender,
                    icon: const Icon(AppIcons.add),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xl),
            ],

            // ── Starting balance (add mode only) ─────────────────
            if (!isEdit)
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.wallet_starting_balance,
                      style: context.textStyles.labelLarge?.copyWith(
                        color: cs.outline,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Text(
                      context.l10n.wallet_starting_balance_hint,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: cs.outline,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    AmountInput(
                      onAmountChanged: (p) =>
                          setState(() => _balancePiastres = p),
                      autofocus: false,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSizes.screenHPadding,
            AppSizes.sm,
            AppSizes.screenHPadding,
            AppSizes.md,
          ),
          child: AppButton(
            label: isEdit
                ? context.l10n.common_save_changes
                : context.l10n.wallet_add_button,
            onPressed: _loading ? null : _save,
            isLoading: _loading,
            icon: AppIcons.check,
          ),
        ),
      ),
    );
  }
}
