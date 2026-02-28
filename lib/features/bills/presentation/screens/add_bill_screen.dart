import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../domain/entities/bill_entity.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/inputs/app_date_picker.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Add / Edit bill screen.
class AddBillScreen extends ConsumerStatefulWidget {
  const AddBillScreen({super.key, this.editId});

  final int? editId;

  @override
  ConsumerState<AddBillScreen> createState() => _AddBillScreenState();
}

class _AddBillScreenState extends ConsumerState<AddBillScreen> {
  final _nameController = TextEditingController();
  int _amountPiastres = 0;
  int? _categoryId;
  int? _walletId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) {
      _loadBill();
    } else {
      _initWallet();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _initWallet() async {
    final wallets = await ref.read(walletRepositoryProvider).getAll();
    if (!mounted || wallets.isEmpty) return;
    setState(() => _walletId = wallets.first.id);
  }

  Future<void> _loadBill() async {
    final bill = await ref.read(billRepositoryProvider).getById(widget.editId!);
    if (!mounted || bill == null) return;
    setState(() {
      _nameController.text = bill.name;
      _amountPiastres = bill.amount;
      _categoryId = bill.categoryId;
      _walletId = bill.walletId;
      _dueDate = bill.dueDate;
    });
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

  void _showCategoryPicker(List<CategoryEntity> categories) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        builder: (_, controller) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              width: AppSizes.dragHandleWidth,
              height: AppSizes.dragHandleHeight,
              decoration: BoxDecoration(
                color: ctx.colors.outlineVariant,
                borderRadius: BorderRadius.circular(AppSizes.dragHandleHeight / 2),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSizes.md,
                0,
                AppSizes.md,
                AppSizes.sm,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  context.l10n.transaction_category_picker,
                  style: ctx.textStyles.titleMedium,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                children: categories
                    .map(
                      (c) => ListTile(
                        leading:
                            Icon(CategoryIconMapper.fromName(c.iconName)),
                        title: Text(c.displayName(context.languageCode)),
                        trailing: _categoryId == c.id
                            ? const Icon(AppIcons.check)
                            : null,
                        onTap: () {
                          setState(() => _categoryId = c.id);
                          ctx.pop();
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWalletPicker() {
    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    if (wallets.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(ctx).height * AppSizes.bottomSheetHeightRatio,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
                width: AppSizes.dragHandleWidth,
                height: AppSizes.dragHandleHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ctx.colors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppSizes.dragHandleHeight / 2),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(
                  AppSizes.md, 0, AppSizes.md, AppSizes.sm,
                ),
                child: Text(
                  context.l10n.transaction_wallet_picker,
                  style: ctx.textStyles.titleMedium,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: wallets.map(
                    (w) => ListTile(
                      leading: const Icon(AppIcons.wallet),
                      title: Text(w.name),
                      trailing:
                          _walletId == w.id ? const Icon(AppIcons.check) : null,
                      onTap: () {
                        setState(() => _walletId = w.id);
                        ctx.pop();
                      },
                    ),
                  ).toList(),
                ),
              ),
              const SizedBox(height: AppSizes.md),
            ],
          ),
        ),
      ),
    );
  }

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    // R5-I3 fix: prevent double-tap race condition
    if (_loading) return;
    final name = _nameController.text.trim();
    if (name.isEmpty ||
        _amountPiastres <= 0 ||
        _categoryId == null ||
        _walletId == null) {
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(billRepositoryProvider);
      if (widget.editId != null) {
        final existing = await repo.getById(widget.editId!);
        if (existing != null) {
          await repo.update(
            BillEntity(
              id: existing.id,
              name: name,
              amount: _amountPiastres,
              walletId: _walletId!,
              categoryId: _categoryId!,
              dueDate: _dueDate,
              isPaid: existing.isPaid,
              paidAt: existing.paidAt,
              linkedTransactionId: existing.linkedTransactionId,
            ),
          );
        }
      } else {
        await repo.create(
          name: name,
          amount: _amountPiastres,
          walletId: _walletId!,
          categoryId: _categoryId!,
          dueDate: _dueDate,
        );
      }

      HapticFeedback.heavyImpact();
      if (!mounted) return;
      context.pop();
    } catch (_) {
      // M1 fix: show error feedback instead of silently stopping spinner
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.common_error_generic)),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editId != null;
    final cs = context.colors;
    final categories =
        ref.watch(expenseCategoriesProvider).valueOrNull ?? [];
    final selectedCat =
        categories.where((c) => c.id == _categoryId).firstOrNull;

    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final selectedWallet =
        wallets.where((w) => w.id == _walletId).firstOrNull;

    final canSave = _nameController.text.trim().isNotEmpty &&
        _amountPiastres > 0 &&
        _categoryId != null &&
        _walletId != null;

    return Scaffold(
      appBar: AppAppBar(
        title: isEdit
            ? context.l10n.bill_edit_title
            : context.l10n.bill_add_title,
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
            // ── Bill name ─────────────────────────────────────────────
            AppTextField(
              label: context.l10n.bill_name_label,
              hint: context.l10n.bill_name_hint,
              controller: _nameController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Category picker ───────────────────────────────────────
            Text(
              context.l10n.transaction_category,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            GestureDetector(
              onTap: () => _showCategoryPicker(categories),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.md,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline),
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusMd),
                ),
                child: Row(
                  children: [
                    Icon(
                      selectedCat != null
                          ? CategoryIconMapper.fromName(
                              selectedCat.iconName,
                            )
                          : AppIcons.category,
                      size: AppSizes.iconSm,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        selectedCat?.displayName(context.languageCode) ??
                            context.l10n.transaction_category_picker,
                        style: selectedCat != null
                            ? context.textStyles.bodyLarge
                            : TextStyle(color: cs.outline),
                      ),
                    ),
                    const Icon(AppIcons.expandMore, size: AppSizes.iconXs),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Wallet picker ─────────────────────────────────────────
            Text(
              context.l10n.transaction_wallet,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            GestureDetector(
              onTap: _showWalletPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                  vertical: AppSizes.md,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: cs.outline),
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusMd),
                ),
                child: Row(
                  children: [
                    const Icon(AppIcons.wallet, size: AppSizes.iconSm),
                    const SizedBox(width: AppSizes.sm),
                    Expanded(
                      child: Text(
                        selectedWallet?.name ??
                            context.l10n.transaction_wallet_picker,
                        style: selectedWallet != null
                            ? context.textStyles.bodyLarge
                            : TextStyle(color: cs.outline),
                      ),
                    ),
                    const Icon(AppIcons.expandMore, size: AppSizes.iconXs),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Amount ────────────────────────────────────────────────
            Text(
              context.l10n.bill_amount_label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            AmountInput(
              initialPiastres: _amountPiastres,
              onAmountChanged: (p) => setState(() => _amountPiastres = p),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Due date ──────────────────────────────────────────────
            Text(
              context.l10n.bill_due_date_label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            AppDatePicker(
              selectedDate: _dueDate,
              onDateChanged: (d) => setState(() => _dueDate = d),
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            ),
            const SizedBox(height: AppSizes.xl),

            // ── Save button ───────────────────────────────────────────
            AppButton(
              label: isEdit
                  ? context.l10n.common_save_changes
                  : context.l10n.bills_add,
              onPressed: canSave && !_loading ? _save : null,
              isLoading: _loading,
              icon: AppIcons.check,
            ),
          ],
        ),
      ),
    );
  }
}
