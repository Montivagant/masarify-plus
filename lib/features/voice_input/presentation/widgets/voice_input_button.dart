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
    // Only microphone permission is needed — audio is recorded and sent
    // to Gemini API for transcription + transaction parsing.
    final status = await Permission.microphone.status;

    if (status.isGranted) {
      if (!context.mounted) return;
      await VoiceInputSheet.show(context);
      return;
    }

    if (status.isPermanentlyDenied) {
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
        final result = await Permission.microphone.request();
        if (result.isGranted && context.mounted) {
          await VoiceInputSheet.show(context);
        }
      },
    );
  }
}
