import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/recurring_rule_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/recurring_rule_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(recurringRulesProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppAppBar(title: context.l10n.recurring_title),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(context.l10n.common_error_generic),
        ),
        data: (rules) {
          if (rules.isEmpty) {
            return EmptyState(
              title: context.l10n.recurring_title,
              subtitle: context.l10n.recurring_empty_sub,
              ctaLabel: context.l10n.recurring_add,
              onCta: () => context.push(AppRoutes.recurringAdd),
            );
          }

          final active = rules.where((r) => r.isActive).toList();
          final paused = rules.where((r) => !r.isActive).toList();

          return ListView(
            padding: const EdgeInsets.only(
              bottom: AppSizes.bottomScrollPadding,
            ),
            children: [
              if (active.isNotEmpty) ...[
                _SectionHeader(label: context.l10n.recurring_active),
                ...active.map(
                  (r) => _RecurringCard(
                    rule: r,
                    categories: categories,
                  ),
                ),
              ],
              if (paused.isNotEmpty) ...[
                _SectionHeader(label: context.l10n.recurring_paused),
                ...paused.map(
                  (r) => _RecurringCard(
                    rule: r,
                    categories: categories,
                  ),
                ),
              ],
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.recurringAdd),
        child: const Icon(AppIcons.add),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSizes.screenHPadding,
        AppSizes.md,
        AppSizes.screenHPadding,
        AppSizes.xs,
      ),
      child: Text(
        label,
        style: context.textStyles.labelLarge?.copyWith(
              color: context.colors.outline,
            ),
      ),
    );
  }
}

// ── Recurring card ────────────────────────────────────────────────────────

class _RecurringCard extends ConsumerWidget {
  const _RecurringCard({
    required this.rule,
    required this.categories,
  });

  final RecurringRuleEntity rule;
  final List categories;

  String _frequencyLabel(BuildContext context, String freq) => switch (freq) {
        'daily' => context.l10n.recurring_frequency_daily,
        'weekly' => context.l10n.recurring_frequency_weekly,
        'biweekly' => context.l10n.recurring_frequency_biweekly,
        'monthly' => context.l10n.recurring_frequency_monthly,
        'quarterly' => context.l10n.recurring_frequency_quarterly,
        'yearly' => context.l10n.recurring_frequency_yearly,
        _ => freq,
      };

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '${date.year}/$m/$d';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    final cat = categories
        .where((c) => c.id == rule.categoryId)
        .firstOrNull;
    final catIcon = cat != null
        ? CategoryIconMapper.fromName(cat.iconName)
        : AppIcons.category;
    final catColor = cat != null
        ? ColorUtils.fromHex(cat.colorHex)
        : cs.outline;
    final typeColor =
        rule.type == 'income' ? context.appTheme.incomeColor : context.appTheme.expenseColor;
    final prefix = rule.type == 'income' ? '+' : '\u2212';

    return Slidable(
      key: ValueKey(rule.id),
      startActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => context.push(
              AppRoutes.recurringEdit.replaceFirst(':id', '${rule.id}'),
            ),
            backgroundColor: context.appTheme.transferColor,
            foregroundColor: cs.onPrimary,
            icon: AppIcons.edit,
            label: context.l10n.common_edit,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _confirmDelete(context, ref),
            backgroundColor: context.appTheme.expenseColor,
            foregroundColor: cs.onError,
            icon: AppIcons.delete,
            label: context.l10n.common_delete,
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => context.push(
          AppRoutes.recurringEdit.replaceFirst(':id', '${rule.id}'),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.screenHPadding,
            vertical: AppSizes.sm,
          ),
          child: Row(
            children: [
              // Category icon badge
              GlassCard(
                tier: GlassTier.inset,
                padding: EdgeInsets.zero,
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusSm),
                tintColor: catColor.withValues(alpha: AppSizes.opacityLight2),
                child: SizedBox(
                  width: AppSizes.iconContainerLg,
                  height: AppSizes.iconContainerLg,
                  child: Icon(catIcon, size: AppSizes.iconMd, color: ColorUtils.contrastColor(catColor)),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              // Title + frequency + next due
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.title,
                      style: context.textStyles.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    Row(
                      children: [
                        Icon(
                          AppIcons.recurring,
                          size: AppSizes.iconXxs,
                          color: cs.outline,
                        ),
                        const SizedBox(width: AppSizes.xs),
                        Text(
                          _frequencyLabel(context, rule.frequency),
                          style:
                              context.textStyles.bodySmall?.copyWith(
                                    color: cs.outline,
                                  ),
                        ),
                        const SizedBox(width: AppSizes.sm),
                        Text(
                          '${context.l10n.recurring_next_due}: ${_formatDate(rule.nextDueDate)}',
                          style:
                              context.textStyles.bodySmall?.copyWith(
                                    color: cs.outline,
                                  ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              // Amount + active toggle
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$prefix ${MoneyFormatter.formatAmount(rule.amount)}',
                    style: context.textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: typeColor,
                        ),
                  ),
                  const SizedBox(height: AppSizes.xxs),
                  SizedBox(
                    height: AppSizes.iconMd,
                    child: Switch.adaptive(
                      value: rule.isActive,
                      // I20 fix: confirm before toggling
                      onChanged: (active) =>
                          _confirmToggle(context, ref, active),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // I20 fix: show confirmation dialog before toggling
  void _confirmToggle(BuildContext context, WidgetRef ref, bool active) {
    final message = active
        ? context.l10n.recurring_confirm_activate
        : context.l10n.recurring_confirm_pause;
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(rule.title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            child: Text(context.l10n.common_confirm),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) _toggleActive(ref, active);
    });
  }

  void _toggleActive(WidgetRef ref, bool active) {
    HapticFeedback.selectionClick();
    // M15 fix: on resume, if nextDueDate is in the past, advance to today
    var nextDue = rule.nextDueDate;
    if (active && nextDue.isBefore(DateTime.now())) {
      final today = DateTime.now();
      nextDue = DateTime(today.year, today.month, today.day);
    }
    ref.read(recurringRuleRepositoryProvider).update(
          RecurringRuleEntity(
            id: rule.id,
            walletId: rule.walletId,
            categoryId: rule.categoryId,
            amount: rule.amount,
            type: rule.type,
            title: rule.title,
            frequency: rule.frequency,
            startDate: rule.startDate,
            endDate: rule.endDate,
            nextDueDate: nextDue,
            isActive: active,
            // IM-31 fix: clear lastProcessedDate on re-activation so scheduler
            // doesn't skip today's check
            lastProcessedDate: active ? null : rule.lastProcessedDate,
          ),
        );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.recurring_delete_title),
        content: Text(context.l10n.recurring_delete_confirm),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () {
              ref.read(recurringRuleRepositoryProvider).delete(rule.id);
              HapticFeedback.mediumImpact();
              ctx.pop();
            },
            child: Text(
              context.l10n.common_delete,
              style: context.textStyles.bodyMedium?.copyWith(color: context.appTheme.expenseColor),
            ),
          ),
        ],
      ),
    );
  }
}
