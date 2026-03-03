import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../domain/entities/recurring_rule_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/inputs/app_date_picker.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Add / Edit recurring transaction rule.
class AddRecurringScreen extends ConsumerStatefulWidget {
  const AddRecurringScreen({super.key, this.editId});

  final int? editId;

  @override
  ConsumerState<AddRecurringScreen> createState() => _AddRecurringScreenState();
}

class _AddRecurringScreenState extends ConsumerState<AddRecurringScreen> {
  final _titleController = TextEditingController();
  String _type = 'expense';
  int _amountPiastres = 0;
  int? _categoryId;
  int? _walletId;
  String _frequency = 'monthly';
  DateTime _startDate = DateTime.now();
  bool _loading = false;

  static const _frequencies = [
    'daily',
    'weekly',
    'biweekly',
    'monthly',
    'quarterly',
    'yearly',
  ];

  String _frequencyLabel(BuildContext context, String freq) => switch (freq) {
        'daily' => context.l10n.recurring_frequency_daily,
        'weekly' => context.l10n.recurring_frequency_weekly,
        'biweekly' => context.l10n.recurring_frequency_biweekly,
        'monthly' => context.l10n.recurring_frequency_monthly,
        'quarterly' => context.l10n.recurring_frequency_quarterly,
        'yearly' => context.l10n.recurring_frequency_yearly,
        _ => freq,
      };

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) {
      _loadRule();
    } else {
      _initWallet();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _initWallet() async {
    final wallets = await ref.read(walletRepositoryProvider).getAll();
    if (!mounted || wallets.isEmpty) return;
    setState(() => _walletId = wallets.first.id);
  }

  Future<void> _loadRule() async {
    final rule =
        await ref.read(recurringRuleRepositoryProvider).getById(widget.editId!);
    if (!mounted || rule == null) return;
    setState(() {
      _titleController.text = rule.title;
      _type = rule.type;
      _amountPiastres = rule.amount;
      _categoryId = rule.categoryId;
      _walletId = rule.walletId;
      _frequency = rule.frequency;
      _startDate = rule.startDate;
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
                AppSizes.screenHPadding,
                0,
                AppSizes.screenHPadding,
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
                  AppSizes.screenHPadding, 0, AppSizes.screenHPadding, AppSizes.sm,
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
    if (_loading) return;
    final title = _titleController.text.trim();
    if (title.isEmpty ||
        _amountPiastres <= 0 ||
        _categoryId == null ||
        _walletId == null) {
      return;
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(recurringRuleRepositoryProvider);
      if (widget.editId != null) {
        final existing = await repo.getById(widget.editId!);
        if (existing != null) {
          await repo.update(
            RecurringRuleEntity(
              id: existing.id,
              title: title,
              type: _type,
              amount: _amountPiastres,
              categoryId: _categoryId!,
              walletId: _walletId!,
              frequency: _frequency,
              startDate: _startDate,
              endDate: existing.endDate,
              nextDueDate: existing.nextDueDate,
              isPaid: existing.isPaid,
              paidAt: existing.paidAt,
              linkedTransactionId: existing.linkedTransactionId,
              isActive: existing.isActive,
              lastProcessedDate: existing.lastProcessedDate,
            ),
          );
        }
      } else {
        await repo.create(
          title: title,
          type: _type,
          amount: _amountPiastres,
          categoryId: _categoryId!,
          walletId: _walletId!,
          frequency: _frequency,
          startDate: _startDate,
          nextDueDate: _startDate,
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
    final allCats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final typeCats =
        allCats.where((c) => c.type == _type || c.type == 'both').toList();
    final selectedCat =
        typeCats.where((c) => c.id == _categoryId).firstOrNull;

    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final selectedWallet =
        wallets.where((w) => w.id == _walletId).firstOrNull;

    final canSave = _titleController.text.trim().isNotEmpty &&
        _amountPiastres > 0 &&
        _categoryId != null &&
        _walletId != null;

    return Scaffold(
      appBar: AppAppBar(
        title: isEdit
            ? context.l10n.recurring_edit
            : context.l10n.recurring_add,
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
            // ── Title ─────────────────────────────────────────────────
            AppTextField(
              label: context.l10n.recurring_title_label,
              hint: context.l10n.recurring_title_hint,
              controller: _titleController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Type toggle ───────────────────────────────────────────
            Text(
              context.l10n.recurring_type_label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'expense',
                  label: Text(context.l10n.transaction_type_expense),
                  icon: const Icon(AppIcons.expense),
                ),
                ButtonSegment(
                  value: 'income',
                  label: Text(context.l10n.transaction_type_income),
                  icon: const Icon(AppIcons.income),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (v) => setState(() {
                _type = v.first;
                _categoryId = null;
              }),
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
              onTap: () => _showCategoryPicker(typeCats),
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
                            : context.textStyles.bodyMedium?.copyWith(color: cs.outline),
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
                            : context.textStyles.bodyMedium?.copyWith(color: cs.outline),
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
              context.l10n.recurring_amount_label,
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

            // ── Frequency ─────────────────────────────────────────────
            Text(
              context.l10n.recurring_frequency_label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: _frequencies
                  .map(
                    (f) => ChoiceChip(
                      label: Text(_frequencyLabel(context, f)),
                      selected: _frequency == f,
                      onSelected: (_) => setState(() => _frequency = f),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Start date ────────────────────────────────────────────
            Text(
              context.l10n.recurring_start_date,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            AppDatePicker(
              selectedDate: _startDate,
              onDateChanged: (d) => setState(() => _startDate = d),
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            ),
            const SizedBox(height: AppSizes.lg),

            const SizedBox(height: AppSizes.xl),

            // ── Save button ───────────────────────────────────────────
            AppButton(
              label: isEdit
                  ? context.l10n.common_save_changes
                  : context.l10n.recurring_add,
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
