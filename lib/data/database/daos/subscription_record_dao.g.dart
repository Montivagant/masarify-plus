// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_record_dao.dart';

// ignore_for_file: type=lint
mixin _$SubscriptionRecordDaoMixin on DatabaseAccessor<AppDatabase> {
  $SubscriptionRecordsTable get subscriptionRecords =>
      attachedDatabase.subscriptionRecords;
  SubscriptionRecordDaoManager get managers =>
      SubscriptionRecordDaoManager(this);
}

class SubscriptionRecordDaoManager {
  final _$SubscriptionRecordDaoMixin _db;
  SubscriptionRecordDaoManager(this._db);
  $$SubscriptionRecordsTableTableManager get subscriptionRecords =>
      $$SubscriptionRecordsTableTableManager(
          _db.attachedDatabase, _db.subscriptionRecords);
}
