import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme_extension.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/services/glass_config_service.dart';

/// Data for a single speed-dial action button.
class _DialAction {
  const _DialAction({
    required this.icon,
    required this.labelKey,
    required this.color,
  });

  final IconData icon;
  final String Function(BuildContext) labelKey;
  final Color Function(BuildContext) color;
}

/// Speed-dial FAB with 3 vertically stacked glass action buttons.
///
/// - **Tap**: expand/collapse the action buttons
/// - **Tap action**: navigate + collapse
/// - Frosted scrim overlay when expanded
/// - FAB rotates + → × when expanded
///
/// **AOT safety**: Action buttons are only added to the widget tree when
/// expanded or animating. No [Opacity] widget, no [Material] with
/// elevation > 0 on action buttons.
class SpeedDialFab extends StatefulWidget {
  const SpeedDialFab({
    super.key,
    required this.onExpense,
    required this.onIncome,
    required this.onVoice,
  });

  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final VoidCallback onVoice;

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<CurvedAnimation> _staggerAnimations;

  bool _isExpanded = false;

  /// Whether action buttons + scrim are in the widget tree.
  /// True when expanded; stays true during close animation so buttons
  /// animate out, then flips false on [AnimationStatus.dismissed].
  bool _showOverlay = false;

  late final List<_DialAction> _actions;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.fabExpand,
    );
    _controller.addStatusListener(_onAnimationStatus);

    // Staggered intervals: each button starts slightly later.
    _staggerAnimations = List.generate(3, (i) {
      final start = i * 0.15; // 0.0, 0.15, 0.30
      final end = (start + 0.7).clamp(0.0, 1.0); // 0.7, 0.85, 1.0
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutBack),
        reverseCurve: Interval(start, end, curve: Curves.easeInCubic),
      );
    });

    _actions = [
      _DialAction(
        icon: AppIcons.expense,
        labelKey: (ctx) => ctx.l10n.fab_expense,
        color: (ctx) => ctx.appTheme.expenseColor,
      ),
      _DialAction(
        icon: AppIcons.income,
        labelKey: (ctx) => ctx.l10n.fab_income,
        color: (ctx) => ctx.appTheme.incomeColor,
      ),
      _DialAction(
        icon: AppIcons.mic,
        labelKey: (ctx) => ctx.l10n.fab_voice,
        color: (ctx) => ctx.colors.primary,
      ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect reduceMotion accessibility setting.
    final newDuration =
        context.reduceMotion ? Duration.zero : AppDurations.fabExpand;
    if (_controller.duration != newDuration && !_controller.isAnimating) {
      _controller.duration = newDuration;
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    for (final anim in _staggerAnimations) {
      anim.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && _showOverlay) {
      setState(() => _showOverlay = false);
    }
  }

  void _toggle() {
    if (_isExpanded) {
      _collapse();
    } else {
      _expand();
    }
  }

  void _expand() {
    if (_isExpanded) return;
    setState(() {
      _isExpanded = true;
      _showOverlay = true;
    });
    _controller.forward();
    HapticFeedback.mediumImpact();
  }

  void _collapse({int? selectedIndex}) {
    if (!_isExpanded) return;
    setState(() => _isExpanded = false);
    _controller.reverse().then((_) {
      if (selectedIndex != null && selectedIndex >= 0 && mounted) {
        HapticFeedback.heavyImpact();
        switch (selectedIndex) {
          case 0:
            widget.onExpense();
          case 1:
            widget.onIncome();
          case 2:
            widget.onVoice();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final theme = context.appTheme;
    final useBlur = GlassConfig.shouldBlur(context);

    // Total height needed: FAB + gap + (3 buttons × height + 2 gaps).
    const totalButtonsHeight = 3 * AppSizes.speedDialButtonHeight +
        2 * AppSizes.speedDialSpacing +
        AppSizes.speedDialOffset;
    const totalHeight = AppSizes.fabSize + totalButtonsHeight;

    return SizedBox(
      width: AppSizes.speedDialContainerWidth,
      height: totalHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Scrim + action buttons — only in tree when expanded/animating.
          if (_showOverlay) ...[
            // Full-screen frosted scrim for tap-to-dismiss.
            Positioned.fill(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _collapse,
                  child: RepaintBoundary(
                    child: useBlur
                        ? ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                sigmaX: AppSizes.glassBlurBackground,
                                sigmaY: AppSizes.glassBlurBackground,
                              ),
                              child: ColoredBox(
                                color: cs.surface.withValues(
                                  alpha: AppSizes.opacityLight4,
                                ),
                                child: SizedBox(
                                  width: MediaQuery.sizeOf(context).width,
                                  height: MediaQuery.sizeOf(context).height,
                                ),
                              ),
                            ),
                          )
                        : ColoredBox(
                            color: cs.scrim.withValues(
                              alpha: AppSizes.opacityLight4,
                            ),
                            child: SizedBox(
                              width: MediaQuery.sizeOf(context).width,
                              height: MediaQuery.sizeOf(context).height,
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // Action buttons — staggered vertically above FAB.
            for (int i = 0; i < _actions.length; i++)
              _buildActionButton(i, cs, theme),
          ],

          // Main FAB — always in tree.
          Positioned(
            bottom: 0,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _controller.value * AppSizes.fabRotationAngle,
                  child: child,
                );
              },
              child: FloatingActionButton(
                heroTag: 'nav_fab',
                onPressed: _toggle,
                elevation: AppSizes.elevationHigh,
                child: const Icon(AppIcons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    int index,
    ColorScheme cs,
    AppThemeExtension theme,
  ) {
    final action = _actions[index];
    final animation = _staggerAnimations[index];
    final accentColor = action.color(context);

    // Vertical offset from bottom: FAB height + gap + stacked buttons below.
    final bottomOffset = AppSizes.fabSize +
        AppSizes.speedDialOffset +
        index * (AppSizes.speedDialButtonHeight + AppSizes.speedDialSpacing);

    return Positioned(
      bottom: bottomOffset,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          final value = animation.value;
          return Transform.translate(
            offset: Offset(0, (1 - value) * AppSizes.speedDialSlideOffset),
            child: Transform.scale(
              scale: value,
              child: child,
            ),
          );
        },
        child: Semantics(
          label: action.labelKey(context),
          button: true,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () => _collapse(selectedIndex: index),
              borderRadius: BorderRadius.circular(AppSizes.speedDialButtonRadius),
              child: Container(
                height: AppSizes.speedDialButtonHeight,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.md,
                ),
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    accentColor.withValues(alpha: AppSizes.opacityLight),
                    cs.surface,
                  ),
                  borderRadius:
                      BorderRadius.circular(AppSizes.speedDialButtonRadius),
                  border: Border.all(
                    color: accentColor.withValues(alpha: AppSizes.opacityLight3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      action.icon,
                      size: AppSizes.speedDialIconSize,
                      color: accentColor,
                    ),
                    const SizedBox(width: AppSizes.sm),
                    Text(
                      action.labelKey(context),
                      style: context.textStyles.labelSmall?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
