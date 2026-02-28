import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart'
    as ph show openAppSettings;

import '../extensions/build_context_extensions.dart';

/// Centralized permission helper.
///
/// Per AGENTS.md Rule 6: every sensitive permission must show a rationale
/// dialog BEFORE requesting the system prompt. This class enforces that.
abstract final class PermissionHelper {
  /// Show a rationale dialog and return `true` if the user tapped "Allow".
  ///
  /// Call this BEFORE requesting any sensitive permission.
  static Future<bool> showRationale(
    BuildContext context, {
    required String title,
    required String rationale,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(rationale),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(ctx.l10n.permission_deny),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            child: Text(ctx.l10n.permission_allow),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Open the app settings page (used when a permission is permanently denied).
  static Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }

  /// Show rationale then, if approved, invoke [onGranted].
  ///
  /// Typical usage:
  /// ```dart
  /// await PermissionHelper.requestWithRationale(
  ///   context,
  ///   title: 'الميكروفون',
  ///   rationale: 'نحتاج الميكروفون لإدخال المعاملات بالصوت.',
  ///   onGranted: () async { /* request actual OS permission */ },
  /// );
  /// ```
  static Future<void> requestWithRationale(
    BuildContext context, {
    required String title,
    required String rationale,
    required Future<void> Function() onGranted,
  }) async {
    final allowed = await showRationale(
      context,
      title: title,
      rationale: rationale,
    );
    if (allowed) await onGranted();
  }
}
