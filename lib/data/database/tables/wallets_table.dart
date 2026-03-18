import 'package:drift/drift.dart';

class Wallets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get type =>
      text()(); // 'physical_cash' | 'bank' | 'mobile_wallet' | 'credit_card' | 'prepaid_card' | 'investment'
  IntColumn get balance =>
      integer().withDefault(const Constant(0))(); // piastres — NEVER double
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('EGP'))();
  TextColumn get iconName => text().withDefault(const Constant('wallet'))();
  TextColumn get colorHex => text().withDefault(const Constant('#1A6B5E'))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();

  /// JSON array of SMS sender addresses / notification package names
  /// linked to this wallet for auto-routing parsed transactions.
  TextColumn get linkedSenders => text().withDefault(const Constant('[]'))();

  /// True for the mandatory Physical Cash system wallet (auto-created, non-deletable).
  BoolColumn get isSystemWallet =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
