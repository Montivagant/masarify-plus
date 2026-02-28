import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Custom semantic color tokens not covered by Material ColorScheme.
/// Access via: context.appTheme.incomeColor
@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.incomeColor,
    required this.expenseColor,
    required this.transferColor,
    required this.warningColor,
    required this.successColor,
    required this.previousPeriodColor,
    required this.previousPeriodColorAlt,
    required this.cardSurface,
    required this.cardBorderRadius,
    required this.listItemRadius,
    required this.cardElevation,
    required this.disabledColor,
    required this.onDisabledColor,
    required this.heroGradient,
    required this.glassSurface,
    required this.glassBorder,
    required this.onTransferColor,
    required this.glassCardSurface,
    required this.glassCardBorder,
    required this.glassSheetSurface,
    required this.glassSheetBorder,
    required this.glassInsetSurface,
    required this.glassInsetBorder,
    required this.glassShadow,
  });

  final Color incomeColor;
  final Color expenseColor;
  final Color transferColor;
  final Color warningColor;
  final Color successColor;
  final Color previousPeriodColor;
  final Color previousPeriodColorAlt;
  final Color cardSurface;
  final double cardBorderRadius;
  final double listItemRadius;
  final double cardElevation;
  final Color disabledColor;
  final Color onDisabledColor;
  final LinearGradient heroGradient;
  final Color glassSurface;
  final Color glassBorder;
  final Color onTransferColor;

  // ── 3-Tier Glass Hierarchy ──────────────────────────────────────────
  final Color glassCardSurface; // Tier 2: cards, sections
  final Color glassCardBorder;
  final Color glassSheetSurface; // Tier 1: sheets, dialogs, overlays
  final Color glassSheetBorder;
  final Color glassInsetSurface; // Tier 3: nested elements, icon badges
  final Color glassInsetBorder;
  final Color glassShadow; // Brand-tinted shadow

  static const light = AppThemeExtension(
    incomeColor: AppColors.incomeGreen, // #059669 — AAA 5.4:1
    expenseColor: AppColors.expenseRed,
    transferColor: AppColors.transferBlue,
    warningColor: AppColors.warning, // #92400E — AA 7.2:1
    successColor: AppColors.success,
    previousPeriodColor: AppColors.lastMonthGray, // Slate 400
    previousPeriodColorAlt: AppColors.lastMonthGrayLight, // Slate 300
    cardSurface: AppColors.surfaceCard,
    cardBorderRadius: 16.0,
    listItemRadius: 12.0,
    cardElevation: 1.0,
    disabledColor: AppColors.disabled,
    onDisabledColor: AppColors.onDisabled,
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.gradientStartLight, AppColors.gradientEndLight],
    ),
    glassSurface: AppColors.glassSurfaceLight,
    glassBorder: AppColors.glassBorderLight,
    onTransferColor: AppColors.onTransfer,
    glassCardSurface: AppColors.glassCardSurfaceLight,
    glassCardBorder: AppColors.glassCardBorderLight,
    glassSheetSurface: AppColors.glassSheetSurfaceLight,
    glassSheetBorder: AppColors.glassSheetBorderLight,
    glassInsetSurface: AppColors.glassInsetSurfaceLight,
    glassInsetBorder: AppColors.glassInsetBorderLight,
    glassShadow: AppColors.glassShadowLight,
  );

  static const dark = AppThemeExtension(
    incomeColor: AppColors.incomeGreenDark, // Emerald 400
    expenseColor: AppColors.expenseRedDark, // Red 300 — 4.6:1 on navy
    transferColor: AppColors.transferBlueDark, // Blue 400
    warningColor: AppColors.warningDark, // Amber 400
    successColor: AppColors.successDark, // Emerald 400
    previousPeriodColor: AppColors.lastMonthGrayDark, // Slate 400 (brighter)
    previousPeriodColorAlt: AppColors.lastMonthGrayLightDark, // Slate 500
    cardSurface: AppColors.surfaceCardDark, // #27274F
    cardBorderRadius: 16.0,
    listItemRadius: 12.0,
    cardElevation: 0.0, // dark mode uses border instead of elevation
    disabledColor: AppColors.disabledDark,
    onDisabledColor: AppColors.onDisabled,
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.gradientStartDark, AppColors.gradientEndDark],
    ),
    glassSurface: AppColors.glassSurfaceDark,
    glassBorder: AppColors.glassBorderDark,
    onTransferColor: AppColors.onTransfer,
    glassCardSurface: AppColors.glassCardSurfaceDark,
    glassCardBorder: AppColors.glassCardBorderDark,
    glassSheetSurface: AppColors.glassSheetSurfaceDark,
    glassSheetBorder: AppColors.glassSheetBorderDark,
    glassInsetSurface: AppColors.glassInsetSurfaceDark,
    glassInsetBorder: AppColors.glassInsetBorderDark,
    glassShadow: AppColors.glassShadowDark,
  );

  @override
  AppThemeExtension copyWith({
    Color? incomeColor,
    Color? expenseColor,
    Color? transferColor,
    Color? warningColor,
    Color? successColor,
    Color? previousPeriodColor,
    Color? previousPeriodColorAlt,
    Color? cardSurface,
    double? cardBorderRadius,
    double? listItemRadius,
    double? cardElevation,
    Color? disabledColor,
    Color? onDisabledColor,
    LinearGradient? heroGradient,
    Color? glassSurface,
    Color? glassBorder,
    Color? onTransferColor,
    Color? glassCardSurface,
    Color? glassCardBorder,
    Color? glassSheetSurface,
    Color? glassSheetBorder,
    Color? glassInsetSurface,
    Color? glassInsetBorder,
    Color? glassShadow,
  }) =>
      AppThemeExtension(
        incomeColor: incomeColor ?? this.incomeColor,
        expenseColor: expenseColor ?? this.expenseColor,
        transferColor: transferColor ?? this.transferColor,
        warningColor: warningColor ?? this.warningColor,
        successColor: successColor ?? this.successColor,
        previousPeriodColor:
            previousPeriodColor ?? this.previousPeriodColor,
        previousPeriodColorAlt:
            previousPeriodColorAlt ?? this.previousPeriodColorAlt,
        cardSurface: cardSurface ?? this.cardSurface,
        cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
        listItemRadius: listItemRadius ?? this.listItemRadius,
        cardElevation: cardElevation ?? this.cardElevation,
        disabledColor: disabledColor ?? this.disabledColor,
        onDisabledColor: onDisabledColor ?? this.onDisabledColor,
        heroGradient: heroGradient ?? this.heroGradient,
        glassSurface: glassSurface ?? this.glassSurface,
        glassBorder: glassBorder ?? this.glassBorder,
        onTransferColor: onTransferColor ?? this.onTransferColor,
        glassCardSurface: glassCardSurface ?? this.glassCardSurface,
        glassCardBorder: glassCardBorder ?? this.glassCardBorder,
        glassSheetSurface: glassSheetSurface ?? this.glassSheetSurface,
        glassSheetBorder: glassSheetBorder ?? this.glassSheetBorder,
        glassInsetSurface: glassInsetSurface ?? this.glassInsetSurface,
        glassInsetBorder: glassInsetBorder ?? this.glassInsetBorder,
        glassShadow: glassShadow ?? this.glassShadow,
      );

  @override
  AppThemeExtension lerp(
    ThemeExtension<AppThemeExtension>? other,
    double t,
  ) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      incomeColor: Color.lerp(incomeColor, other.incomeColor, t)!,
      expenseColor: Color.lerp(expenseColor, other.expenseColor, t)!,
      transferColor: Color.lerp(transferColor, other.transferColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      previousPeriodColor:
          Color.lerp(previousPeriodColor, other.previousPeriodColor, t)!,
      previousPeriodColorAlt:
          Color.lerp(previousPeriodColorAlt, other.previousPeriodColorAlt, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardBorderRadius:
          lerpDouble(cardBorderRadius, other.cardBorderRadius, t)!,
      listItemRadius: lerpDouble(listItemRadius, other.listItemRadius, t)!,
      cardElevation: lerpDouble(cardElevation, other.cardElevation, t)!,
      disabledColor: Color.lerp(disabledColor, other.disabledColor, t)!,
      onDisabledColor:
          Color.lerp(onDisabledColor, other.onDisabledColor, t)!,
      heroGradient: t < 0.5 ? heroGradient : other.heroGradient,
      glassSurface: Color.lerp(glassSurface, other.glassSurface, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      onTransferColor:
          Color.lerp(onTransferColor, other.onTransferColor, t)!,
      glassCardSurface:
          Color.lerp(glassCardSurface, other.glassCardSurface, t)!,
      glassCardBorder:
          Color.lerp(glassCardBorder, other.glassCardBorder, t)!,
      glassSheetSurface:
          Color.lerp(glassSheetSurface, other.glassSheetSurface, t)!,
      glassSheetBorder:
          Color.lerp(glassSheetBorder, other.glassSheetBorder, t)!,
      glassInsetSurface:
          Color.lerp(glassInsetSurface, other.glassInsetSurface, t)!,
      glassInsetBorder:
          Color.lerp(glassInsetBorder, other.glassInsetBorder, t)!,
      glassShadow: Color.lerp(glassShadow, other.glassShadow, t)!,
    );
  }
}

// ── BuildContext shorthand extensions ────────────────────────────────────────
extension AppThemeX on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textStyles => Theme.of(this).textTheme;
}
