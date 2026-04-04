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
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/sheets/drag_handle.dart';
import 'voice_wave_bars.dart';

/// Voice input states.
enum _VoiceState { idle, recording, processing, error }

/// Modal overlay for AI voice input using audio recording + Gemini API.
///
/// Records audio via [AudioRecorder], sends WAV bytes to Gemini for
/// transcription + transaction parsing in a single API call.
///
/// Displayed as a glassmorphic overlay covering the bottom ~65% of the screen,
/// with hold-to-record and tap-to-toggle recording support.
class VoiceInputSheet extends ConsumerStatefulWidget {
  const VoiceInputSheet({super.key});

  /// Show the voice input overlay as a general dialog.
  static Future<void> show(BuildContext context) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: AppColors.black.withValues(alpha: AppSizes.opacityMedium),
      transitionDuration: AppDurations.overlayExpand,
      pageBuilder: (_, __, ___) => const VoiceInputSheet(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curvedAnimation),
          child: child,
        );
      },
    );
  }

  @override
  ConsumerState<VoiceInputSheet> createState() => _VoiceInputSheetState();
}

class _VoiceInputSheetState extends ConsumerState<VoiceInputSheet> {
  final _recorder = AudioRecorder();

  _VoiceState _state = _VoiceState.idle;
  String? _tempFilePath;
  bool _isMicPermissionError = false;
  String? _errorMessage;

  /// Synchronous guard against concurrent `_stopAndProcess` calls.
  bool _isStopping = false;

  /// Set when user cancels during processing — prevents navigation on late response.
  bool _cancelled = false;

  /// Recording duration displayed as MM:SS.
  int _recordingSeconds = 0;
  Timer? _durationTimer;

  /// Normalized amplitude (0.0 - 1.0) fed to [VoiceWaveBars].
  double _currentAmplitude = 0.0;
  StreamSubscription<Amplitude>? _amplitudeSubscription;

  /// Safety limit — auto-stop after max recording duration.
  static final _maxRecordingSeconds = AppDurations.voiceMaxRecording.inSeconds;

