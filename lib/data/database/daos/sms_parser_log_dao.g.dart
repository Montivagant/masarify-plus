// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sms_parser_log_dao.dart';

// ignore_for_file: type=lint
mixin _$SmsParserLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $SmsParserLogsTable get smsParserLogs => attachedDatabase.smsParserLogs;
  SmsParserLogDaoManager get managers => SmsParserLogDaoManager(this);
}

class SmsParserLogDaoManager {
  final _$SmsParserLogDaoMixin _db;
  SmsParserLogDaoManager(this._db);
  $$SmsParserLogsTableTableManager get smsParserLogs =>
      $$SmsParserLogsTableTableManager(_db.attachedDatabase, _db.smsParserLogs);
}
