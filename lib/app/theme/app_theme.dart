import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_sizes.dart';
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
        secondaryContainer: AppColors.secondaryContainerLight,
        tertiary: AppColors.incomeGreen,
        tertiaryContainer: AppColors.tertiaryContainerLight,
        appBarColor: AppColors.primary,
        error: AppColors.expenseRed,
      ),
      // surfaceMode + blendLevel removed (theme revamp v7) — gradient page
      // owns the surface tone; FlexColorScheme tinting was producing
      // greenish neutrals we no longer want.
      subThemesData: const FlexSubThemesData(
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        cardRadius: AppSizes.borderRadiusMd,
        inputDecoratorRadius: AppSizes.borderRadiusMd,
        inputDecoratorSchemeColor: SchemeColor.primary,
        inputDecoratorBorderSchemeColor: SchemeColor.outline,
        inputDecoratorUnfocusedBorderIsColored: false,
        dialogRadius: AppSizes.borderRadiusLg,
        bottomSheetRadius: AppSizes.borderRadiusLg,
        bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
        textButtonSchemeColor: SchemeColor.primary,
        filledButtonSchemeColor: SchemeColor.primary,
        outlinedButtonSchemeColor: SchemeColor.primary,
        chipRadius: AppSizes.borderRadiusSm,
        chipBlendColors: false,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );

    return base.copyWith(
      textTheme: base.textTheme.merge(AppTextStyles.sizeOverrides),
      primaryTextTheme:
          base.primaryTextTheme.merge(AppTextStyles.sizeOverrides),
      scaffoldBackgroundColor: Colors.transparent,
      // Warm dark text (deep forest) instead of M3 default near-black —
      // matches the v7 mockup's `#0F3D2C` body colour.
      colorScheme: base.colorScheme.copyWith(
        onSurface: const Color(0xFF0F3D2C),
        onSurfaceVariant: const Color(0xFF5C7868),
      ),
      // App bar: transparent so the gradient flows under the title.
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Color(0xFF0F3D2C),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        elevation: AppSizes.elevationNone,
        height: AppSizes.bottomNavHeight,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      ),
      extensions: const [AppThemeExtension.light],
    );
  }

  static ThemeData get dark {
    final base = FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: AppColors.primaryDark,
        primaryContainer: AppColors.primaryContainerDark,
        secondary: AppColors.secondaryDark,
        secondaryContainer: AppColors.secondaryContainerDark,
        tertiary: AppColors.tertiaryDark,
        tertiaryContainer: AppColors.tertiaryContainerDark,
        appBarColor: AppColors.backgroundDark,
        error: AppColors.errorDark,
      ),
      // surfaceMode + blendLevel removed (theme revamp v7).
      subThemesData: const FlexSubThemesData(
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        cardRadius: AppSizes.borderRadiusMd,
        inputDecoratorRadius: AppSizes.borderRadiusMd,
        inputDecoratorSchemeColor: SchemeColor.primary,
        inputDecoratorBorderSchemeColor: SchemeColor.outline,
        inputDecoratorUnfocusedBorderIsColored: false,
        dialogRadius: AppSizes.borderRadiusLg,
        bottomSheetRadius: AppSizes.borderRadiusLg,
        bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
        textButtonSchemeColor: SchemeColor.primary,
        filledButtonSchemeColor: SchemeColor.primary,
        outlinedButtonSchemeColor: SchemeColor.primary,
        chipRadius: AppSizes.borderRadiusSm,
        chipBlendColors: false,
      ),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    );

    return base.copyWith(
      textTheme: base.textTheme.merge(AppTextStyles.sizeOverrides),
      primaryTextTheme:
          base.primaryTextTheme.merge(AppTextStyles.sizeOverrides),
      scaffoldBackgroundColor: Colors.transparent,
      // Light mint glow text on dark mint backdrop.
      colorScheme: base.colorScheme.copyWith(
        onSurface: const Color(0xFFD8F0E2),
        onSurfaceVariant: const Color(0xFFA3C4B3),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: Color(0xFFD8F0E2),
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        indicatorShape: const StadiumBorder(),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        elevation: AppSizes.elevationNone,
        height: AppSizes.bottomNavHeight,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
      ),
      extensions: const [AppThemeExtension.dark],
    );
  }
}
