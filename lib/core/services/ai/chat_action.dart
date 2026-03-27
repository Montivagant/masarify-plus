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
      case 'create_budget':
        return _parseBudget(json);
      case 'create_recurring':
        return _parseRecurring(json);
      case 'create_wallet':
        return _parseWallet(json);
      case 'create_transfer':
        return _parseTransfer(json);
      case 'delete_transaction':
        return _parseDeleteTransaction(json);
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

  static CreateBudgetAction? _parseBudget(Map<String, dynamic> json) {
    final category = json['category'] as String?;
    final rawAmount = json['limit'];
    if (category == null || category.isEmpty || rawAmount == null) return null;

    final piastres = (_toDouble(rawAmount) * 100).round();
    if (piastres <= 0 || piastres > _kMaxPiastres) return null;

    final month = json['month'] as int?;
    final year = json['year'] as int?;

    return CreateBudgetAction(
      categoryName: category,
      limitPiastres: piastres,
      month: month,
      year: year,
    );
  }

  static CreateRecurringAction? _parseRecurring(Map<String, dynamic> json) {
    final title = json['title'] as String?;
    final rawAmount = json['amount'];
    final frequency = json['frequency'] as String?;
    final category = json['category'] as String?;
    final type = json['type'] as String?;
    if (title == null ||
        title.isEmpty ||
        rawAmount == null ||
        frequency == null ||
        category == null ||
        type == null) {
      return null;
    }

    final piastres = (_toDouble(rawAmount) * 100).round();
    if (piastres <= 0 || piastres > _kMaxPiastres) return null;
    if (type != 'income' && type != 'expense') return null;

    const validFreqs = {'once', 'daily', 'weekly', 'monthly', 'yearly'};
    if (!validFreqs.contains(frequency)) return null;

    return CreateRecurringAction(
      title: title,
      amountPiastres: piastres,
      frequency: frequency,
      categoryName: category,
      type: type,
    );
  }

  static CreateWalletAction? _parseWallet(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.isEmpty) return null;

    final type = json['type'] as String? ?? 'bank';
    final rawBalance = json['initial_balance'];
    final balancePiastres =
        rawBalance != null ? (_toDouble(rawBalance) * 100).round() : 0;
    if (balancePiastres < 0 || balancePiastres > _kMaxPiastres) return null;

    return CreateWalletAction(
      name: name,
      type: type,
      initialBalancePiastres: balancePiastres,
    );
  }

  static CreateTransferAction? _parseTransfer(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    final from = json['from_wallet'] as String?;
    final to = json['to_wallet'] as String?;
    if (rawAmount == null ||
        from == null ||
        from.isEmpty ||
        to == null ||
        to.isEmpty) {
      return null;
    }

    final piastres = (_toDouble(rawAmount) * 100).round();
    if (piastres <= 0 || piastres > _kMaxPiastres) return null;

    return CreateTransferAction(
      amountPiastres: piastres,
      fromWalletName: from,
      toWalletName: to,
      note: json['note'] as String?,
      date: json['date'] as String?,
    );
  }

  static DeleteTransactionAction? _parseDeleteTransaction(
    Map<String, dynamic> json,
  ) {
    final title = json['title'] as String?;
    final rawAmount = json['amount'];
    if (title == null || title.isEmpty || rawAmount == null) return null;

    final piastres = (_toDouble(rawAmount) * 100).round();
    if (piastres <= 0 || piastres > _kMaxPiastres) return null;

    return DeleteTransactionAction(
      title: title,
      amountPiastres: piastres,
      date: json['date'] as String?,
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

/// Action to create a monthly budget for a category.
class CreateBudgetAction extends ChatAction {
  const CreateBudgetAction({
    required this.categoryName,
    required this.limitPiastres,
    this.month,
    this.year,
  });

  final String categoryName;

  /// Limit in integer piastres.
  final int limitPiastres;

  /// Optional month/year — defaults to current month if null.
  final int? month;
  final int? year;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'create_budget',
        'category': categoryName,
        'limit': limitPiastres / 100,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      };
}

/// Action to create a recurring rule (bill or recurring transaction).
class CreateRecurringAction extends ChatAction {
  const CreateRecurringAction({
    required this.title,
    required this.amountPiastres,
    required this.frequency,
    required this.categoryName,
    required this.type,
  });

  final String title;

  /// Amount in integer piastres.
  final int amountPiastres;

  /// One of: once, daily, weekly, monthly, yearly.
  final String frequency;

  final String categoryName;

  /// 'income' or 'expense'.
  final String type;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'create_recurring',
        'title': title,
        'amount': amountPiastres / 100,
        'frequency': frequency,
        'category': categoryName,
        'type': type,
      };
}

/// Action to create a new wallet/account.
class CreateWalletAction extends ChatAction {
  const CreateWalletAction({
    required this.name,
    required this.type,
    required this.initialBalancePiastres,
  });

  final String name;

  /// One of: physical_cash, bank, mobile_wallet, credit_card, prepaid_card, investment.
  final String type;

  /// Initial balance in integer piastres.
  final int initialBalancePiastres;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'create_wallet',
        'name': name,
        'type': type,
        'initial_balance': initialBalancePiastres / 100,
      };
}

/// Action to create an inter-account transfer.
class CreateTransferAction extends ChatAction {
  const CreateTransferAction({
    required this.amountPiastres,
    required this.fromWalletName,
    required this.toWalletName,
    this.note,
    this.date,
  });

  /// Amount in integer piastres (100 EGP = 10000).
  final int amountPiastres;

  final String fromWalletName;
  final String toWalletName;
  final String? note;
  final String? date;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'create_transfer',
        'amount': amountPiastres / 100,
        'from_wallet': fromWalletName,
        'to_wallet': toWalletName,
        if (note != null) 'note': note,
        if (date != null) 'date': date,
      };
}

/// Action to delete a transaction by matching title + amount + date.
class DeleteTransactionAction extends ChatAction {
  const DeleteTransactionAction({
    required this.title,
    required this.amountPiastres,
    this.date,
  });

  final String title;

  /// Amount in integer piastres.
  final int amountPiastres;

  final String? date;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'delete_transaction',
        'title': title,
        'amount': amountPiastres / 100,
        if (date != null) 'date': date,
      };
}

/// Status of a pending action in the chat UI (ephemeral, not persisted).
enum ChatActionStatus { pending, confirmed, cancelled, failed }
