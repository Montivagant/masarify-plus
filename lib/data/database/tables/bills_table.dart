import 'package:drift/drift.dart';

import 'categories_table.dart';
import 'transactions_table.dart';
import 'wallets_table.dart';

// Bills = one-off upcoming payments.
// For repeating payments use RecurringRules instead.
class Bills extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get amount => integer()(); // piastres
  IntColumn get walletId => integer().references(Wallets, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  DateTimeColumn get dueDate => dateTime()();
  BoolColumn get isPaid =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get paidAt => dateTime().nullable()();
  IntColumn get linkedTransactionId =>
      integer().nullable().references(Transactions, #id)();
}
