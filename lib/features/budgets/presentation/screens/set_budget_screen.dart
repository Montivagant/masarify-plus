import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/extensions/month_name_extension.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/budget_entity.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../shared/providers/background_ai_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/subscription_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../../../../shared/widgets/sheets/drag_handle.dart';

class SetBudgetScreen extends ConsumerStatefulWidget {
  const SetBudgetScreen({
    super.key,
    this.editId,
    this.initialYear,
    this.initialMonth,
    this.isSheet = false,
  });

  final int? editId;
  final int? initialYear;
  final int? initialMonth;
  final bool isSheet;

  /// Show the set-budget form as a modal bottom sheet (add mode).
  static Future<void> show(
    BuildContext context, {
    int? initialYear,
    int? initialMonth,
  }) {
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
        initialChildSize: 0.75,
        minChildSize: AppSizes.sheetMinSize,
        maxChildSize: AppSizes.sheetMaxSize,
        expand: false,
        builder: (_, __) => SetBudgetScreen(
          isSheet: true,
          initialYear: initialYear,
          initialMonth: initialMonth,
        ),
      ),
    );
  }

  /// Show the edit-budget form as a modal bottom sheet.
  static Future<void> showEdit(
    BuildContext context,
    int editId, {
    int? initialYear,
    int? initialMonth,
  }) {
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
        initialChildSize: 0.75,
        minChildSize: AppSizes.sheetMinSize,
        maxChildSize: AppSizes.sheetMaxSize,
        expand: false,
        builder: (_, __) => SetBudgetScreen(
          editId: editId,
          isSheet: true,
          initialYear: initialYear,
          initialMonth: initialMonth,
        ),
      ),
    );
  }

  @override
  ConsumerState<SetBudgetScreen> createState() => _SetBudgetScreenState();
}

