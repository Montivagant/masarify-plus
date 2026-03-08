import 'package:drift/drift.dart';

import '../../../domain/entities/chat_message_entity.dart';
import '../app_database.dart';
import '../tables/chat_messages_table.dart';

part 'chat_message_dao.g.dart';

@DriftAccessor(tables: [ChatMessages])
class ChatMessageDao extends DatabaseAccessor<AppDatabase>
    with _$ChatMessageDaoMixin {
  ChatMessageDao(super.db);

  /// Insert a new message and return its ID.
  Future<int> insertMessage({
    required String role,
    required String content,
    required int tokenCount,
  }) {
    return into(chatMessages).insert(
      ChatMessagesCompanion.insert(
        role: role,
        content: content,
        tokenCount: Value(tokenCount),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Watch all messages ordered by creation time (oldest first).
  Stream<List<ChatMessageEntity>> watchAll() {
    final query = select(chatMessages)
      ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]);
    return query
        .map(
          (row) => ChatMessageEntity(
            id: row.id,
            role: row.role,
            content: row.content,
            tokenCount: row.tokenCount,
            createdAt: row.createdAt,
          ),
        )
        .watch();
  }

  /// Delete all messages (clear chat).
  Future<int> deleteAll() => delete(chatMessages).go();
}
