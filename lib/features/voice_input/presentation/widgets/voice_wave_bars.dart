import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';

/// Visual states for the voice wave bar equalizer.
enum VoiceWaveState { idle, recording, processing, error }

/// Animated equalizer bars for the voice recording feature.
///
/// Renders [AppSizes.voiceBarCount] vertical bars whose heights respond
/// to the current [amplitude] (0.0 – 1.0). Center bars react more
/// strongly while edge bars are damped, creating an organic wave shape.
class VoiceWaveBars extends StatefulWidget {
  const VoiceWaveBars({
    super.key,
    required this.state,
    this.amplitude = 0.0,
  });

  final VoiceWaveState state;

  /// Normalized amplitude 0.0 – 1.0.
  final double amplitude;

  @override
  State<VoiceWaveBars> createState() => _VoiceWaveBarsState();
}

class _VoiceWaveBarsState extends State<VoiceWaveBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  late final List<double> _barHeights;
  final math.Random _random = math.Random();
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _barHeights = List<double>.filled(
      AppSizes.voiceBarCount,
      AppSizes.voiceBarMinHeight,
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: AppDurations.voiceShimmer,
    );
    _syncState();
  }

  @override
  void didUpdateWidget(VoiceWaveBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _syncState();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _shimmerController.dispose();
    super.dispose();
  }

  // ── State synchronisation ────────────────────────────────────────────

  void _syncState() {
    _updateTimer?.cancel();
    _updateTimer = null;

    switch (widget.state) {
      case VoiceWaveState.idle:
      case VoiceWaveState.error:
        _shimmerController.stop();
        _resetBars();

      case VoiceWaveState.recording:
        _shimmerController.stop();
        _startRecordingUpdates();

      case VoiceWaveState.processing:
        _resetBars();
        if (!context.reduceMotion) {
          _shimmerController.repeat();
        }
    }
  }

  void _resetBars() {
    setState(() {
      for (var i = 0; i < _barHeights.length; i++) {
        _barHeights[i] = AppSizes.voiceBarMinHeight;
      }
    });
  }

  void _startRecordingUpdates() {
    _updateTimer = Timer.periodic(AppDurations.voiceBarUpdate, (_) {
      if (!mounted) return;
      _computeBarHeights();
    });
  }

  /// Compute bar heights from the current amplitude.
  ///
  /// Centre bars respond more strongly; edge bars are damped by 60 %.
  /// A small random factor (0.8 – 1.2) keeps the visual organic.
  void _computeBarHeights() {
    const count = AppSizes.voiceBarCount;
    const center = (count - 1) / 2.0;
    final amp = widget.amplitude.clamp(0.0, 1.0);
    const range = AppSizes.voiceBarMaxHeight - AppSizes.voiceBarMinHeight;

    setState(() {
      for (var i = 0; i < count; i++) {
        final distFromCenter = (i - center).abs() / center;
        final damping = 1.0 - distFromCenter * 0.6;
        final randomFactor = 0.8 + _random.nextDouble() * 0.4;
        _barHeights[i] =
            AppSizes.voiceBarMinHeight + range * amp * damping * randomFactor;
      }
    });
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final reduceMotion = context.reduceMotion;
    final colorScheme = Theme.of(context).colorScheme;

    // When the user prefers reduced motion, show a static representation.
    if (reduceMotion && widget.state == VoiceWaveState.recording) {
      const count = AppSizes.voiceBarCount;
      const center = (count - 1) / 2.0;
      final amp = widget.amplitude.clamp(0.0, 1.0);
      const range = AppSizes.voiceBarMaxHeight - AppSizes.voiceBarMinHeight;
      for (var i = 0; i < count; i++) {
        final distFromCenter = (i - center).abs() / center;
        final damping = 1.0 - distFromCenter * 0.6;
        _barHeights[i] = AppSizes.voiceBarMinHeight + range * amp * damping;
      }
    }

    final Color barColor;
    switch (widget.state) {
      case VoiceWaveState.error:
        barColor = colorScheme.error;
      case VoiceWaveState.idle:
        barColor = colorScheme.outlineVariant;
      case VoiceWaveState.recording:
      case VoiceWaveState.processing:
        barColor = colorScheme.primary;
    }

    return SizedBox(
      height: AppSizes.voiceWaveContainerHeight,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return CustomPaint(
            painter: _VoiceWaveBarsPainter(
              barHeights: _barHeights,
              barColor: barColor,
              shimmerProgress: widget.state == VoiceWaveState.processing
                  ? _shimmerController.value
                  : null,
              shimmerColor: colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}

// ── CustomPainter ──────────────────────────────────────────────────────

class _VoiceWaveBarsPainter extends CustomPainter {
  _VoiceWaveBarsPainter({
    required this.barHeights,
    required this.barColor,
    required this.shimmerProgress,
    required this.shimmerColor,
  });

  final List<double> barHeights;
  final Color barColor;

  /// When non-null the painter draws a shimmer gradient sweep.
  final double? shimmerProgress;
  final Color shimmerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final count = barHeights.length;
    const barWidth = AppSizes.voiceBarWidth;
    const gap = AppSizes.voiceBarGap;
    final totalBarsWidth = count * barWidth + (count - 1) * gap;
    final startX = (size.width - totalBarsWidth) / 2;
    final centerY = size.height / 2;
    const radius = Radius.circular(barWidth / 2);

    for (var i = 0; i < count; i++) {
      final x = startX + i * (barWidth + gap);
      final h = barHeights[i].clamp(
        AppSizes.voiceBarMinHeight,
        AppSizes.voiceBarMaxHeight,
      );
      final top = centerY - h / 2;

      Color color = barColor;

      // Apply shimmer gradient when processing.
      if (shimmerProgress != null) {
        final barFraction = i / (count - 1);
        // The shimmer band is ~30 % wide and sweeps left-to-right.
        final shimmerCenter = shimmerProgress!;
        final dist = (barFraction - shimmerCenter).abs();
        const shimmerWidth = 0.15;
        if (dist < shimmerWidth) {
          final t = 1.0 - (dist / shimmerWidth);
          color = Color.lerp(
            shimmerColor.withValues(alpha: AppSizes.opacityLight4),
            shimmerColor,
            t,
          )!;
        } else {
          color = shimmerColor.withValues(alpha: AppSizes.opacityLight4);
        }
      }

      final paint = Paint()..color = color;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, top, barWidth, h),
        radius,
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_VoiceWaveBarsPainter oldDelegate) {
    return oldDelegate.barColor != barColor ||
        oldDelegate.shimmerProgress != shimmerProgress ||
        !_listEquals(oldDelegate.barHeights, barHeights);
  }

  static bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
