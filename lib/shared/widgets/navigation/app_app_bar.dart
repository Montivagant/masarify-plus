import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../buttons/app_icon_button.dart';

/// Standard Masarify AppBar.
/// Handles back button, actions, and title in a consistent way.
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
    return AppBar(
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
      scrolledUnderElevation: 0,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0),
      );
}
