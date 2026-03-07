abstract final class AppDurations {
  static const Duration pinPadAnim = Duration(milliseconds: 400);
  static const Duration dotPulse = Duration(milliseconds: 150);
  static const Duration countUp = Duration(milliseconds: 600);
  static const Duration progressAnim = Duration(milliseconds: 800);

  // Staggered list entry animations
  static const Duration listItemEntry = Duration(milliseconds: 350);
  static const Duration listItemStagger = Duration(milliseconds: 50);

  // FAB expand/collapse
  static const Duration fabExpand = Duration(milliseconds: 250);

  // Nav bar pill slide
  static const Duration navPillSlide = Duration(milliseconds: 300);



  // Splash & onboarding
  static const Duration splashFade = Duration(milliseconds: 1200);
  static const Duration splashHold = Duration(milliseconds: 1500);
  static const Duration pageTransition = Duration(milliseconds: 350);

  // Quick animation
  static const Duration animQuick = Duration(milliseconds: 200);

  // Delays
  static const Duration delaySmall = Duration(milliseconds: 500);
  static const Duration retryDelay = Duration(seconds: 1);

  // Snackbar
  static const Duration snackbarDefault = Duration(seconds: 3);
  static const Duration snackbarError = Duration(seconds: 4);
  static const Duration snackbarLong = Duration(seconds: 5);

  // Timeouts
  static const Duration voiceTimeout = Duration(seconds: 2);
  static const Duration geocodeTimeout = Duration(seconds: 5);
  static const Duration locationTimeout = Duration(seconds: 10);
  static const Duration voiceListenTimeout = Duration(seconds: 20);
  static const Duration aiHttpTimeout = Duration(seconds: 30);
  static const Duration lockoutDuration = Duration(seconds: 30);
  static const Duration voiceMaxRecording = Duration(seconds: 60);

  // Service delays
  static const Duration listenerBindDelay = Duration(seconds: 3);
}
