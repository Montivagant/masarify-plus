abstract final class AppDurations {
  static const Duration pinPadAnim = Duration(milliseconds: 400);
  static const Duration dotPulse = Duration(milliseconds: 150);
  static const Duration countUp = Duration(milliseconds: 600);
  static const Duration progressAnim = Duration(milliseconds: 800);

  // Staggered list entry animations
  static const Duration listItemEntry = Duration(milliseconds: 350);

  // FAB expand/collapse
  static const Duration fabExpand = Duration(milliseconds: 250);

  // Splash & onboarding
  static const Duration splashFade = Duration(milliseconds: 1200);
  static const Duration splashHold = Duration(milliseconds: 1500);
  static const Duration pageTransition = Duration(milliseconds: 350);

  // Quick animation
  static const Duration animQuick = Duration(milliseconds: 200);

  // Snackbar
  static const Duration snackbarShort = Duration(seconds: 2);
  static const Duration snackbarDefault = Duration(seconds: 3);
  static const Duration snackbarError = Duration(seconds: 4);
  static const Duration snackbarLong = Duration(seconds: 5);

  // Timeouts
  static const Duration dnsLookupTimeout = Duration(seconds: 3);
  static const Duration geocodeTimeout = Duration(seconds: 5);
  static const Duration locationTimeout = Duration(seconds: 10);
  static const Duration aiHttpTimeout = Duration(seconds: 30);
  static const Duration lockoutDuration = Duration(seconds: 30);
  static const Duration lockoutDurationMid = Duration(minutes: 5);
  static const Duration lockoutDurationMax = Duration(minutes: 30);
  static const Duration voiceMaxRecording = Duration(seconds: 60);

  // Micro-interactions
  static const Duration microBounce = Duration(milliseconds: 200);
  static const Duration microPress = Duration(milliseconds: 150);
  static const Duration microRelease = Duration(milliseconds: 100);
  static const Duration staggerDelay = Duration(milliseconds: 50);

  // Onboarding
  static const Duration onboardingParallax = Duration(milliseconds: 500);
  static const Duration onboardingCardSwipe = Duration(milliseconds: 400);
  static const Duration onboardingTextDelay1 = Duration(milliseconds: 200);
  static const Duration onboardingTextDelay2 = Duration(milliseconds: 350);
  static const Duration onboardingCtaDelay = Duration(milliseconds: 500);
  static const Duration onboardingDemoDelay1 = Duration(milliseconds: 400);
  static const Duration onboardingDemoDelay2 = Duration(milliseconds: 600);
  static const Duration onboardingDemoDelay3 = Duration(milliseconds: 700);
  static const Duration onboardingDemoDelay4 = Duration(milliseconds: 800);
  static const Duration onboardingDemoDelay5 = Duration(milliseconds: 1100);
  static const Duration onboardingPulse = Duration(milliseconds: 1500);

  // Voice
  static const Duration voiceRecordingTick = Duration(seconds: 1);
  static const Duration voiceBarUpdate = Duration(milliseconds: 50);
  static const Duration voiceShimmer = Duration(milliseconds: 1500);

  // Search
  static const int searchDebounceMs = 300;
  static const Duration searchDebounce =
      Duration(milliseconds: searchDebounceMs);

  // Service delays
  static const Duration listenerBindDelay = Duration(seconds: 3);

  // Temp file cleanup
  static const Duration tempFileCleanupDelay = Duration(seconds: 2);

  // Category suggestion debounce
  static const Duration categorySuggestionDebounce =
      Duration(milliseconds: 500);

  // Smart defaults
  static const Duration transactionDedupeWindow = Duration(minutes: 10);

  // Chat
  static const Duration typingIndicator = Duration(milliseconds: 400);

  // Date pickers
  static const Duration datePickerMaxOffset = Duration(days: 365 * 5);
}
