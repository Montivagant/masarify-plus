import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/extensions/frequency_label_extension.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../domain/entities/recurring_rule_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/inputs/app_date_picker.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../../../../shared/widgets/sheets/drag_handle.dart';

/// Add / Edit recurring transaction rule or one-time bill.
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
  DateTime? _endDate;
  bool _loading = false;

  static const _frequencies = [
    'once',
    'daily',
    'weekly',
    'monthly',
    'yearly',
    'custom',
  ];

  /// Whether the frequency is 'once' (one-time bill).
  bool get _isOnce => _frequency == 'once';

  /// Whether the frequency is 'custom' (both dates required).
  bool get _isCustom => _frequency == 'custom';

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
    // Validate loaded category still matches the rule's type
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final loadedCat =
        categories.where((c) => c.id == rule.categoryId).firstOrNull;
    final validCategory = loadedCat != null &&
        (loadedCat.type == rule.type || loadedCat.type == 'both');

    setState(() {
      _titleController.text = rule.title;
      _type = rule.type;
      _amountPiastres = rule.amount;
      _categoryId = validCategory ? rule.categoryId : null;
      _walletId = rule.walletId;
      _frequency = rule.frequency;
      _startDate = rule.startDate;
      _endDate = rule.endDate;
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
            const DragHandle(),
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
                        leading: Icon(CategoryIconMapper.fromName(c.iconName)),
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
                  0,
                  AppSizes.screenHPadding,
                  AppSizes.sm,
                ),
                child: Text(
                  context.l10n.transaction_wallet_picker,
                  style: ctx.textStyles.titleMedium,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: wallets
                      .map(
                        (w) => ListTile(
                          leading: const Icon(AppIcons.wallet),
                          title: Text(w.name),
                          trailing: _walletId == w.id
                              ? const Icon(AppIcons.check)
                              : null,
                          onTap: () {
                            setState(() => _walletId = w.id);
                            ctx.pop();
                          },
                        ),
                      )
                      .toList(),
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

    // For custom frequency, endDate is required.
    if (_isCustom && _endDate == null) return;

    // M9 fix: guard end date < start date
    if (_endDate != null && _endDate!.isBefore(_startDate)) return;

    setState(() => _loading = true);
    try {
      final repo = ref.read(recurringRuleRepositoryProvider);

      // Compute effective dates based on frequency.
      final DateTime effectiveStartDate = _startDate;
      final DateTime? effectiveEndDate;
      final DateTime effectiveNextDue;

      if (_isOnce) {
        // One-time: endDate = startDate, nextDueDate = startDate
        effectiveEndDate = effectiveStartDate;
        effectiveNextDue = effectiveStartDate;
      } else {
        effectiveEndDate = _endDate;
        effectiveNextDue = effectiveStartDate;
      }

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
              startDate: effectiveStartDate,
              endDate: effectiveEndDate,
              // C6 fix: reset nextDueDate if start date or frequency changed
              nextDueDate: _isOnce
                  ? effectiveNextDue
                  : (_startDate != existing.startDate ||
                          _frequency != existing.frequency
                      ? effectiveStartDate
                      : existing.nextDueDate),
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
          startDate: effectiveStartDate,
          nextDueDate: effectiveNextDue,
          endDate: effectiveEndDate,
        );
      }

      HapticFeedback.heavyImpact();
      if (!mounted) return;
      context.pop();
    } catch (_) {
      // M1 fix: show error feedback instead of silently stopping spinner
      if (!mounted) return;
      setState(() => _loading = false);
      SnackHelper.showError(context, context.l10n.common_error_generic);
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
    final selectedCat = typeCats.where((c) => c.id == _categoryId).firstOrNull;

    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final selectedWallet = wallets.where((w) => w.id == _walletId).firstOrNull;

    final canSave = _titleController.text.trim().isNotEmpty &&
        _amountPiastres > 0 &&
        _categoryId != null &&
        _walletId != null &&
        (!_isCustom || _endDate != null);

    return Scaffold(
      appBar: AppAppBar(
        title:
            isEdit ? context.l10n.recurring_edit : context.l10n.recurring_add,
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
              style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
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
              style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
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
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
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
                            : context.textStyles.bodyMedium
                                ?.copyWith(color: cs.outline),
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
              style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
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
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
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
                            : context.textStyles.bodyMedium
                                ?.copyWith(color: cs.outline),
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
              style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
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
              style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: _frequencies
                  .map(
                    (f) => ChoiceChip(
                      label: Text(context.l10n.frequencyLabel(f)),
                      selected: _frequency == f,
                      onSelected: (_) => setState(() {
                        _frequency = f;
                        // Reset end date when switching frequency.
                        if (f == 'once') {
                          _endDate = _startDate;
                        } else if (f != 'custom') {
                          _endDate = null;
                        }
                      }),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: AppSizes.lg),

            // ── Date pickers ──────────────────────────────────────────
            ..._buildDatePickers(cs),
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
            label: isEdit
                ? context.l10n.common_save_changes
                : context.l10n.recurring_add,
            onPressed: canSave && !_loading ? _save : null,
            isLoading: _loading,
            icon: AppIcons.check,
          ),
        ),
      ),
    );
  }

  // ── Date Picker Builders ────────────────────────────────────────────────

  List<Widget> _buildDatePickers(ColorScheme cs) {
    if (_isOnce) {
      // One-time: single "Due Date" picker.
      return [
        Text(
          context.l10n.recurring_due_date_label,
          style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
        ),
        const SizedBox(height: AppSizes.sm),
        AppDatePicker(
          selectedDate: _startDate,
          onDateChanged: (d) => setState(() {
            _startDate = d;
            _endDate = d;
          }),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(AppDurations.datePickerMaxOffset),
        ),
        const SizedBox(height: AppSizes.lg),
      ];
    }

    if (_isCustom) {
      // Custom: both start and end date required.
      return [
        Text(
          context.l10n.recurring_start_date,
          style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
        ),
        const SizedBox(height: AppSizes.sm),
        AppDatePicker(
          selectedDate: _startDate,
          onDateChanged: (d) => setState(() => _startDate = d),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(AppDurations.datePickerMaxOffset),
        ),
        const SizedBox(height: AppSizes.lg),
        Text(
          context.l10n.recurring_end_date_required,
          style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
        ),
        const SizedBox(height: AppSizes.sm),
        AppDatePicker(
          selectedDate: _endDate ?? _startDate,
          onDateChanged: (d) => setState(() => _endDate = d),
          firstDate: _startDate,
          lastDate: DateTime.now().add(AppDurations.datePickerMaxOffset),
        ),
        const SizedBox(height: AppSizes.lg),
      ];
    }

    // Standard recurring: start date + optional end date.
    return [
      Text(
        context.l10n.recurring_start_date,
        style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
      ),
      const SizedBox(height: AppSizes.sm),
      AppDatePicker(
        selectedDate: _startDate,
        onDateChanged: (d) => setState(() => _startDate = d),
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(AppDurations.datePickerMaxOffset),
      ),
      const SizedBox(height: AppSizes.lg),
      // Optional end date.
      Row(
        children: [
          Expanded(
            child: Text(
              context.l10n.recurring_end_date,
              style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
            ),
          ),
          if (_endDate != null)
            IconButton(
              icon: const Icon(AppIcons.close, size: AppSizes.iconXs),
              tooltip: context.l10n.common_clear,
              onPressed: () => setState(() => _endDate = null),
            ),
        ],
      ),
      const SizedBox(height: AppSizes.sm),
      if (_endDate != null)
        AppDatePicker(
          selectedDate: _endDate!,
          onDateChanged: (d) => setState(() => _endDate = d),
          firstDate: _startDate,
          lastDate: DateTime.now().add(AppDurations.datePickerMaxOffset),
        )
      else
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: _startDate,
              lastDate: DateTime.now().add(AppDurations.datePickerMaxOffset),
            );
            if (picked != null && mounted) {
              setState(() => _endDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: AppSizes.sm,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: cs.outlineVariant),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  AppIcons.calendar,
                  size: AppSizes.iconSm,
                  color: cs.primary,
                ),
                const SizedBox(width: AppSizes.xs),
                Text(
                  '---',
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: cs.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      const SizedBox(height: AppSizes.lg),
    ];
  }
}
