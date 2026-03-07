import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';

/// Data for a single radial menu bubble.
class _FabBubble {
  const _FabBubble({
    required this.icon,
    required this.labelKey,
    required this.offset,
    required this.color,
  });

  final IconData icon;
  // M2 fix: use a function that takes l10n context instead of hardcoded string
  final String Function(BuildContext) labelKey;
  final Offset offset; // LTR offset from FAB center
  final Color Function(BuildContext) color;
}

/// Expandable radial FAB with 3 bubbles: Expense, Mic, Income.
///
/// - **Tap**: navigate to AddTransaction (expense preset)
/// - **Long press**: expand 3 bubbles in a radial arc
/// - **Drag**: highlight closest bubble, release to select
/// - **RTL-aware**: mirrors horizontal offsets in Arabic layout
///
/// **AOT fix**: Bubbles are only added to the widget tree when expanded or
/// animating. Material widgets with elevation at opacity 0 leak shadows in
/// AOT (release/profile) builds, causing a grey overlay.
class ExpandableFab extends StatefulWidget {
  const ExpandableFab({
    super.key,
    required this.onExpense,
    required this.onIncome,
    required this.onVoice,
    required this.onTap,
  });

  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final VoidCallback onVoice;
  final VoidCallback onTap;

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;

  bool _isExpanded = false;
  int _hoveredIndex = -1;

  /// Whether bubbles + scrim are in the widget tree.
  /// True when expanded; stays true during the close animation so bubbles
  /// animate out, then flips false on [AnimationStatus.dismissed].
  bool _showOverlay = false;

  // Hit zone radius for each bubble
  static const double _hitRadius = AppSizes.fabHitRadius;
  // Bubble icon container size
  static const double _bubbleSize = AppSizes.fabBubbleSize;

