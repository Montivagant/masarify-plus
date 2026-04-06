import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Glassmorphic insight banner with icon + text.
///
/// Used across analytics tabs to surface contextual, encouraging insights
/// like savings rate or top category trends.
class InsightCard extends StatelessWidget {
  const InsightCard({
    super.key,
    required this.text,
    this.icon,
  });

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Semantics(
      label: context.l10n.semantics_insight_label(text),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
        child: GlassCard(
          tier: GlassTier.inset,
          tintColor: cs.primary.withValues(alpha: AppSizes.opacityXLight2),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  icon ?? AppIcons.reports,
                  size: AppSizes.iconMd,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: AppSizes.sm),
              Expanded(
                child: Text(
                  text,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
