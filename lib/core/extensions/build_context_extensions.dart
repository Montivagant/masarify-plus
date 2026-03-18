import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

// Re-export AppThemeX so importing this file gives access to
// context.appTheme, context.colors, context.textStyles.
export '../../app/theme/app_theme_extension.dart' show AppThemeX;

/// Additional BuildContext convenience extensions.
extension BuildContextX on BuildContext {
  /// Screen width.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// True if current locale is RTL.
  bool get isRtl => Directionality.of(this) == TextDirection.rtl;

  /// True if user has requested reduced motion.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// Shorthand for AppLocalizations.of(context)!
  AppLocalizations get l10n => AppLocalizations.of(this)!;

  /// Current locale language code (e.g. 'en', 'ar').
  String get languageCode => Localizations.localeOf(this).languageCode;
}
