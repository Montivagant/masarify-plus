import 'package:drift/drift.dart';

import 'categories_table.dart';
import 'wallets_table.dart';

class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get walletId =>
      integer().references(Wallets, #id, onDelete: KeyAction.restrict)();
  IntColumn get categoryId =>
      integer().references(Categories, #id, onDelete: KeyAction.restrict)();
  IntColumn get amount => integer()(); // piastres
  TextColumn get type => text()(); // 'income' | 'expense'
  TextColumn get title => text()();
  // 'once' | 'daily' | 'weekly' | 'monthly' | 'yearly' | 'custom'
  // Legacy values 'biweekly' | 'quarterly' still supported in scheduler.
  TextColumn get frequency => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get nextDueDate => dateTime()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  DateTimeColumn get paidAt => dateTime().nullable()();
  // No FK to Transactions — intentional: deleting a transaction should not
  // cascade-unpay a bill. A dangling ID is harmless (display-only link).
  IntColumn get linkedTransactionId => integer().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastProcessedDate => dateTime().nullable()();
}
