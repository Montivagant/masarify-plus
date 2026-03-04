import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/services/glass_config_service.dart';

/// Shows a standard Masarify bottom sheet with frosted glass styling.
///
/// Provides a unified look across the app: rounded top corners, a frosted
/// drag handle, glass background, and transparent barrier. Callers supply
/// the body via [builder]; the drag handle is prepended automatically.
///
/// Set [isScrollControlled] to `true` when the content may exceed half the
/// screen (e.g. pickers, forms wrapped in `DraggableScrollableSheet`).
Future<T?> showMasarifyBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useSafeArea = true,
  bool isScrollControlled = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    isScrollControlled: isScrollControlled,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.barrierScrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.borderRadiusLg),
      ),
    ),
    builder: (ctx) => _GlassSheetBody(builder: builder, ctx: ctx),
  );
}

class _GlassSheetBody extends StatelessWidget {
  const _GlassSheetBody({required this.builder, required this.ctx});
  final WidgetBuilder builder;
  final BuildContext ctx;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    const radius = BorderRadius.vertical(
      top: Radius.circular(AppSizes.borderRadiusLg),
    );

    final content = Container(
      decoration: BoxDecoration(
        color: theme.glassSheetSurface,
        borderRadius: radius,
        border: Border.all(
          color: theme.glassSheetBorder,
          width: AppSizes.glassBorderWidthSubtle,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Frosted drag handle ────────────────────────────────────
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: AppSizes.sm),
              width: AppSizes.dragHandleWidth,
              height: AppSizes.dragHandleHeight,
              decoration: BoxDecoration(
                color: AppColors.dragHandle,
                borderRadius:
                    BorderRadius.circular(AppSizes.dragHandleHeight / 2),
              ),
            ),
          ),
          builder(ctx),
        ],
      ),
    );

    if (!GlassConfig.shouldBlur(context)) {
      return ClipRRect(borderRadius: radius, child: content);
    }

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSizes.glassBlurBackground,
          sigmaY: AppSizes.glassBlurBackground,
        ),
        child: content,
      ),
    );
  }
}
