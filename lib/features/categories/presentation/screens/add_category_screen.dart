import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class AddCategoryScreen extends ConsumerStatefulWidget {
  const AddCategoryScreen({super.key, this.editId});

  final int? editId;

  @override
  ConsumerState<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends ConsumerState<AddCategoryScreen> {
  final _nameController = TextEditingController();
  String _type = 'expense';
  String _iconName = 'food';
  String _colorHex = AppColors.pickerOptions.first;
  String? _groupType = 'needs';
  String? _nameError;
  bool _loading = false;

  static const _iconNames = [
    'food',
    'transport',
    'housing',
    'utilities',
    'phone',
    'health',
    'groceries',
    'education',
    'shopping',
    'entertainment',
    'clothing',
    'personal_care',
    'gifts',
    'travel',
    'subscriptions',
    'salary',
    'freelance',
    'business',
    'investment',
    'wallet',
    'goals',
  ];

  static const _colorOptions = AppColors.pickerOptions;

  static const _groupValues = ['needs', 'wants', 'savings'];

  @override
  void initState() {
    super.initState();
    if (widget.editId != null) _loadCategory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCategory() async {
    final cat =
        await ref.read(categoryRepositoryProvider).getById(widget.editId!);
    if (!mounted || cat == null) return;
    setState(() {
      _nameController.text = cat.displayName(context.languageCode);
      _type = cat.type;
      _iconName = cat.iconName;
      _colorHex = cat.colorHex;
      _groupType = cat.groupType;
    });
  }

  Future<void> _save() async {
    if (_loading) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = context.l10n.error_name_required);
      return;
    }

    // Check for duplicate category name (same pattern as add_wallet_screen).
    final allCats = ref.read(categoriesProvider).valueOrNull ?? [];
    final isAr = context.languageCode == 'ar';
    final duplicate = allCats.any((c) {
      if (widget.editId != null && c.id == widget.editId) return false;
      final existingName = isAr ? c.nameAr : c.name;
      return existingName.toLowerCase() == name.toLowerCase();
    });
    if (duplicate) {
      setState(() => _nameError = context.l10n.category_name_duplicate);
      return;
    }

    setState(() {
      _nameError = null;
      _loading = true;
    });
    try {
      final repo = ref.read(categoryRepositoryProvider);
      if (widget.editId != null) {
        final existing = await repo.getById(widget.editId!);
        if (existing != null) {
          await repo.update(
            existing.copyWith(
              name: isAr ? existing.name : name,
              nameAr: isAr ? name : existing.nameAr,
              iconName: _iconName,
              colorHex: _colorHex,
              groupType: _type == 'expense' ? _groupType : null,
            ),
          );
        }
      } else {
        await repo.create(
          name: isAr ? '' : name,
          nameAr: isAr ? name : '',
          iconName: _iconName,
          colorHex: _colorHex,
          type: _type,
          groupType: _type == 'expense' ? _groupType : null,
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
      resizeToAvoidBottomInset: true,
      appBar: AppAppBar(
        title: isEdit
            ? context.l10n.category_edit_title
            : context.l10n.category_add_title,
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
            AppTextField(
              label: context.l10n.category_name_label,
              hint: context.l10n.category_name_hint,
              controller: _nameController,
              errorText: _nameError,
              prefixIcon: const Icon(AppIcons.category),
            ),
            const SizedBox(height: AppSizes.lg),

            // Type — add mode only
            if (!isEdit) ...[
              Text(
                context.l10n.category_type,
                style:
                    context.textStyles.labelLarge?.copyWith(color: cs.outline),
              ),
              const SizedBox(height: AppSizes.sm),
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'expense',
                    label: Text(context.l10n.categories_expense),
                    icon: const Icon(AppIcons.expense),
                  ),
                  ButtonSegment(
                    value: 'income',
                    label: Text(context.l10n.categories_income),
                    icon: const Icon(AppIcons.income),
                  ),
                ],
                selected: {_type},
                onSelectionChanged: (s) => setState(() {
                  _type = s.first;
                  _groupType = _type == 'expense' ? 'needs' : null;
                }),
              ),
              const SizedBox(height: AppSizes.lg),
            ],

            // Group type — expense only
            if (_type == 'expense') ...[
              Text(
                context.l10n.transaction_category,
                style:
                    context.textStyles.labelLarge?.copyWith(color: cs.outline),
              ),
              const SizedBox(height: AppSizes.sm),
              Wrap(
                spacing: AppSizes.sm,
                children: _groupValues.map((value) {
                  final isSelected = value == _groupType;
                  final label = switch (value) {
                    'needs' => context.l10n.category_group_needs,
                    'wants' => context.l10n.category_group_wants,
                    'savings' => context.l10n.category_group_savings,
                    _ => value,
                  };
                  return FilterChip(
                    selected: isSelected,
                    label: Text(label),
                    onSelected: (_) => setState(() => _groupType = value),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSizes.lg),
            ],

            // Color picker
            Text(
              context.l10n.category_color,
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
                  label: context.l10n.category_color,
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
              context.l10n.category_icon,
              style: context.textStyles.labelLarge?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: AppSizes.sm),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _iconNames.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: AppSizes.sm,
                crossAxisSpacing: AppSizes.sm,
              ),
              itemBuilder: (_, i) {
                final iconName = _iconNames[i];
                final isSelected = iconName == _iconName;
                return Semantics(
                  label: 'Icon: $iconName',
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
                        CategoryIconMapper.fromName(iconName),
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
                : context.l10n.category_add,
            onPressed: _loading ? null : _save,
            isLoading: _loading,
            icon: AppIcons.check,
          ),
        ),
      ),
    );
  }
}
