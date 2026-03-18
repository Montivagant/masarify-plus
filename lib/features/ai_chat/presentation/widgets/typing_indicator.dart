import 'package:flutter/material.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  static const _dotCount = 3;
  static const _duration = AppDurations.countUp;
  static const _staggerDelay = AppDurations.animQuick;

  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _dotCount,
      (index) => AnimationController(vsync: this, duration: _duration),
    );
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    for (var i = 0; i < _controllers.length; i++) {
      if (i > 0) {
        await Future<void>.delayed(_staggerDelay);
        if (!mounted) return;
      }
      _controllers[i].repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = context.colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_dotCount, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xxs),
          child: AnimatedBuilder(
            animation: _controllers[index],
            builder: (context, child) {
              final value = _controllers[index].value;
              return Container(
                width: AppSizes.dotSm,
                height: AppSizes.dotSm,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: baseColor.withValues(alpha: 0.3 + 0.5 * value),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
