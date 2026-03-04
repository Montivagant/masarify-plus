import 'dart:developer' as dev;

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/ai_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';

/// Voice input states.
enum _VoiceState { idle, listening, processing, error }

/// Bottom sheet for AI voice input using device STT.
///
/// Uses [SpeechToText] for live on-device transcription, then sends the
/// transcript to the AI voice parser (OpenRouter) for structured parsing.
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
  final _stt = SpeechToText();

  _VoiceState _state = _VoiceState.idle;
  String _transcript = '';
  bool _sttAvailable = false;

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    try {
      _sttAvailable = await _stt.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (mounted && _state == _VoiceState.listening) {
              setState(() => _state = _VoiceState.idle);
            }
          }
        },
        onError: (error) {
          dev.log('STT error: ${error.errorMsg}', name: 'VoiceInputSheet');
          if (mounted) {
            setState(() => _state = _VoiceState.error);
          }
        },
      );
      if (!mounted) return;
      if (!_sttAvailable) {
        setState(() => _state = _VoiceState.error);
      }
    } catch (e) {
      dev.log('STT init failed: $e', name: 'VoiceInputSheet');
      if (mounted) setState(() => _state = _VoiceState.error);
    }
  }

  Future<void> _startListening() async {
    if (!_sttAvailable) return;

    _transcript = '';
    final localeId = await _getLocaleId();
    if (!mounted) return;
    _stt.listen(
      onResult: (result) {
        if (!mounted) return;
        setState(() {
          _transcript = result.recognizedWords;
        });
      },
      localeId: localeId,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
    );
    setState(() => _state = _VoiceState.listening);
  }

  Future<void> _stopAndProcess() async {
    await _stt.stop();
    if (!mounted) return;

    if (_transcript.trim().isEmpty) {
      _popAndShowInfo(context.l10n.voice_no_results);
      return;
    }

    setState(() => _state = _VoiceState.processing);

    // Check connectivity before calling AI
    final online = ref.read(isOnlineProvider).valueOrNull ?? true;
    if (!online) {
      if (!mounted) return;
      _popAndShowInfo(context.l10n.voice_offline_message);
      return;
    }

    try {
      final parser = ref.read(aiVoiceParserProvider);
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];
      final goals = ref.read(activeGoalsProvider).valueOrNull ?? [];
      final modelPref =
          ref.read(aiModelPreferenceProvider).valueOrNull ?? 'auto';

      final result = await parser.parse(
        transcript: _transcript,
        categories: categories,
        goals: goals,
        modelPreference: modelPref,
      );

      if (!mounted) return;

      if (result.drafts.isEmpty) {
        _popAndShowInfo(
          result.errorMessage ?? context.l10n.voice_ai_error,
        );
        return;
      }

      // Capture router before popping — the bottom sheet's context becomes
      // invalid after pop, so we need a reference that survives dismissal.
      final router = GoRouter.of(context);
      context.pop(); // Close the bottom sheet first
      router.push(
        AppRoutes.voiceConfirm,
        extra: result.drafts,
      );
    } catch (e) {
      dev.log('AI parsing failed: $e', name: 'VoiceInputSheet');
      if (!mounted) return;
      _popAndShowInfo(context.l10n.voice_ai_error);
    }
  }

  /// Returns the best STT locale ID, preferring the app language.
  /// Falls back to device-supported locales if the preferred one isn't available.
  Future<String> _getLocaleId() async {
    final langCode = context.languageCode;
    final preferred = langCode == 'ar' ? 'ar_EG' : 'en_US';

    // Check if the device actually supports the preferred locale.
    final locales = await _stt.locales();
    final supported = locales.map((l) => l.localeId).toSet();
    if (supported.contains(preferred)) return preferred;

    // Fallback: find any locale matching the language code.
    final fallback = locales.firstWhere(
      (l) => l.localeId.startsWith(langCode),
      orElse: () => locales.first,
    );
    return fallback.localeId;
  }

  void _popAndShowInfo(String message) {
    if (!mounted) return;
    SnackHelper.showInfo(context, message);
    context.pop();
  }

  @override
  void dispose() {
    _stt.stop();
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
              onPressed: () {
                _stt.stop();
                context.pop();
              },
              visualDensity: VisualDensity.compact,
              tooltip: context.l10n.common_close,
            ),
          ),

          // -- Mic button with avatar_glow pulse --
          Builder(builder: (context) {
            final reduceMotion = MediaQuery.of(context).disableAnimations;
            return Semantics(
              button: true,
              label: _state == _VoiceState.idle
                  ? context.l10n.voice_tap_to_start
                  : _state == _VoiceState.listening
                      ? context.l10n.common_done
                      : null,
              child: GestureDetector(
                onTap: _state == _VoiceState.idle
                    ? _startListening
                    : _state == _VoiceState.listening
                        ? _stopAndProcess
                        : null,
                child: AvatarGlow(
                  animate:
                      !reduceMotion && _state == _VoiceState.listening,
                  glowRadiusFactor: 0.3,
                  glowColor: cs.primary,
                  child: Container(
                    width: AppSizes.voiceMicSize,
                    height: AppSizes.voiceMicSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _state == _VoiceState.listening
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
                      color: _state == _VoiceState.listening
                          ? cs.onPrimary
                          : _state == _VoiceState.error
                              ? cs.onError
                              : cs.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            );
          },),
          const SizedBox(height: AppSizes.md),

          // -- Status text --
          Text(
            _statusText(context),
            style: context.textStyles.bodyMedium?.copyWith(color: cs.outline),
          ),

          // -- Live transcript --
          if (_state == _VoiceState.listening &&
              _transcript.isNotEmpty) ...[
            const SizedBox(height: AppSizes.sm),
            Container(
              constraints: const BoxConstraints(maxHeight: 80),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest
                    .withValues(alpha: AppSizes.opacityLight2),
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: Text(
                  _transcript,
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: cs.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSizes.lg),

          // -- Action buttons --
          if (_state == _VoiceState.listening)
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
                    _initStt();
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
      _VoiceState.listening => context.l10n.voice_listening,
      _VoiceState.processing => context.l10n.voice_ai_parsing,
      _VoiceState.error => context.l10n.voice_error_no_service,
    };
  }
}
