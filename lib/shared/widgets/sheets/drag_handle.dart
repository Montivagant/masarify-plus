import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';

/// Standard bottom sheet drag handle — replaces the duplicated Container
/// pattern found across 7+ bottom sheet implementations.
class DragHandle extends StatelessWidget {
  const DragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSizes.sm),
        width: AppSizes.dragHandleWidth,
        height: AppSizes.dragHandleHeight,
        decoration: BoxDecoration(
          color: context.colors.outlineVariant,
          borderRadius: BorderRadius.circular(AppSizes.dragHandleHeight / 2),
        ),
      ),
    );
  }
}