  @override
  void dispose() {
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
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
        setState(() {
          _isMicPermissionError = true;
          _state = _VoiceState.error;
          _errorMessage = null;
        });
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

      // Subscribe to amplitude updates for VoiceWaveBars visualisation.
      _amplitudeSubscription = _recorder
          .onAmplitudeChanged(AppDurations.voiceBarUpdate)
          .listen((amp) {
        if (mounted) {
          setState(() {
            _currentAmplitude = _normalizeAmplitude(amp.current);
          });
        }
      });

      setState(() => _state = _VoiceState.recording);
      dev.log('Recording started -> $_tempFilePath', name: 'VoiceInputSheet');
    } catch (e) {
      dev.log('Recording start failed: $e', name: 'VoiceInputSheet');
      if (mounted) {
        setState(() {
          _state = _VoiceState.error;
          _errorMessage = null;
        });
      }
    }
  }

  Future<void> _stopAndProcess() async {
    // Synchronous guard against concurrent calls from timer + user tap.
    if (_state != _VoiceState.recording || _isStopping) return;
    _isStopping = true;
    _durationTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _currentAmplitude = 0.0;
    setState(() => _state = _VoiceState.processing);

    try {
      final path = await _recorder.stop();
      dev.log('Recording stopped -> $path', name: 'VoiceInputSheet');

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
        name: 'VoiceInputSheet',
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
        name: 'VoiceInputSheet',
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
      // Exclude system Cash wallet — "cash" is a payment method, not an account.
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
        name: 'VoiceInputSheet',
      );

      if (drafts.isEmpty) {
        _showErrorState(context.l10n.voice_no_results);
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
      _showErrorState(context.l10n.voice_ai_error);
    } on TimeoutException {
      dev.log('Gemini request timed out', name: 'VoiceInputSheet');
      if (!mounted) return;
      _showErrorState(context.l10n.voice_ai_error);
    } on SocketException {
      dev.log('Network lost during Gemini call', name: 'VoiceInputSheet');
      if (!mounted) return;
      _showErrorState(context.l10n.voice_error_no_service);
    } catch (e) {
      dev.log('Voice processing failed: $e', name: 'VoiceInputSheet');
      if (!mounted) return;
      _showErrorState(context.l10n.voice_ai_error);
    } finally {
      _isStopping = false;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Normalize dB amplitude (range -160..0) to 0.0..1.0 for VoiceWaveBars.
  double _normalizeAmplitude(double dB) => ((dB + 160) / 160).clamp(0.0, 1.0);

  /// Map internal [_VoiceState] to [VoiceWaveState] for the wave bars widget.
  VoiceWaveState get _voiceWaveState => switch (_state) {
        _VoiceState.idle => VoiceWaveState.idle,
        _VoiceState.recording => VoiceWaveState.recording,
        _VoiceState.processing => VoiceWaveState.processing,
        _VoiceState.error => VoiceWaveState.error,
      };

  /// Transition to error state and display the given message in the overlay.
  void _showErrorState(String message) {
    if (!mounted) return;
    setState(() {
      _state = _VoiceState.error;
      _errorMessage = message;
    });
  }

  /// Close the overlay, stopping recording if active.
  Future<void> _close() async {
    if (_state == _VoiceState.recording) {
      _durationTimer?.cancel();
      _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;
      await _recorder.stop();
    }
    if (_state == _VoiceState.processing) {
      _cancelled = true;
    }
    if (!mounted) return;
    context.pop();
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
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Mic button handlers ────────────────────────────────────────────────

  void _onMicTap() {
    if (_state == _VoiceState.idle) {
      _startRecording();
    } else if (_state == _VoiceState.recording) {
      _stopAndProcess();
    }
  }

  void _onMicLongPressStart() {
    if (_state == _VoiceState.idle) {
      _startRecording();
    }
  }

  void _onMicLongPressEnd() {
    if (_state == _VoiceState.recording) {
      _stopAndProcess();
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Align(
      alignment: Alignment.bottomCenter,
      child: GlassCard(
        tier: GlassTier.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.borderRadiusLg),
        ),
        padding: EdgeInsets.zero,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight * AppSizes.voiceOverlayMinHeight,
            maxHeight: screenHeight * AppSizes.voiceOverlayMaxHeight,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
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
                  const DragHandle(),

                  // -- Close button (top-right) --
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: IconButton(
                      icon: const Icon(AppIcons.close, size: AppSizes.iconSm),
                      onPressed: _close,
                      visualDensity: VisualDensity.compact,
                      tooltip: context.l10n.common_close,
                    ),
                  ),

                  const Spacer(),

                  // -- Mic button (glassmorphic, circular) --
                  _buildMicButton(cs, theme),
                  const SizedBox(height: AppSizes.lg),

                  // -- Voice wave bars --
                  VoiceWaveBars(
                    state: _voiceWaveState,
                    amplitude: _currentAmplitude,
                  ),
                  const SizedBox(height: AppSizes.md),

                  // -- Duration badge --
                  if (_state == _VoiceState.recording)
                    GlassCard(
                      tier: GlassTier.inset,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.xs,
                      ),
                      borderRadius:
                          BorderRadius.circular(AppSizes.borderRadiusFull),
                      child: Text(
                        _formatDuration(_recordingSeconds),
                        style: context.textStyles.headlineSmall?.copyWith(
                          color: cs.primary,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  if (_state != _VoiceState.recording)
                    // Reserve space when not recording to keep layout stable.
                    const SizedBox(height: AppSizes.xl),

                  const SizedBox(height: AppSizes.sm),

                  // -- Status text --
                  Text(
                    _statusText(context),
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: _state == _VoiceState.error
                          ? cs.error
                          : cs.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // -- Action buttons --
                  _buildActionButtons(cs),

                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMicButton(ColorScheme cs, dynamic theme) {
    final micColor = switch (_state) {
      _VoiceState.recording => cs.primary,
      _VoiceState.error => cs.error,
      _ => cs.primaryContainer,
    };
    final micIconColor = switch (_state) {
      _VoiceState.recording => cs.onPrimary,
      _VoiceState.error => cs.onError,
      _ => cs.onPrimaryContainer,
    };

    final isInteractive =
        _state == _VoiceState.idle || _state == _VoiceState.recording;

    return Semantics(
      button: true,
      label: _state == _VoiceState.idle
          ? context.l10n.voice_tap_to_start
          : _state == _VoiceState.recording
              ? context.l10n.common_done
              : null,
      child: GestureDetector(
        onTap: isInteractive ? _onMicTap : null,
        onLongPressStart: isInteractive ? (_) => _onMicLongPressStart() : null,
        onLongPressEnd: isInteractive ? (_) => _onMicLongPressEnd() : null,
        child: AnimatedContainer(
          duration: AppDurations.animQuick,
          width: AppSizes.voiceMicSize,
          height: AppSizes.voiceMicSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: micColor,
            boxShadow: _state == _VoiceState.recording
                ? [
                    BoxShadow(
                      color:
                          cs.primary.withValues(alpha: AppSizes.opacityLight4),
                      blurRadius: AppSizes.xl,
                      spreadRadius: AppSizes.xs,
                    ),
                  ]
                : null,
            border: Border.all(
              color: context.appTheme.glassCardBorder,
              width: AppSizes.glassBorderWidthSubtle,
            ),
          ),
          child: Icon(
            _state == _VoiceState.error ? AppIcons.close : AppIcons.mic,
            size: AppSizes.voiceMicIconSize,
            color: micIconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme cs) {
    return switch (_state) {
      _VoiceState.idle => const SizedBox.shrink(),
      _VoiceState.recording => FilledButton.icon(
          onPressed: _stopAndProcess,
          icon: const Icon(AppIcons.check, size: AppSizes.iconSm2),
          label: Text(context.l10n.common_done),
        ),
      _VoiceState.processing => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: AppSizes.spinnerSize,
              height: AppSizes.spinnerSize,
              child: CircularProgressIndicator(
                strokeWidth: AppSizes.spinnerStrokeWidth,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: AppSizes.md),
            TextButton(
              onPressed: () {
                _cancelled = true;
                context.pop();
              },
              child: Text(context.l10n.common_cancel),
            ),
          ],
        ),
      _VoiceState.error => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _close,
              child: Text(context.l10n.common_cancel),
            ),
            const SizedBox(width: AppSizes.md),
            FilledButton(
              onPressed: () {
                setState(() {
                  _isMicPermissionError = false;
                  _errorMessage = null;
                  _state = _VoiceState.idle;
                });
              },
              child: Text(context.l10n.voice_retry),
            ),
          ],
        ),
    };
  }

  String _statusText(BuildContext context) {
    if (_state == _VoiceState.error) {
      if (_isMicPermissionError) return context.l10n.permission_mic_body;
      return _errorMessage ?? context.l10n.voice_error_no_service;
    }
    return switch (_state) {
      _VoiceState.idle => context.l10n.voice_tap_to_start,
      _VoiceState.recording => context.l10n.voice_listening,
      _VoiceState.processing => context.l10n.voice_ai_parsing,
      _VoiceState.error => context.l10n.voice_error_no_service,
    };
  }
}
