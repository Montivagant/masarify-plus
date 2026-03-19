import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';

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

/// Speed-dial FAB with 2 action buttons arranged in a semi-circular arc.
///
/// - **Tap**: expand/collapse the action buttons
/// - **Tap action**: navigate + collapse
/// - Semi-transparent scrim overlay when expanded
/// - FAB rotates + -> x when expanded
/// - Buttons burst outward in an arc (radial expansion + scale)
/// - RTL-aware: Voice/Manual swap sides
///
/// ```
///    [Voice]    [Manual]    <- 45 deg left / right
///          [+]              <- FAB center
/// ```
class SpeedDialFab extends StatefulWidget {
  const SpeedDialFab({
    super.key,
    required this.onVoice,
    required this.onManual,
    this.tabIndex = 0,
  });

  final VoidCallback onVoice;
  final VoidCallback onManual;

  /// Current navigation tab index. When this changes, the FAB auto-collapses.
  final int tabIndex;

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<CurvedAnimation> _staggerAnimations;

  bool _isExpanded = false;

  /// Whether the FAB icon shows the close (x) rotation.
  /// True when expanded; stays true during close animation so the FAB
  /// rotation animates out, then flips false on [AnimationStatus.dismissed].
  bool _showOverlay = false;

  /// Full-screen overlay entry containing both the scrim AND the arc action
  /// buttons. Rendered via [Overlay] so everything sits above the Scaffold.
  OverlayEntry? _scrimEntry;

  /// Key attached to the main FAB button so we can compute its global
  /// position and place the arc buttons relative to it inside the overlay.
  final GlobalKey _fabKey = GlobalKey();

  late final List<_DialAction> _actions;

  /// Angles from vertical (12 o'clock), clockwise positive.
  /// Voice = -45deg (left), Manual = +45deg (right).
  static const double _angleSpread = math.pi / 4; // 45 degrees
  static final List<double> _angles = [
    -_angleSpread, // Voice: upper-left (45deg)
    _angleSpread, // Manual: upper-right (45deg)
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.fabExpand,
    );
    _controller.addStatusListener(_onAnimationStatus);
    _controller.addListener(_onAnimationTick);

