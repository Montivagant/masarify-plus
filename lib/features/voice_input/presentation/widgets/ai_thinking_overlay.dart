import 'dart:async';
import 'dart:developer' as dev;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

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

/// Centered glassmorphic overlay shown during Gemini AI processing.
///
/// Displays a Lottie robot thinking animation and typewriter-cycling
/// funny messages while waiting for Gemini to parse the audio.
class AiThinkingOverlay extends ConsumerStatefulWidget {
  const AiThinkingOverlay({
    super.key,
    required this.audioBytes,
    required this.onDismiss,
  });

  /// Raw WAV audio bytes to send to Gemini.
  final Uint8List audioBytes;

  /// Called when overlay should be removed (success, cancel, or error).
  final VoidCallback onDismiss;

  @override
  ConsumerState<AiThinkingOverlay> createState() => _AiThinkingOverlayState();
}

class _AiThinkingOverlayState extends ConsumerState<AiThinkingOverlay>
    with TickerProviderStateMixin {
  bool _cancelled = false;
  String? _errorMessage;
  bool _hasError = false;

  // ── Typewriter state ────────────────────────────────────────────────────
  final _random = Random();
  late List<String> _messages;
  int _currentMessageIndex = 0;
  String _displayedText = '';
  int _charIndex = 0;
  Timer? _typewriterTimer;
  Timer? _holdTimer;
  bool _isTyping = true;
  bool _typewriterStarted = false;

  // ── Entrance animation ─────────────────────────────────────────────────
  late final AnimationController _entranceController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: AppDurations.voiceThinkingFadeIn,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _entranceController.forward();
    _startGeminiCall();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Parse l10n messages — split on semicolons.
    _messages = context.l10n.voice_ai_thinking_messages.split(';');
    if (_messages.isNotEmpty && !_typewriterStarted) {
      _typewriterStarted = true;
      _currentMessageIndex = _random.nextInt(_messages.length);
      _startTypewriter();
    }
  }

  @override
  void dispose() {
    _typewriterTimer?.cancel();
    _holdTimer?.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  // ── Typewriter ────────────────────────────────────────���─────────────────

  void _startTypewriter() {
    final reduce = context.reduceMotion;
    if (reduce) {
      // Show full message immediately, cycle every hold duration.
      setState(() {
        _displayedText = _messages[_currentMessageIndex];
        _isTyping = false;
      });
      _holdTimer = Timer(AppDurations.voiceTypewriterHold, _nextMessage);
      return;
    }

    _charIndex = 0;
    _isTyping = true;
    _displayedText = '';
    final message = _messages[_currentMessageIndex];

    _typewriterTimer = Timer.periodic(AppDurations.voiceTypewriterChar, (_) {
      if (!mounted || _cancelled) {
        _typewriterTimer?.cancel();
        return;
      }

      if (_charIndex < message.length) {
        setState(() {
          _charIndex++;
          _displayedText = message.substring(0, _charIndex);
        });
      } else {
        _typewriterTimer?.cancel();
        setState(() => _isTyping = false);
        // Hold the fully typed message, then cycle.
        _holdTimer = Timer(AppDurations.voiceTypewriterHold, _nextMessage);
      }
    });
  }

  void _nextMessage() {
    if (!mounted || _cancelled) return;
    // Pick a different random message.
    int next;
    if (_messages.length > 1) {
      do {
        next = _random.nextInt(_messages.length);
      } while (next == _currentMessageIndex);
    } else {
      next = 0;
    }
    _currentMessageIndex = next;
    _startTypewriter();
  }

  // ─��� Gemini API call ──────────────────────────────────���──────────────────

  Future<void> _startGeminiCall() async {
    try {
      // Check connectivity before calling Gemini.
      final online = ref.read(isOnlineProvider).valueOrNull ?? false;
      dev.log(
        'Connectivity before Gemini call: $online',
        name: 'AiThinkingOverlay',
      );
      if (!online) {
        if (!mounted) return;
        _showError(context.l10n.voice_error_no_service);
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
        audioBytes: widget.audioBytes,
        mimeType: 'audio/wav',
        categories: categories,
        goals: goals,
        walletNames: walletNames,
      );

      if (!mounted || _cancelled) return;

      dev.log(
        'Gemini result: ${drafts.length} drafts',
        name: 'AiThinkingOverlay',
      );

      if (drafts.isEmpty) {
        _showError(context.l10n.voice_no_results);
        return;
      }

      // Navigate to confirm screen then dismiss overlay.
      context.push(AppRoutes.voiceConfirm, extra: drafts);
      widget.onDismiss();
    } on GeminiAudioException catch (e) {
      dev.log(
        'Gemini error: ${e.statusCode} — ${e.message}'
        '${e.isRateLimit ? " (RATE LIMITED)" : ""}'
        '${e.isUnauthorized ? " (AUTH FAILED)" : ""}'
        '${e.isServerError ? " (SERVER ERROR)" : ""}',
        name: 'AiThinkingOverlay',
      );
      if (!mounted) return;
      _showError(context.l10n.voice_ai_error);
    } on TimeoutException {
      dev.log('Gemini request timed out', name: 'AiThinkingOverlay');
      if (!mounted) return;
      _showError(context.l10n.voice_ai_error);
    } on SocketException {
      dev.log('Network lost during Gemini call', name: 'AiThinkingOverlay');
      if (!mounted) return;
      _showError(context.l10n.voice_error_no_service);
    } catch (e) {
      dev.log('Voice processing failed: $e', name: 'AiThinkingOverlay');
      if (!mounted) return;
      _showError(context.l10n.voice_ai_error);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
    _typewriterTimer?.cancel();
    _holdTimer?.cancel();
    Future.delayed(AppDurations.voicePillErrorDismiss, () {
      if (mounted) widget.onDismiss();
    });
  }

  void _cancel() {
    _cancelled = true;
    _typewriterTimer?.cancel();
    _holdTimer?.cancel();
    widget.onDismiss();
  }

  // ── UI ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizes.aiThinkingMaxWidth,
            ),
            child: GlassCard(
              tier: GlassTier.background,
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.lg,
                vertical: AppSizes.lg,
              ),
              child: _hasError ? _buildError() : _buildThinking(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThinking() {
    final cs = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Robot animation
        SizedBox(
          width: AppSizes.aiThinkingRobotSize,
          height: AppSizes.aiThinkingRobotSize,
          child: context.reduceMotion
              ? Lottie.asset(
                  'assets/animations/ai_thinking.json',
                  animate: false,
                )
              : Lottie.asset(
                  'assets/animations/ai_thinking.json',
                  repeat: true,
                ),
        ),
        const SizedBox(height: AppSizes.md),

        // Typewriter text
        SizedBox(
          height: AppSizes.aiThinkingTextHeight,
          child: Center(
            child: AnimatedSwitcher(
              duration: AppDurations.animQuick,
              child: Text(
                _displayedText,
                key: ValueKey('$_currentMessageIndex-${_displayedText.length}'),
                style: context.textStyles.bodyMedium?.copyWith(
                  color: cs.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.sm),

        // Typing dots (visible while typewriter is active)
        SizedBox(
          height: AppSizes.dotSm + AppSizes.xs,
          child: _isTyping ? _TypingDots(color: cs.primary) : const SizedBox(),
        ),
        const SizedBox(height: AppSizes.md),

        // Cancel button
        TextButton(
          onPressed: _cancel,
          child: Text(context.l10n.voice_ai_cancel),
        ),
      ],
    );
  }

  Widget _buildError() {
    final cs = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          AppIcons.errorCircle,
          size: AppSizes.iconLg,
          color: cs.error,
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          _errorMessage ?? context.l10n.voice_ai_error,
          style: context.textStyles.bodyMedium?.copyWith(color: cs.error),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TypingDots — Simplified 3-dot indicator reused from TypingIndicator pattern
// ─────────────────────────────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  const _TypingDots({required this.color});

  final Color color;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  static const _dotCount = 3;
  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _dotCount,
      (index) => AnimationController(
        vsync: this,
        duration: AppDurations.typingIndicator,
      ),
    );
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    for (var i = 0; i < _controllers.length; i++) {
      if (i > 0) {
        await Future<void>.delayed(AppDurations.animQuick);
        if (!mounted) return;
      }
      _controllers[i].repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_dotCount, (i) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxs),
          child: AnimatedBuilder(
            animation: _controllers[i],
            builder: (context, child) {
              final value = _controllers[i].value;
              return Container(
                width: AppSizes.dotSm,
                height: AppSizes.dotSm,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(
                    alpha:
                        AppSizes.opacityLight3 + AppSizes.opacityMedium * value,
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
