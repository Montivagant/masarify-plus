import 'package:flutter/material.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';

/// Six-dot PIN display showing filled/empty state.
class PinDots extends StatelessWidget {
  const PinDots({
    super.key,
    required this.filledCount,
    this.totalDots = 6,
  });

  final int filledCount;
  final int totalDots;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalDots, (i) {
        final filled = i < filledCount;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
          child: AnimatedContainer(
            duration: AppDurations.dotPulse,
            width: AppSizes.dotLg,
            height: AppSizes.dotLg,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? cs.primary : cs.surfaceContainerHighest,
              border: filled
                  ? null
                  : Border.all(color: cs.outline, width: 1.5),
            ),
          ),
        );
      }),
    );
  }
}
