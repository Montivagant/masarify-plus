import 'dart:math' as math;

/// Masarify spacing, radius, elevation, and icon size constants.
/// NEVER hardcode dp values in widgets — use these constants.
abstract final class AppSizes {
  // ── Spacing scale (multiples of 4dp) ──────────────────────────────────
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // ── Border radius ──────────────────────────────────────────────────────
  static const double borderRadiusXs = 4;
  static const double borderRadiusSm = 8;
  static const double borderRadiusMdSm = 12; // Between sm(8) and md(16)
  static const double borderRadiusMd = 16;
  static const double borderRadiusLg = 24;
  static const double borderRadiusFull = 100;

  // ── Elevation ─────────────────────────────────────────────────────────
  static const double elevationNone = 0;
  static const double elevationLow = 1;
  static const double elevationMedium = 2;
  static const double elevationHigh = 4;

  // ── Icon sizes ────────────────────────────────────────────────────────
  static const double iconXxs = 12;
  static const double iconXxs2 = 14;
  static const double iconXs = 16;
  static const double iconSm2 = 18;
  static const double iconSm = 20;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double iconXl = 48;
  static const double iconXl2 = 56;
  static const double iconXl3 = 64;

  // ── Layout ────────────────────────────────────────────────────────────
  static const double screenHPadding = md; // Horizontal screen edge padding
  static const double bottomScrollPadding = 120; // nav bar (64) + margin (16) + FAB clearance (40)
  static const double bottomNavHeight = 64; // WS-6: M3 standard height
  static const double appBarHeight = 56;
  static const double fabSize = 56;
  static const double minTapTarget = 48; // Accessibility: min touch target

  // ── Fine spacing ─────────────────────────────────────────────────────
  static const double xxs = 2;

  // ── Icon containers ─────────────────────────────────────────────────
  static const double iconContainerXs = 28;
  static const double iconContainerSm = 32;
  static const double colorSwatchSize = 36;
  static const double iconContainerMd = 40;
  static const double iconContainerLg = 44;
  static const double categoryChipSize = 52;

  // ── Progress rings ──────────────────────────────────────────────────
  static const double progressRingSm = 56;
  static const double progressRingInner = 72;
  static const double voiceMicSize = 72;
  static const double progressRingLg = 96;
  static const double onboardingIcon = 120;

  // ── Chart heights ───────────────────────────────────────────────────
  static const double chartHeightSm = 160;
  static const double chartHeightMd = 200;
  static const double chartHeightLg = 220;
  static const double chartHeightXl = 240;

  // ── Drag handle ─────────────────────────────────────────────────────
  static const double dragHandleWidth = 40;
  static const double dragHandleHeight = 4;

  // ── Shimmer placeholders ────────────────────────────────────────────
  static const double shimmerTextHeight = 14;
  static const double shimmerTextHeightSm = 11;

  // ── Dots / indicators ───────────────────────────────────────────────
  static const double dotSm = 6;
  static const double indicatorDotSize = 8.0;
  static const double dotMd = 10;
  static const double dotLg = 12;

  // ── Chart bars & labels ─────────────────────────────────────────────
  static const double chartBarWidth = 20;
  static const double progressBarHeight = 8;
  static const double chartLabelSize = 11;

  // ── Color picker ────────────────────────────────────────────────────
  static const double colorSwatchBorder = 3.0;

  // ── Dashboard carousel ─────────────────────────────────────────────
  static const double carouselHeight = 240;
  static const double fabVerticalOffset = 10;

  // ── Misc ────────────────────────────────────────────────────────────
  static const double spinnerSize = 20;
  static const double dividerHeight = 1.0;
  static const double barChartWidth = 12.0;
  static const double comparisonColumnWidth = 64.0;
  static const double pinKeypadButtonSize = 72.0;
  static const double shimmerWidthLg = 100.0;
  static const double shimmerWidthSm = 60.0;
  static const double screenVPadding = md;

  // ── Line heights ──────────────────────────────────────────────────────
  static const double lineHeightRelaxed = 1.6;
  static const double lineHeightNormal = 1.5;

