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

/// Subscriptions & Bills screen — revamped with summary header,
/// status-grouped cards, accent bars, and spending insights.
class RecurringScreen extends ConsumerStatefulWidget {
  const RecurringScreen({super.key});

  @override
  ConsumerState<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends ConsumerState<RecurringScreen> {
  bool _viewAll = false;

  @override
  Widget build(BuildContext context) {
    final rulesAsync = ref.watch(recurringRulesProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final cs = context.colors;
    final theme = context.appTheme;

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.recurring_and_bills_title,
        actions: [
          // View All toggle
          TextButton(
            onPressed: () => setState(() => _viewAll = !_viewAll),
            child: Text(
              _viewAll
                  ? context.l10n.common_cancel
                  : context.l10n.recurring_view_all,
            ),
          ),
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

          // Categorize rules
          final overdue = <RecurringRuleEntity>[];
          final upcoming = <RecurringRuleEntity>[];
          final active = <RecurringRuleEntity>[];
          final paid = <RecurringRuleEntity>[];
          final inactive = <RecurringRuleEntity>[];

          for (final r in rules) {
            if (r.isPaid) {
              paid.add(r);
            } else if (r.isBill && r.isDue) {
              overdue.add(r);
            } else if (r.isBill) {
              upcoming.add(r);
            } else if (!r.isActive) {
              inactive.add(r);
            } else {
              active.add(r);
            }
          }

          // Monthly total (active + upcoming only)
          final monthlyTotal = rules
              .where((r) => r.isActive && r.type == 'expense')
              .fold(0, (sum, r) => sum + r.amount);

          // Due this week count
          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final weekEnd = now.add(const Duration(days: 7));
          final dueThisWeek = rules
              .where(
                (r) =>
                    !r.isPaid &&
                    r.isActive &&
                    !r.nextDueDate.isBefore(todayStart) &&
                    r.nextDueDate.isBefore(weekEnd),
              )
              .length;

          final reduceMotion = context.reduceMotion;
          var staggerIdx = 0;

          Widget animateCard(Widget card) {
            if (reduceMotion) return card;
            final idx = staggerIdx++;
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
              // ── Summary header card ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenHPadding,
                  vertical: AppSizes.md,
                ),
                child: GlassCard(
                  showShadow: true,
                  padding: const EdgeInsets.all(AppSizes.lg),
                  tintColor: cs.primaryContainer.withValues(
                    alpha: AppSizes.opacitySubtle,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.recurring_total_monthly_spend
                            .toUpperCase(),
                        style: context.textStyles.labelSmall?.copyWith(
                          color: cs.outline,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      Text(
                        MoneyFormatter.format(monthlyTotal),
                        style: context.textStyles.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      if (dueThisWeek > 0) ...[
                        const SizedBox(height: AppSizes.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSizes.sm,
                            vertical: AppSizes.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: theme.warningColor.withValues(
                              alpha: AppSizes.opacityLight2,
                            ),
                            borderRadius: BorderRadius.circular(
                              AppSizes.borderRadiusFull,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: AppSizes.indicatorDotSize,
                                height: AppSizes.indicatorDotSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: theme.warningColor,
                                ),
                              ),
                              const SizedBox(width: AppSizes.xs),
                              Text(
                                context.l10n
                                    .recurring_due_this_week(dueThisWeek),
                                style: context.textStyles.labelSmall?.copyWith(
                                  color: theme.warningColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── View All mode: flat list ─────────────────────────
              if (_viewAll) ...[
                ...rules.map(
                  (r) => animateCard(
                    _SubscriptionCard(
                      rule: r,
                      categories: categories,
                    ),
                  ),
                ),
              ] else ...[
                // ── Grouped mode ────────────────────────────────────

                // Attention Required (overdue) — coral tint
                if (overdue.isNotEmpty) ...[
                  _SectionLabel(
                    label:
                        context.l10n.recurring_attention_required.toUpperCase(),
                    color: theme.expenseColor,
                  ),
                  ...overdue.map(
                    (r) => animateCard(
                      _SubscriptionCard(
                        rule: r,
                        categories: categories,
                        accentColor: theme.expenseColor,
                        tintColor: theme.expenseColor
                            .withValues(alpha: AppSizes.opacityXLight2),
                      ),
                    ),
                  ),
                ],

                // Coming Soon (upcoming bills) — amber tint
                if (upcoming.isNotEmpty) ...[
                  _SectionLabel(
                    label: context.l10n.recurring_coming_soon.toUpperCase(),
                    color: cs.primary,
                  ),
                  ...upcoming.map(
                    (r) => animateCard(
                      _SubscriptionCard(
                        rule: r,
                        categories: categories,
                        accentColor: theme.warningColor,
                      ),
                    ),
                  ),
                ],

                // Active Services
                if (active.isNotEmpty) ...[
                  _SectionLabel(
                    label: context.l10n.recurring_active_services.toUpperCase(),
                    color: cs.primary,
                  ),
                  ...active.map(
                    (r) => animateCard(
                      _SubscriptionCard(
                        rule: r,
                        categories: categories,
                        accentColor: theme.incomeColor,
                        tintColor: cs.primaryContainer
                            .withValues(alpha: AppSizes.opacityXLight2),
                      ),
                    ),
                  ),
                ],

                // Recently Paid
                if (paid.isNotEmpty) ...[
                  _SectionLabel(
                    label: context.l10n.recurring_recently_paid.toUpperCase(),
                    color: cs.outline,
                  ),
                  ...paid.map(
                    (r) => animateCard(
                      _SubscriptionCard(
                        rule: r,
                        categories: categories,
                        muted: true,
                      ),
                    ),
                  ),
                ],

                // Inactive
                if (inactive.isNotEmpty) ...[
                  _SectionLabel(
                    label: context.l10n.recurring_paused.toUpperCase(),
                    color: cs.outline,
                  ),
                  ...inactive.map(
                    (r) => animateCard(
                      _SubscriptionCard(
                        rule: r,
                        categories: categories,
                        muted: true,
                      ),
                    ),
                  ),
                ],

                // ── Insight cards (TODO: wire to real computed data) ──
              ],
            ],
          );
        },
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSizes.screenHPadding + AppSizes.xs,
        AppSizes.lg,
        AppSizes.screenHPadding,
        AppSizes.sm,
      ),
      child: Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: color ?? context.colors.outline,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

// ── Subscription card ─────────────────────────────────────────────────────

/// Accent bar width — thicker than default for visual prominence.
const double _kAccentBarWidth = 6;

class _SubscriptionCard extends ConsumerWidget {
  const _SubscriptionCard({
    required this.rule,
    required this.categories,
    this.accentColor,
    this.tintColor,
    this.muted = false,
  });

  final RecurringRuleEntity rule;
  final List<CategoryEntity> categories;
  final Color? accentColor;
  final Color? tintColor;
  final bool muted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    final theme = context.appTheme;
    final cat = categories.where((c) => c.id == rule.categoryId).firstOrNull;
    final catIcon = cat != null
        ? CategoryIconMapper.fromName(cat.iconName)
        : AppIcons.category;
    final catColor =
        cat != null ? ColorUtils.fromHex(cat.colorHex) : cs.outline;
    final typeColor = switch (rule.type) {
      'income' => theme.incomeColor,
      'transfer' => theme.transferColor,
      _ => theme.expenseColor,
    };
    final brand = BrandRegistry.match(rule.title);
    final effectiveAccent = accentColor ?? catColor;
    // Overdue items use expense color for icon circle
    final iconColor = rule.isOverdue ? theme.expenseColor : catColor;

    // ── Build subtitle status text ──
    final freq = context.l10n.frequencyLabel(rule.frequency);
    final String statusText;
    final Color subtitleColor;
    if (rule.isPaid) {
      final paidDate = rule.paidAt != null
          ? DateFormat.MMMd(context.languageCode).format(rule.paidAt!)
          : '';
      final ref = rule.linkedTransactionId != null
          ? ' \u2022 #${rule.linkedTransactionId}'
          : '';
      statusText = '$freq \u2022 ${context.l10n.recurring_paid} $paidDate$ref';
      subtitleColor = cs.outline;
    } else if (rule.isOverdue) {
      statusText = '$freq \u2022 ${context.l10n.recurring_overdue}';
      subtitleColor = theme.expenseColor;
    } else if (rule.isBill) {
      final dueDate =
          DateFormat.MMMd(context.languageCode).format(rule.nextDueDate);
      statusText =
          '$freq \u2022 ${context.l10n.recurring_due_date_label} $dueDate';
      subtitleColor = cs.outline;
    } else {
      final nextDate =
          DateFormat.MMMd(context.languageCode).format(rule.nextDueDate);
      statusText = '$freq \u2022 ${context.l10n.recurring_next_due} $nextDate';
      subtitleColor = cs.outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.sm,
      ),
      child: Opacity(
        opacity: muted ? AppSizes.opacityMedium2 : 1.0,
        child: GlassCard(
          padding: EdgeInsets.zero,
          showShadow: !muted,
          tintColor: tintColor,
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
                  backgroundColor: theme.transferColor,
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
                  backgroundColor: theme.expenseColor,
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
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Left accent bar (6px) ──
                    Container(
                      width: _kAccentBarWidth,
                      decoration: BoxDecoration(
                        color: effectiveAccent,
                        borderRadius: const BorderRadiusDirectional.only(
                          topStart: Radius.circular(AppSizes.borderRadiusMd),
                          bottomStart: Radius.circular(AppSizes.borderRadiusMd),
                        ),
                      ),
                    ),
                    // ── Card content ──
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.md,
                          vertical: AppSizes.md,
                        ),
                        child: Row(
                          children: [
                            // Brand/category icon
                            if (brand != null)
                              BrandLogo(
                                brand: brand,
                                size: AppSizes.iconContainerLg,
                              )
                            else
                              Container(
                                width: AppSizes.iconContainerLg,
                                height: AppSizes.iconContainerLg,
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(
                                    alpha: AppSizes.opacityLight,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  catIcon,
                                  size: AppSizes.iconSm,
                                  color: iconColor,
                                ),
                              ),
                            const SizedBox(width: AppSizes.md),
                            // Title + subtitle
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    rule.title,
                                    style:
                                        context.textStyles.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: AppSizes.xxs),
                                  Text(
                                    statusText,
                                    style:
                                        context.textStyles.bodySmall?.copyWith(
                                      color: subtitleColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            // Amount + action column
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  MoneyFormatter.format(rule.amount),
                                  style:
                                      context.textStyles.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: muted ? cs.outline : typeColor,
                                    decoration: rule.isPaid
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: AppSizes.xs),
                                // Action: Mark Paid, Toggle, or Paid badge
                                if (rule.isBill && rule.isDue)
                                  _MarkPaidChip(rule: rule)
                                else if (!rule.isPaid)
                                  SizedBox(
                                    height: AppSizes.iconMd,
                                    child: Switch.adaptive(
                                      value: rule.isActive,
                                      onChanged: (v) => _confirmToggle(
                                        context,
                                        ref,
                                        v,
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  )
                                else if (rule.isPaid)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSizes.sm,
                                      vertical: AppSizes.xxs,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.incomeColor.withValues(
                                        alpha: AppSizes.opacityLight2,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppSizes.borderRadiusFull,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          AppIcons.check,
                                          size: AppSizes.iconXxs,
                                          color: theme.incomeColor,
                                        ),
                                        const SizedBox(width: AppSizes.xxs),
                                        Text(
                                          context.l10n.recurring_paid
                                              .toUpperCase(),
                                          style: context.textStyles.labelSmall
                                              ?.copyWith(
                                            color: theme.incomeColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmToggle(
    BuildContext context,
    WidgetRef ref,
    bool active,
  ) async {
    final message = active
        ? context.l10n.recurring_confirm_activate
        : context.l10n.recurring_confirm_pause;
    final confirmed = await ConfirmDialog.show(
      context,
      title: rule.title,
      message: message,
      confirmLabel: context.l10n.common_confirm,
    );
    if (!confirmed || !context.mounted) return;
    await _toggleActive(context, ref, active);
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    bool active,
  ) async {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    var nextDue = rule.nextDueDate;
    if (active && nextDue.isBefore(now)) {
      nextDue = DateTime(now.year, now.month, now.day);
    }
    try {
      await ref.read(recurringRuleRepositoryProvider).update(
            rule.copyWith(
              isActive: active,
              nextDueDate: nextDue,
              lastProcessedDate: () => active ? null : rule.lastProcessedDate,
            ),
          );
      ref.invalidate(recurringRulesProvider);
    } catch (e) {
      if (context.mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.confirmDelete(
      context,
      title: context.l10n.recurring_delete_title,
      message: context.l10n.recurring_delete_confirm,
    );
    if (!confirmed || !context.mounted) return;
    try {
      await ref.read(recurringRuleRepositoryProvider).delete(rule.id);
      await ref
          .read(notificationTriggerServiceProvider)
          .cancelBillReminder(rule.id);
      ref.invalidate(recurringRulesProvider);
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (context.mounted) {
        SnackHelper.showError(context, context.l10n.common_error_title);
      }
    }
  }
}

// ── Mark Paid chip ────────────────────────────────────────────────────────

class _MarkPaidChip extends ConsumerStatefulWidget {
  const _MarkPaidChip({required this.rule});

  final RecurringRuleEntity rule;

  @override
  ConsumerState<_MarkPaidChip> createState() => _MarkPaidChipState();
}

class _MarkPaidChipState extends ConsumerState<_MarkPaidChip> {
  bool _processing = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final cs = context.colors;
    return GestureDetector(
      onTap: _processing ? null : () => _markPaid(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xxs,
        ),
        decoration: BoxDecoration(
          color: theme.expenseColor,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
        ),
        child: Text(
          context.l10n.recurring_mark_paid.toUpperCase(),
          style: context.textStyles.labelSmall?.copyWith(
            color: cs.onError,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _markPaid(BuildContext context) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: widget.rule.title,
      message: context.l10n.recurring_mark_paid_confirm,
      confirmLabel: context.l10n.recurring_mark_paid,
    );
    if (!confirmed || !mounted) return;

    setState(() => _processing = true);
    HapticFeedback.mediumImpact();

    try {
      final rule = widget.rule;
      await ref.read(recurringRuleRepositoryProvider).payBill(
            ruleId: rule.id,
            walletId: rule.walletId,
            categoryId: rule.categoryId,
            amount: rule.amount,
            type: rule.type,
            title: rule.title,
          );
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
