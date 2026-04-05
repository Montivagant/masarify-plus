import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/recurring_rule_entity.dart';
import '../../../../shared/providers/background_ai_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Dashboard section showing up to 3 upcoming bills in a horizontal row.
///
/// Watches [upcomingBillsProvider] and hides entirely when no bills are due
/// within the next 7 days.
class DueSoonSection extends ConsumerWidget {
  const DueSoonSection({super.key});

  static const _cardWidth = 140.0;
  static const _cardHeight = 80.0;
  static const _maxVisible = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bills = ref.watch(upcomingBillsProvider);
    if (bills.isEmpty) return const SizedBox.shrink();

    final visibleBills = bills.take(_maxVisible).toList();
    final extraCount = bills.length - _maxVisible;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSizes.screenHPadding,
        right: AppSizes.screenHPadding,
        bottom: AppSizes.sectionGap,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ────────────────────────────────────────────
          Row(
            children: [
              Icon(
                AppIcons.bill,
                size: AppSizes.iconSm,
                color: context.colors.onSurface,
              ),
              const SizedBox(width: AppSizes.sm),
              Text(
                context.l10n.home_due_soon_title,
                style: context.textStyles.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),

          // ── Horizontal card row ──────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: Row(
              children: [
                for (final bill in visibleBills) ...[
                  _BillMiniCard(bill: bill),
                  const SizedBox(width: AppSizes.sm),
                ],
                if (extraCount > 0) _MoreChip(count: extraCount),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini-card for a single bill ────────────────────────────────────────────

class _BillMiniCard extends StatelessWidget {
  const _BillMiniCard({required this.bill});

  final RecurringRuleEntity bill;

  @override
  Widget build(BuildContext context) {
    final daysUntilDue = _daysUntilDue(bill);
    final dueLabel = _dueLabel(context, daysUntilDue);
    final dueColor = _dueColor(context, daysUntilDue);

    return SizedBox(
      width: DueSoonSection._cardWidth,
      height: DueSoonSection._cardHeight,
      child: GlassCard(
        onTap: () => context.push(AppRoutes.recurring),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bill title
            Text(
              bill.title,
              style: context.textStyles.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Amount
            Text(
              MoneyFormatter.format(bill.amount),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.outline,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // Due label
            Text(
              dueLabel,
              style: context.textStyles.labelSmall?.copyWith(
                color: dueColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _daysUntilDue(RecurringRuleEntity rule) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(
      rule.nextDueDate.year,
      rule.nextDueDate.month,
      rule.nextDueDate.day,
    );
    return due.difference(today).inDays;
  }

  String _dueLabel(BuildContext context, int days) {
    if (days <= 0) return context.l10n.home_due_soon_today;
    if (days == 1) return context.l10n.home_due_soon_tomorrow;
    return context.l10n.home_due_soon_in_days(days);
  }

  Color _dueColor(BuildContext context, int days) {
    if (days <= 1) return context.appTheme.expenseColor;
    if (days <= 3) return context.appTheme.warningColor;
    return context.appTheme.incomeColor;
  }
}

// ── "+N more" chip ─────────────────────────────────────────────────────────

class _MoreChip extends StatelessWidget {
  const _MoreChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(context.l10n.home_due_soon_more(count)),
      onPressed: () => context.push(AppRoutes.recurring),
    );
  }
}
