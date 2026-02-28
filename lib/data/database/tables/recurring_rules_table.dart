import 'package:drift/drift.dart';

import 'categories_table.dart';
import 'wallets_table.dart';

class RecurringRules extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get walletId => integer().references(Wallets, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get amount => integer()(); // piastres
  TextColumn get type => text()(); // 'income' | 'expense'
  TextColumn get title => text()();
  TextColumn get frequency => text()();
  // 'daily' | 'weekly' | 'biweekly' | 'monthly' | 'quarterly' | 'yearly'
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get nextDueDate => dateTime()();
  BoolColumn get autoLog =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastProcessedDate => dateTime().nullable()();
}
