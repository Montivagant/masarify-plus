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
      padding: const EdgeInsets.only(
        left: AppSizes.screenHPadding,
        right: AppSizes.screenHPadding,
        top: AppSizes.xs,
        bottom: AppSizes.sectionGap,
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
                  size: AppSizes.iconMd,
                  color: cs.primary,
                ),
                const SizedBox(width: AppSizes.sm),
                Expanded(
                  child: Text(
                    l10n.quick_start_tip_title,
                    style: context.textStyles.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ),
                Icon(
                  context.isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
                  size: AppSizes.iconSm,
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
