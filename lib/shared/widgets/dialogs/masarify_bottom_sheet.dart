import 'package:flutter/material.dart';

import '../../../core/constants/app_sizes.dart';

/// Shows a standard Masarify bottom sheet with consistent styling.
///
/// Provides a unified look across the app: rounded top corners, a standard
/// drag handle, and surface background colour. Callers supply the body via
/// [builder]; the drag handle is prepended automatically.
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
  final cs = Theme.of(context).colorScheme;
  return showModalBottomSheet<T>(
    context: context,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: useSafeArea,
    isScrollControlled: isScrollControlled,
    backgroundColor: cs.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSizes.borderRadiusLg),
      ),
    ),
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Drag handle ────────────────────────────────────────────
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: AppSizes.sm),
            width: AppSizes.dragHandleWidth,
            height: AppSizes.dragHandleHeight,
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.outlineVariant,
              borderRadius:
                  BorderRadius.circular(AppSizes.dragHandleHeight / 2),
            ),
          ),
        ),
        builder(ctx),
      ],
    ),
  );
}
