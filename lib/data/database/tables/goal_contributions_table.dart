import 'package:drift/drift.dart';

import 'savings_goals_table.dart';

// Separate contribution tracking from main transactions.
class GoalContributions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get goalId => integer().references(SavingsGoals, #id)();
  IntColumn get amount => integer()(); // piastres
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
}
