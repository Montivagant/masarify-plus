import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../providers/subscription_provider.dart';

/// Wraps a widget that requires Pro access.
///
/// If the user has Pro (subscription or trial), shows [child].
/// Otherwise, shows a locked placeholder with a CTA to the paywall.
///
/// Use [inline] mode for small elements (e.g., an export button):
///   shows a lock icon badge instead of a full placeholder.
class ProFeatureGuard extends ConsumerWidget {
  const ProFeatureGuard({
    super.key,
    required this.child,
    this.featureName,
    this.inline = false,
  });

  /// The widget to show when the user has Pro access.
  final Widget child;

  /// Display name for this feature (shown in the lock placeholder).
  final String? featureName;

  /// If true, shows a compact lock badge instead of a full placeholder.
  final bool inline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPro = ref.watch(hasProAccessProvider);

    if (hasPro) return child;

    if (inline) {
      return GestureDetector(
        onTap: () => context.push(AppRoutes.paywall),
        child: Stack(
          children: [
            Opacity(opacity: AppSizes.opacityDisabled, child: child),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppSizes.xxs),
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.lock,
                  size: AppSizes.iconXxs,
                  color: context.colors.onPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () => context.push(AppRoutes.paywall),
      child: Container(
        padding: const EdgeInsets.all(AppSizes.lg),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest.withValues(
            alpha: AppSizes.opacityLight2,
          ),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              AppIcons.lock,
              size: AppSizes.iconLg,
              color: context.colors.primary,
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              featureName ?? context.l10n.paywall_pro_feature,
              style: context.textStyles.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              context.l10n.paywall_unlock_cta,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