  late final List<_FabBubble> _bubbles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.fabExpand,
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );
    _controller.addStatusListener(_onAnimationStatus);

    // M2 fix: labels resolved from l10n context, not hardcoded English
    _bubbles = [
      _FabBubble(
        icon: AppIcons.expense,
        labelKey: (ctx) => ctx.l10n.fab_expense,
        offset: const Offset(-AppSizes.fabRadialDistance, -AppSizes.fabRadialDistance),
        color: (ctx) => ctx.appTheme.expenseColor,
      ),
      _FabBubble(
        icon: AppIcons.mic,
        labelKey: (ctx) => ctx.l10n.fab_voice,
        offset: const Offset(0, -AppSizes.fabRadialDistanceTop),
        color: (ctx) => ctx.colors.primary,
      ),
      _FabBubble(
        icon: AppIcons.income,
        labelKey: (ctx) => ctx.l10n.fab_income,
        offset: const Offset(AppSizes.fabRadialDistance, -AppSizes.fabRadialDistance),
        color: (ctx) => ctx.appTheme.incomeColor,
      ),
    ];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect reduceMotion accessibility setting.
    // Only update duration when not actively animating to avoid jumps.
    final newDuration = context.reduceMotion
        ? Duration.zero
        : AppDurations.fabExpand;
    if (_controller.duration != newDuration && !_controller.isAnimating) {
      _controller.duration = newDuration;
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  void _onAnimationStatus(AnimationStatus status) {
    // Remove bubbles from the widget tree once the close animation finishes.
    // This prevents Material elevation shadows from leaking in AOT builds.
    if (status == AnimationStatus.dismissed && _showOverlay) {
      setState(() => _showOverlay = false);
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
    setState(() {
      _isExpanded = false;
      _hoveredIndex = -1;
    });
    _controller.reverse();

    if (selectedIndex != null && selectedIndex >= 0) {
      HapticFeedback.heavyImpact();
      switch (selectedIndex) {
        case 0:
          widget.onExpense();
        case 1:
          widget.onVoice();
        case 2:
          widget.onIncome();
      }
    }
  }

  Offset _getDirectionalOffset(_FabBubble bubble) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final dx = isRtl ? -bubble.offset.dx : bubble.offset.dx;
    return Offset(dx, bubble.offset.dy);
  }

  int _findClosestBubble(Offset localDrag) {
    double minDist = double.infinity;
    int closest = -1;

    for (int i = 0; i < _bubbles.length; i++) {
      final bubbleOffset = _getDirectionalOffset(_bubbles[i]);
      final dist = (localDrag - bubbleOffset).distance;
      if (dist < minDist && dist < _hitRadius * 2) {
        minDist = dist;
        closest = i;
      }
    }

    return closest;
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return SizedBox(
      width: AppSizes.fabContainerSize,
      height: AppSizes.fabContainerSize,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Bubbles + scrim — only in tree when expanded or animating closed.
          // AOT safety: no Opacity widget, no Material(elevation>0), no BoxShadow.
          if (_showOverlay) ...[
            // Invisible scrim: pure hit-test for tap-to-dismiss.
            // No ColoredBox, no painting — just catches taps outside bubbles.
            Positioned.fill(
              child: OverflowBox(
                maxWidth: double.infinity,
                maxHeight: double.infinity,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _collapse,
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width,
                    height: MediaQuery.sizeOf(context).height,
                  ),
                ),
              ),
            ),
            ..._buildBubbles(cs),
          ],

          // Main FAB — always in tree.
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onLongPressStart: (_) => _expand(),
              onLongPressMoveUpdate: (details) {
                if (!_isExpanded) return;
                final local = details.localPosition -
                    const Offset(AppSizes.fabSize / 2, AppSizes.fabSize / 2);
                final closest = _findClosestBubble(local);
                if (closest != _hoveredIndex) {
                  setState(() => _hoveredIndex = closest);
                  if (closest >= 0) HapticFeedback.selectionClick();
                }
              },
              onLongPressEnd: (_) {
                if (_isExpanded) _collapse(selectedIndex: _hoveredIndex);
              },
              child: FloatingActionButton(
                heroTag: 'nav_fab',
                onPressed: () {
                  if (_isExpanded) {
                    _collapse();
                  } else {
                    HapticFeedback.mediumImpact();
                    widget.onTap();
                  }
                },
                elevation: AppSizes.elevationHigh,
                child: const Icon(AppIcons.add),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBubbles(ColorScheme cs) {
    return List.generate(_bubbles.length, (i) {
      final bubble = _bubbles[i];
      final directionalOffset = _getDirectionalOffset(bubble);
      final bubbleColor = bubble.color(context);
      final isHovered = _hoveredIndex == i;

      // AOT-safe: no Opacity widget, no Material(elevation>0), no BoxShadow.
      // Transform.scale alone handles show/hide (scale 0 = invisible).
      return Positioned(
        bottom: AppSizes.fabSize / 2,
        left: AppSizes.fabContainerSize / 2 - _bubbleSize / 2,
        child: AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final scale = _expandAnimation.value;
            final dx = directionalOffset.dx * scale;
            final dy = directionalOffset.dy * scale;

            return Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.scale(
                scale: scale,
                child: child,
              ),
            );
          },
          // Hover scale feedback wraps the entire bubble+label column.
          child: AnimatedScale(
            scale: isHovered ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: Semantics(
              label: bubble.labelKey(context),
              button: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // AOT-safe: default elevation (0) — InkWell ripple without
                  // elevation shadows. Do NOT add elevation > 0 here.
                  Material(
                    type: MaterialType.circle,
                    color: bubbleColor,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _collapse(selectedIndex: i),
                      child: SizedBox(
                        width: _bubbleSize,
                        height: _bubbleSize,
                        child: Icon(
                          bubble.icon,
                          size: AppSizes.iconMd,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  // Label with surface background for readability.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.xs,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
                    ),
                    child: Text(
                      bubble.labelKey(context),
                      style: context.textStyles.labelSmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
