import 'package:drift/drift.dart';

import 'categories_table.dart';
import 'recurring_rules_table.dart';
import 'savings_goals_table.dart';
import 'wallets_table.dart';

// NOTE: Wallet-to-wallet transfers use the Transfers table instead.
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get walletId => integer().references(Wallets, #id)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  IntColumn get amount => integer()(); // always positive, in piastres
  TextColumn get type => text()(); // 'income' | 'expense'
  TextColumn get currencyCode =>
      text().withLength(min: 3, max: 3).withDefault(const Constant('EGP'))();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  TextColumn get receiptImagePath => text().nullable()();
  TextColumn get tags =>
      text().withDefault(const Constant(''))(); // comma-separated

  // Location (optional)
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  TextColumn get locationName => text().nullable()();

  // Source tracking — MANDATORY for non-manual entries
  TextColumn get source =>
      text().withDefault(const Constant('manual'))();
  // Values: 'manual' | 'voice' | 'sms' | 'notification' | 'import' | 'ai_chat'
  TextColumn get rawSourceText =>
      text().nullable()(); // original SMS body or voice transcript

  // Recurring link
  BoolColumn get isRecurring =>
      boolean().withDefault(const Constant(false))();
  IntColumn get recurringRuleId =>
      integer().nullable().references(RecurringRules, #id)();

  // Goal link
  IntColumn get goalId =>
      integer().nullable().references(SavingsGoals, #id)();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}
