/// AI chat action data models — pure Dart, no Flutter imports.
///
/// Represents structured actions the AI suggests in its response.
/// Parsed from JSON blocks embedded in the AI's text output.
/// Maximum piastres accepted from AI (100 million EGP).
const _kMaxPiastres = 10000000000; // 100_000_000 * 100

sealed class ChatAction {
  const ChatAction();

  /// Parse a JSON map into a [ChatAction]. Returns `null` if the JSON
  /// is malformed, has an unrecognized action type, or missing required fields.
  static ChatAction? fromJson(Map<String, dynamic> json) {
    final action = json['action'] as String?;
    if (action == null) return null;

    switch (action) {
      case 'create_goal':
        return _parseGoal(json);
      case 'create_transaction':
        return _parseTransaction(json);
      default:
        return null;
    }
  }

  Map<String, dynamic> toJson();

  static CreateGoalAction? _parseGoal(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final rawAmount = json['target_amount'];
    if (name == null || name.isEmpty || rawAmount == null) return null;

    final piastres = (_toDouble(rawAmount) * 100).round();
    if (piastres <= 0 || piastres > _kMaxPiastres) return null;

    return CreateGoalAction(
      name: name,
      targetAmountPiastres: piastres,
      deadline: json['deadline'] as String?,
    );
  }

  static CreateTransactionAction? _parseTransaction(Map<String, dynamic> json) {
    final title = json['title'] as String?;
    final rawAmount = json['amount'];
    final type = json['type'] as String?;
    final category = json['category'] as String?;
    if (title == null ||
        title.isEmpty ||
        rawAmount == null ||
        type == null ||
        category == null) {
      return null;
    }

    final piastres = (_toDouble(rawAmount) * 100).round();
    if (piastres <= 0 || piastres > _kMaxPiastres) return null;
    if (type != 'income' && type != 'expense') return null;

    return CreateTransactionAction(
      title: title,
      amountPiastres: piastres,
      type: type,
      categoryName: category,
      date: json['date'] as String?,
      note: json['note'] as String?,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

/// Action to create a savings goal.
class CreateGoalAction extends ChatAction {
  const CreateGoalAction({
    required this.name,
    required this.targetAmountPiastres,
    this.deadline,
  });

  final String name;

  /// Amount in integer piastres (100 EGP = 10000).
  final int targetAmountPiastres;

  final String? deadline;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'create_goal',
        'name': name,
        'target_amount': targetAmountPiastres / 100,
        if (deadline != null) 'deadline': deadline,
      };
}

/// Action to create a transaction.
class CreateTransactionAction extends ChatAction {
  const CreateTransactionAction({
    required this.title,
    required this.amountPiastres,
    required this.type,
    required this.categoryName,
    this.date,
    this.note,
  });

  final String title;

  /// Amount in integer piastres (100 EGP = 10000).
  final int amountPiastres;

  final String type;
  final String categoryName;
  final String? date;
  final String? note;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'create_transaction',
        'title': title,
        'amount': amountPiastres / 100,
        'type': type,
        'category': categoryName,
        if (date != null) 'date': date,
        if (note != null) 'note': note,
      };
}

/// Status of a pending action in the chat UI (ephemeral, not persisted).
enum ChatActionStatus { pending, confirmed, cancelled, failed }
