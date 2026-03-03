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
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(recurringRulesProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppAppBar(title: context.l10n.recurring_and_bills_title),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Text(context.l10n.common_error_generic),
        ),
        data: (rules) {
          if (rules.isEmpty) {
            return EmptyState(
              title: context.l10n.recurring_and_bills_title,
              subtitle: context.l10n.recurring_empty_sub,
              ctaLabel: context.l10n.recurring_add,
              onCta: () => context.push(AppRoutes.recurringAdd),
            );
          }

          // Section 1: Overdue bills (once-frequency, not paid, past due)
          final overdue = rules.where((r) => r.isOverdue).toList();
          // Section 2: Upcoming bills (once-frequency, not paid, not overdue)
          final upcomingBills = rules
              .where((r) => r.isBill && !r.isPaid && !r.isOverdue)
              .toList();
          // Section 3: Active recurring (non-once frequency, active)
          final activeRecurring = rules
              .where((r) => !r.isBill && r.isActive)
              .toList();
          // Section 4: Paid / Completed (isPaid == true)
          final paid = rules.where((r) => r.isPaid).toList();
          // Also include inactive non-bill items in a sub-group at end
          final inactive = rules
              .where((r) => !r.isBill && !r.isActive)
              .toList();

          return ListView(
            padding: const EdgeInsets.only(
              bottom: AppSizes.bottomScrollPadding,
            ),
            children: [
              if (overdue.isNotEmpty) ...[
                _SectionHeader(
                  label: context.l10n.recurring_overdue,
                  color: context.appTheme.expenseColor,
                ),
                ...overdue.map(
                  (r) => _RecurringCard(
                    rule: r,
                    categories: categories,
                  ),
                ),
              ],
              if (upcomingBills.isNotEmpty) ...[
                _SectionHeader(label: context.l10n.recurring_upcoming_bills),
                ...upcomingBills.map(
                  (r) => _RecurringCard(
                    rule: r,
                    categories: categories,
                  ),
                ),
              ],
              if (activeRecurring.isNotEmpty) ...[
                _SectionHeader(label: context.l10n.recurring_active),
                ...activeRecurring.map(
                  (r) => _RecurringCard(
                    rule: r,
                    categories: categories,
                  ),
                ),
              ],
              if (paid.isNotEmpty) ...[
                _SectionHeader(
                  label: context.l10n.recurring_paid,
                  color: context.colors.outline,
                ),
                ...paid.map(
                  (r) => _RecurringCard(
                    rule: r,
                    categories: categories,
                  ),
                ),
              ],
              if (inactive.isNotEmpty) ...[
                _SectionHeader(
                  label: context.l10n.recurring_paused,
                  color: context.colors.outline,
                ),
                ...inactive.map(
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
  const _SectionHeader({required this.label, this.color});

  final String label;
  final Color? color;

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
              color: color ?? context.colors.outline,
              fontWeight: color != null ? FontWeight.w700 : null,
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
        'once' => context.l10n.recurring_frequency_once,
        'daily' => context.l10n.recurring_frequency_daily,
        'weekly' => context.l10n.recurring_frequency_weekly,
        'monthly' => context.l10n.recurring_frequency_monthly,
        'yearly' => context.l10n.recurring_frequency_yearly,
        'custom' => context.l10n.recurring_frequency_custom,
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
    final isBill = rule.isBill;
    final isOverdue = rule.isOverdue;

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
              // Category icon badge — overdue gets red tint
              GlassCard(
                tier: GlassTier.inset,
                padding: EdgeInsets.zero,
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusSm),
                tintColor: isOverdue
                    ? context.appTheme.expenseColor.withValues(alpha: AppSizes.opacityLight2)
                    : catColor.withValues(alpha: AppSizes.opacityLight2),
                child: SizedBox(
                  width: AppSizes.iconContainerLg,
                  height: AppSizes.iconContainerLg,
                  child: Icon(
                    isBill ? AppIcons.bill : catIcon,
                    size: AppSizes.iconMd,
                    color: isOverdue
                        ? context.appTheme.expenseColor
                        : ColorUtils.contrastColor(catColor),
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.md),
              // Title + subtitle row
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rule.title,
                      style: context.textStyles.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: rule.isPaid ? TextDecoration.lineThrough : null,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.xxs),
                    if (isBill) _buildBillSubtitle(context) else _buildRecurringSubtitle(context),
                  ],
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              // Amount + action
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$prefix ${MoneyFormatter.formatAmount(rule.amount)}',
                    style: context.textStyles.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: rule.isPaid
                              ? cs.outline
                              : typeColor,
                        ),
                  ),
                  const SizedBox(height: AppSizes.xxs),
                  if (isBill && !rule.isPaid)
                    _MarkPaidButton(rule: rule)
                  else if (!isBill)
                    SizedBox(
                      height: AppSizes.iconMd,
                      child: Switch.adaptive(
                        value: rule.isActive,
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

  /// Subtitle for bill items: due date, with overdue styling.
  Widget _buildBillSubtitle(BuildContext context) {
    final cs = context.colors;
    final isOverdue = rule.isOverdue;
    final dueDateColor = isOverdue ? context.appTheme.expenseColor : cs.outline;

    return Row(
      children: [
        Icon(
          AppIcons.calendar,
          size: AppSizes.iconXxs,
          color: dueDateColor,
        ),
        const SizedBox(width: AppSizes.xs),
        Text(
          '${context.l10n.recurring_due_date_label}: ${_formatDate(rule.nextDueDate)}',
          style: context.textStyles.bodySmall?.copyWith(
                color: dueDateColor,
                fontWeight: isOverdue ? FontWeight.w600 : null,
              ),
        ),
        if (isOverdue) ...[
          const SizedBox(width: AppSizes.sm),
          Icon(
            AppIcons.warning,
            size: AppSizes.iconXxs,
            color: context.appTheme.expenseColor,
          ),
          const SizedBox(width: AppSizes.xxs),
          Text(
            context.l10n.recurring_overdue,
            style: context.textStyles.bodySmall?.copyWith(
                  color: context.appTheme.expenseColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ],
    );
  }

  /// Subtitle for recurring items: frequency badge + next due date.
  Widget _buildRecurringSubtitle(BuildContext context) {
    final cs = context.colors;
    return Row(
      children: [
        Icon(
          AppIcons.recurring,
          size: AppSizes.iconXxs,
          color: cs.outline,
        ),
        const SizedBox(width: AppSizes.xs),
        Text(
          _frequencyLabel(context, rule.frequency),
          style: context.textStyles.bodySmall?.copyWith(
                color: cs.outline,
              ),
        ),
        const SizedBox(width: AppSizes.sm),
        Text(
          '${context.l10n.recurring_next_due}: ${_formatDate(rule.nextDueDate)}',
          style: context.textStyles.bodySmall?.copyWith(
                color: cs.outline,
              ),
        ),
      ],
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
            isPaid: rule.isPaid,
            paidAt: rule.paidAt,
            linkedTransactionId: rule.linkedTransactionId,
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

// ── Mark Paid button ──────────────────────────────────────────────────────

class _MarkPaidButton extends ConsumerWidget {
  const _MarkPaidButton({required this.rule});

  final RecurringRuleEntity rule;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: AppSizes.iconContainerSm,
      child: FilledButton.tonal(
        onPressed: () => _markPaid(context, ref),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
          visualDensity: VisualDensity.compact,
        ),
        child: Text(
          context.l10n.recurring_mark_paid,
          style: context.textStyles.labelSmall,
        ),
      ),
    );
  }

  void _markPaid(BuildContext context, WidgetRef ref) {
    HapticFeedback.mediumImpact();
    ref
        .read(recurringRuleRepositoryProvider)
        .markPaid(rule.id, DateTime.now());
    ref.invalidate(recurringRulesProvider);
    SnackHelper.showSuccess(
      context,
      context.l10n.recurring_bill_paid_success,
    );
  }
}
