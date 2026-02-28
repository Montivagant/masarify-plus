/// App-wide feature flags.
/// All flags are OFF by default — enable only when the phase is explicitly active.
abstract final class AppConfig {
  /// SMS transaction parsing — enabled (owner-approved).
  static const bool kSmsEnabled = true;

  /// In-app purchases / monetization — enable only in Phase 5
  /// after 1000+ active users.
  static const bool kMonetizationEnabled = false;
}
