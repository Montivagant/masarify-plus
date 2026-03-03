import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';

/// Voice recording states.
enum _RecordingState { idle, recording, processing, error }

/// Bottom sheet for AI voice input.
///
/// Records audio via the `record` package. Currently requires device STT
/// (Task 19) for transcription before AI parsing via OpenRouter.
class VoiceInputSheet extends ConsumerStatefulWidget {
  const VoiceInputSheet({super.key});

  /// Show the voice input sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.borderRadiusMd),
        ),
      ),
      builder: (_) => const VoiceInputSheet(),
    );
  }

  @override
  ConsumerState<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends ConsumerState<VoiceInputSheet> {
  final _recorder = AudioRecorder();

  _RecordingState _state = _RecordingState.idle;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!mounted) return;
      if (!hasPermission) {
        setState(() => _state = _RecordingState.error);
      }
    } catch (e) {
      dev.log('Permission check failed: $e', name: 'VoiceInputSheet');
      if (mounted) setState(() => _state = _RecordingState.error);
    }
  }

  Future<void> _startRecording() async {
    try {
      final dir = await getTemporaryDirectory();
      final filePath =
          '${dir.path}/masarify_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(),
        path: filePath,
      );

      _recordedFilePath = filePath;
      _recordingDuration = Duration.zero;
      _durationTimer = Timer.periodic(AppDurations.retryDelay, (_) {
        if (!mounted) return;
        setState(() {
          _recordingDuration += AppDurations.retryDelay;
        });
        // Auto-stop at max recording duration
        if (_recordingDuration >= AppDurations.voiceMaxRecording) {
          _stopRecording();
        }
      });

      if (mounted) setState(() => _state = _RecordingState.recording);
    } catch (e) {
      dev.log('Recording start failed: $e', name: 'VoiceInputSheet');
      if (mounted) {
        setState(() => _state = _RecordingState.error);
      }
    }
  }

  Future<void> _stopRecording() async {
    _durationTimer?.cancel();

    try {
      final path = await _recorder.stop();
      if (!mounted) return;

      if (path == null || path.isEmpty) {
        _popAndShowInfo(context.l10n.voice_no_results);
        return;
      }

      _recordedFilePath = path;
      setState(() => _state = _RecordingState.processing);
      await _processAudio(path);
    } catch (e) {
      dev.log('Recording stop failed: $e', name: 'VoiceInputSheet');
      if (mounted) {
        setState(() => _state = _RecordingState.error);
      }
    }
  }

  Future<void> _cancelRecording() async {
    _durationTimer?.cancel();
    try {
      await _recorder.cancel();
    } catch (e) {
      dev.log('Recorder cancel error: $e', name: 'VoiceInputSheet');
    }
    // Clean up temp file
    if (_recordedFilePath != null) {
      try {
        final file = File(_recordedFilePath!);
        if (file.existsSync()) file.deleteSync();
      } catch (e) {
        dev.log('Temp file cleanup error: $e', name: 'VoiceInputSheet');
      }
    }
    if (mounted) context.pop();
  }

  Future<void> _processAudio(String audioPath) async {
    try {
      // TODO(Task-19): Replace with device STT transcription + AI parsing.
      // Without STT, audio files cannot be transcribed — show error.
      _popAndShowInfo(context.l10n.voice_ai_error);
    } finally {
      // Clean up temp audio file
      try {
        final file = File(audioPath);
        if (file.existsSync()) file.deleteSync();
      } catch (e) {
        dev.log('Audio file cleanup error: $e', name: 'VoiceInputSheet');
      }
    }
  }

  void _popAndShowInfo(String message) {
    if (!mounted) return;
    SnackHelper.showInfo(context, message);
    context.pop();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSizes.screenHPadding,
        right: AppSizes.screenHPadding,
        top: AppSizes.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────
          Container(
            width: AppSizes.dragHandleWidth,
            height: AppSizes.dragHandleHeight,
            decoration: BoxDecoration(
              color: cs.outline.withValues(alpha: AppSizes.opacityLight4),
              borderRadius:
                  BorderRadius.circular(AppSizes.dragHandleHeight / 2),
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // ── Close button ─────────────────────────────────────
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              icon: const Icon(AppIcons.close, size: AppSizes.iconSm),
              onPressed: _state == _RecordingState.recording
                  ? _cancelRecording
                  : () => context.pop(),
              visualDensity: VisualDensity.compact,
              tooltip: context.l10n.common_close,
            ),
          ),

          // ── Mic button with avatar_glow pulse ─────────────────
          Builder(builder: (context) {
            final reduceMotion = MediaQuery.of(context).disableAnimations;
            return Semantics(
              button: true,
              label: _state == _RecordingState.idle
                  ? context.l10n.voice_tap_to_start
                  : _state == _RecordingState.recording
                      ? context.l10n.common_done
                      : null,
              child: GestureDetector(
                onTap: _state == _RecordingState.idle
                    ? _startRecording
                    : _state == _RecordingState.recording
                        ? _stopRecording
                        : null,
                child: AvatarGlow(
                animate: !reduceMotion &&
                    _state == _RecordingState.recording,
                glowRadiusFactor: 0.3,
                glowColor: cs.primary,
                child: Container(
                  width: AppSizes.voiceMicSize,
                  height: AppSizes.voiceMicSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _state == _RecordingState.recording
                        ? cs.primary
                        : _state == _RecordingState.error
                            ? cs.error
                            : cs.primaryContainer,
                  ),
                  child: Icon(
                    _state == _RecordingState.error
                        ? AppIcons.close
                        : AppIcons.mic,
                    size: AppSizes.iconLg,
                    color: _state == _RecordingState.recording
                        ? cs.onPrimary
                        : _state == _RecordingState.error
                            ? cs.onError
                            : cs.onPrimaryContainer,
                  ),
                ),
              ),
            ),
            );
          },),
          const SizedBox(height: AppSizes.md),

          // ── Status text ──────────────────────────────────────
          Text(
            _statusText(context),
            style: context.textStyles.bodyMedium?.copyWith(color: cs.outline),
          ),

          // ── Recording duration ───────────────────────────────
          if (_state == _RecordingState.recording) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              _formatDuration(_recordingDuration),
              style: context.textStyles.titleLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          const SizedBox(height: AppSizes.lg),

          // ── Action buttons ───────────────────────────────────
          if (_state == _RecordingState.recording)
            FilledButton.icon(
              onPressed: _stopRecording,
              icon: const Icon(AppIcons.check, size: AppSizes.iconSm2),
              label: Text(context.l10n.common_done),
            )
          else if (_state == _RecordingState.error)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: Text(context.l10n.common_close),
                ),
                const SizedBox(width: AppSizes.md),
                FilledButton(
                  onPressed: () {
                    setState(() => _state = _RecordingState.idle);
                    _checkPermission();
                  },
                  child: Text(context.l10n.voice_retry),
                ),
              ],
            )
          else if (_state == _RecordingState.processing)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSizes.md),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  child: Text(context.l10n.common_cancel),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _statusText(BuildContext context) {
    return switch (_state) {
      _RecordingState.idle => context.l10n.voice_tap_to_start,
      _RecordingState.recording => context.l10n.voice_listening,
      _RecordingState.processing => context.l10n.voice_ai_parsing,
      _RecordingState.error => context.l10n.voice_error_no_service,
    };
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
