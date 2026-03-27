import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/extensions/month_name_extension.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../domain/entities/budget_entity.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
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
  });

  final int? editId;
  final int? initialYear;
  final int? initialMonth;

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
    final isEdit = widget.editId != null;
    final cs = context.colors;
    final categories = ref.watch(expenseCategoriesProvider).valueOrNull ?? [];
    final selectedCat =
        categories.where((c) => c.id == _categoryId).firstOrNull;
    final canSave = _categoryId != null && _limitPiastres > 0;

    return Scaffold(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month chip
            GlassCard(
              tintColor: cs.surfaceContainerHighest
                  .withValues(alpha: AppSizes.opacityLight4),
              child: Row(
                children: [
                  const Icon(AppIcons.calendar, size: AppSizes.iconSm),
                  const SizedBox(width: AppSizes.sm),
                  Text(
                    '${context.l10n.monthName(_month)} $_year',
                    style: context.textStyles.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.lg),

            // Category picker (add mode only)
            if (!isEdit) ...[
              Text(
                context.l10n.transaction_category,
                style:
                    context.textStyles.labelLarge?.copyWith(color: cs.outline),
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
              const SizedBox(height: AppSizes.lg),
            ],

            // Budget limit
            Text(
              context.l10n.budget_limit,
              style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            AmountInput(
              initialPiastres: _limitPiastres,
              onAmountChanged: (p) => setState(() => _limitPiastres = p),
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
            label: isEdit
                ? context.l10n.common_save_changes
                : context.l10n.budget_set,
            onPressed: canSave && !_loading ? _save : null,
            isLoading: _loading,
            icon: AppIcons.check,
          ),
        ),
      ),
    );
  }
}
