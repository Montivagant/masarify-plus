import 'package:drift/drift.dart';

import 'wallets_table.dart';

class SavingsGoals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 80)();
  TextColumn get iconName => text()();
  TextColumn get colorHex => text()();
  IntColumn get targetAmount => integer()(); // piastres
  IntColumn get currentAmount =>
      integer().withDefault(const Constant(0))(); // piastres
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('EGP'))();
  DateTimeColumn get deadline => dateTime().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  // JSON array of keyword strings: ["Noon","laptop","سفر","تذكرة"]
  TextColumn get keywords => text().withDefault(const Constant('[]'))();
  IntColumn get walletId => integer()
      .nullable()
      .references(Wallets, #id, onDelete: KeyAction.setNull)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
