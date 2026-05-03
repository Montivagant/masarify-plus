import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../buttons/app_icon_button.dart';

/// Standard Masarify AppBar.
/// Handles back button, actions, and title in a consistent way.
///
/// Theme revamp v7.2: AppBar is transparent and the system status bar
/// is transparent. Pair with `Scaffold(extendBodyBehindAppBar: true,
/// backgroundColor: Colors.transparent)` so the global gradient flows
/// under the bar without a colour break. The AppBarTheme defaults from
/// `AppTheme` already enforce transparent / no-tint.
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showBack = true,
    this.onBack,
    this.bottom,
    this.centerTitle = true,
  });

  final String title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Transparent app bar + transparent system status bar so the page
    // gradient (theme revamp v7) flows continuously from the top edge
    // of the screen.
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: isDark
          ? SystemUiOverlayStyle.light.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            )
          : SystemUiOverlayStyle.dark.copyWith(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
      title: Text(
        title,
        style: context.textStyles.headlineMedium,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading: showBack && GoRouter.of(context).canPop()
          ? AppIconButton(
              icon: AppIcons.arrowBack,
              onPressed: onBack ?? () => context.pop(),
              tooltip: context.l10n.common_back,
            )
          : null,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}
