import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/parsed_event_groups_table.dart';
import '../tables/sms_parser_logs_table.dart';

part 'parsed_event_group_dao.g.dart';

@DriftAccessor(tables: [ParsedEventGroups, SmsParserLogs])
class ParsedEventGroupDao extends DatabaseAccessor<AppDatabase>
    with _$ParsedEventGroupDaoMixin {
  ParsedEventGroupDao(super.db);
}
