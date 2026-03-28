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
  static const double bottomScrollPadding =
      130; // nav bar (64) + margin (16) + raised FAB clearance (50)
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
  static const double onboardingDemoHeight = 260;

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
  static const double indicatorDotGap = 3.0;
  static const double dotMd = 10;
  static const double dotLg = 12;

  // ── Chart bars & labels ─────────────────────────────────────────────
  static const double chartBarWidth = 20;
  static const double chartLineWidth = 3.0;
  static const double chartDotRadius = 4.0;
  static const double chartDotStrokeWidth = 2.0;
  static const double chartShadowBlur = 8.0;
  static const double chartShadowOffsetY = 4.0;
  static const double chartBarRowHeight = 64.0;
  static const double chartBarHeaderHeight = 48.0;
  static const double chartAxisReservedSm = 48.0;
  static const double chartAxisReservedMd = 80.0;
  static const double progressBarHeight = 8;
  static const double progressBarHeightSm = 4.0;
  static const double chartLabelSize = 11;

  // ── Color picker ────────────────────────────────────────────────────
  static const double colorSwatchBorder = 3.0;

  // ── Dashboard carousel ─────────────────────────────────────────────
  static const double carouselHeight = 240;
  static const double carouselViewportFraction = 0.92;
  static const double fabVerticalOffset = 24;

  /// Snackbar bottom margin — minimal gap only.
  /// Flutter's Scaffold auto-offsets floating SnackBars above the FAB.
  /// Explicit large margins stack on top of that, pushing to mid-screen.
  static const double snackbarBottomMargin = sm;

  // ── SnackBar / Toast ──────────────────────────────────────────────────
  static const double snackTextSize = 13.0;
  static const double snackBorderRadius = 12.0;
  static const double snackVerticalPadding = 10.0;
  static const double snackHorizontalMargin = 24.0;
  static const double snackElevation = 4.0;

  // ── Brand icon ──────────────────────────────────────────────────────
  static const double brandIconFontLarge = 11;
  static const double brandIconFontSmall = 8;

  // ── Border widths ───────────────────────────────────────────────────
  static const double borderWidth = 1.0;
  static const double borderWidthFocus = 2.0;
  static const double borderWidthSelected = 2.5;

  // ── Shadow presets ────────────────────────────────────────────────
  static const double heroShadowBlur = 16.0;
  static const double heroShadowOffsetY = 6.0;
  static const double cardShadowBlur = 12.0;
  static const double cardShadowOffsetY = 4.0;

  // ── Voice input ────────────────────────────────────────────────────
  static const double voiceMicGlowRadius = 0.3;

  // ── Voice wave bars ──────────────────────────────────────────────────
  static const int voiceBarCount = 24;
  static const double voiceBarWidth = 3.0;
  static const double voiceBarGap = 2.0;
  static const double voiceBarMinHeight = 4.0;
  static const double voiceBarMaxHeight = 40.0;
  static const double voiceWaveContainerHeight = 60.0;

  // ── List wheel ────────────────────────────────────────────────────
  static const double listWheelItemExtent = 40.0;

  // ── Misc ────────────────────────────────────────────────────────────
  static const double spinnerSize = 20;
  static const double spinnerSizeSm = 16;
  static const double spinnerStrokeWidth = 2.0;
  static const double dividerHeight = 1.0;
  static const double barChartWidth = 12.0;
  static const double comparisonColumnWidth = 64.0;
  static const double pinKeypadButtonSize = 72.0;
  static const double shimmerWidthLg = 100.0;
  static const double shimmerWidthSm = 60.0;

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
  static const double opacityDisabled = 0.38;
  static const double opacityMedium = 0.5;
  static const double opacityMedium2 = 0.6;
  static const double opacityStrong = 0.7;
  static const double opacityHeavy = 0.8;

  // ── FAB (Speed Dial) ─────────────────────────────────────────────────
  static const double fabRotationAngle = math.pi / 4;

  // ── Nav bar ───────────────────────────────────────────────────────
  static const double navShadowBlur = 16.0;
  static const double navShadowOffsetY = -2.0;
  static const double splashIconSize = 80.0;

  // ── Speed dial ─────────────────────────────────────────────────────
  static const double speedDialButtonSize =
      48.0; // circular, meets minTapTarget
  static const double speedDialArcRadius = 110.0; // FAB center to button center
  static const double speedDialArcWidth = 280.0; // container width
  static const double speedDialArcHeight = 220.0; // container height
  static const double speedDialIconSize = 20.0;
  static const double speedDialLabelGap = 4.0; // circle to label gap

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
  static const int categoryChipMaxVisible = 6;

  // ── Chat ──────────────────────────────────────────────────────────────
  static const double chatBubbleMaxWidthFraction = 0.78;
  static const double chatActionLabelWidth = 80.0;

  // ── Bottom sheet (WS-22) ─────────────────────────────────────────────
  static const double bottomSheetHeightRatio = 0.5;

  // ── DraggableScrollableSheet fractions ────────────────────────────────
  static const double sheetInitialSize = 0.6;
  static const double sheetMinSize = 0.3;
  static const double sheetMaxSize = 0.85;
  static const double sheetSmallInitialSize = 0.4;
  static const double sheetSmallMaxSize = 0.6;
  static const double sheetFullSize = 0.95;

  // ── Onboarding ─────────────────────────────────────────────────────────
  static const double onboardingFeatureCardHeight = 200.0;
  static const double onboardingParallaxOffset = 30.0;

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
