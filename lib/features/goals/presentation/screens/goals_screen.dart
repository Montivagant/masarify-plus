import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
import '../../../../shared/providers/subscription_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import 'add_goal_screen.dart';

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAsync = ref.watch(activeGoalsProvider);
    final hasPro = ref.watch(hasProAccessProvider);
    final completedAsync = ref.watch(completedGoalsProvider);

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.goals_title,
        actions: [
          IconButton(
            icon: Icon(
              !hasPro && (activeAsync.valueOrNull?.length ?? 0) >= 1
                  ? AppIcons.lock
                  : AppIcons.add,
            ),
            tooltip: context.l10n.goal_add_title,
            onPressed: () {
              if (!hasPro && (activeAsync.valueOrNull?.length ?? 0) >= 1) {
                context.push(AppRoutes.paywall);
              } else {
                AddGoalScreen.show(context);
              }
            },
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
              onCta: () => AddGoalScreen.show(context),
            );
          }
          return ListView(
            padding:
                const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
            children: [
              if (active.isNotEmpty) ...[
                _SectionHeader(
                  title: context.l10n.goal_active_section,
                  count: active.length,
                ),
                for (var i = 0; i < active.length; i++)
                  _buildAnimatedGoalCard(
                    context,
                    index: i,
                    child: _GoalCard(
                      goal: active[i],
                      onTap: () =>
                          context.push(AppRoutes.goalDetailPath(active[i].id)),
                    ),
                  ),
              ],
              if (completed.isNotEmpty) ...[
                _SectionHeader(
                  title: context.l10n.goal_completed_section,
                  count: completed.length,
                ),
                for (var i = 0; i < completed.length; i++)
                  _buildAnimatedGoalCard(
                    context,
                    index: active.length + i,
                    child: _GoalCard(
                      goal: completed[i],
                      onTap: () => context
                          .push(AppRoutes.goalDetailPath(completed[i].id)),
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
        error: (_, __) => EmptyState(
          title: context.l10n.common_error_title,
          ctaLabel: context.l10n.common_retry,
          onCta: () => ref.invalidate(activeGoalsProvider),
        ),
      ),
    );
  }
}

/// M10: Wraps a list item with staggered fade+slide animation.
/// Returns the child unchanged when user prefers reduced motion.
Widget _buildAnimatedGoalCard(
  BuildContext context, {
  required int index,
  required Widget child,
}) {
  if (context.reduceMotion) return child;
  return child
      .animate()
      .fadeIn(duration: AppDurations.listItemEntry)
      .slideY(
        begin: 0.03,
        end: 0,
        duration: AppDurations.listItemEntry,
        curve: Curves.easeOutCubic,
      )
      .then(delay: AppDurations.staggerDelay * index);
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
              vertical: AppSizes.xxs,
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

    return GlassCard(
      showShadow: true,
      onTap: onTap,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GlassCard(
                tier: GlassTier.inset,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                tintColor: color.withValues(alpha: AppSizes.opacityLight2),
                child: SizedBox(
                  width: AppSizes.iconContainerLg,
                  height: AppSizes.iconContainerLg,
                  child: Icon(icon, color: color, size: AppSizes.iconSm),
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: context.textStyles.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    if (daysLeft != null)
                      Text(
                        daysLeft > 0
                            ? context.l10n.goal_days_remaining(daysLeft)
                            : goal.isCompleted
                                ? context.l10n.goal_completed_chip
                                : context.l10n.goal_overdue,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.outline,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                MoneyFormatter.formatPercent(pct),
                style: context.textStyles.titleMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.sm),
          RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: goal.progressFraction),
                duration:
                    context.reduceMotion ? Duration.zero : AppDurations.countUp,
                curve: Curves.easeOutCubic,
                builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: context.colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                MoneyFormatter.formatCompact(goal.currentAmount),
                style: context.textStyles.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                MoneyFormatter.formatCompact(goal.targetAmount),
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colors.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
