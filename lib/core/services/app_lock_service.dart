/// H2 fix: global lock state to prevent deep-link PIN bypass.
///
/// Tracks whether the app has been unlocked (via PIN or biometric).
/// Checked by GoRouter redirect guard.
class AppLockService {
  AppLockService._();
  static final instance = AppLockService._();

  bool _isUnlocked = false;
  bool _requiresAuth = false;

  /// Whether the app has been unlocked this session.
  bool get isUnlocked => _isUnlocked;

  /// Whether the app requires authentication (PIN is enabled).
  /// Set by splash screen based on preferences.
  bool get requiresAuth => _requiresAuth;

  /// Set whether authentication is required (called by splash screen).
  void setRequiresAuth(bool value) => _requiresAuth = value;

  /// Mark the app as unlocked (called after successful PIN/biometric auth).
  void unlock() => _isUnlocked = true;

  /// Lock the app (called on app lifecycle pause after timeout).
  void lock() => _isUnlocked = false;
}
