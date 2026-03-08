class ChatMessageEntity {
  const ChatMessageEntity({
    required this.id,
    required this.role,
    required this.content,
    required this.tokenCount,
    required this.createdAt,
  });

  final int id;
  final String role;
  final String content;
  final int tokenCount;
  final DateTime createdAt;
}
