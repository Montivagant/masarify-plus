import 'package:drift/drift.dart';

/// Persistent chat messages for AI conversation.
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get role => text()(); // 'user' | 'assistant' | 'system'
  TextColumn get content => text()();
  IntColumn get tokenCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}
