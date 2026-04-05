import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/brand_registry.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/extensions/frequency_label_extension.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/category_entity.dart';
import '../../../../domain/entities/recurring_rule_entity.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/recurring_rule_provider.dart';
import '../../../../shared/providers/repository_providers.dart';

import '../../../../shared/widgets/cards/brand_logo.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/confirm_dialog.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import 'add_recurring_screen.dart';

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(recurringRulesProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.recurring_and_bills_title,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.add),
            tooltip: context.l10n.recurring_add,
            onPressed: () => AddRecurringScreen.show(context),
          ),
        ],
      ),
      body: rulesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => EmptyState(
          title: context.l10n.common_error_title,
          ctaLabel: context.l10n.common_retry,
          onCta: () => ref.invalidate(recurringRulesProvider),
        ),
        data: (rules) {
          if (rules.isEmpty) {
            return EmptyState(
              title: context.l10n.recurring_and_bills_title,
              subtitle: context.l10n.recurring_empty_sub,
              ctaLabel: context.l10n.recurring_add,
              onCta: () => AddRecurringScreen.show(context),
            );
          }

          // Mutually exclusive sections — each rule belongs to exactly one.
          final overdue = <RecurringRuleEntity>[];
          final upcomingBills = <RecurringRuleEntity>[];
          final activeRecurring = <RecurringRuleEntity>[];
          final paid = <RecurringRuleEntity>[];
          final inactive = <RecurringRuleEntity>[];

          for (final r in rules) {
            if (r.isPaid) {
              paid.add(r);
            } else if (r.isOverdue) {
              overdue.add(r);
            } else if (r.isBill) {
              upcomingBills.add(r);
            } else if (!r.isActive) {
              inactive.add(r);
            } else {
              activeRecurring.add(r);
            }
          }

          // E4: Build children with a running index for stagger animation.
          final reduceMotion = context.reduceMotion;
          var staggerIndex = 0;

          Widget animateCard(RecurringRuleEntity r) {
            final card = _RecurringCard(rule: r, categories: categories);
            if (reduceMotion) return card;
            final idx = staggerIndex++;
            return card
                .animate()
                .fadeIn(duration: AppDurations.listItemEntry)
                .slideY(
                  begin: 0.03,
                  end: 0,
                  duration: AppDurations.listItemEntry,
                  curve: Curves.easeOutCubic,
                )
                .then(delay: AppDurations.staggerDelay * idx);
          }

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
                ...overdue.map(animateCard),
              ],
              if (upcomingBills.isNotEmpty) ...[
                _SectionHeader(label: context.l10n.recurring_upcoming_bills),
                ...upcomingBills.map(animateCard),
              ],
              if (activeRecurring.isNotEmpty) ...[
                _SectionHeader(label: context.l10n.recurring_active),
                ...activeRecurring.map(animateCard),
              ],
              if (paid.isNotEmpty) ...[
                _SectionHeader(
                  label: context.l10n.recurring_paid,
                  color: context.colors.outline,
                ),
                ...paid.map(animateCard),
              ],
              if (inactive.isNotEmpty) ...[
                _SectionHeader(
                  label: context.l10n.recurring_paused,
                  color: context.colors.outline,
                ),
                ...inactive.map(animateCard),
              ],
            ],
          );
        },
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
  final List<CategoryEntity> categories;

  String _formatDate(BuildContext context, DateTime date) {
    return DateFormat.yMd(context.languageCode).format(date);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    final cat = categories.where((c) => c.id == rule.categoryId).firstOrNull;
    final catIcon = cat != null
        ? CategoryIconMapper.fromName(cat.iconName)
        : AppIcons.category;
    final catColor =
        cat != null ? ColorUtils.fromHex(cat.colorHex) : cs.outline;
    final typeColor = switch (rule.type) {
      'income' => context.appTheme.incomeColor,
      'transfer' => context.appTheme.transferColor,
      _ => context.appTheme.expenseColor,
    };
    final prefix = rule.type == 'income' ? '+' : '\u2212';
    final isBill = rule.isBill;
    final isOverdue = rule.isOverdue;
    final brand = BrandRegistry.match(rule.title);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Slidable(
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
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            onTap: () => context.push(
              AppRoutes.recurringEdit.replaceFirst(':id', '${rule.id}'),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              child: Row(
                children: [
                  // Brand logo (3-tier) or category icon fallback.
                  if (brand != null)
                    BrandLogo(
                      brand: brand,
                      size: AppSizes.iconContainerMd,
                    )
                  else
                    Container(
                      width: AppSizes.iconContainerMd,
                      height: AppSizes.iconContainerMd,
                      decoration: BoxDecoration(
                        color: (isOverdue
                                ? context.appTheme.expenseColor
                                : catColor)
                            .withValues(alpha: AppSizes.opacityLight2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isBill ? AppIcons.bill : catIcon,
                        size: AppSizes.iconSm,
                        color: isOverdue
                            ? context.appTheme.expenseColor
                            : catColor,
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
                            decoration:
                                rule.isPaid ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: AppSizes.xxs),
                        if (isBill)
                          _buildBillSubtitle(context)
                        else
                          _buildRecurringSubtitle(context),
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
                          color: rule.isPaid ? cs.outline : typeColor,
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
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
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
          '${context.l10n.recurring_due_date_label}: ${_formatDate(context, rule.nextDueDate)}',
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
          context.l10n.frequencyLabel(rule.frequency),
          style: context.textStyles.bodySmall?.copyWith(
            color: cs.outline,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Text(
          '${context.l10n.recurring_next_due}: ${_formatDate(context, rule.nextDueDate)}',
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
    ConfirmDialog.show(
      context,
      title: rule.title,
      message: message,
      confirmLabel: context.l10n.common_confirm,
    ).then((confirmed) {
      if (confirmed) _toggleActive(ref, active);
    });
  }

  void _toggleActive(WidgetRef ref, bool active) {
    HapticFeedback.selectionClick();
    // M15 fix: on resume, if nextDueDate is in the past, advance to today
    final now = DateTime.now();
    var nextDue = rule.nextDueDate;
    if (active && nextDue.isBefore(now)) {
      nextDue = DateTime(now.year, now.month, now.day);
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
    ConfirmDialog.confirmDelete(
      context,
      title: context.l10n.recurring_delete_title,
      message: context.l10n.recurring_delete_confirm,
    ).then((confirmed) async {
      if (!confirmed) return;
      try {
        await ref.read(recurringRuleRepositoryProvider).delete(rule.id);
        await ref
            .read(notificationTriggerServiceProvider)
            .cancelBillReminder(rule.id);
        HapticFeedback.mediumImpact();
      } catch (e) {
        if (context.mounted) {
          SnackHelper.showError(context, context.l10n.common_error_title);
        }
      }
    });
  }
}

// ── Mark Paid button ──────────────────────────────────────────────────────

class _MarkPaidButton extends ConsumerStatefulWidget {
  const _MarkPaidButton({required this.rule});

  final RecurringRuleEntity rule;

  @override
  ConsumerState<_MarkPaidButton> createState() => _MarkPaidButtonState();
}

class _MarkPaidButtonState extends ConsumerState<_MarkPaidButton> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.iconContainerSm,
      child: FilledButton.tonal(
        onPressed: _processing ? null : () => _markPaid(context),
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

  Future<void> _markPaid(BuildContext context) async {
    // M1 fix: confirmation dialog before marking paid
    final confirmed = await ConfirmDialog.show(
      context,
      title: widget.rule.title,
      message: context.l10n.recurring_mark_paid_confirm,
      confirmLabel: context.l10n.recurring_mark_paid,
    );
    if (!confirmed || !mounted) return;

    // M2 fix: loading guard prevents double-tap
    setState(() => _processing = true);
    HapticFeedback.mediumImpact();

    try {
      final rule = widget.rule;
      // C5 fix: atomic — create transaction + adjust wallet + mark paid
      await ref.read(recurringRuleRepositoryProvider).payBill(
            ruleId: rule.id,
            walletId: rule.walletId,
            categoryId: rule.categoryId,
            amount: rule.amount,
            type: rule.type,
            title: rule.title,
          );
      // Cancel the old bill reminder (bill is paid)
      await ref
          .read(notificationTriggerServiceProvider)
          .cancelBillReminder(rule.id);
      if (!context.mounted) return;
      ref.invalidate(recurringRulesProvider);
      SnackHelper.showSuccess(
        context,
        context.l10n.recurring_bill_paid_success,
      );
    } catch (e) {
      if (!context.mounted) return;
      SnackHelper.showError(context, context.l10n.common_error_generic);
    } finally {
      if (context.mounted) setState(() => _processing = false);
    }
  }
}
