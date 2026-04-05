import '../../domain/entities/chat_message_entity.dart';
import '../../domain/repositories/i_chat_message_repository.dart';
import '../database/app_database.dart';
import '../database/daos/chat_message_dao.dart';

class ChatMessageRepositoryImpl implements IChatMessageRepository {
  const ChatMessageRepositoryImpl(this._dao, this._db);

  final ChatMessageDao _dao;
  final AppDatabase _db;

  // ── Streams ──────────────────────────────────────────────────────────────

  @override
  Stream<List<ChatMessageEntity>> watchAll() => _dao.watchAll();

  // ── Mutations ────────────────────────────────────────────────────────────

  @override
  Future<int> insert({
    required String role,
    required String content,
    required int tokenCount,
  }) =>
      _dao.insertMessage(
        role: role,
        content: content,
        tokenCount: tokenCount,
      );

  @override
  Future<void> updateContent(
    int id,
    String newContent, {
    int? tokenCount,
  }) =>
      _dao.updateContent(id, newContent, tokenCount: tokenCount);

  @override
  Future<void> finalizeAction({
    required int messageId,
    required String strippedContent,
    required int strippedTokenCount,
    required String followUpContent,
  }) =>
      _dao.finalizeAction(
        messageId: messageId,
        strippedContent: strippedContent,
        strippedTokenCount: strippedTokenCount,
        followUpContent: followUpContent,
      );

  @override
  Future<T> executeAndFinalizeAction<T>({
    required Future<T> Function() action,
    required String Function(T result) followUpFromResult,
    required int messageId,
    required String strippedContent,
    required int strippedTokenCount,
  }) =>
      _db.transaction(() async {
        final result = await action();
        await _dao.finalizeAction(
          messageId: messageId,
          strippedContent: strippedContent,
          strippedTokenCount: strippedTokenCount,
          followUpContent: followUpFromResult(result),
        );
        return result;
      });

  @override
  Future<void> deleteAll() => _dao.deleteAll();
}
