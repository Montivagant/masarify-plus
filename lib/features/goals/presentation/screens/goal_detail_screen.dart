import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

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
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/wallet_provider.dart';
import '../../../../shared/widgets/buttons/app_button.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/feedback/confirm_dialog.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/inputs/amount_input.dart';
import '../../../../shared/widgets/inputs/app_text_field.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../../../../shared/widgets/sheets/drag_handle.dart';

class GoalDetailScreen extends ConsumerWidget {
  const GoalDetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(goalByIdProvider(id));
    final contributionsAsync = ref.watch(goalContributionsProvider(id));

    return goalAsync.when(
      loading: () => Scaffold(
        appBar: AppAppBar(title: context.l10n.goal_detail_title),
        body: const Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (_, __) => Scaffold(
        appBar: AppAppBar(title: context.l10n.goal_detail_title),
        body: EmptyState(title: context.l10n.common_error_title),
      ),
      data: (goal) {
        if (goal == null) {
          return Scaffold(
            appBar: AppAppBar(title: context.l10n.goal_detail_title),
            body: EmptyState(title: context.l10n.goal_not_found),
          );
        }

        return Scaffold(
          appBar: AppAppBar(
            title: goal.name,
            actions: [
              IconButton(
                icon: const Icon(AppIcons.edit),
                tooltip: context.l10n.common_edit,
                onPressed: () => context.push(AppRoutes.editGoalPath(goal.id)),
              ),
              // H6 fix: goal delete button
              IconButton(
                icon: const Icon(AppIcons.delete),
                tooltip: context.l10n.common_delete,
                onPressed: () => _confirmDeleteGoal(context, ref, goal.id),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding:
                const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _GoalHeader(goal: goal),
                const SizedBox(height: AppSizes.lg),

                if (!goal.isCompleted)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.screenHPadding,
                    ),
                    child: AppButton(
                      label: context.l10n.goal_detail_add_savings,
                      icon: AppIcons.add,
                      onPressed: () => _showAddContribution(context, ref, goal),
                    ),
                  ),

                const SizedBox(height: AppSizes.lg),

                // Keywords
                Builder(
                  builder: (_) {
                    // R5-C4 fix: guard against corrupted JSON
                    List<String> kws;
                    try {
                      kws = (jsonDecode(goal.keywords) as List).cast<String>();
                    } catch (_) {
                      kws = [];
                    }
                    if (kws.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.screenHPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.l10n.goal_keywords,
                            style: context.textStyles.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSizes.sm),
                          Wrap(
                            spacing: AppSizes.sm,
                            runSpacing: AppSizes.xs,
                            children: kws
                                .map(
                                  (kw) => Chip(
                                    label: Text(kw),
                                    avatar: const Icon(
                                      AppIcons.tag,
                                      size: AppSizes.iconXxs2,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: AppSizes.lg),
                        ],
                      ),
                    );
                  },
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.screenHPadding,
                  ),
                  child: Text(
                    context.l10n.goal_saved_label,
                    style: context.textStyles.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: AppSizes.xs),

                contributionsAsync.when(
                  data: (contributions) {
                    if (contributions.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(AppSizes.xl),
                        child: EmptyState(
                          title: context.l10n.goal_detail_no_savings,
                          subtitle: context.l10n.goal_detail_no_savings_sub,
                        ),
                      );
                    }
                    return Column(
                      children: contributions.map((c) {
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(AppIcons.goals, size: AppSizes.iconXs),
                          ),
                          title: Text(MoneyFormatter.format(c.amount)),
                          subtitle: Text(
                            '${DateFormat.yMd(context.languageCode).format(c.date)}'
                            '${c.note != null ? " · ${c.note}" : ""}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              AppIcons.delete,
                              size: AppSizes.iconSm,
                            ),
                            // M11 fix: add confirmation dialog
                            onPressed: () async {
                              final confirmed =
                                  await ConfirmDialog.confirmDelete(
                                context,
                                title: context.l10n.common_delete,
                                message: context
                                    .l10n.goal_delete_contribution_confirm,
                              );
                              if (confirmed && context.mounted) {
                                // CR-19 fix: await the async delete
                                await ref
                                    .read(goalRepositoryProvider)
                                    .deleteContribution(c.id);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSizes.xl),
                      child: CircularProgressIndicator.adaptive(),
                    ),
                  ),
                  error: (_, __) =>
                      EmptyState(title: context.l10n.common_error_title),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDeleteGoal(
    BuildContext context,
    WidgetRef ref,
    int goalId,
  ) async {
    final confirmed = await ConfirmDialog.confirmDelete(
      context,
      title: context.l10n.goal_delete_title,
      message: context.l10n.goal_delete_confirm,
    );
    if (confirmed) {
      await ref.read(goalRepositoryProvider).deleteGoal(goalId);
      HapticFeedback.mediumImpact();
      if (context.mounted) context.pop();
    }
  }

  void _showAddContribution(
    BuildContext context,
    WidgetRef ref,
    SavingsGoalEntity goal,
  ) {
    int amountPiastres = 0;
    int? selectedWalletId;
    final noteController = TextEditingController();
    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    final nonSystem = wallets.where((w) => !w.isSystemWallet).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: StatefulBuilder(
              builder: (ctx, setSheetState) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DragHandle(),
                  Text(
                    context.l10n.goal_detail_add_savings,
                    style: ctx.textStyles.titleMedium,
                  ),
                  const SizedBox(height: AppSizes.md),
                  AmountInput(
                    onAmountChanged: (p) => amountPiastres = p,
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Wallet picker — deduct from selected account
                  if (nonSystem.isNotEmpty) ...[
                    Text(
                      context.l10n.goal_contribution_from_wallet,
                      style: ctx.textStyles.labelLarge?.copyWith(
                        color: ctx.colors.outline,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xs),
                    Wrap(
                      spacing: AppSizes.sm,
                      runSpacing: AppSizes.xs,
                      children: [
                        // "No deduction" option
                        ChoiceChip(
                          label: Text(context.l10n.common_none),
                          selected: selectedWalletId == null,
                          onSelected: (_) =>
                              setSheetState(() => selectedWalletId = null),
                          showCheckmark: false,
                        ),
                        ...nonSystem.map(
                          (w) => ChoiceChip(
                            label: Text(w.name),
                            avatar: Icon(
                              AppIcons.walletType(w.type),
                              size: AppSizes.iconXs,
                            ),
                            selected: selectedWalletId == w.id,
                            onSelected: (_) =>
                                setSheetState(() => selectedWalletId = w.id),
                            showCheckmark: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.md),
                  ],

                  AppTextField(
                    label: context.l10n.goal_contribution_note,
                    controller: noteController,
                  ),
                  const SizedBox(height: AppSizes.md),
                  AppButton(
                    label: context.l10n.common_save,
                    icon: AppIcons.check,
                    onPressed: () async {
                      if (amountPiastres <= 0) return;
                      // H6 fix: pre-validate contribution doesn't exceed remaining
                      final remaining = goal.targetAmount - goal.currentAmount;
                      if (remaining <= 0) {
                        SnackHelper.showError(
                          ctx,
                          ctx.l10n.goal_already_funded,
                        );
                        return;
                      }
                      if (amountPiastres > remaining) {
                        SnackHelper.showError(
                          ctx,
                          '${ctx.l10n.common_error_generic} (max: ${MoneyFormatter.formatAmount(remaining)})',
                        );
                        return;
                      }
                      try {
                        final repo = ref.read(goalRepositoryProvider);
                        final note = noteController.text.trim().isEmpty
                            ? null
                            : noteController.text.trim();
                        if (selectedWalletId != null) {
                          await repo.addContributionWithDeduction(
                            goalId: goal.id,
                            amount: amountPiastres,
                            date: DateTime.now(),
                            walletId: selectedWalletId!,
                            note: note,
                          );
                        } else {
                          await repo.addContribution(
                            goalId: goal.id,
                            amount: amountPiastres,
                            date: DateTime.now(),
                            note: note,
                          );
                        }
                        HapticFeedback.mediumImpact();
                        // Fire goal milestone notification check
                        final prevAmount = goal.currentAmount;
                        final updatedGoal = await repo.getById(goal.id);
                        if (updatedGoal != null) {
                          ref
                              .read(notificationTriggerServiceProvider)
                              .checkGoalMilestone(
                                goal: updatedGoal,
                                previousAmount: prevAmount,
                              );
                        }
                        if (ctx.mounted) ctx.pop();
                      } catch (e) {
                        if (ctx.mounted) {
                          SnackHelper.showError(
                            ctx,
                            ctx.l10n.common_error_generic,
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(noteController.dispose);
  }
}

class _GoalHeader extends StatelessWidget {
  const _GoalHeader({required this.goal});
  final SavingsGoalEntity goal;

  @override
  Widget build(BuildContext context) {
    final color = ColorUtils.fromHex(goal.colorHex);
    final icon = CategoryIconMapper.fromName(goal.iconName);
    final pct = (goal.progressFraction * 100).clamp(0, 100).round();
    final cs = context.colors;

    return GlassCard(
      showShadow: true,
      margin: const EdgeInsets.all(AppSizes.screenHPadding),
      padding: const EdgeInsets.all(AppSizes.lg),
      tintColor: color.withValues(alpha: AppSizes.opacitySubtle),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: AppSizes.progressRingLg,
                height: AppSizes.progressRingLg,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: goal.progressFraction),
                  duration: context.reduceMotion
                      ? Duration.zero
                      : AppDurations.progressAnim,
                  curve: Curves.easeOutCubic,
                  builder: (_, value, __) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 8,
                    backgroundColor: cs.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ),
              GlassCard(
                tier: GlassTier.inset,
                padding: EdgeInsets.zero,
                borderRadius:
                    BorderRadius.circular(AppSizes.progressRingInner / 2),
                tintColor: color.withValues(alpha: AppSizes.opacityLight2),
                child: SizedBox(
                  width: AppSizes.progressRingInner,
                  height: AppSizes.progressRingInner,
                  child: Icon(icon, color: color, size: AppSizes.iconLg),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            MoneyFormatter.formatPercent(pct),
            style: context.textStyles.headlineMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSizes.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Stat(
                label: context.l10n.goal_saved_label,
                value: MoneyFormatter.formatCompact(goal.currentAmount),
                color: color,
              ),
              _Stat(
                label: context.l10n.goal_target_label,
                value: MoneyFormatter.formatCompact(goal.targetAmount),
                color: cs.onSurface,
              ),
              _Stat(
                label: context.l10n.goal_remaining_label,
                value: MoneyFormatter.formatCompact(goal.remainingAmount),
                color: cs.outline,
              ),
            ],
          ),
          if (goal.deadline != null) ...[
            const SizedBox(height: AppSizes.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(AppIcons.calendar, size: AppSizes.iconXs),
                const SizedBox(width: AppSizes.xs),
                Text(
                  DateFormat.yMd(context.languageCode).format(goal.deadline!),
                  style: context.textStyles.bodySmall,
                ),
              ],
            ),
          ],
          if (goal.isCompleted) ...[
            const SizedBox(height: AppSizes.sm),
            Chip(
              label: Text(context.l10n.goal_completed_chip),
              avatar: const Icon(AppIcons.check, size: AppSizes.iconXs),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: context.textStyles.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.outline,
          ),
        ),
      ],
    );
  }
}
