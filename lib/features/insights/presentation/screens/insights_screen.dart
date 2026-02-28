import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/insight_engine.dart';
import '../../../../core/utils/insight_presenter.dart';
import '../../../../shared/providers/insight_provider.dart';
import '../../../../shared/widgets/cards/insight_card.dart';
import '../../../../shared/widgets/feedback/shimmer_list.dart';
import '../../../../shared/widgets/lists/empty_state.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  final Set<String> _dismissed = {};

  @override
  void initState() {
    super.initState();
    _loadDismissed();
  }

  Future<void> _loadDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('dismissed_insights') ?? [];
    setState(() => _dismissed.addAll(list));
  }

  Future<void> _dismiss(String id) async {
    setState(() => _dismissed.add(id));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dismissed_insights', _dismissed.toList());
  }

  @override
  Widget build(BuildContext context) {
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      appBar: AppAppBar(title: context.l10n.insights_title),
      body: insightsAsync.when(
        loading: () => const ShimmerList(),
        error: (_, __) => EmptyState(
          title: context.l10n.common_error_generic,
          ctaLabel: context.l10n.voice_retry,
          onCta: () => ref.invalidate(insightsProvider),
        ),
        data: (insights) {
          final visible = insights
              .where((i) => !_dismissed.contains(_insightId(i)))
              .toList();

          if (visible.isEmpty) {
            return EmptyState(
              title: context.l10n.insights_empty_title,
              subtitle: context.l10n.insight_no_insights,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
            itemCount: visible.length,
            itemBuilder: (context, index) {
              final insight = visible[index];
              return InsightCard(
                insight: insight,
                title: InsightPresenter.title(context, insight),
                body: InsightPresenter.body(context, insight),
                onDismiss: () => _dismiss(_insightId(insight)),
                actionLabel: InsightPresenter.actionLabel(context, insight),
                onAction: () => InsightPresenter.onAction(context, insight),
              );
            },
          );
        },
      ),
    );
  }

  /// Generate a stable ID for dismiss persistence.
  static String _insightId(Insight insight) {
    return '${insight.type.name}_${insight.params.values.join('_')}';
  }
}
