import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/subscription_records_table.dart';

part 'subscription_record_dao.g.dart';

@DriftAccessor(tables: [SubscriptionRecords])
class SubscriptionRecordDao extends DatabaseAccessor<AppDatabase>
    with _$SubscriptionRecordDaoMixin {
  SubscriptionRecordDao(super.db);

  /// Insert or update a subscription record keyed by purchaseToken.
  Future<void> upsertRecord({
    required String purchaseToken,
    required String productId,
    required DateTime purchaseDate,
    DateTime? expiryDate,
    String status = 'active',
  }) async {
    final existing = await (select(subscriptionRecords)
          ..where((r) => r.purchaseToken.equals(purchaseToken)))
        .getSingleOrNull();

    if (existing != null) {
      await (update(subscriptionRecords)
            ..where((r) => r.id.equals(existing.id)))
          .write(
        SubscriptionRecordsCompanion(
          productId: Value(productId),
          expiryDate: Value(expiryDate),
          status: Value(status),
        ),
      );
    } else {
      await into(subscriptionRecords).insert(
        SubscriptionRecordsCompanion.insert(
          purchaseToken: purchaseToken,
          productId: productId,
          purchaseDate: purchaseDate,
          expiryDate: Value(expiryDate),
          status: Value(status),
        ),
      );
    }
  }

  /// Get the most recent active subscription record.
  Future<SubscriptionRecord?> getActiveSubscription() async {
    return (select(subscriptionRecords)
          ..where((r) => r.status.equals('active'))
          ..orderBy([(r) => OrderingTerm.desc(r.purchaseDate)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Update the status of a subscription by purchaseToken.
  Future<void> updateStatus(String purchaseToken, String status) async {
    await (update(subscriptionRecords)
          ..where((r) => r.purchaseToken.equals(purchaseToken)))
        .write(SubscriptionRecordsCompanion(status: Value(status)));
  }

  /// Get all subscription records (for debugging/settings display).
  Future<List<SubscriptionRecord>> getAll() async {
    return (select(subscriptionRecords)
          ..orderBy([(r) => OrderingTerm.desc(r.purchaseDate)]))
        .get();
  }
}
