import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_navigation.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/services/glass_config_service.dart';
import '../../../features/voice_input/presentation/widgets/voice_input_button.dart';
import 'notched_nav_clipper.dart';
import 'speed_dial_fab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppNavBar — Floating glassmorphic 4-tab bottom nav with center FAB notch
// ─────────────────────────────────────────────────────────────────────────────

/// Glassmorphic bottom nav bar with a smooth semicircular notch for the FAB.
///
/// Tabs are split 2-left (Home, Transactions) and 2-right (Analytics, More).
/// The active tab gets a frosted glass pill indicator with brand-color glow
/// that slides smoothly between tabs.
class AppNavBar extends StatefulWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  State<AppNavBar> createState() => _AppNavBarState();
}

class _AppNavBarState extends State<AppNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pillController;
  late Animation<double> _pillAnimation;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _pillController = AnimationController(
      vsync: this,
      duration: AppDurations.navPillSlide,
    );
    _pillAnimation = CurvedAnimation(
      parent: _pillController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(AppNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      if (context.reduceMotion) {
        _pillController.value = 1.0;
      } else {
        _pillController
          ..reset()
          ..forward();
      }
    }
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const dests = AppNavigation.destinations;
    final cs = context.colors;
    final theme = context.appTheme;
    final langCode = context.languageCode;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final useBlur = GlassConfig.shouldBlur(context);

    // The center notch gap width.
    const notchGap = (AppSizes.navNotchRadius + AppSizes.navNotchMargin) * 2;

    final navContent = Material(
      type: MaterialType.transparency,
      child: SizedBox(
        height: AppSizes.bottomNavHeight,
        child: Stack(
          children: [
            // Glass background with notch clip + BackdropFilter.
            Positioned.fill(
              child: ClipPath(
                clipper: const NotchedNavClipper(),
                child: useBlur
                    ? BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: AppSizes.glassBlurCard,
                          sigmaY: AppSizes.glassBlurCard,
                        ),
                        child: ColoredBox(
                          color: theme.glassCardSurface,
                        ),
                      )
                    : ColoredBox(
                        // Opaque fallback: blend glass token against surface
                        color: Color.alphaBlend(
                          theme.glassCardSurface,
                          cs.surface,
                        ),
                      ),
              ),
            ),

            // Glass border following the notch shape.
            Positioned.fill(
              child: CustomPaint(
                painter: NotchedNavBorderPainter(
                  borderColor: theme.glassCardBorder,
                ),
              ),
            ),

            // Animated pill indicator behind active tab.
            _PillIndicator(
              animation: _pillAnimation,
              currentIndex: widget.currentIndex,
              previousIndex: _previousIndex,
              primaryColor: cs.primary,
              pillColor: cs.primary.withValues(alpha: AppSizes.opacityLight3),
            ),

            // Tab items: 2-left + center gap + 2-right.
            Row(
              children: [
                for (var i = 0; i < 2; i++)
                  Expanded(
                    child: _NavTab(
                      icon: dests[i].icon,
                      activeIcon: dests[i].activeIcon,
                      label: dests[i].label(langCode),
                      isSelected: i == widget.currentIndex,
                      selectedColor: cs.primary,
                      unselectedColor: cs.onSurfaceVariant,
                      onTap: () {
                        if (i != widget.currentIndex) {
                          HapticFeedback.selectionClick();
                          widget.onTap(i);
                        }
                      },
                    ),
                  ),
                // Center gap for FAB notch.
                const SizedBox(width: notchGap),
                for (var i = 2; i < dests.length; i++)
                  Expanded(
                    child: _NavTab(
                      icon: dests[i].icon,
                      activeIcon: dests[i].activeIcon,
                      label: dests[i].label(langCode),
                      isSelected: i == widget.currentIndex,
                      selectedColor: cs.primary,
                      unselectedColor: cs.onSurfaceVariant,
                      onTap: () {
                        if (i != widget.currentIndex) {
                          HapticFeedback.selectionClick();
                          widget.onTap(i);
                        }
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.fromLTRB(
          AppSizes.md,
          0,
          AppSizes.md,
          AppSizes.md + bottomInset,
        ),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withValues(alpha: AppSizes.opacityLight3),
              blurRadius: AppSizes.navShadowBlur,
              offset: const Offset(0, AppSizes.navShadowOffsetY),
            ),
          ],
        ),
        child: navContent,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PillIndicator — Animated glass pill behind the active tab
// ─────────────────────────────────────────────────────────────────────────────

class _PillIndicator extends StatelessWidget {
  const _PillIndicator({
    required this.animation,
    required this.currentIndex,
    required this.previousIndex,
    required this.primaryColor,
    required this.pillColor,
  });

  final Animation<double> animation;
  final int currentIndex;
  final int previousIndex;
  final Color primaryColor;
  final Color pillColor;

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder outside AnimatedBuilder: constraints don't change
    // during animation, so we measure once and pass the width in.
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const notchGap =
            (AppSizes.navNotchRadius + AppSizes.navNotchMargin) * 2;
        final tabAreaWidth = (totalWidth - notchGap) / 4;

        double tabCenterX(int index) {
          if (index < 2) {
            return tabAreaWidth * index + tabAreaWidth / 2;
          } else {
            return tabAreaWidth * 2 +
                notchGap +
                tabAreaWidth * (index - 2) +
                tabAreaWidth / 2;
          }
        }

        final fromX = tabCenterX(previousIndex);
        final toX = tabCenterX(currentIndex);

        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final currentX =
                fromX + (toX - fromX) * animation.value;
            const pillWidth = AppSizes.navPillWidth;
            const pillHeight = AppSizes.navPillHeight;
            final atRest = animation.value == 1.0;

            return Positioned(
              left: currentX - pillWidth / 2,
              top: (AppSizes.bottomNavHeight - pillHeight) / 2,
              child: Container(
                width: pillWidth,
                height: pillHeight,
                decoration: BoxDecoration(
                  color: pillColor,
                  borderRadius:
                      BorderRadius.circular(AppSizes.borderRadiusFull),
                  // Only render glow shadow at rest to avoid GPU cost
                  // per animation frame.
                  boxShadow: atRest
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(
                              alpha: AppSizes.navPillGlowOpacity,
                            ),
                            blurRadius: AppSizes.navPillGlowRadius,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavTab — A single tab in the floating nav bar
// ─────────────────────────────────────────────────────────────────────────────

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  color: color,
                  size: AppSizes.iconMd,
                ),
                // Show label only when selected (inside the pill).
                if (isSelected) ...[
                  const SizedBox(height: AppSizes.xxs),
                  Text(
                    label,
                    style: context.textStyles.labelSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppScaffoldShell — Stateful shell hosting tabs + center FAB
// ─────────────────────────────────────────────────────────────────────────────

/// A stateful shell widget that hosts the 4-tab scaffold + center-docked FAB.
class AppScaffoldShell extends ConsumerStatefulWidget {
  const AppScaffoldShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppScaffoldShell> createState() => _AppScaffoldShellState();
}

class _AppScaffoldShellState extends ConsumerState<AppScaffoldShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: AppNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
      ),
      floatingActionButton: SpeedDialFab(
        onExpense: () {
          context.push(
            AppRoutes.transactionAdd,
            extra: const {'type': 'expense'},
          );
        },
        onIncome: () {
          context.push(
            AppRoutes.transactionAdd,
            extra: const {'type': 'income'},
          );
        },
        onVoice: () => VoiceInputButton.handleVoiceInput(context),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