  // ── Opacity scale ─────────────────────────────────────────────────────
  static const double opacityNone = 0.0;
  static const double opacityXLight2 = 0.06;
  static const double opacitySubtle = 0.08;
  static const double opacityXLight = 0.1;
  static const double opacityLight2 = 0.12;
  static const double opacityLight = 0.15;
  static const double opacityLight3 = 0.2;
  static const double opacityQuarter = 0.25;
  static const double opacityLight4 = 0.3;
  static const double opacityLight5 = 0.4;
  static const double opacityMedium = 0.5;
  static const double opacityMedium2 = 0.6;
  static const double opacityStrong = 0.7;
  static const double opacityHeavy = 0.8;
  static const double opacityNearFull = 0.85;

  // ── FAB (Speed Dial) ─────────────────────────────────────────────────
  static const double fabRotationAngle = math.pi / 4;

  // ── Nav bar (notched glass) ────────────────────────────────────────
  static const double navNotchRadius = 30.0;
  static const double navNotchMargin = 2.0;
  static const double navPillHeight = 36.0;
  static const double navPillPadding = 12.0;
  static const double navPillGlowRadius = 12.0;
  static const double navPillGlowOpacity = 0.3;
  static const double navShadowBlur = 16.0;
  static const double navShadowOffsetY = -2.0;
  static const double splashIconSize = 80.0;

  // ── Speed dial ─────────────────────────────────────────────────────
  static const double speedDialButtonHeight = 44.0;
  static const double speedDialButtonRadius = 22.0;
  static const double speedDialSpacing = 10.0;
  static const double speedDialIconSize = 20.0;
  static const double speedDialOffset = 12.0;
  static const double speedDialContainerWidth = 160.0;
  static const double speedDialSlideOffset = 20.0;

  // ── Nav pill ───────────────────────────────────────────────────────
  static const double navPillWidth = 72.0;

  // ── Card ──────────────────────────────────────────────────────────────
  static const double cardPadding = md;
  static const double cardRadius = borderRadiusMd;
  static const double cardElevation = elevationLow;

  // ── Pie chart ──────────────────────────────────────────────────────────
  static const double pieChartRadius = 36.0; // WS-9: increased from 28
  static const double pieChartCenterRadius = 60.0; // WS-9: increased from 52
  static const double pieChartSectionSpace = 2.0;

  // ── Glass / Gradient (WS-7) ──────────────────────────────────────────
  static const double glassBlurSigma = 12.0;
  static const double glassBorderWidth = 1.0;
  static const double gradientBorderRadius = 24.0;

  // ── Glass hierarchy (3-tier iOS Control Center style) ──────────────
  static const double glassBlurBackground = 20.0; // Tier 1: sheets, dialogs
  static const double glassBlurCard = 12.0; // Tier 2: cards, sections
  static const double glassBlurInset = 8.0; // Tier 3: nested elements
  static const double glassBorderWidthSubtle = 0.5; // Tier 1 border

  // ── Decorative circles (balance card) ──────────────────────────────
  static const double decorCircleLg = 100.0;
  static const double decorCircleSm = 80.0;
  static const double decorCircleLgOffset = -20.0;
  static const double decorCircleSmOffsetBottom = -30.0;
  static const double decorCircleSmOffsetStart = -15.0;
  static const double decorCircleLgOpacity = 0.08;
  static const double decorCircleSmOpacity = 0.05;

  // ── Dashboard sections (WS-8) ────────────────────────────────────────
  static const double sectionGap = 16.0;

  // ── Insight cards ──────────────────────────────────────────────────
  static const double insightCardListHeight = 72.0;
  static const double insightCardMaxWidth = 180.0;

  // ── Smart defaults / Quick Add ──────────────────────────────────────
  static const double borderWidthEmphasis = 1.5;
  static const int quickAddMinOccurrences = 3;
  static const int quickAddMaxItems = 3;
  static const int categoryChipMaxVisible = 6;

  // ── Chat ──────────────────────────────────────────────────────────────
  static const double chatBubbleMaxWidthFraction = 0.78;

  // ── Bottom sheet (WS-22) ─────────────────────────────────────────────
  static const double bottomSheetHeightRatio = 0.5;

  // ── PDF layout ────────────────────────────────────────────────────────
  static const double pdfMargin = 32.0;
  static const double pdfCellPadding = 6.0;
  static const double pdfCellPaddingSm = 4.0;
  static const double pdfTitleFontSize = 20.0;
  static const double pdfSubtitleFontSize = 14.0;
  static const double pdfBodyFontSize = 11.0;
  static const double pdfSmallFontSize = 9.0;
  static const double pdfSummaryFontSize = 16.0;
}
