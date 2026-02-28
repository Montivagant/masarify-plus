import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../buttons/app_button.dart';

/// M8 fix: removed stale STUB comment — fully implemented.
/// Empty state with title + subtitle + optional CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.ctaLabel,
    this.onCta,
    this.animationPath,
    this.compact = false,
  }) : assert(
         !compact || (ctaLabel == null && onCta == null),
         'EmptyState: ctaLabel/onCta are ignored in compact mode',
       );

  final String title;
  final String? subtitle;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final String? animationPath;

  /// When true, uses smaller icon and padding (for inline sections like dashboard).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? AppSizes.iconLg : AppSizes.iconXl3;
    final padding = compact ? AppSizes.md : AppSizes.xl;
    final titleStyle = compact
        ? Theme.of(context).textTheme.titleSmall
        : Theme.of(context).textTheme.titleLarge;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.inbox,
              size: iconSize,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              title,
              style: titleStyle,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSizes.xs),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (ctaLabel != null && onCta != null && !compact) ...[
              const SizedBox(height: AppSizes.lg),
              AppButton(
                label: ctaLabel!,
                onPressed: onCta,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
