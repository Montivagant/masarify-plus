import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/extensions/frequency_label_extension.dart';
import '../../../../core/services/ai/recurring_pattern_detector.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../domain/entities/recurring_rule_entity.dart';
import '../../../../shared/providers/background_ai_provider.dart';
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
  const AddRecurringScreen({
    super.key,
    this.editId,
    this.detectedPattern,
    this.isSheet = false,
  });

  final int? editId;
  final DetectedPattern? detectedPattern;
  final bool isSheet;

  /// Show the add-recurring form as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.borderRadiusLg),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: AppSizes.sheetMaxSize,
        minChildSize: AppSizes.sheetMinSize,
        maxChildSize: AppSizes.sheetMaxSize,
        expand: false,
        builder: (_, __) => const AddRecurringScreen(isSheet: true),
      ),
    );
  }

  /// Show the edit-recurring form as a modal bottom sheet.
  static Future<void> showEdit(BuildContext context, int editId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.borderRadiusLg),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: AppSizes.sheetMaxSize,
        minChildSize: AppSizes.sheetMinSize,
        maxChildSize: AppSizes.sheetMaxSize,
        expand: false,
        builder: (_, __) => AddRecurringScreen(editId: editId, isSheet: true),
      ),
    );
  }

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

  /// Suggested category from title text via categorization learning.
  CategoryEntity? _suggestedCategory;
  Timer? _debounceTimer;

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
    } else if (widget.detectedPattern != null) {
      _prefillFromPattern(widget.detectedPattern!);
    } else {
      _initWallet();
    }
    _titleController.addListener(_onTitleChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    super.dispose();
  }

  void _onTitleChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(AppDurations.categorySuggestionDebounce, () async {
      final text = _titleController.text.trim();
      if (text.length < 3 || _categoryId != null) return;
      final service = ref.read(categorizationLearningServiceProvider);
      final suggestedId = await service.suggestCategory(text);
      if (!mounted || suggestedId == null || _categoryId != null) return;
      final cats = ref.read(categoriesProvider).valueOrNull ?? [];
      final cat = cats.where((c) => c.id == suggestedId).firstOrNull;
      if (cat != null && (cat.type == _type || cat.type == 'both')) {
        setState(() => _suggestedCategory = cat);
      }
    });
  }

  Future<void> _initWallet() async {
    final wallets = await ref.read(walletRepositoryProvider).getAll();
    if (!mounted || wallets.isEmpty) return;
    setState(() => _walletId = wallets.first.id);
  }

  Future<void> _prefillFromPattern(DetectedPattern pattern) async {
    _titleController.text = pattern.title;
    _amountPiastres = pattern.amount;
    _frequency = pattern.frequency;
    _type = pattern.type;
    _startDate = pattern.nextExpectedDate;

    // Validate category still exists before setting it.
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    final cat = cats.where((c) => c.id == pattern.categoryId).firstOrNull;
    if (cat != null && (cat.type == pattern.type || cat.type == 'both')) {
      _categoryId = pattern.categoryId;
    }

    // Select default account (non-archived).
    final wallets = await ref.read(walletRepositoryProvider).getAll();
    if (!mounted || wallets.isEmpty) return;
    final active = wallets.where((w) => !w.isArchived).toList();
    if (active.isEmpty) return;
    final defaultWallet = active.firstWhere(
      (w) => w.isDefaultAccount,
      orElse: () => active.first,
    );
    setState(() => _walletId = defaultWallet.id);
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
                          setState(() {
                            _categoryId = c.id;
                            _suggestedCategory = null;
                          });
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
    if (title.isEmpty) {
      SnackHelper.showError(context, context.l10n.recurring_error_title);
      return;
    }
    if (_amountPiastres <= 0) {
      SnackHelper.showError(context, context.l10n.recurring_error_amount);
      return;
    }
    if (_categoryId == null) {
      SnackHelper.showError(context, context.l10n.recurring_error_category);
      return;
    }
    if (_walletId == null) {
      SnackHelper.showError(context, context.l10n.recurring_error_wallet);
      return;
    }

    // For custom frequency, endDate is required.
    if (_isCustom && _endDate == null) {
      SnackHelper.showError(context, context.l10n.recurring_error_end_date);
      return;
    }

    // Guard end date < start date.
    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      SnackHelper.showError(context, context.l10n.recurring_error_date_order);
      return;
    }

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

      final notifService = ref.read(notificationTriggerServiceProvider);

      if (widget.editId != null) {
        final existing = await repo.getById(widget.editId!);
        if (existing != null) {
          final updatedNextDue = _isOnce
              ? effectiveNextDue
              : (_startDate != existing.startDate ||
                      _frequency != existing.frequency
                  ? effectiveStartDate
                  : existing.nextDueDate);
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
              nextDueDate: updatedNextDue,
              isPaid: existing.isPaid,
              paidAt: existing.paidAt,
              linkedTransactionId: existing.linkedTransactionId,
              isActive: existing.isActive,
              lastProcessedDate: existing.lastProcessedDate,
            ),
          );
          // Reschedule bill reminder with updated due date
          await notifService.scheduleBillReminder(
            ruleId: existing.id,
            title: title,
            amount: _amountPiastres,
            dueDate: updatedNextDue,
          );
        }
      } else {
        final newId = await repo.create(
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
        // Schedule bill reminder notification
        await notifService.scheduleBillReminder(
          ruleId: newId,
          title: title,
          amount: _amountPiastres,
          dueDate: effectiveNextDue,
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
    if (widget.isSheet) return _buildSheetBody(context);

    final isEdit = widget.editId != null;
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
        child: _buildFormFields(context, isEdit: isEdit),
      ),
      bottomNavigationBar: _buildBottomButton(context, isEdit: isEdit),
    );
  }

  Widget _buildSheetBody(BuildContext context) {
    final cs = context.colors;
    final isEdit = widget.editId != null;
    return Column(
      children: [
        const SizedBox(height: AppSizes.sm),
        Container(
          width: AppSizes.dragHandleWidth,
          height: AppSizes.dragHandleHeight,
          decoration: BoxDecoration(
            color: cs.outlineVariant,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
          ),
        ),
        const SizedBox(height: AppSizes.md),
        Text(
          isEdit ? context.l10n.recurring_edit : context.l10n.recurring_add,
          style: context.textStyles.headlineMedium,
        ),
        const SizedBox(height: AppSizes.lg),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding,
            ),
            child: _buildFormFields(context, isEdit: isEdit),
          ),
        ),
        _buildBottomButton(context, isEdit: isEdit),
      ],
    );
  }

  Widget _buildFormFields(BuildContext context, {required bool isEdit}) {
    final cs = context.colors;
    final allCats = ref.watch(categoriesProvider).valueOrNull ?? [];
    final typeCats =
        allCats.where((c) => c.type == _type || c.type == 'both').toList();
    final selectedCat = typeCats.where((c) => c.id == _categoryId).firstOrNull;
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final selectedWallet = wallets.where((w) => w.id == _walletId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Amount FIRST (hero) ────────────────────────────────────
        Center(
          child: Text(
            context.l10n.recurring_amount_label,
            style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        AmountInput(
          initialPiastres: _amountPiastres,
          onAmountChanged: (p) => setState(() => _amountPiastres = p),
          autofocus: false,
          compact: true,
        ),
        const SizedBox(height: AppSizes.lg),

        // ── Title ─────────────────────────────────────────────────
        AppTextField(
          label: context.l10n.recurring_title_label,
          hint: context.l10n.recurring_title_hint,
          controller: _titleController,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSizes.md),

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
            _suggestedCategory = null;
          }),
        ),
        const SizedBox(height: AppSizes.lg),

        // ── Category & Wallet (side by side) ──────────────────────
        if (_suggestedCategory != null && _categoryId == null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.sm),
            child: ActionChip(
              avatar: Icon(
                CategoryIconMapper.fromName(_suggestedCategory!.iconName),
                size: AppSizes.iconSm,
              ),
              label: Text(
                _suggestedCategory!.displayName(context.languageCode),
              ),
              onPressed: () {
                setState(() {
                  _categoryId = _suggestedCategory!.id;
                  _suggestedCategory = null;
                });
              },
            ),
          ),
        Row(
          children: [
            // Category
            Expanded(
              child: GestureDetector(
                onTap: () => _showCategoryPicker(typeCats),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
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
                            ? CategoryIconMapper.fromName(selectedCat.iconName)
                            : AppIcons.category,
                        size: AppSizes.iconSm,
                      ),
                      const SizedBox(width: AppSizes.xs),
                      Expanded(
                        child: Text(
                          selectedCat?.displayName(context.languageCode) ??
                              context.l10n.transaction_category,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: selectedCat != null ? null : cs.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(AppIcons.expandMore, size: AppSizes.iconXxs),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            // Wallet
            Expanded(
              child: GestureDetector(
                onTap: _showWalletPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
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
                      const SizedBox(width: AppSizes.xs),
                      Expanded(
                        child: Text(
                          selectedWallet?.name ??
                              context.l10n.transaction_wallet,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: selectedWallet != null ? null : cs.outline,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(AppIcons.expandMore, size: AppSizes.iconXxs),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
                    if (f == 'once') {
                      _endDate = _startDate;
                    } else if (f == 'yearly') {
                      _endDate = DateTime(
                        _startDate.year + 1,
                        _startDate.month,
                        _startDate.day,
                      );
                    } else if (f != 'custom') {
                      _endDate = null;
                    }
                  }),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSizes.lg),

        // ── Dates ─────────────────────────────────────────────────
        ..._buildDatePickers(cs),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context, {required bool isEdit}) {
    final canSave = _titleController.text.trim().isNotEmpty &&
        _amountPiastres > 0 &&
        _categoryId != null &&
        _walletId != null &&
        (!_isCustom || _endDate != null);
    return SafeArea(
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
              : context.l10n.recurring_add,
          onPressed: canSave && !_loading ? _save : null,
          isLoading: _loading,
          icon: AppIcons.check,
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
