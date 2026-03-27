import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../domain/entities/savings_goal_entity.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class AddGoalScreen extends ConsumerStatefulWidget {
  const AddGoalScreen({super.key, this.editId});

  final int? editId;

  @override
  ConsumerState<AddGoalScreen> createState() => _AddGoalScreenState();
}

class _AddGoalScreenState extends ConsumerState<AddGoalScreen> {
  final _nameController = TextEditingController();
  final _keywordController = TextEditingController();
  String _iconName = 'goals';
  String _colorHex = '#1A6B5E';
  int _targetPiastres = 0;
  DateTime? _deadline;
  List<String> _keywords = [];
  String? _nameError;
  bool _loading = false;

  static const _icons = [
    (name: 'goals', labelAr: 'أهداف'),
    (name: 'travel', labelAr: 'سفر'),
    (name: 'housing', labelAr: 'سكن'),
    (name: 'education', labelAr: 'تعليم'),
    (name: 'health', labelAr: 'صحة'),
    (name: 'shopping', labelAr: 'تسوق'),
    (name: 'business', labelAr: 'أعمال'),
    (name: 'investment', labelAr: 'استثمار'),
    (name: 'gifts', labelAr: 'هدايا'),
    (name: 'wallet', labelAr: 'محفظة'),
    (name: 'entertainment', labelAr: 'ترفيه'),
    (name: 'salary', labelAr: 'راتب'),
  ];

  static const _colorOptions = AppColors.pickerOptions;

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) _loadGoal();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _loadGoal() async {
    final goal = await ref.read(goalRepositoryProvider).getById(widget.editId!);
    if (!mounted || goal == null) return;
    setState(() {
      _nameController.text = goal.name;
      _iconName = goal.iconName;
      _colorHex = goal.colorHex;
      _targetPiastres = goal.targetAmount;
      _deadline = goal.deadline;
      // R5-C4 fix: guard against corrupted JSON
      try {
        _keywords = (jsonDecode(goal.keywords) as List).cast<String>();
      } catch (_) {
        _keywords = [];
      }
    });
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  void _addKeyword() {
    final kw = _keywordController.text.trim();
    if (kw.isEmpty || _keywords.contains(kw)) return;
    // I18 fix: limit keyword length to 50 characters
    if (kw.length > 50) return;
    setState(() {
      _keywords = [..._keywords, kw];
      _keywordController.clear();
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
    // R5-I1 fix: validate target on both create and edit
    if (_targetPiastres <= 0) {
      if (widget.editId == null) {
        // Create mode: require positive target
        setState(() => _nameError = null);
        SnackHelper.showError(context, context.l10n.goal_target_required);
        return;
      }
      // Edit mode: target stays as-is (line 140 handles this)
    }
    setState(() {
      _nameError = null;
      _loading = true;
    });
    try {
      final repo = ref.read(goalRepositoryProvider);
      if (widget.editId != null) {
        final existing = await repo.getById(widget.editId!);
        if (existing != null) {
          await repo.updateGoal(
            SavingsGoalEntity(
              id: existing.id,
              name: name,
              iconName: _iconName,
              colorHex: _colorHex,
              targetAmount:
                  _targetPiastres > 0 ? _targetPiastres : existing.targetAmount,
              currentAmount: existing.currentAmount,
              currencyCode: existing.currencyCode,
              deadline: _deadline,
              isCompleted: existing.isCompleted,
              keywords: jsonEncode(_keywords),
              walletId: existing.walletId,
              createdAt: existing.createdAt,
            ),
          );
        }
      } else {
        await repo.createGoal(
          name: name,
          iconName: _iconName,
          colorHex: _colorHex,
          targetAmount: _targetPiastres,
          deadline: _deadline,
          keywords: jsonEncode(_keywords),
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editId != null;
    final cs = context.colors;
    final selectedColor = ColorUtils.fromHex(_colorHex);

    return Scaffold(
      appBar: AppAppBar(
        title:
            isEdit ? context.l10n.goal_edit_title : context.l10n.goal_add_title,
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
              label: context.l10n.goal_name_label,
              hint: context.l10n.goal_name_hint,
              controller: _nameController,
              errorText: _nameError,
              prefixIcon: const Icon(AppIcons.goals),
            ),
            const SizedBox(height: AppSizes.lg),

            // Target amount
            Text(
              context.l10n.goal_target,
              style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            AmountInput(
              initialPiastres: _targetPiastres,
              onAmountChanged: (p) => setState(() => _targetPiastres = p),
            ),
            const SizedBox(height: AppSizes.lg),

            // Deadline
            Text(
              context.l10n.goal_deadline,
              style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDeadline,
                    icon: const Icon(AppIcons.calendar, size: AppSizes.iconSm),
                    label: Text(
                      _deadline != null
                          ? DateFormat.yMd(context.languageCode)
                              .format(_deadline!)
                          : context.l10n.goal_pick_date,
                    ),
                  ),
                ),
                if (_deadline != null) ...[
                  const SizedBox(width: AppSizes.sm),
                  IconButton(
                    icon: const Icon(AppIcons.close),
                    tooltip: context.l10n.goal_remove_date,
                    onPressed: () => setState(() => _deadline = null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // Keywords
            Text(
              context.l10n.goal_keywords,
              style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.xs,
              children: [
                ..._keywords.map(
                  (kw) => Chip(
                    label: Text(kw),
                    deleteIcon:
                        const Icon(AppIcons.close, size: AppSizes.iconXxs2),
                    onDeleted: () => setState(
                      () =>
                          _keywords = _keywords.where((k) => k != kw).toList(),
                    ),
                  ),
                ),
              ],
            ),
            if (_keywords.isNotEmpty) const SizedBox(height: AppSizes.sm),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: context.l10n.goal_keywords,
                    hint: context.l10n.goal_keyword_hint,
                    controller: _keywordController,
                    onSubmitted: (_) => _addKeyword(),
                  ),
                ),
                const SizedBox(width: AppSizes.sm),
                IconButton.filled(
                  icon: const Icon(AppIcons.add, size: AppSizes.iconSm),
                  onPressed: _addKeyword,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.lg),

            // Color picker
            Text(
              context.l10n.goal_color_label,
              style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: _colorOptions.map((hex) {
                final color = ColorUtils.fromHex(hex);
                final isSelected = hex == _colorHex;
                return Semantics(
                  label: context.l10n.goal_color_label,
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
            const SizedBox(height: AppSizes.lg),

            // Icon picker
            Text(
              context.l10n.goal_icon_label,
              style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _icons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: AppSizes.sm,
                crossAxisSpacing: AppSizes.sm,
              ),
              itemBuilder: (_, i) {
                final item = _icons[i];
                final isSelected = item.name == _iconName;
                return Semantics(
                  label: 'Icon: ${item.name}',
                  button: true,
                  selected: isSelected,
                  child: GestureDetector(
                    onTap: () => setState(() => _iconName = item.name),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColor.withValues(
                                alpha: AppSizes.opacityLight,
                              )
                            : cs.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusSm),
                        border: isSelected
                            ? Border.all(
                                color: selectedColor,
                                width: AppSizes.borderWidthFocus,
                              )
                            : null,
                      ),
                      child: Icon(
                        CategoryIconMapper.fromName(item.name),
                        color: isSelected ? selectedColor : cs.onSurfaceVariant,
                        size: AppSizes.iconSm,
                      ),
                    ),
                  ),
                );
              },
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
                : context.l10n.goal_add,
            onPressed: _loading ? null : _save,
            isLoading: _loading,
            icon: AppIcons.check,
          ),
        ),
      ),
    );
  }
}
