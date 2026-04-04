import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../domain/entities/savings_goal_entity.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/subscription_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class AddGoalScreen extends ConsumerStatefulWidget {
  const AddGoalScreen({super.key, this.editId, this.isSheet = false});

  final int? editId;
  final bool isSheet;

  /// Show the add-goal form as a modal bottom sheet.
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
        builder: (_, __) => const AddGoalScreen(isSheet: true),
      ),
    );
  }

  /// Show the edit-goal form as a modal bottom sheet.
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
        builder: (_, __) => AddGoalScreen(editId: editId, isSheet: true),
      ),
    );
  }

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

  static const _iconNames = [
    'goals',
    'travel',
    'housing',
    'education',
    'health',
    'shopping',
    'business',
    'investment',
    'gifts',
    'wallet',
    'entertainment',
    'salary',
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
    // Validate target on both create and edit — target must be positive.
    if (_targetPiastres <= 0) {
      setState(() => _nameError = null);
      SnackHelper.showError(context, context.l10n.goal_target_required);
      return;
    }

    // Free tier: max 1 active goal.
    if (widget.editId == null) {
      final hasPro = ref.read(hasProAccessProvider);
      if (!hasPro) {
        final goals = ref.read(activeGoalsProvider).valueOrNull;
        if (goals != null && goals.isNotEmpty) {
          context.push(AppRoutes.paywall);
          return;
        }
      }
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
              targetAmount: _targetPiastres,
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
    if (widget.isSheet) return _buildSheetBody(context);

    final isEdit = widget.editId != null;
    return Scaffold(
      resizeToAvoidBottomInset: true,
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
        child: _buildFormFields(context, isEdit: isEdit),
      ),
      bottomNavigationBar: _buildBottomButton(context, isEdit: isEdit),
    );
  }

  /// Bottom-sheet body — target amount hero first, airy layout.
  Widget _buildSheetBody(BuildContext context) {
    final cs = context.colors;
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
          widget.editId != null
              ? context.l10n.goal_edit_title
              : context.l10n.goal_add_title,
          style: context.textStyles.headlineMedium,
        ),
        const SizedBox(height: AppSizes.lg),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding,
            ),
            child: _buildFormFields(
              context,
              isEdit: widget.editId != null,
            ),
          ),
        ),
        _buildBottomButton(context, isEdit: widget.editId != null),
      ],
    );
  }

  /// Shared form fields — reordered for add mode (target first).
  Widget _buildFormFields(BuildContext context, {required bool isEdit}) {
    final cs = context.colors;
    final selectedColor = ColorUtils.fromHex(_colorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Target amount FIRST (hero in add mode) ──────────────
        if (!isEdit) ...[
          Center(
            child: Text(
              context.l10n.goal_target,
              style: context.textStyles.labelLarge?.copyWith(
                color: cs.outline,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          AmountInput(
            initialPiastres: _targetPiastres,
            onAmountChanged: (p) => setState(() => _targetPiastres = p),
            autofocus: false,
            compact: true,
          ),
          const SizedBox(height: AppSizes.lg),
        ],

        // ── Goal name ───────────────────────────────────────────
        AppTextField(
          label: context.l10n.goal_name_label,
          hint: context.l10n.goal_name_hint,
          controller: _nameController,
          errorText: _nameError,
          prefixIcon: const Icon(AppIcons.goals),
        ),
        const SizedBox(height: AppSizes.lg),

        // ── Target amount (edit mode — below name) ──────────────
        if (isEdit) ...[
          Text(
            context.l10n.goal_target,
            style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: AppSizes.sm),
          AmountInput(
            initialPiastres: _targetPiastres,
            onAmountChanged: (p) => setState(() => _targetPiastres = p),
            autofocus: false,
          ),
          const SizedBox(height: AppSizes.lg),
        ],

        // ── Target date (compact, one line) ─────────────────────
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
                      ? DateFormat.yMd(context.languageCode).format(_deadline!)
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

        // ── Keywords (secondary) ────────────────────────────────
        Text(
          context.l10n.goal_keywords,
          style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
        ),
        const SizedBox(height: AppSizes.sm),
        if (_keywords.isNotEmpty) ...[
          Wrap(
            spacing: AppSizes.sm,
            runSpacing: AppSizes.xs,
            children: _keywords
                .map(
                  (kw) => Chip(
                    label: Text(kw),
                    deleteIcon: const Icon(
                      AppIcons.close,
                      size: AppSizes.iconXxs2,
                    ),
                    onDeleted: () => setState(
                      () =>
                          _keywords = _keywords.where((k) => k != kw).toList(),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSizes.sm),
        ],
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

        // ── Color picker ────────────────────────────────────────
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

        // ── Icon picker ─────────────────────────────────────────
        Text(
          context.l10n.goal_icon_label,
          style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
        ),
        const SizedBox(height: AppSizes.sm),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _iconNames.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: AppSizes.sm,
            crossAxisSpacing: AppSizes.sm,
          ),
          itemBuilder: (_, i) {
            final iconName = _iconNames[i];
            final isSelected = iconName == _iconName;
            return Semantics(
              label: '${context.l10n.category_icon}: $iconName',
              button: true,
              selected: isSelected,
              child: GestureDetector(
                onTap: () => setState(() => _iconName = iconName),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedColor.withValues(
                            alpha: AppSizes.opacityLight,
                          )
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(
                      AppSizes.borderRadiusSm,
                    ),
                    border: isSelected
                        ? Border.all(
                            color: selectedColor,
                            width: AppSizes.borderWidthFocus,
                          )
                        : null,
                  ),
                  child: Icon(
                    CategoryIconMapper.fromName(iconName),
                    color: isSelected ? selectedColor : cs.onSurfaceVariant,
                    size: AppSizes.iconSm,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSizes.lg),
      ],
    );
  }

  Widget _buildBottomButton(BuildContext context, {required bool isEdit}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenHPadding,
          AppSizes.sm,
          AppSizes.screenHPadding,
          AppSizes.md,
        ),
        child: AppButton(
          label:
              isEdit ? context.l10n.common_save_changes : context.l10n.goal_add,
          onPressed: _loading ? null : _save,
          isLoading: _loading,
          icon: AppIcons.check,
        ),
      ),
    );
  }
}
