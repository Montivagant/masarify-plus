import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import 'glass_card.dart';

/// A grouped glass container that wraps children with internal dividers.
///
/// Replaces `Card(child: Column(children: tiles))` pattern in Hub/Settings.
/// Optional [header] displayed above the glass panel.
class GlassSection extends StatelessWidget {
  const GlassSection({
    super.key,
    required this.children,
    this.header,
    this.padding = EdgeInsets.zero,
    this.margin = const EdgeInsets.only(bottom: AppSizes.md),
    this.showDividers = true,
  });

  final List<Widget> children;
  final String? header;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool showDividers;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (header != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSizes.xs,
              bottom: AppSizes.sm,
            ),
            child: Text(
              header!,
              style: context.textStyles.titleSmall?.copyWith(
                color: context.colors.onSurface.withValues(alpha: AppSizes.opacityMedium2),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        GlassCard(
          padding: padding,
          showShadow: true,
          margin: margin,
          child: Column(
            children: _buildChildren(context),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildChildren(BuildContext context) {
    if (!showDividers || children.length <= 1) return children;

    final result = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      result.add(children[i]);
      if (i < children.length - 1) {
        result.add(
          Divider(
            height: AppSizes.dividerHeight,
            thickness: AppSizes.dividerHeight,
            color: context.colors.onSurface.withValues(alpha: AppSizes.opacityXLight2),
          ),
        );
      }
    }
    return result;
  }
}
