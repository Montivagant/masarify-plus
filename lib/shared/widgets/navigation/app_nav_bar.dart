import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_navigation.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/services/glass_config_service.dart';
import '../../../features/voice_input/presentation/widgets/voice_input_button.dart';
import '../../../shared/providers/notification_listener_provider.dart';
import 'expandable_fab.dart';

/// Floating glassmorphic 4-tab bottom navigation bar.
///
/// Uses [BackdropFilter] + [ClipRRect] for frosted glass effect.
/// Theme-aware: surface color at 85% opacity with subtle blur.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    const dests = AppNavigation.destinations;
    final cs = context.colors;
    final langCode = context.languageCode;
    const radius = BorderRadius.all(Radius.circular(AppSizes.borderRadiusLg));

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final useBlur = GlassConfig.shouldBlur(context);

    final navContent = Material(
      type: MaterialType.transparency,
      child: Container(
        height: AppSizes.bottomNavHeight,
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: AppSizes.opacityHeavy),
          borderRadius: radius,
          border: Border.all(
            color: cs.outline.withValues(alpha: AppSizes.opacityXLight),
            // ignore: avoid_redundant_argument_values
            width: AppSizes.glassBorderWidth,
          ),
        ),
        child: Row(
          children: [
            for (var i = 0; i < dests.length; i++)
              Expanded(
                child: _NavTab(
                  icon: dests[i].icon,
                  activeIcon: dests[i].activeIcon,
                  label: dests[i].label(langCode),
                  isSelected: i == currentIndex,
                  selectedColor: cs.primary,
                  unselectedColor: cs.onSurfaceVariant,
                  onTap: () {
                    if (i != currentIndex) {
                      HapticFeedback.selectionClick();
                      onTap(i);
                    }
                  },
                ),
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
        child: ClipRRect(
          borderRadius: radius,
          child: useBlur
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppSizes.glassBlurSigma,
                    sigmaY: AppSizes.glassBlurSigma,
                  ),
                  child: navContent,
                )
              : navContent,
        ),
      ),
    );
  }
}

/// A single tab in the floating nav bar.
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
                const SizedBox(height: AppSizes.xxs),
                Text(
                  label,
                  style: context.textStyles.labelSmall?.copyWith(
                        color: color,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Selected indicator dot (always rendered to prevent layout shift)
                const SizedBox(height: AppSizes.xxs),
                Container(
                  width: AppSizes.dotSm,
                  height: AppSizes.xxs,
                  decoration: BoxDecoration(
                    color: isSelected ? selectedColor : AppColors.transparent,
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusFull),
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

/// A stateful shell widget that hosts the 4-tab scaffold + center FAB.
class AppScaffoldShell extends ConsumerStatefulWidget {
  const AppScaffoldShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppScaffoldShell> createState() => _AppScaffoldShellState();
}

class _AppScaffoldShellState extends ConsumerState<AppScaffoldShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check notification listener permission on resume.
      final listener = ref.read(notificationListenerProvider);
      listener.recheckPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // I16 fix: wrap shell body in error boundary to prevent full-app crash
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
      floatingActionButton: ExpandableFab(
        onTap: () {
          context.push(
            AppRoutes.transactionAdd,
            extra: const {'type': 'expense'},
          );
        },
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
      floatingActionButtonLocation: const _LowerCenterFabLocation(),
    );
  }
}

class _LowerCenterFabLocation extends FloatingActionButtonLocation {
  const _LowerCenterFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final baseOffset =
        FloatingActionButtonLocation.centerFloat.getOffset(scaffoldGeometry);
    return Offset(baseOffset.dx, baseOffset.dy + AppSizes.fabVerticalOffset);
  }
}
