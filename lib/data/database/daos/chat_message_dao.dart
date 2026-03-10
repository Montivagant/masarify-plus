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
      ..orderBy([
        (m) => OrderingTerm.asc(m.createdAt),
        (m) => OrderingTerm.asc(m.id),
      ]);
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

  /// Update the content of a message (e.g. to strip an actioned JSON block).
  /// Also recalculates [tokenCount] so [_trimHistory] budgets remain accurate.
  Future<void> updateContent(int id, String newContent, {int? tokenCount}) {
    return (update(chatMessages)..where((m) => m.id.equals(id))).write(
      ChatMessagesCompanion(
        content: Value(newContent),
        tokenCount: tokenCount != null ? Value(tokenCount) : const Value.absent(),
      ),
    );
  }

  /// Atomically strip an action JSON block from a message and insert a
  /// follow-up confirmation/error message. Wraps both writes in a single
  /// DB transaction so a crash between them cannot leave inconsistent state.
  Future<void> finalizeAction({
    required int messageId,
    required String strippedContent,
    required int strippedTokenCount,
    required String followUpContent,
  }) {
    return transaction(() async {
      await (update(chatMessages)..where((m) => m.id.equals(messageId))).write(
        ChatMessagesCompanion(
          content: Value(strippedContent),
          tokenCount: Value(strippedTokenCount),
        ),
      );
      await into(chatMessages).insert(
        ChatMessagesCompanion.insert(
          role: 'assistant',
          content: followUpContent,
          tokenCount: const Value(0),
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  /// Delete all messages (clear chat).
  Future<int> deleteAll() => delete(chatMessages).go();
}
