import '../entities/chat_message_entity.dart';

/// Repository interface for chat message persistence.
abstract interface class IChatMessageRepository {
  /// Watch all messages ordered by creation time (oldest first).
  Stream<List<ChatMessageEntity>> watchAll();

  /// Insert a new message and return its ID.
  Future<int> insert({
    required String role,
    required String content,
    required int tokenCount,
  });

  /// Update the content (and optionally token count) of a message.
  Future<void> updateContent(int id, String newContent, {int? tokenCount});

  /// Atomically strip an action JSON block from a message and insert a
  /// follow-up confirmation/error message in a single DB transaction.
  Future<void> finalizeAction({
    required int messageId,
    required String strippedContent,
    required int strippedTokenCount,
    required String followUpContent,
  });

  /// Atomically execute [action] and finalize the message in a single
  /// DB transaction to prevent inconsistent state if the app crashes
  /// between action execution and message finalization.
  ///
  /// [followUpFromResult] extracts the follow-up message text from the
  /// action result so it can be persisted inside the same transaction.
  /// Returns the result of [action].
  Future<T> executeAndFinalizeAction<T>({
    required Future<T> Function() action,
    required String Function(T result) followUpFromResult,
    required int messageId,
    required String strippedContent,
    required int strippedTokenCount,
  });

  /// Delete all messages (clear chat).
  Future<void> deleteAll();
}
