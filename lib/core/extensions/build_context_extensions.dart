import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../constants/app_sizes.dart';

// Re-export AppThemeX so importing this file gives access to
// context.appTheme, context.colors, context.textStyles.
export '../../app/theme/app_theme_extension.dart' show AppThemeX;

/// Additional BuildContext convenience extensions.
extension BuildContextX on BuildContext {
  /// Screen width.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// True if current locale is RTL.
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// True if dark mode is active.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// True if user has requested reduced motion.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// Horizontal screen padding for consistent page layout.
  EdgeInsets get screenPadding => const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
      );

  /// Shorthand for AppLocalizations.of(context)!
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Current locale language code (e.g. 'en', 'ar').
  String get languageCode => Localizations.localeOf(this).languageCode;
}
