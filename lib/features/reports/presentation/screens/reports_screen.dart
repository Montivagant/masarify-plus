import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../widgets/categories_tab.dart';
import '../widgets/overview_tab.dart';
import '../widgets/trends_tab.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppAppBar(
          title: context.l10n.reports_title,
          centerTitle: false,
          actions: [
            IconButton(
              icon: const Icon(AppIcons.calendar),
              onPressed: () => context.push(AppRoutes.calendar),
              tooltip: context.l10n.calendar_title,
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.reports_overview),
              Tab(text: context.l10n.reports_categories),
              Tab(text: context.l10n.reports_trends),
            ],
          ),
        ),
        // Each tab embeds its own TabFilterRow — no global filter bar.
        body: const TabBarView(
          children: [
            OverviewTab(),
            CategoriesTab(),
            TrendsTab(),
          ],
        ),
      ),
    );
  }
}
