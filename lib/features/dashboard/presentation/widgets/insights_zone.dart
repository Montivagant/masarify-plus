import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/insight_presenter.dart';
import '../../../../shared/providers/insight_provider.dart';
import '../../../../shared/widgets/cards/insight_card.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';

/// Zone 6: Smart insights — watches only insightsProvider.
class InsightsZone extends ConsumerWidget {
  const InsightsZone({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);

    return insightsAsync.when(
      data: (insights) {
        if (insights.isEmpty) return const SizedBox.shrink();
        final top = insights.take(2).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSizes.sectionGap),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
                vertical: AppSizes.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.l10n.insights_title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push(AppRoutes.insights),
                    label: Text(context.l10n.insight_see_all),
                    icon: Icon(
                      context.isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
                      size: AppSizes.iconXs,
                    ),
                    iconAlignment: IconAlignment.end,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
            ...top.map(
              (insight) => InsightCard(
                insight: insight,
                title: InsightPresenter.title(context, insight),
                body: InsightPresenter.body(context, insight),
                actionLabel: InsightPresenter.actionLabel(context, insight),
                onAction: () => InsightPresenter.onAction(context, insight),
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSizes.screenHPadding,
        ),
        child: ShimmerList(itemCount: 2),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
