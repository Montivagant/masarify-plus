import 'package:drift/drift.dart';

/// Persists IAP purchase records for subscription state tracking.
///
/// Replaces SharedPreferences-only storage to support:
/// - Purchase token verification on app relaunch
/// - Grace period and cancellation state tracking
/// - Expiry-based access revocation
class SubscriptionRecords extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Google Play purchase token — unique identifier for each purchase.
  TextColumn get purchaseToken => text()();

  /// Product ID (e.g., 'masarify_pro_monthly', 'masarify_pro_yearly').
  TextColumn get productId => text()();

  /// When the purchase was made.
  DateTimeColumn get purchaseDate => dateTime()();

  /// When the subscription expires. Null for lifetime purchases (not applicable yet).
  DateTimeColumn get expiryDate => dateTime().nullable()();

  /// Subscription status: 'active', 'cancelled', 'expired', 'grace_period'.
  TextColumn get status => text().withDefault(const Constant('active'))();
}
