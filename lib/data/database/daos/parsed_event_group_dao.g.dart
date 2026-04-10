// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parsed_event_group_dao.dart';

// ignore_for_file: type=lint
mixin _$ParsedEventGroupDaoMixin on DatabaseAccessor<AppDatabase> {
  $SmsParserLogsTable get smsParserLogs => attachedDatabase.smsParserLogs;
  $ParsedEventGroupsTable get parsedEventGroups =>
      attachedDatabase.parsedEventGroups;
  ParsedEventGroupDaoManager get managers => ParsedEventGroupDaoManager(this);
}

class ParsedEventGroupDaoManager {
  final _$ParsedEventGroupDaoMixin _db;
  ParsedEventGroupDaoManager(this._db);
  $$SmsParserLogsTableTableManager get smsParserLogs =>
      $$SmsParserLogsTableTableManager(_db.attachedDatabase, _db.smsParserLogs);
  $$ParsedEventGroupsTableTableManager get parsedEventGroups =>
      $$ParsedEventGroupsTableTableManager(
          _db.attachedDatabase, _db.parsedEventGroups);
}
