import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/ai/gemini_audio_service.dart';
import '../../../../shared/providers/ai_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';

/// Voice input states.
enum _VoiceState { idle, recording, processing, error }

/// Bottom sheet for AI voice input using audio recording + Gemini API.
///
/// Records audio via [AudioRecorder], sends WAV bytes to Gemini for
/// transcription + transaction parsing in a single API call.
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

  _VoiceState _state = _VoiceState.idle;
  String? _tempFilePath;

  /// Synchronous guard against concurrent `_stopAndProcess` calls.
  bool _isStopping = false;

  /// Recording duration displayed as MM:SS.
  int _recordingSeconds = 0;
  Timer? _durationTimer;

  /// Safety limit — auto-stop after 60 seconds.
  static const _maxRecordingSeconds = 60;

  @override
  void dispose() {
    _durationTimer?.cancel();
    _recorder.dispose();
    _cleanupTempFile();
    super.dispose();
  }

  // ── Recording ───────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        dev.log('Microphone permission denied', name: 'VoiceInputSheet');
        if (!mounted) return;
        setState(() => _state = _VoiceState.error);
        return;
      }

      final dir = await getTemporaryDirectory();
      _tempFilePath =
          '${dir.path}/masarify_voice_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
        ),
        path: _tempFilePath!,
      );

      if (!mounted) return;

      _recordingSeconds = 0;
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _recordingSeconds++);
        if (_recordingSeconds >= _maxRecordingSeconds) {
          timer.cancel();
          _stopAndProcess();
        }
      });

      setState(() => _state = _VoiceState.recording);
      dev.log('Recording started → $_tempFilePath', name: 'VoiceInputSheet');
    } catch (e) {
      dev.log('Recording start failed: $e', name: 'VoiceInputSheet');
      if (mounted) {
        setState(() => _state = _VoiceState.error);
      }
    }
  }

  Future<void> _stopAndProcess() async {
    // Synchronous guard against concurrent calls from timer + user tap.
    if (_state != _VoiceState.recording || _isStopping) return;
    _isStopping = true;
    _durationTimer?.cancel();
    setState(() => _state = _VoiceState.processing);

    try {
      final path = await _recorder.stop();
      dev.log('Recording stopped → $path', name: 'VoiceInputSheet');

      if (path == null || path.isEmpty) {
        await _cleanupTempFile();
        if (!mounted) return;
        _popAndShowInfo(context.l10n.voice_no_results);
        return;
      }

      // Read WAV bytes and clean up temp file.
      final file = File(path);
      if (!file.existsSync()) {
        await _cleanupTempFile();
        if (!mounted) return;
        _popAndShowInfo(context.l10n.voice_no_results);
        return;
      }

      final audioBytes = await file.readAsBytes();
      await _cleanupTempFile();

      dev.log(
        'Audio recorded: ${audioBytes.length} bytes',
        name: 'VoiceInputSheet',
      );

      // ~1 second of 16kHz mono WAV — reject sub-second noise.
      if (audioBytes.length < 32000) {
        if (!mounted) return;
        _popAndShowInfo(context.l10n.voice_no_results);
        return;
      }

      // Check connectivity before calling Gemini.
      final online = ref.read(isOnlineProvider).valueOrNull ?? true;
      dev.log(
        'Connectivity before Gemini call: $online',
        name: 'VoiceInputSheet',
      );
      if (!online) {
        if (!mounted) return;
        _popAndShowInfo(context.l10n.voice_error_no_service);
        return;
      }

      // Send audio to Gemini for transcription + parsing.
      final gemini = ref.read(geminiAudioServiceProvider);
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];
      final goals = ref.read(activeGoalsProvider).valueOrNull ?? [];

      final drafts = await gemini.parseAudio(
        audioBytes: audioBytes,
        mimeType: 'audio/wav',
        categories: categories,
        goals: goals,
      );

      if (!mounted) return;

      dev.log(
        'Gemini result: ${drafts.length} drafts',
        name: 'VoiceInputSheet',
      );

      if (drafts.isEmpty) {
        _popAndShowInfo(context.l10n.voice_ai_error);
        return;
      }

      // Navigate to confirm screen.
      final router = GoRouter.of(context);
      context.pop();
      router.push(AppRoutes.voiceConfirm, extra: drafts);
    } on GeminiAudioException catch (e) {
      dev.log(
        'Gemini error: ${e.statusCode} — ${e.message}'
        '${e.isRateLimit ? " (RATE LIMITED)" : ""}'
        '${e.isUnauthorized ? " (AUTH FAILED)" : ""}'
        '${e.isServerError ? " (SERVER ERROR)" : ""}',
        name: 'VoiceInputSheet',
      );
      if (!mounted) return;
      _popAndShowInfo(context.l10n.voice_ai_error);
    } on TimeoutException {
      dev.log('Gemini request timed out', name: 'VoiceInputSheet');
      if (!mounted) return;
      _popAndShowInfo(context.l10n.voice_ai_error);
    } on SocketException {
      dev.log('Network lost during Gemini call', name: 'VoiceInputSheet');
      if (!mounted) return;
      _popAndShowInfo(context.l10n.voice_error_no_service);
    } catch (e) {
      dev.log('Voice processing failed: $e', name: 'VoiceInputSheet');
      if (!mounted) return;
      _popAndShowInfo(context.l10n.voice_ai_error);
    } finally {
      _isStopping = false;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  void _popAndShowInfo(String message) {
    if (!mounted) return;
    SnackHelper.showInfo(context, message);
    context.pop();
  }

  Future<void> _cleanupTempFile() async {
    if (_tempFilePath != null) {
      try {
        final file = File(_tempFilePath!);
        if (file.existsSync()) await file.delete();
      } catch (_) {}
      _tempFilePath = null;
    }
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppSizes.screenHPadding,
        end: AppSizes.screenHPadding,
        top: AppSizes.sm,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSizes.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // -- Drag handle --
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

          // -- Close button --
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              icon: const Icon(AppIcons.close, size: AppSizes.iconSm),
              onPressed: () async {
                final nav = GoRouter.of(context);
                if (_state == _VoiceState.recording) {
                  await _recorder.stop();
                }
                nav.pop();
              },
              visualDensity: VisualDensity.compact,
              tooltip: context.l10n.common_close,
            ),
          ),

          // -- Mic button with avatar_glow pulse --
          Builder(
            builder: (context) {
              final reduceMotion = MediaQuery.disableAnimationsOf(context);
              return Semantics(
                button: true,
                label: _state == _VoiceState.idle
                    ? context.l10n.voice_tap_to_start
                    : _state == _VoiceState.recording
                        ? context.l10n.common_done
                        : null,
                child: GestureDetector(
                  onTap: _state == _VoiceState.idle
                      ? _startRecording
                      : _state == _VoiceState.recording
                          ? _stopAndProcess
                          : null,
                  child: AvatarGlow(
                    animate:
                        !reduceMotion && _state == _VoiceState.recording,
                    glowRadiusFactor: 0.3,
                    glowColor: cs.primary,
                    child: Container(
                      width: AppSizes.voiceMicSize,
                      height: AppSizes.voiceMicSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _state == _VoiceState.recording
                            ? cs.primary
                            : _state == _VoiceState.error
                                ? cs.error
                                : cs.primaryContainer,
                      ),
                      child: Icon(
                        _state == _VoiceState.error
                            ? AppIcons.close
                            : AppIcons.mic,
                        size: AppSizes.iconLg,
                        color: _state == _VoiceState.recording
                            ? cs.onPrimary
                            : _state == _VoiceState.error
                                ? cs.onError
                                : cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSizes.md),

          // -- Status text --
          Text(
            _statusText(context),
            style: context.textStyles.bodyMedium?.copyWith(color: cs.outline),
          ),

          // -- Recording duration counter --
          if (_state == _VoiceState.recording) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              _formatDuration(_recordingSeconds),
              style: context.textStyles.headlineSmall?.copyWith(
                color: cs.primary,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ],
          const SizedBox(height: AppSizes.lg),

          // -- Action buttons --
          if (_state == _VoiceState.recording)
            FilledButton.icon(
              onPressed: _stopAndProcess,
              icon: const Icon(AppIcons.check, size: AppSizes.iconSm2),
              label: Text(context.l10n.common_done),
            )
          else if (_state == _VoiceState.error)
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
                    setState(() => _state = _VoiceState.idle);
                  },
                  child: Text(context.l10n.voice_retry),
                ),
              ],
            )
          else if (_state == _VoiceState.processing)
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
      _VoiceState.idle => context.l10n.voice_tap_to_start,
      _VoiceState.recording => context.l10n.voice_listening,
      _VoiceState.processing => context.l10n.voice_ai_parsing,
      _VoiceState.error => context.l10n.voice_error_no_service,
    };
  }
}
