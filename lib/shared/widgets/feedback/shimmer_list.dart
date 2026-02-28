import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';

/// Shimmer skeleton loader for list screens.
/// Shows [itemCount] placeholder rows matching typical transaction card height.
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.itemCount = 6,
    this.itemHeight = 72,
  });

  final int itemCount;
  final double itemHeight;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final baseColor = cs.surfaceContainerHighest;
    final highlightColor = cs.surfaceContainerLow;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: itemCount,
        separatorBuilder: (_, __) =>
            const SizedBox(height: AppSizes.sm),
        itemBuilder: (_, __) => _ShimmerItem(height: itemHeight),
      ),
    );
  }
}

class _ShimmerItem extends StatelessWidget {
  const _ShimmerItem({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
      ),
      child: Row(
        children: [
          // Avatar/icon circle
          Container(
            width: AppSizes.iconContainerLg,
            height: AppSizes.iconContainerLg,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: AppSizes.shimmerTextHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusSm),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
                Container(
                  height: AppSizes.shimmerTextHeightSm,
                  width: AppSizes.shimmerWidthLg,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusSm),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                height: AppSizes.shimmerTextHeight,
                width: AppSizes.shimmerWidthSm,
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusSm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
