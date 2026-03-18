import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// Dismissible tip card shown on dashboard when Quick Start wizard hasn't
/// been completed. Tapping navigates to the wizard.
class QuickStartTipCard extends ConsumerStatefulWidget {
  const QuickStartTipCard({super.key});

  @override
  ConsumerState<QuickStartTipCard> createState() => _QuickStartTipCardState();
}

class _QuickStartTipCardState extends ConsumerState<QuickStartTipCard> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final prefsAsync = ref.watch(preferencesFutureProvider);
    final isDone = prefsAsync.valueOrNull?.isQuickStartDone ?? false;

    if (isDone || _dismissed) return const SizedBox.shrink();

    final cs = context.colors;
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.sm,
      ),
      child: Dismissible(
        key: const ValueKey('quick_start_tip'),
        onDismissed: (_) => setState(() => _dismissed = true),
        child: GlassCard(
          tintColor: cs.primaryContainer.withValues(
            alpha: AppSizes.opacityLight2,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
            onTap: () => context.push(AppRoutes.quickStart),
            child: Row(
              children: [
                Icon(
                  AppIcons.quickStart,
                  size: AppSizes.iconLg,
                  color: cs.primary,
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.quick_start_tip_title,
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),
                      Text(
                        l10n.quick_start_tip_subtitle,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  context.isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
                  color: cs.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
