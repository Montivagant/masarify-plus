import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionIcon,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? actionIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (actionLabel != null && onAction != null)
            if (actionIcon != null)
              TextButton.icon(
                onPressed: onAction,
                label: Text(actionLabel!),
                icon: Icon(actionIcon, size: AppSizes.iconXs),
                iconAlignment: IconAlignment.end,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              )
            else
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(actionLabel!),
              ),
        ],
      ),
    );
  }
}
