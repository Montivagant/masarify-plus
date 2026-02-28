import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/utils/permission_helper.dart';
import 'voice_input_sheet.dart';

/// Mic button that handles permission flow before opening VoiceInputSheet.
///
/// Can be used in AppBar actions or anywhere a mic trigger is needed.
class VoiceInputButton extends StatelessWidget {
  const VoiceInputButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(AppIcons.mic, size: AppSizes.iconSm),
      onPressed: () => handleVoiceInput(context),
      tooltip: context.l10n.settings_voice_input,
    );
  }

  /// Reusable static method for launching voice input from anywhere.
  static Future<void> handleVoiceInput(BuildContext context) async {
    await _handlePress(context);
  }

  static Future<void> _handlePress(BuildContext context) async {
    // On iOS, we need both microphone AND speech recognition permissions.
    // On Android, only microphone is needed (speech uses Google services).
    final permissions = <Permission>[Permission.microphone];
    if (Platform.isIOS) {
      permissions.add(Permission.speech);
    }

    // Check if all permissions are already granted
    final statuses = await Future.wait(
      permissions.map((p) => p.status),
    );

    final allGranted = statuses.every((s) => s.isGranted);
    if (allGranted) {
      if (!context.mounted) return;
      await VoiceInputSheet.show(context);
      return;
    }

    // Check if any are permanently denied
    final anyPermanentlyDenied = statuses.any((s) => s.isPermanentlyDenied);
    if (anyPermanentlyDenied) {
      if (!context.mounted) return;
      await PermissionHelper.openAppSettings();
      return;
    }

    // Show rationale then request
    if (!context.mounted) return;
    await PermissionHelper.requestWithRationale(
      context,
      title: context.l10n.permission_mic_title,
      rationale: context.l10n.permission_mic_body,
      onGranted: () async {
        final results = await permissions.request();
        final granted = results.values.every((s) => s.isGranted);
        if (granted && context.mounted) {
          await VoiceInputSheet.show(context);
        }
      },
    );
  }
}
