import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/ai/gemini_audio_service.dart';
import '../../../../shared/providers/ai_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/providers/wallet_provider.dart';
import 'voice_wave_bars.dart';

/// Pill bar states — no idle state because the pill auto-starts recording.
enum _PillState { recording, processing, error }

/// Compact 56dp floating pill bar for voice recording.
///
/// Auto-starts recording on mount. Shows wave visualizer + timer while
/// recording, a spinner during Gemini processing, and an error state that
/// auto-dismisses after [AppDurations.voicePillErrorDismiss].
class VoiceRecordingPill extends ConsumerStatefulWidget {
  const VoiceRecordingPill({super.key, required this.onDismiss});

  /// Called when the pill should be removed from the widget tree.
  final VoidCallback onDismiss;

  @override
  ConsumerState<VoiceRecordingPill> createState() => _VoiceRecordingPillState();
}

class _VoiceRecordingPillState extends ConsumerState<VoiceRecordingPill>
    with SingleTickerProviderStateMixin {
  final _recorder = AudioRecorder();

  _PillState _state = _PillState.recording;
  String? _tempFilePath;
  String? _errorMessage;

  /// Synchronous guard against concurrent `_stopAndProcess` calls.
  bool _isStopping = false;

  /// Set when user cancels during processing — prevents navigation.
  final bool _cancelled = false;

  /// Recording duration in seconds.
  int _recordingSeconds = 0;
  Timer? _durationTimer;

  /// Normalized amplitude (0.0 – 1.0) fed to [VoiceWaveBars].
  double _currentAmplitude = 0.0;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  /// Safety limit — auto-stop after max recording duration.
  static final _maxRecordingSeconds = AppDurations.voiceMaxRecording.inSeconds;

  /// Pulsing red dot animation controller.
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: AppDurations.voicePillPulse,
    )..repeat(reverse: true);
    _startRecording();
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    _cleanupTempFile();
    super.dispose();
  }

  // ── Recording ───────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        dev.log('Microphone permission denied', name: 'VoiceRecordingPill');
        if (!mounted) return;
        _showErrorState(context.l10n.permission_mic_body);
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
      _durationTimer = Timer.periodic(AppDurations.voiceRecordingTick, (timer) {
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

      // Subscribe to amplitude updates for VoiceWaveBars visualization.
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(AppDurations.voiceBarUpdate)
          .listen((amp) {
        if (mounted) {
          setState(() {
            _currentAmplitude = _normalizeAmplitude(amp.current);
          });
        }
      });

      setState(() => _state = _PillState.recording);
      dev.log(
        'Recording started -> $_tempFilePath',
        name: 'VoiceRecordingPill',
      );
    } catch (e) {
      dev.log('Recording start failed: $e', name: 'VoiceRecordingPill');
      if (mounted) {
        _showErrorState(context.l10n.voice_ai_error);
      }
    }
  }

  Future<void> _stopAndProcess() async {
    // Synchronous guard against concurrent calls from timer + user tap.
    if (_state != _PillState.recording || _isStopping) return;
    _isStopping = true;
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _currentAmplitude = 0.0;
    setState(() => _state = _PillState.processing);

    try {
      final path = await _recorder.stop();
      dev.log('Recording stopped -> $path', name: 'VoiceRecordingPill');

      if (path == null || path.isEmpty) {
        await _cleanupTempFile();
        if (!mounted) return;
        _showErrorState(context.l10n.voice_no_results);
        return;
      }

      // Read WAV bytes and clean up temp file.
      final file = File(path);
      if (!file.existsSync()) {
        await _cleanupTempFile();
        if (!mounted) return;
        _showErrorState(context.l10n.voice_no_results);
        return;
      }

      final audioBytes = await file.readAsBytes();
      await _cleanupTempFile();

      dev.log(
        'Audio recorded: ${audioBytes.length} bytes',
        name: 'VoiceRecordingPill',
      );

      // ~1 second of 16kHz mono WAV — reject sub-second noise.
      if (audioBytes.length < 32000) {
        if (!mounted) return;
        _showErrorState(context.l10n.voice_no_results);
        return;
      }

      // Check connectivity before calling Gemini.
      final online = ref.read(isOnlineProvider).valueOrNull ?? false;
      dev.log(
        'Connectivity before Gemini call: $online',
        name: 'VoiceRecordingPill',
      );
      if (!online) {
        if (!mounted) return;
        _showErrorState(context.l10n.voice_error_no_service);
        return;
      }

      // Send audio to Gemini for transcription + parsing.
      final gemini = ref.read(geminiAudioServiceProvider);
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];
      final goals = ref.read(activeGoalsProvider).valueOrNull ?? [];
      final wallets = ref.read(walletsProvider).valueOrNull ?? [];
      // Exclude system Cash wallet.
      final walletNames =
          wallets.where((w) => !w.isSystemWallet).map((w) => w.name).toList();

      final drafts = await gemini.parseAudio(
        audioBytes: audioBytes,
        mimeType: 'audio/wav',
        categories: categories,
        goals: goals,
        walletNames: walletNames,
      );

      if (!mounted || _cancelled) return;

      dev.log(
        'Gemini result: ${drafts.length} drafts',
        name: 'VoiceRecordingPill',
      );

      if (drafts.isEmpty) {
        _showErrorState(context.l10n.voice_no_results);
        return;
      }

      // Navigate to confirm screen then dismiss pill.
      context.push(AppRoutes.voiceConfirm, extra: drafts);
      widget.onDismiss();
    } on GeminiAudioException catch (e) {
      dev.log(
        'Gemini error: ${e.statusCode} — ${e.message}'
        '${e.isRateLimit ? " (RATE LIMITED)" : ""}'
        '${e.isUnauthorized ? " (AUTH FAILED)" : ""}'
        '${e.isServerError ? " (SERVER ERROR)" : ""}',
        name: 'VoiceRecordingPill',
      );
      if (!mounted) return;
      _showErrorState(context.l10n.voice_ai_error);
    } on TimeoutException {
      dev.log('Gemini request timed out', name: 'VoiceRecordingPill');
      if (!mounted) return;
      _showErrorState(context.l10n.voice_ai_error);
    } on SocketException {
      dev.log('Network lost during Gemini call', name: 'VoiceRecordingPill');
      if (!mounted) return;
      _showErrorState(context.l10n.voice_error_no_service);
    } catch (e) {
      dev.log('Voice processing failed: $e', name: 'VoiceRecordingPill');
      if (!mounted) return;
      _showErrorState(context.l10n.voice_ai_error);
    } finally {
      _isStopping = false;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Normalize dB amplitude (range -160..0) to 0.0..1.0 for VoiceWaveBars.
  double _normalizeAmplitude(double dB) => ((dB + 160) / 160).clamp(0.0, 1.0);

  /// Transition to error state — auto-dismiss after delay.
  void _showErrorState(String message) {
    if (!mounted) return;
    setState(() {
      _state = _PillState.error;
      _errorMessage = message;
    });
    Future.delayed(AppDurations.voicePillErrorDismiss, () {
      if (mounted) widget.onDismiss();
    });
  }

  Future<void> _cleanupTempFile() async {
    if (_tempFilePath != null) {
      try {
        final file = File(_tempFilePath!);
        if (file.existsSync()) await file.delete();
      } catch (_) {/* Best-effort cleanup */}
      _tempFilePath = null;
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;

    return Container(
      height: AppSizes.voicePillHeight,
      decoration: BoxDecoration(
        color: theme.glassCardSurface,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
        border: Border.all(
          color: theme.glassCardBorder,
          width: AppSizes.glassBorderWidthSubtle,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      child: switch (_state) {
        _PillState.recording => _buildRecordingContent(cs),
        _PillState.processing => _buildProcessingContent(cs),
        _PillState.error => _buildErrorContent(cs),
      },
    );
  }

  Widget _buildRecordingContent(ColorScheme cs) {
    return Row(
      children: [
        // Pulsing red dot
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = 0.8 + _pulseController.value * 0.2;
            return Transform.scale(
              scale: scale,
              child: child,
            );
          },
          child: Container(
            width: AppSizes.voicePillDotSize,
            height: AppSizes.voicePillDotSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.appTheme.expenseColor,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),

        // Wave bars — sized compact for the pill
        Expanded(
          child: SizedBox(
            height: AppSizes.voicePillHeight - AppSizes.md,
            child: VoiceWaveBars(
              state: VoiceWaveState.recording,
              amplitude: _currentAmplitude,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.sm),

        // Timer
        Text(
          _formatDuration(_recordingSeconds),
          style: context.textStyles.labelMedium?.copyWith(
            color: cs.onSurface,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: AppSizes.sm),

        // Stop button
        GestureDetector(
          onTap: _stopAndProcess,
          child: Container(
            width: AppSizes.voicePillStopSize,
            height: AppSizes.voicePillStopSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.appTheme.expenseColor,
            ),
            child: const Icon(
              AppIcons.stop,
              size: AppSizes.voicePillStopIconSize,
              color: AppColors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingContent(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: AppSizes.spinnerSize,
          height: AppSizes.spinnerSize,
          child: CircularProgressIndicator(
            strokeWidth: AppSizes.spinnerStrokeWidth,
            color: cs.primary,
          ),
        ),
        const SizedBox(width: AppSizes.sm),
        Text(
          context.l10n.voice_ai_parsing,
          style: context.textStyles.labelMedium?.copyWith(
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContent(ColorScheme cs) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          AppIcons.errorCircle,
          size: AppSizes.iconSm,
          color: cs.error,
        ),
        const SizedBox(width: AppSizes.sm),
        Flexible(
          child: Text(
            _errorMessage ?? context.l10n.voice_ai_error,
            style: context.textStyles.labelMedium?.copyWith(
              color: cs.error,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
