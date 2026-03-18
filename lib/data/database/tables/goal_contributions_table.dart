import 'package:drift/drift.dart';

import 'savings_goals_table.dart';
import 'wallets_table.dart';

// Separate contribution tracking from main transactions.
class GoalContributions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId =>
      integer().references(SavingsGoals, #id, onDelete: KeyAction.cascade)();
  IntColumn get amount => integer()(); // piastres
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();

  /// The wallet that was deducted when this contribution was made.
  /// Null for legacy contributions created before wallet-deduction was added.
  IntColumn get walletId => integer()
      .nullable()
      .references(Wallets, #id, onDelete: KeyAction.setNull)();
}
