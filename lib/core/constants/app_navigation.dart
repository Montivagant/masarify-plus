import 'package:flutter/material.dart';

import 'app_icons.dart';
import 'app_routes.dart';

/// A single bottom navigation destination descriptor.
class AppNavDest {
  const AppNavDest({
    required this.labelAr,
    required this.labelEn,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });

  final String labelAr;
  final String labelEn;
  final IconData icon;
  final IconData activeIcon;
  final String route;

  /// Returns the label for the given language code (e.g. 'ar', 'en').
  String label(String languageCode) => languageCode == 'ar' ? labelAr : labelEn;
}

/// 4-tab navigation configuration with center FAB.
/// Tabs: Home | Recurring | [FAB] | Analytics | Planning
/// Budget & Goals moved to Hub (users check weekly, not daily).
/// Settings is accessed via gear icon in AppBar — NOT a tab.
abstract final class AppNavigation {
  static const List<AppNavDest> destinations = [
    AppNavDest(
      labelAr: 'الرئيسية',
      labelEn: 'Home',
      icon: AppIcons.homeOutlined,
      activeIcon: AppIcons.home,
      route: AppRoutes.dashboard,
    ),
    AppNavDest(
      labelAr: 'الاشتراكات',
      labelEn: 'Subscriptions',
      icon: AppIcons.recurringOutlined,
      activeIcon: AppIcons.recurring,
      route: AppRoutes.recurring,
    ),
    AppNavDest(
      labelAr: 'التحليلات',
      labelEn: 'Analytics',
      icon: AppIcons.analyticsOutlined,
      activeIcon: AppIcons.analytics,
      route: AppRoutes.analytics,
    ),
    AppNavDest(
      labelAr: 'التخطيط',
      labelEn: 'Planning',
      icon: AppIcons.moreOutlined,
      activeIcon: AppIcons.more,
      route: AppRoutes.hub,
    ),
  ];
}