    // Staggered intervals: each button starts slightly later.
    _staggerAnimations = List.generate(2, (i) {
      final start = i * 0.12; // 0.0, 0.12
      final end = (start + 0.76).clamp(0.0, 1.0); // 0.76, 0.88
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, end, curve: Curves.easeOutBack),
        reverseCurve: Interval(start, end, curve: Curves.easeInCubic),
      );
    });

    _actions = [
      _DialAction(
        icon: AppIcons.mic,
        labelKey: (ctx) => ctx.l10n.fab_voice,
        color: (ctx) => ctx.colors.primary,
      ),
      _DialAction(
        icon: AppIcons.edit,
        labelKey: (ctx) => ctx.l10n.fab_manual,
        color: (ctx) => ctx.colors.secondary,
      ),
    ];
  }

  @override
  void didUpdateWidget(covariant SpeedDialFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-collapse when navigating to a different tab.
    if (oldWidget.tabIndex != widget.tabIndex && _isExpanded) {
      _collapse();
    }
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
    _scrimEntry?.remove();
    _scrimEntry = null;
    _controller.removeListener(_onAnimationTick);
    _controller.removeStatusListener(_onAnimationStatus);
    for (final anim in _staggerAnimations) {
      anim.dispose();
    }
    _controller.dispose();
    super.dispose();
  }

  /// Force the [OverlayEntry] to rebuild every animation frame so the arc
  /// buttons animate smoothly inside the overlay.
  void _onAnimationTick() {
    _scrimEntry?.markNeedsBuild();
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

    final scrimColor = Theme.of(context).colorScheme.scrim.withValues(
          alpha: AppSizes.opacityLight4,
        );

    // Insert a full-screen overlay containing BOTH the scrim AND the arc
    // action buttons. This guarantees the buttons render above the scrim
    // and receive taps correctly.
    _scrimEntry = OverlayEntry(
      builder: (overlayContext) => _buildOverlayContent(
        overlayContext,
        scrimColor: scrimColor,
      ),
    );
    Overlay.of(context).insert(_scrimEntry!);

    _controller.forward();
    HapticFeedback.mediumImpact();
  }

  void _collapse({int? selectedIndex}) {
    if (!_isExpanded) return;
    setState(() => _isExpanded = false);
    _controller.reverse().then((_) {
      _scrimEntry?.remove();
      _scrimEntry = null;
      if (mounted) setState(() => _showOverlay = false);
      if (selectedIndex != null && selectedIndex >= 0 && mounted) {
        HapticFeedback.heavyImpact();
        switch (selectedIndex) {
          case 0:
            widget.onVoice();
          case 1:
            widget.onManual();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Action buttons are now rendered inside the OverlayEntry (see
    // _buildOverlayContent) so they sit above the scrim and receive taps.
    return SizedBox(
      width: AppSizes.speedDialArcWidth,
      height: AppSizes.speedDialArcHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
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
                key: _fabKey,
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

  /// Builds the full overlay content: a full-screen [Stack] with the scrim
  /// on the bottom layer and the 2 arc action buttons on top, positioned
  /// relative to the FAB's global coordinates.
  Widget _buildOverlayContent(
    BuildContext overlayContext, {
    required Color scrimColor,
  }) {
    // Resolve the FAB's global center position.
    final fabBox = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    // Fallback to screen center-bottom if the FAB hasn't laid out yet.
    final size = MediaQuery.sizeOf(context);
    final Offset fabCenter;
    if (fabBox != null && fabBox.hasSize) {
      fabCenter = fabBox.localToGlobal(
        Offset(fabBox.size.width / 2, fabBox.size.height / 2),
      );
    } else {
      fabCenter = Offset(size.width / 2, size.height - AppSizes.fabSize / 2);
    }

    final cs = Theme.of(context).colorScheme;
    final isRtl = context.isRtl;
    final dirFactor = isRtl ? -1.0 : 1.0;

    return Stack(
      children: [
        // Bottom layer: full-screen scrim.
        FadeTransition(
          opacity: _controller,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _collapse,
            child: ColoredBox(
              color: scrimColor,
              child: const SizedBox.expand(),
            ),
          ),
        ),

        // Top layer: arc action buttons.
        for (int i = 0; i < _actions.length; i++)
          _buildOverlayArcButton(
            index: i,
            cs: cs,
            fabCenter: fabCenter,
            dirFactor: dirFactor,
          ),
      ],
    );
  }

  /// Builds a single arc button positioned absolutely in the overlay,
  /// relative to [fabCenter].
  Widget _buildOverlayArcButton({
    required int index,
    required ColorScheme cs,
    required Offset fabCenter,
    required double dirFactor,
  }) {
    final action = _actions[index];
    final animation = _staggerAnimations[index];
    final accentColor = action.color(context);
    final angle = _angles[index];

    final value = animation.value;
    final radius = AppSizes.speedDialArcRadius * value;
    // Polar to Cartesian. dx flips for RTL.
    final dx = math.sin(angle) * radius * dirFactor;
    final dy = -math.cos(angle) * radius; // negative = upward

    // Position the button center at fabCenter + (dx, dy).
    final buttonLeft = fabCenter.dx + dx;
    final buttonTop = fabCenter.dy + dy;

    return Positioned(
      left: buttonLeft,
      top: buttonTop,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Transform.scale(
          scale: value,
          child: Semantics(
            label: action.labelKey(context),
            button: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Circular icon button with ink splash
                Material(
                  color: Color.alphaBlend(
                    accentColor.withValues(alpha: AppSizes.opacityLight),
                    cs.surface,
                  ),
                  shape: CircleBorder(
                    side: BorderSide(
                      color: accentColor.withValues(
                        alpha: AppSizes.opacityLight3,
                      ),
                    ),
                  ),
                  child: InkWell(
                    onTap: () => _collapse(selectedIndex: index),
                    customBorder: const CircleBorder(),
                    splashColor: accentColor.withValues(
                      alpha: AppSizes.opacityLight3,
                    ),
                    child: SizedBox(
                      width: AppSizes.speedDialButtonSize,
                      height: AppSizes.speedDialButtonSize,
                      child: Icon(
                        action.icon,
                        size: AppSizes.speedDialIconSize,
                        color: accentColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.speedDialLabelGap),
                // Label
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
    );
  }
}
