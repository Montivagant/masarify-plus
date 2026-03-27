/// App-wide feature flags.
/// All flags are OFF by default — enable only when the phase is explicitly active.
abstract final class AppConfig {
  /// SMS transaction parsing — HIDDEN (P5 strategic pivot to AI-first).
  /// Code preserved for future Pro-tier re-enablement. See plan for details.
  static const bool kSmsEnabled = false;

  /// In-app purchases / monetization — enabled (P5).
  static const bool kMonetizationEnabled = true;
}
