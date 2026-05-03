import 'package:flutter/material.dart';

/// [SliverPersistentHeaderDelegate] that pins the filter bar at a fixed height.
///
/// The [FilterBar] widget watches providers internally, so this delegate
/// does not need to track rebuild state — [shouldRebuild] is always false.
class FilterBarDelegate extends SliverPersistentHeaderDelegate {
  const FilterBarDelegate({required this.child});

  final Widget child;

  static const double _height = 52.0;

  @override
  double get maxExtent => _height;

  @override
  double get minExtent => _height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Transparent so the dashboard's tier-2 backdrop region (theme revamp
    // v7, §5.1.3) shows through the pinned filter bar. A solid M3 surface
    // here would block the gradient and break the glass aesthetic.
    return Material(
      color: Colors.transparent,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant FilterBarDelegate oldDelegate) => false;
}
