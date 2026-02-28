import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_theme_extension.dart';

abstract final class AppTheme {
  static ThemeData get light {
    final base = FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: AppColors.primary,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.accent,
        secondaryContainer: Color(0xFFD4EDE3), // Light sage
        tertiary: AppColors.incomeGreen,
        tertiaryContainer: Color(0xFFD1FAE5), // Emerald 100
        appBarColor: AppColors.primary,
        error: AppColors.expenseRed,
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: const FlexSubThemesData(

        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        cardRadius: 16.0,
        inputDecoratorRadius: 16.0,
        dialogRadius: 24.0,
        bottomSheetRadius: 24.0,
        bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,

      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );

    return base.copyWith(
      textTheme: base.textTheme.merge(AppTextStyles.sizeOverrides),
      primaryTextTheme: base.primaryTextTheme.merge(AppTextStyles.sizeOverrides),
      scaffoldBackgroundColor: AppColors.surface,
      extensions: const [AppThemeExtension.light],
    );
  }

  static ThemeData get dark {
    final base = FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: AppColors.primaryDark,
        primaryContainer: Color(0xFF2D2344), // Dark Violet
        secondary: Color(0xFFC4898A), // Mauve Pink
        secondaryContainer: Color(0xFF3D2A2A), // Dark mauve
        tertiary: Color(0xFFE19B8B), // Rose Gold
        tertiaryContainer: Color(0xFF3D2B25), // Dark rose
        appBarColor: AppColors.backgroundDark,
        error: Color(0xFFB85450),
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: const FlexSubThemesData(

        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        cardRadius: 16.0,
        inputDecoratorRadius: 16.0,
        dialogRadius: 24.0,
        bottomSheetRadius: 24.0,
        bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,

      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );

    return base.copyWith(
      textTheme: base.textTheme.merge(AppTextStyles.sizeOverrides),
      primaryTextTheme: base.primaryTextTheme.merge(AppTextStyles.sizeOverrides),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      extensions: const [AppThemeExtension.dark],
    );
  }
}
