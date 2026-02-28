import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
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
  String _type = 'cash';
  String _colorHex = '#1A6B5E';
  int _balancePiastres = 0;
  String? _nameError;
  bool _loading = false;

  static const _colorOptions = AppColors.pickerOptions;

  List<({String value, String label, IconData icon})> _walletTypes(
    BuildContext context,
  ) =>
      [
        (value: 'cash',          label: context.l10n.wallet_type_cash_short,          icon: AppIcons.wallet),
        (value: 'bank',          label: context.l10n.wallet_type_bank_short,           icon: AppIcons.netWorth),
        (value: 'mobile_wallet', label: context.l10n.wallet_type_mobile_wallet_short, icon: AppIcons.phone),
        (value: 'credit_card',   label: context.l10n.wallet_type_credit_card_short,    icon: AppIcons.creditCard),
        (value: 'savings',       label: context.l10n.wallet_type_savings_short,        icon: AppIcons.goals),
      ];

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) _loadWallet();
  }

  @override
  void dispose() {
    _nameController.dispose();
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
    });
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
      // M3 fix: check for duplicate wallet name
      if (widget.editId == null) {
        final exists = await repo.existsByName(name);
        if (exists && mounted) {
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
            existing.copyWith(name: name, type: _type, colorHex: _colorHex),
          );
        }
      } else {
        await repo.create(
          name: name,
          type: _type,
          initialBalance: _balancePiastres,
          colorHex: _colorHex,
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.common_error_generic)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editId != null;
    final cs = context.colors;
    final types = _walletTypes(context);

    return Scaffold(
      appBar: AppAppBar(
        title: isEdit ? context.l10n.wallet_edit_title : context.l10n.wallet_add_title,
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
            // Name
            AppTextField(
              label: context.l10n.wallet_name_label,
              hint: context.l10n.wallet_name_hint_example,
              controller: _nameController,
              errorText: _nameError,
              textInputAction: TextInputAction.next,
              prefixIcon: const Icon(AppIcons.wallet),
            ),
            const SizedBox(height: AppSizes.lg),

            // Type
            Text(
              context.l10n.wallet_type_label,
              style: context.textStyles.labelLarge?.copyWith(
                    color: cs.outline,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
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
            const SizedBox(height: AppSizes.lg),

            // Color
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
                return GestureDetector(
                  onTap: () => setState(() => _colorHex = hex),
                  child: Container(
                    width: AppSizes.colorSwatchSize,
                    height: AppSizes.colorSwatchSize,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: cs.primary, width: AppSizes.colorSwatchBorder)
                          : Border.all(color: Colors.transparent, width: AppSizes.colorSwatchBorder),
                    ),
                    child: isSelected
                        ? Icon(AppIcons.check, color: ColorUtils.contrastColor(color), size: AppSizes.iconXs)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.xl),

            // Opening balance (add mode only)
            if (!isEdit) ...[
              Text(
                context.l10n.wallet_initial_balance,
                style: context.textStyles.labelLarge?.copyWith(
                      color: cs.outline,
                    ),
              ),
              const SizedBox(height: AppSizes.sm),
              AmountInput(
                onAmountChanged: (p) => setState(() => _balancePiastres = p),
              ),
              const SizedBox(height: AppSizes.xl),
            ],

            AppButton(
              label: isEdit
                  ? context.l10n.common_save_changes
                  : context.l10n.wallet_add_button,
              onPressed: _loading ? null : _save,
              isLoading: _loading,
              icon: AppIcons.check,
            ),
          ],
        ),
      ),
    );
  }
}
