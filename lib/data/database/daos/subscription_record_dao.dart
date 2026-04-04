import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/subscription_records_table.dart';

part 'subscription_record_dao.g.dart';

@DriftAccessor(tables: [SubscriptionRecords])
class SubscriptionRecordDao extends DatabaseAccessor<AppDatabase>
    with _$SubscriptionRecordDaoMixin {
  SubscriptionRecordDao(super.db);
}
