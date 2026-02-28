import 'dart:async';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/ai_config.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/ai/ai_voice_parser.dart';
import '../../../../core/services/voice_input_service.dart';
import '../../../../core/utils/voice_transaction_parser.dart';
import '../../../../shared/providers/ai_provider.dart';
import '../../../../shared/providers/category_provider.dart';
import '../../../../shared/providers/goal_provider.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';

/// Bottom sheet that handles voice recording, live transcript, and parsing.
///
/// Shows a pulsing mic icon, live transcript text, and transitions to
/// VoiceConfirmScreen when done.
class VoiceInputSheet extends ConsumerStatefulWidget {
  const VoiceInputSheet({super.key});

  /// Show the voice input sheet as a modal bottom sheet.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
  final _service = VoiceInputService.instance;
  final _parser = const VoiceTransactionParser();

  VoiceState _state = VoiceState.idle;
  String _transcript = '';
  bool _serviceReady = false;
  bool _resultHandled = false;
  bool _aiParsing = false;
  bool _aiCancelled = false;

  StreamSubscription<VoiceState>? _stateSub;
  StreamSubscription<String>? _transcriptSub;

  @override
  void initState() {
    super.initState();

    _stateSub = _service.stateStream.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);

      if (state == VoiceState.processing) {
        _handleProcessingState();
      }
    });

    _transcriptSub = _service.transcriptStream.listen((text) {
      if (!mounted) return;
      setState(() => _transcript = text);
    });

    // Initialize but DON'T auto-start — wait for user tap
    _initService();
  }

  Future<void> _initService() async {
    final available = await _service.initialize();
    if (!mounted) return;

    setState(() {
      _serviceReady = available;
      if (!available) _state = VoiceState.error;
    });
  }

  Future<void> _startListening() async {
    if (!_serviceReady) return;
    _resultHandled = false;
    await _service.startListening();
  }

  Future<void> _retry() async {
    setState(() {
      _state = VoiceState.idle;
      _transcript = '';
    });
    _service.resetInitialization();
    final available = await _service.initialize();
    if (!mounted) return;
    if (available) {
      setState(() => _serviceReady = true);
    } else {
      setState(() => _state = VoiceState.error);
    }
  }

  Future<void> _handleProcessingState() async {
    if (_resultHandled) return;

    if (_transcript.trim().isEmpty) {
      _resultHandled = true;
      _popAndShowInfo(context.l10n.voice_no_results);
      return;
    }

    _resultHandled = true;

    if (AiConfig.hasApiKey) {
      setState(() {
        _aiParsing = true;
        _aiCancelled = false;
      });
      final categories = ref.read(categoriesProvider).valueOrNull ?? [];
      final goals = ref.read(activeGoalsProvider).valueOrNull ?? [];
      final modelPref =
          ref.read(aiModelPreferenceProvider).valueOrNull ?? 'auto';
      // H6 fix: wrap with timeout so the entire chain doesn't exceed 20s
      final result = await ref.read(aiVoiceParserProvider).parse(
            transcript: _transcript,
            categories: categories,
            goals: goals,
            modelPreference: modelPref,
          ).timeout(
            const Duration(seconds: 20),
            onTimeout: () => const AiVoiceParseResult(
              drafts: [],
              usedAi: false,
              errorMessage: 'AI parsing timed out',
            ),
          );
      if (!mounted || _aiCancelled) return;
      setState(() => _aiParsing = false);

      // WS-39: if AI was attempted but failed, show error instead of
      // silently falling back to rule-based parsing.
      if (!result.usedAi && result.errorMessage != null) {
        _popAndShowInfo(context.l10n.voice_ai_error);
        return;
      }

      if (result.drafts.isEmpty) {
        _popAndShowInfo(context.l10n.voice_no_results);
        return;
      }
      _navigateToConfirm(result.drafts);
    } else {
      final drafts = _parser.parseAll(_transcript);
      if (drafts.isEmpty) {
        _popAndShowInfo(context.l10n.voice_no_results);
        return;
      }
      _navigateToConfirm(drafts);
    }
  }

  void _navigateToConfirm(List<VoiceTransactionDraft> drafts) {
    // R5-C2 fix: mounted check + postFrameCallback to avoid pop→push race
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.push(AppRoutes.voiceConfirm, extra: drafts);
    });
  }

  /// Close the sheet and show an info snack on the underlying scaffold.
  void _popAndShowInfo(String message) {
    // Capture scaffold messenger before popping (context will be unmounted).
    SnackHelper.showInfo(context, message);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _transcriptSub?.cancel();
    // Don't dispose singleton _service — it lives for the app lifecycle.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
              borderRadius: BorderRadius.circular(AppSizes.dragHandleHeight / 2),
            ),
          ),
          const SizedBox(height: AppSizes.sm),

          // ── Close button ─────────────────────────────────────
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: IconButton(
              icon: const Icon(AppIcons.close, size: AppSizes.iconSm),
              onPressed: () => Navigator.of(context).pop(),
              visualDensity: VisualDensity.compact,
            ),
          ),

          // ── Mic button with avatar_glow pulse ─────────────────
          if (!_serviceReady && _state != VoiceState.error)
            const SizedBox(
              width: 72,
              height: 72,
              child: Center(child: CircularProgressIndicator()),
            )
          else
          Builder(builder: (context) {
            final reduceMotion = MediaQuery.of(context).disableAnimations;
            return GestureDetector(
              onTap: _state == VoiceState.idle ? _startListening : null,
              child: AvatarGlow(
                animate: !reduceMotion && _state == VoiceState.listening,
                glowRadiusFactor: 0.3,
                glowColor: cs.primary,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _state == VoiceState.listening
                        ? cs.primary
                        : _state == VoiceState.error
                            ? cs.error
                            : cs.primaryContainer,
                  ),
                  child: Icon(
                    _state == VoiceState.error ? AppIcons.close : AppIcons.mic,
                    size: AppSizes.iconLg,
                    color: _state == VoiceState.listening
                        ? cs.onPrimary
                        : _state == VoiceState.error
                            ? cs.onError
                            : cs.onPrimaryContainer,
                  ),
                ),
              ),
            );
          },),
          const SizedBox(height: AppSizes.md),

          // ── Status text ──────────────────────────────────────
          Text(
            _statusText(context),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.outline,
                ),
          ),
          const SizedBox(height: AppSizes.md),

          // ── Live transcript ──────────────────────────────────
          if (_transcript.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: AppSizes.opacityLight5),
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusSm),
              ),
              child: Text(
                _transcript,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: AppSizes.lg),

          // ── Action buttons ───────────────────────────────────
          if (_state == VoiceState.listening)
            FilledButton.icon(
              onPressed: () => _service.stopListening(),
              icon: const Icon(AppIcons.close, size: AppSizes.iconSm2),
              label: Text(context.l10n.common_done),
            )
          else if (_state == VoiceState.error)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.common_close),
                ),
                const SizedBox(width: AppSizes.md),
                FilledButton(
                  onPressed: _retry,
                  child: Text(context.l10n.voice_retry),
                ),
              ],
            )
          // H6 fix: show cancel button during AI parsing
          else if (_state == VoiceState.processing && _aiParsing)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: AppSizes.md),
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _aiCancelled = true;
                      _aiParsing = false;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(context.l10n.common_cancel),
                ),
              ],
            )
          else if (_state == VoiceState.processing)
            const CircularProgressIndicator(),
        ],
      ),
    );
  }

  String _statusText(BuildContext context) {
    if (_aiParsing) return context.l10n.voice_ai_parsing;

    return switch (_state) {
      VoiceState.idle => context.l10n.voice_tap_to_start,
      // WS-2: show resolved locale so user can verify Arabic is detected.
      VoiceState.listening => _service.resolvedLocale != null
          ? '${context.l10n.voice_listening} (${_service.resolvedLocale})'
          : context.l10n.voice_listening,
      VoiceState.processing => context.l10n.voice_processing,
      VoiceState.error => switch (_service.lastError) {
          VoiceError.noService => context.l10n.voice_error_no_service,
          VoiceError.noLocale => context.l10n.voice_error_no_locale,
          VoiceError.speechError => context.l10n.voice_error_speech,
          VoiceError.none => context.l10n.voice_unavailable,
        },
    };
  }
}
