import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../widgets/categories_tab.dart';
import '../widgets/comparison_tab.dart';
import '../widgets/overview_tab.dart';
import '../widgets/trends_tab.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppAppBar(
          title: context.l10n.reports_title,
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: context.l10n.reports_overview),
              Tab(text: context.l10n.reports_categories),
              Tab(text: context.l10n.reports_trends),
              Tab(text: context.l10n.reports_comparison),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OverviewTab(),
            CategoriesTab(),
            TrendsTab(),
            ComparisonTab(),
          ],
        ),
      ),
    );
  }
}
