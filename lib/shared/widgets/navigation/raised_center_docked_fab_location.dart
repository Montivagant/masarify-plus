import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

/// [FloatingActionButtonLocation] that delegates to [centerDocked]
/// and shifts the FAB upward by [offset] dp.
class RaisedCenterDockedFabLocation extends FloatingActionButtonLocation {
  const RaisedCenterDockedFabLocation(this.offset);

  final double offset;

  static const raised =
      RaisedCenterDockedFabLocation(AppSizes.fabVerticalOffset);

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final standard =
        FloatingActionButtonLocation.centerDocked.getOffset(scaffoldGeometry);
    return Offset(standard.dx, standard.dy - offset);
  }
}
