import 'package:drift/drift.dart';

import 'wallets_table.dart';

// Wallet-to-wallet transfers — NEVER counted as income or expense.
class Transfers extends Table {
  IntColumn get id => integer().autoIncrement()();
  @ReferenceName('fromTransfers')
  IntColumn get fromWalletId =>
      integer().references(Wallets, #id, onDelete: KeyAction.restrict)();
  @ReferenceName('toTransfers')
  IntColumn get toWalletId =>
      integer().references(Wallets, #id, onDelete: KeyAction.restrict)();
  IntColumn get amount => integer()(); // piastres
  IntColumn get fee => integer().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get transferDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
