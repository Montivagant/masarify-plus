import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/constants/app_durations.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_navigation.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/services/glass_config_service.dart';
import '../../../core/utils/permission_helper.dart';
import '../../../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../../../features/voice_input/presentation/widgets/ai_thinking_overlay.dart';
import '../../../features/voice_input/presentation/widgets/voice_recording_pill.dart';
import '../../providers/background_ai_provider.dart';
import '../../providers/preferences_provider.dart';
import '../backgrounds/gradient_background.dart';
import '../feedback/first_time_hint.dart';
import 'raised_center_docked_fab_location.dart';
import 'speed_dial_fab.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppNavBar — M3 NavigationBar in a floating container
// ─────────────────────────────────────────────────────────────────────────────

/// M3 [NavigationBar] wrapped in a floating rounded container with shadow.
///
/// Uses a 5-destination layout: [Home] [Recurring] [spacer] [Analytics] [Planning].
/// The center spacer reserves space for the `centerDocked` FAB.
/// Tab selection is mapped between the 4-tab logical index (0–3) and
/// the 5-destination visual index (0, 1, _, 3, 4).
class AppNavBar extends ConsumerWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = context.colors;
    final theme = context.appTheme;
    final canBlur = GlassConfig.shouldBlur(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final dests = AppNavigation.destinations;
    final upcomingCount = ref.watch(upcomingBillsProvider).length;

    // Map logical 4-tab index (0–3) → visual 5-destination index (0,1,_,3,4).
    final navIndex = currentIndex < 2 ? currentIndex : currentIndex + 1;

    Widget navContent = MediaQuery.removePadding(
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
              icon: i == 1
                  ? Badge(
                      isLabelVisible: upcomingCount > 0,
                      label: Text('$upcomingCount'),
                      child: Icon(dests[i].icon),
                    )
                  : Icon(dests[i].icon),
              selectedIcon: i == 1
                  ? Badge(
                      isLabelVisible: upcomingCount > 0,
                      label: Text('$upcomingCount'),
                      child: Icon(dests[i].activeIcon),
                    )
                  : Icon(dests[i].activeIcon),
              label: dests[i].label(context),
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
              label: dests[i].label(context),
            ),
        ],
      ),
    );

    if (canBlur) {
      navContent = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppSizes.glassBlurBackground,
          sigmaY: AppSizes.glassBlurBackground,
        ),
        child: navContent,
      );
    }

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
          color: theme.glassSheetSurface,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
          border: Border.all(
            color: theme.glassSheetBorder,
            width: AppSizes.glassBorderWidthSubtle,
          ),
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
  bool _showFabHint = false;
  bool _showVoicePill = false;
  bool _showAiThinking = false;
  Uint8List? _pendingAudioBytes;

  /// True when either the recording pill or AI overlay is visible.
  bool get _showVoiceOverlay => _showVoicePill || _showAiThinking;

  @override
  void initState() {
    super.initState();
    _maybeShowFabHint();
  }

  Future<void> _maybeShowFabHint() async {
    final prefs = await ref.read(preferencesFutureProvider.future);
    if (prefs.fabHintShown) return;

    // Wait for the first frame + a short delay so the UI is fully rendered.
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(AppDurations.fabHintDelay, () {
        if (mounted) setState(() => _showFabHint = true);
      });
    });
  }

  Future<void> _dismissFabHint() async {
    setState(() => _showFabHint = false);
    final prefs = await ref.read(preferencesFutureProvider.future);
    await prefs.setFabHintShown();
  }

  Future<void> _onVoiceTap() async {
    var status = await Permission.microphone.status;

    if (status.isPermanentlyDenied) {
      if (!mounted) return;
      await PermissionHelper.openAppSettings();
      return;
    }

    if (!status.isGranted) {
      if (!mounted) return;
      final allowed = await PermissionHelper.showRationale(
        context,
        title: context.l10n.permission_mic_title,
        rationale: context.l10n.permission_mic_body,
      );
      if (!allowed || !mounted) return;
      status = await Permission.microphone.request();
      if (!status.isGranted) return;
    }

    if (!mounted) return;
    setState(() => _showVoicePill = true);
  }

  /// Transition from recording pill → AI thinking overlay.
  void _onVoiceProcess(Uint8List audioBytes) {
    setState(() {
      _showVoicePill = false;
      _pendingAudioBytes = audioBytes;
      _showAiThinking = true;
    });
  }

  void _dismissVoiceOverlay() {
    setState(() {
      _showVoicePill = false;
      _showAiThinking = false;
      _pendingAudioBytes = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final scaffold = Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: GradientBackground(child: widget.navigationShell),
      bottomNavigationBar: AppNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
      ),
      // Hide FAB when keyboard is open to prevent mid-screen push-up.
      floatingActionButton: MediaQuery.viewInsetsOf(context).bottom > 0
          ? null
          : SpeedDialFab(
              tabIndex: widget.navigationShell.currentIndex,
              onVoice: _onVoiceTap,
              onManual: () => AddTransactionScreen.show(context),
            ),
      floatingActionButtonLocation: RaisedCenterDockedFabLocation.raised,
    );

    // Layer: scaffold → blur scrim → recording pill / AI overlay → fab hint.
    return Stack(
      children: [
        scaffold,

        // Blur + scrim backdrop — visible during recording & AI processing.
        // Scrim tap dismisses only during recording; the overlay manages
        // its own cancel button during AI processing.
        if (_showVoiceOverlay)
          _VoiceBlurScrim(
            onTap: _showAiThinking ? null : _dismissVoiceOverlay,
          ),

        // Recording pill — compact bar above bottom nav.
        if (_showVoicePill)
          Positioned(
            left: AppSizes.screenHPadding,
            right: AppSizes.screenHPadding,
            bottom: AppSizes.bottomNavHeight + AppSizes.voicePillBottomMargin,
            child: VoiceRecordingPill(
              onDismiss: _dismissVoiceOverlay,
              onProcess: _onVoiceProcess,
            ),
          ),

        // AI thinking overlay — centered card with robot + typewriter.
        if (_showAiThinking && _pendingAudioBytes != null)
          AiThinkingOverlay(
            audioBytes: _pendingAudioBytes!,
            onDismiss: _dismissVoiceOverlay,
          ),

        if (_showFabHint)
          Positioned.fill(
            child: FirstTimeHint(
              message: context.l10n.hint_fab,
              icon: AppIcons.add,
              alignment: Alignment.bottomCenter,
              onDismiss: _dismissFabHint,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VoiceBlurScrim — Full-screen blur + semi-transparent scrim
// ─────────────────────────────────────────────────────────────────────────────

class _VoiceBlurScrim extends StatelessWidget {
  const _VoiceBlurScrim({this.onTap});

  /// Tap handler — null disables tap-to-dismiss (during AI processing).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final useBlur = GlassConfig.shouldBlur(context);
    final scrimColor = AppColors.black.withValues(alpha: AppSizes.opacityLight);

    Widget scrim = Positioned.fill(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.translucent,
        child: Container(color: scrimColor),
      ),
    );

    if (useBlur) {
      scrim = Positioned.fill(
        child: RepaintBoundary(
          child: GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.translucent,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppSizes.aiThinkingBlurSigma,
                sigmaY: AppSizes.aiThinkingBlurSigma,
              ),
              child: Container(color: scrimColor),
            ),
          ),
        ),
      );
    }

    return scrim;
  }
}
