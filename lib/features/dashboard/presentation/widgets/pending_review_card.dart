import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/pending_transactions_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// WS5: Small card shown on dashboard when pending parsed transactions exist.
class PendingReviewCard extends ConsumerWidget {
  const PendingReviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingCountProvider).valueOrNull ?? 0;

    if (pendingCount == 0) return const SizedBox.shrink();

    final cs = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
      ),
      child: GlassCard(
        tintColor:
            cs.primaryContainer.withValues(alpha: AppSizes.opacityXLight),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          onTap: () => context.push(AppRoutes.parserReview),
          child: Row(
            children: [
              Icon(
                AppIcons.inbox,
                size: AppSizes.iconSm,
                color: cs.primary,
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  context.l10n.dashboard_pending_review(pendingCount),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.parserReview),
                child: Text(context.l10n.dashboard_pending_review_action),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
