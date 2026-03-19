import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_navigation.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../../../features/voice_input/presentation/widgets/voice_input_button.dart';
import 'raised_center_docked_fab_location.dart';
import 'speed_dial_fab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppNavBar — M3 NavigationBar in a floating container
// ─────────────────────────────────────────────────────────────────────────────

/// M3 [NavigationBar] wrapped in a floating rounded container with shadow.
///
/// Uses a 5-destination layout: [Home] [Transactions] [spacer] [Analytics] [More].
/// The center spacer reserves space for the `centerDocked` FAB.
/// Tab selection is mapped between the 4-tab logical index (0–3) and
/// the 5-destination visual index (0, 1, _, 3, 4).
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
    final cs = context.colors;
    final langCode = context.languageCode;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    const dests = AppNavigation.destinations;

    // Map logical 4-tab index (0–3) → visual 5-destination index (0,1,_,3,4).
    final navIndex = currentIndex < 2 ? currentIndex : currentIndex + 1;

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsetsDirectional.fromSTEB(
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
        // Strip bottom padding so NavigationBar's internal SafeArea
        // doesn't double the inset our Container margin already handles.
        child: MediaQuery.removePadding(
          context: context,
          removeBottom: true,
          child: NavigationBar(
            selectedIndex: navIndex,
            onDestinationSelected: (i) {
              if (i == 2) return; // center spacer — ignore
              final logicalIndex = i < 2 ? i : i - 1;
              if (logicalIndex != currentIndex) {
                HapticFeedback.selectionClick();
                onTap(logicalIndex);
              }
            },
            height: AppSizes.bottomNavHeight,
            destinations: [
              for (var i = 0; i < 2; i++)
                NavigationDestination(
                  icon: Icon(dests[i].icon),
                  selectedIcon: Icon(dests[i].activeIcon),
                  label: dests[i].label(langCode),
                ),
              // Center spacer for FAB overlap.
              const NavigationDestination(
                icon: SizedBox.shrink(),
                label: '',
              ),
              for (var i = 2; i < dests.length; i++)
                NavigationDestination(
                  icon: Icon(dests[i].icon),
                  selectedIcon: Icon(dests[i].activeIcon),
                  label: dests[i].label(langCode),
                ),
            ],
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
        tabIndex: widget.navigationShell.currentIndex,
        onVoice: () => VoiceInputButton.handleVoiceInput(context),
        onManual: () => AddTransactionScreen.show(context),
      ),
      floatingActionButtonLocation: RaisedCenterDockedFabLocation.raised,
    );
  }
}
