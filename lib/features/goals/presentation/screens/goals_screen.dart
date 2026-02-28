import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/category_icon_mapper.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/savings_goal_entity.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeGoalsProvider);
    final completedAsync = ref.watch(completedGoalsProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.goals_title,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.add),
            tooltip: context.l10n.goal_add_title,
            onPressed: () => context.push(AppRoutes.goalAdd),
          ),
        ],
      ),
      body: activeAsync.when(
        data: (active) {
          final completed = completedAsync.valueOrNull ?? [];
          if (active.isEmpty && completed.isEmpty) {
            return EmptyState(
              title: context.l10n.goals_empty_title,
              subtitle: context.l10n.goals_empty_sub_long,
              ctaLabel: context.l10n.goal_add,
              onCta: () => context.push(AppRoutes.goalAdd),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
            children: [
              if (active.isNotEmpty) ...[
                _SectionHeader(title: context.l10n.goal_active_section, count: active.length),
                ...active.map(
                  (g) => _GoalCard(
                    goal: g,
                    onTap: () => context.push(AppRoutes.goalDetailPath(g.id)),
                  ),
                ),
              ],
              if (completed.isNotEmpty) ...[
                _SectionHeader(title: context.l10n.goal_completed_section, count: completed.length),
                ...completed.map(
                  (g) => _GoalCard(
                    goal: g,
                    onTap: () => context.push(AppRoutes.goalDetailPath(g.id)),
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: AppSizes.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: AppSizes.xxs),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
            ),
            child: Text('$count', style: Theme.of(context).textTheme.labelSmall),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.onTap});
  final SavingsGoalEntity goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.fromHex(goal.colorHex);
    final icon = CategoryIconMapper.fromName(goal.iconName);
    final pct = (goal.progressFraction * 100).clamp(0, 100).round();
    final daysLeft = goal.deadline?.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: AppSizes.iconContainerLg,
                    height: AppSizes.iconContainerLg,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: AppSizes.opacityLight2),
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadiusMd),
                    ),
                    child: Icon(icon, color: color, size: AppSizes.iconSm),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.name,
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (daysLeft != null)
                          Text(
                            daysLeft > 0
                                ? context.l10n.goal_days_remaining(daysLeft)
                                : goal.isCompleted
                                    ? context.l10n.goal_completed_chip
                                    : context.l10n.goal_overdue,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '$pct%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: goal.progressFraction),
                  duration: AppDurations.countUp,
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => LinearProgressIndicator(
                    value: value,
                    minHeight: 8,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    MoneyFormatter.formatCompact(goal.currentAmount),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  Text(
                    MoneyFormatter.formatCompact(goal.targetAmount),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
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
}
