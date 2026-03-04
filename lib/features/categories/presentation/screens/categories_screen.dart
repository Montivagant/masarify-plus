import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/confirm_dialog.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.categories_title,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.add),
            tooltip: context.l10n.category_add_title,
            onPressed: () => context.push(AppRoutes.categoryAdd),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) {
          final nonArchived = categories.where((c) => !c.isArchived).toList();
          if (nonArchived.isEmpty) {
            return EmptyState(
              title: context.l10n.categories_empty_title,
              subtitle: context.l10n.categories_empty_sub,
              ctaLabel: context.l10n.category_add,
              onCta: () => context.push(AppRoutes.categoryAdd),
            );
          }
          final expense = nonArchived
              .where((c) => c.type == 'expense' || c.type == 'both')
              .toList();
          final income = nonArchived
              .where((c) => c.type == 'income' || c.type == 'both')
              .toList();
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
            children: [
              if (expense.isNotEmpty) ...[
                _SectionHeader(title: context.l10n.categories_expense, count: expense.length),
                ...expense.map(
                  (c) => _CategoryTile(
                    category: c,
                    onTap: () => context.push(AppRoutes.editCategoryPath(c.id)),
                    onDelete: () => _confirmDelete(context, ref, c),
                  ),
                ),
              ],
              if (income.isNotEmpty) ...[
                _SectionHeader(title: context.l10n.categories_income, count: income.length),
                ...income.map(
                  (c) => _CategoryTile(
                    category: c,
                    onTap: () => context.push(AppRoutes.editCategoryPath(c.id)),
                    onDelete: () => _confirmDelete(context, ref, c),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSizes.screenHPadding),
          child: ShimmerList(),
        ),
        error: (_, __) => EmptyState(title: context.l10n.common_error_title),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    CategoryEntity category,
  ) async {
    if (category.isDefault) {
      await ConfirmDialog.show(
        context,
        title: context.l10n.category_default_title,
        message: context.l10n.category_delete_default_warning,
        confirmLabel: context.l10n.common_ok,
      );
      return;
    }

    final confirmed = await ConfirmDialog.confirmDelete(
      context,
      title: context.l10n.category_delete_title,
      message: context.l10n.category_delete_confirm(category.displayName(context.languageCode)),
    );

    if (confirmed) {
      await ref.read(categoryRepositoryProvider).archive(category.id);
      HapticFeedback.mediumImpact();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSizes.screenHPadding,
        AppSizes.lg,
        AppSizes.screenHPadding,
        AppSizes.xs,
      ),
      child: Row(
        children: [
          Text(
            title,
            style: context.textStyles.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppSizes.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.sm,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
            ),
            child: Text('$count', style: context.textStyles.labelSmall),
          ),
        ],
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.onTap,
    required this.onDelete,
  });
  final CategoryEntity category;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  static String _groupLabel(BuildContext context, String group) => switch (group) {
        'needs' => context.l10n.category_group_needs,
        'wants' => context.l10n.category_group_wants,
        'savings' => context.l10n.category_group_savings,
        _ => group,
      };

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.fromHex(category.colorHex);
    final icon = CategoryIconMapper.fromName(category.iconName);
    return GlassCard(
      showShadow: true,
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: AppSizes.iconMd),
        title: Text(category.displayName(context.languageCode)),
        subtitle: category.groupType != null
            ? Text(_groupLabel(context, category.groupType!))
            : null,
        trailing: category.isDefault
            ? Chip(
                label: Text(context.l10n.category_default_chip),
                labelStyle: context.textStyles.labelSmall,
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              )
            : IconButton(
                icon: Icon(
                  AppIcons.delete,
                  size: AppSizes.iconSm,
                  color: context.colors.error,
                ),
                tooltip: context.l10n.common_delete,
                onPressed: onDelete,
              ),
      ),
    );
  }
}
