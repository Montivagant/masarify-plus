import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'app_icons.dart';
import 'app_routes.dart';

/// A single bottom navigation destination descriptor.
class AppNavDest {
  const AppNavDest({
    required this.labelBuilder,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });

  /// Returns the localised label for the current [BuildContext].
  final String Function(BuildContext context) labelBuilder;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  /// Convenience — resolve the label from a [BuildContext].
  String label(BuildContext context) => labelBuilder(context);
}

/// 4-tab navigation configuration with center FAB.
/// Tabs: Home | Subscriptions | [FAB] | Analytics | Planning
/// Budget & Goals moved to Hub (users check weekly, not daily).
/// Settings is accessed via gear icon in AppBar — NOT a tab.
abstract final class AppNavigation {
  static final List<AppNavDest> destinations = [
    AppNavDest(
      labelBuilder: (ctx) => AppLocalizations.of(ctx)!.nav_home,
      icon: AppIcons.homeOutlined,
      activeIcon: AppIcons.home,
      route: AppRoutes.dashboard,
    ),
    AppNavDest(
      labelBuilder: (ctx) => AppLocalizations.of(ctx)!.nav_subscriptions,
      icon: AppIcons.recurringOutlined,
      activeIcon: AppIcons.recurring,
      route: AppRoutes.recurring,
    ),
    AppNavDest(
      labelBuilder: (ctx) => AppLocalizations.of(ctx)!.nav_analytics,
      icon: AppIcons.analyticsOutlined,
      activeIcon: AppIcons.analytics,
      route: AppRoutes.analytics,
    ),
    AppNavDest(
      labelBuilder: (ctx) => AppLocalizations.of(ctx)!.nav_planning,
      icon: AppIcons.moreOutlined,
      activeIcon: AppIcons.more,
      route: AppRoutes.hub,
    ),
  ];
}
