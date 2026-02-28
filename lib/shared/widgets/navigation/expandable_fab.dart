import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

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
        color: (ctx) => Theme.of(ctx).colorScheme.primary,
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _expand() {
    if (_isExpanded) return;
    setState(() => _isExpanded = true);
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
    final cs = Theme.of(context).colorScheme;

    // M3 fix: use OverlayEntry-style full-screen scrim via LayoutBuilder
    // instead of 200x200 SizedBox so tapping anywhere outside collapses the FAB.
    return SizedBox(
      width: AppSizes.fabContainerSize,
      height: AppSizes.fabContainerSize,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // M3 fix: full-screen scrim when expanded — covers entire screen.
          // Uses OverlayEntry-style Positioned.fill to avoid negative-offset
          // calculations that break in RTL layouts.
          if (_isExpanded)
            Positioned.fill(
              child: OverflowBox(
                maxWidth: MediaQuery.sizeOf(context).width * 2,
                maxHeight: MediaQuery.sizeOf(context).height * 2,
                child: GestureDetector(
                  onTap: () => _collapse(),
                  behavior: HitTestBehavior.opaque,
                  child: ColoredBox(
                    color: cs.scrim.withValues(alpha: 0.3),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),

          // Bubbles
          ..._buildBubbles(cs),

          // Main FAB
          Positioned(
            bottom: 0,
            child: GestureDetector(
              onTap: () {
                if (_isExpanded) {
                  _collapse();
                } else {
                  HapticFeedback.mediumImpact();
                  widget.onTap();
                }
              },
              onLongPressStart: (details) {
                _expand();
              },
              onLongPressMoveUpdate: (details) {
                // Compute offset relative to FAB center
                const fabCenter = Offset(
                  AppSizes.fabSize / 2,
                  AppSizes.fabSize / 2,
                );
                final dragOffset = details.localPosition - fabCenter;
                setState(() {
                  final newHovered = _findClosestBubble(dragOffset);
                  if (newHovered != _hoveredIndex) {
                    _hoveredIndex = newHovered;
                    if (newHovered >= 0) {
                      HapticFeedback.selectionClick();
                    }
                  }
                });
              },
              onLongPressEnd: (details) {
                _collapse(selectedIndex: _hoveredIndex);
              },
              child: AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  final rotation = _expandAnimation.value * AppSizes.fabRotationAngle;
                  return Transform.rotate(
                    angle: rotation,
                    child: child,
                  );
                },
                child: const FloatingActionButton(
                  heroTag: 'nav_fab',
                  onPressed: null, // Handled by GestureDetector
                  elevation: AppSizes.elevationHigh,
                  child: Icon(AppIcons.add),
                ),
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
      final isHovered = _hoveredIndex == i;
      final bubbleColor = bubble.color(context);

      return Positioned(
        bottom: AppSizes.fabSize / 2,
        left: AppSizes.fabContainerSize / 2 - _bubbleSize / 2,
        child: AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            final scale = _expandAnimation.value;
            final hoverScale = isHovered ? AppSizes.fabHoverScale : 1.0;
            final dx = directionalOffset.dx * scale;
            final dy = directionalOffset.dy * scale;

            return Transform.translate(
              offset: Offset(dx, dy),
              child: Transform.scale(
                scale: scale * hoverScale,
                child: Opacity(
                  opacity: scale.clamp(0.0, 1.0),
                  child: child,
                ),
              ),
            );
          },
          child: Semantics(
            label: bubble.labelKey(context),
            button: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: _bubbleSize,
                  height: _bubbleSize,
                  child: Material(
                    elevation: isHovered ? AppSizes.fabElevationHovered : AppSizes.fabElevationResting,
                    shape: const CircleBorder(),
                    color: isHovered
                        ? bubbleColor
                        : bubbleColor.withValues(alpha: 0.85),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _collapse(selectedIndex: i),
                      child: Icon(
                        bubble.icon,
                        size: AppSizes.iconMd,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.sm,
                    vertical: AppSizes.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: cs.shadow.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(AppSizes.borderRadiusFull),
                  ),
                  child: Text(
                    bubble.labelKey(context),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