class _SetBudgetScreenState extends ConsumerState<SetBudgetScreen> {
  int? _categoryId;
  int _limitPiastres = 0;
  late int _year;
  late int _month;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _year = widget.initialYear ?? now.year;
    _month = widget.initialMonth ?? now.month;
    if (widget.editId != null) _loadBudget();
  }

  Future<void> _loadBudget() async {
    final budgets =
        await ref.read(budgetRepositoryProvider).getByMonth(_year, _month);
    final budget = budgets.where((b) => b.id == widget.editId).firstOrNull;
    if (!mounted || budget == null) return;
    setState(() {
      _categoryId = budget.categoryId;
      _limitPiastres = budget.limitAmount;
    });
  }

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

  Future<void> _save() async {
    if (_categoryId == null || _limitPiastres <= 0) return;

    // Free tier: max 2 budgets per month.
    if (widget.editId == null) {
      final hasPro = ref.read(hasProAccessProvider);
      if (!hasPro) {
        final existing =
            await ref.read(budgetRepositoryProvider).getByMonth(_year, _month);
        if (existing.length >= 2) {
          if (!mounted) return;
          context.push(AppRoutes.paywall);
          return;
        }
      }
    }

    setState(() => _loading = true);
    try {
      final repo = ref.read(budgetRepositoryProvider);
      if (widget.editId != null) {
        final budgets = await repo.getByMonth(_year, _month);
        final existing =
            budgets.where((b) => b.id == widget.editId).firstOrNull;
        if (existing != null) {
          await repo.update(
            BudgetEntity(
              id: existing.id,
              categoryId: existing.categoryId,
              month: existing.month,
              year: existing.year,
              limitAmount: _limitPiastres,
              rollover: false,
              rolloverAmount: 0,
            ),
          );
        }
      } else {
        // C4 fix: check for existing budget on same category+month → upsert
        final existing = await repo.getByCategoryAndMonth(
          _categoryId!,
          _year,
          _month,
        );
        if (existing != null) {
          await repo.update(
            BudgetEntity(
              id: existing.id,
              categoryId: existing.categoryId,
              month: existing.month,
              year: existing.year,
              limitAmount: _limitPiastres,
              rollover: false,
              rolloverAmount: 0,
            ),
          );
        } else {
          await repo.create(
            categoryId: _categoryId!,
            month: _month,
            year: _year,
            limitAmount: _limitPiastres,
          );
        }
      }
      HapticFeedback.heavyImpact();
      if (!mounted) return;
      // M5 fix: show appropriate toast for update vs create
      // (existing != null means we upserted an existing budget)
      SnackHelper.showSuccess(
        context,
        widget.editId != null
            ? context.l10n.common_save_changes
            : context.l10n.budget_set,
      );
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
    if (widget.isSheet) return _buildSheetBody(context);

    final isEdit = widget.editId != null;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppAppBar(
        title:
            isEdit ? context.l10n.budget_edit_title : context.l10n.budget_set,
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
          isEdit ? context.l10n.budget_edit_title : context.l10n.budget_set,
          style: context.textStyles.headlineMedium,
        ),
        const SizedBox(height: AppSizes.xs),
        // Month context badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.sm,
            vertical: AppSizes.xxs,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.calendar,
                size: AppSizes.iconXxs,
                color: cs.outline,
              ),
              const SizedBox(width: AppSizes.xs),
              Text(
                '${context.l10n.monthName(_month)} $_year',
                style: context.textStyles.labelSmall?.copyWith(
                  color: cs.outline,
                ),
              ),
            ],
          ),
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
    final categories = ref.watch(expenseCategoriesProvider).valueOrNull ?? [];
    final selectedCat =
        categories.where((c) => c.id == _categoryId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Budget limit FIRST (hero) ───────────────────────────
        Center(
          child: Text(
            context.l10n.budget_limit,
            style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        AmountInput(
          initialPiastres: _limitPiastres,
          onAmountChanged: (p) => setState(() => _limitPiastres = p),
          autofocus: false,
          compact: true,
        ),
        const SizedBox(height: AppSizes.lg),

        // ── Category picker (add mode only) ─────────────────────
        if (!isEdit) ...[
          Text(
            context.l10n.transaction_category,
            style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: AppSizes.sm),
          // AI suggestion chips
          if (_categoryId == null)
            Builder(
              builder: (context) {
                final suggestions = ref.watch(budgetSuggestionsProvider);
                if (suggestions.isEmpty) return const SizedBox.shrink();
                final catMap = {for (final c in categories) c.id: c};
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.sm),
                  child: Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.xs,
                    children: suggestions.take(2).map((s) {
                      final cat = catMap[s.categoryId];
                      if (cat == null) return const SizedBox.shrink();
                      return ActionChip(
                        avatar: Icon(
                          CategoryIconMapper.fromName(cat.iconName),
                          size: AppSizes.iconSm,
                        ),
                        label: Text(
                          '${cat.displayName(context.languageCode)}'
                          ' (~${MoneyFormatter.format(s.monthlyAvg)}/mo)',
                        ),
                        onPressed: () =>
                            setState(() => _categoryId = s.categoryId),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          GestureDetector(
            onTap: () => _showCategoryPicker(categories),
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
                        ? CategoryIconMapper.fromName(selectedCat.iconName)
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
                          : context.textStyles.bodyLarge
                              ?.copyWith(color: cs.outline),
                    ),
                  ),
                  const Icon(AppIcons.expandMore, size: AppSizes.iconXs),
                ],
              ),
            ),
          ),
        ],

        // ── Month chip (edit mode shows it in form) ─────────────
        if (isEdit) ...[
          const SizedBox(height: AppSizes.lg),
          Row(
            children: [
              const Icon(AppIcons.calendar, size: AppSizes.iconSm),
              const SizedBox(width: AppSizes.sm),
              Text(
                '${context.l10n.monthName(_month)} $_year',
                style: context.textStyles.bodyLarge,
              ),
            ],
          ),
        ],

        const SizedBox(height: AppSizes.lg),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context, {required bool isEdit}) {
    final canSave = _categoryId != null && _limitPiastres > 0;
    return SafeArea(
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
              : context.l10n.budget_set,
          onPressed: canSave && !_loading ? _save : null,
          isLoading: _loading,
          icon: AppIcons.check,
        ),
      ),
    );
  }
}
