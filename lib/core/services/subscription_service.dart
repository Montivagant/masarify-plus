import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Product IDs — must match Google Play Console configuration.
abstract final class SubscriptionIds {
  static const String monthlyPro = 'masarify_pro_monthly';
  static const String yearlyPro = 'masarify_pro_yearly';

  static const Set<String> all = {monthlyPro, yearlyPro};
}

/// Manages in-app subscription state via Google Play Billing.
///
/// Exposes a [proStatusStream] that emits `true` when the user has
/// an active Pro subscription or is within the free trial period.
///
/// Trial logic: 7-day free trial starting after onboarding. Stored locally
/// in SharedPreferences — not enforced server-side (acceptable for v1).
class SubscriptionService {
  SubscriptionService(this._prefs);

  final SharedPreferences _prefs;

  static const _kTrialStartDate = 'trial_start_date';
  static const _kProActive = 'pro_active';
  static const _kSubscriptionValidatedAt = 'subscription_validated_at';
  static const _trialDays = 7;

  /// Grace period: monthly billing cycle + 3-day buffer.
  /// If the subscription wasn't re-validated within this window, consider
  /// it potentially expired and require re-validation via the store.
  static const _subscriptionGraceDays = 33;

  final _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSub;
  final _proController = StreamController<bool>.broadcast();
  bool _isRestoring = false;

  /// Stream of Pro status changes.
  Stream<bool> get proStatusStream => _proController.stream;

  /// Current Pro status (subscription OR trial).
  bool get isPro => _prefs.getBool(_kProActive) ?? false;

  /// Days remaining in trial, or 0 if expired/not started.
  /// Compares at midnight boundaries for consistent calendar-day precision.
  int get trialDaysRemaining {
    final startStr = _prefs.getString(_kTrialStartDate);
    if (startStr == null) return _trialDays; // Not started = full trial
    final start = DateTime.tryParse(startStr);
    if (start == null) return 0;
    final startDate = DateTime(start.year, start.month, start.day);
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final elapsed = todayDate.difference(startDate).inDays;
    return (elapsed < _trialDays) ? _trialDays - elapsed : 0;
  }

  /// Whether the user is currently in the free trial period.
  bool get isInTrial => trialDaysRemaining > 0;

  /// Whether the paid subscription has gone stale (not re-validated within
  /// the grace period). Returns false if not Pro (nothing to expire).
  bool get _isSubscriptionStale {
    if (!isPro) return false;
    final validatedStr = _prefs.getString(_kSubscriptionValidatedAt);
    if (validatedStr == null) return true; // Never validated → stale
    final validated = DateTime.tryParse(validatedStr);
    if (validated == null) return true;
    return DateTime.now().difference(validated).inDays > _subscriptionGraceDays;
  }

  /// Whether the user has any Pro access (subscription OR trial).
  /// C-2: Returns cached isPro during restore to prevent flicker.
  /// A paid subscription is considered expired if it hasn't been re-validated
  /// within [_subscriptionGraceDays] days (handles lapsed subscriptions).
  bool get hasProAccess {
    if (_isRestoring) return isPro;
    return (isPro && !_isSubscriptionStale) || isInTrial;
  }

  /// Start the trial if not already started.
  Future<void> ensureTrialStarted() async {
    if (_prefs.getString(_kTrialStartDate) != null) return;
    await _prefs.setString(
      _kTrialStartDate,
      DateTime.now().toIso8601String(),
    );
  }

  /// Initialize the IAP connection and listen for purchases.
  Future<void> initialize() async {
    final available = await _iap.isAvailable();
    if (!available) return;

    // Listen for purchase updates.
    _purchaseSub = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (_) {},
    );

    // Check for any pending purchases on startup.
    await _restorePurchases();
  }

  /// Fetch available products from the store.
  Future<List<ProductDetails>> getProducts() async {
    final available = await _iap.isAvailable();
    if (!available) return [];

    final response = await _iap.queryProductDetails(SubscriptionIds.all);
    return response.productDetails;
  }

  /// Initiate a purchase flow for the given product.
  Future<void> purchase(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  /// Restore previous purchases (e.g., after reinstall).
  /// C-2 fix: removed preemptive false reset — Pro status will be set by
  /// _handlePurchaseUpdates if a valid purchase exists.
  Future<void> _restorePurchases() async {
    _isRestoring = true;
    try {
      await _iap.restorePurchases();
    } finally {
      _isRestoring = false;
    }
  }

  /// Public restore for the settings/paywall "Restore" button.
  Future<void> restorePurchases() => _restorePurchases();

  /// Re-validate subscription with the store. Call on app resume to detect
  /// lapsed subscriptions. Resets Pro status and re-checks via Play Billing.
  Future<void> revalidate() async {
    final available = await _iap.isAvailable();
    if (!available) return;
    await _restorePurchases();
  }

  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _activatePro();
          if (purchase.pendingCompletePurchase) {
            _iap.completePurchase(purchase);
          }
        case PurchaseStatus.error:
        case PurchaseStatus.canceled:
          // No action needed — user cancelled or error occurred.
          break;
        case PurchaseStatus.pending:
          // Payment processing — do nothing until resolved.
          break;
      }
    }
  }

  Future<void> _activatePro() async {
    await _prefs.setBool(_kProActive, true);
    await _prefs.setString(
      _kSubscriptionValidatedAt,
      DateTime.now().toIso8601String(),
    );
    _proController.add(true);
  }

  /// Dispose the purchase stream subscription.
  void dispose() {
    _purchaseSub?.cancel();
    _proController.close();
  }
}
