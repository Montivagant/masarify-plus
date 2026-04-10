// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer_dao.dart';

// ignore_for_file: type=lint
mixin _$TransferDaoMixin on DatabaseAccessor<AppDatabase> {
  $WalletsTable get wallets => attachedDatabase.wallets;
  $TransfersTable get transfers => attachedDatabase.transfers;
  TransferDaoManager get managers => TransferDaoManager(this);
}

class TransferDaoManager {
  final _$TransferDaoMixin _db;
  TransferDaoManager(this._db);
  $$WalletsTableTableManager get wallets =>
      $$WalletsTableTableManager(_db.attachedDatabase, _db.wallets);
  $$TransfersTableTableManager get transfers =>
      $$TransfersTableTableManager(_db.attachedDatabase, _db.transfers);
}
