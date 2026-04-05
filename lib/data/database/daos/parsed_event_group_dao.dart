import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/parsed_event_groups_table.dart';
import '../tables/sms_parser_logs_table.dart';

part 'parsed_event_group_dao.g.dart';

@DriftAccessor(tables: [ParsedEventGroups, SmsParserLogs])
class ParsedEventGroupDao extends DatabaseAccessor<AppDatabase>
    with _$ParsedEventGroupDaoMixin {
  ParsedEventGroupDao(super.db);

  Future<List<ParsedEventGroup>> getAll() => select(parsedEventGroups).get();

  Future<int> insertRow(ParsedEventGroupsCompanion entry) =>
      into(parsedEventGroups).insert(entry);

  Future<void> deleteById(int id) =>
      (delete(parsedEventGroups)..where((t) => t.id.equals(id))).go();
}
