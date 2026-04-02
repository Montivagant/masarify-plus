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
      case 'update_transaction':
        return _parseUpdateTransaction(json);
      case 'update_budget':
        return _parseUpdateBudget(json);
      case 'delete_budget':
        return _parseDeleteBudget(json);
      case 'delete_goal':
        return _parseDeleteGoal(json);
      case 'delete_recurring':
        return _parseDeleteRecurring(json);
      case 'update_wallet':
        return _parseUpdateWallet(json);
      case 'update_goal':
        return _parseUpdateGoal(json);
      case 'update_recurring':
        return _parseUpdateRecurring(json);
      case 'update_category':
        return _parseUpdateCategory(json);
      case 'create_category':
        return _parseCreateCategory(json);
      case 'delete_wallet':
        return _parseDeleteWallet(json);
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
      walletName: json['wallet'] as String?,
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
      startDate: json['start_date'] as String?,
      nextDueDate: json['next_due_date'] as String?,
      endDate: json['end_date'] as String?,
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

  static UpdateTransactionAction? _parseUpdateTransaction(
    Map<String, dynamic> json,
  ) {
    // Match criteria: title + amount (required to find the transaction).
    final title = json['title'] as String?;
    final rawAmount = json['amount'];
    if (title == null || title.isEmpty || rawAmount == null) return null;

    final piastres = (_toDouble(rawAmount) * 100).round();
    if (piastres <= 0 || piastres > _kMaxPiastres) return null;

    // Updatable fields (all optional — at least one should be provided).
    final newRawAmount = json['new_amount'];
    final newPiastres =
        newRawAmount != null ? (_toDouble(newRawAmount) * 100).round() : null;

    return UpdateTransactionAction(
      title: title,
      amountPiastres: piastres,
      date: json['date'] as String?,
      newTitle: json['new_title'] as String?,
      newAmountPiastres:
          newPiastres != null && newPiastres > 0 ? newPiastres : null,
      newCategory: json['new_category'] as String?,
      newDate: json['new_date'] as String?,
      newNote: json['new_note'] as String?,
    );
  }

  static UpdateBudgetAction? _parseUpdateBudget(Map<String, dynamic> json) {
    final category = json['category'] as String?;
    if (category == null || category.isEmpty) return null;

    final rawNewLimit = json['new_limit'];
    if (rawNewLimit == null) return null;

    final newPiastres = (_toDouble(rawNewLimit) * 100).round();
    if (newPiastres <= 0 || newPiastres > _kMaxPiastres) return null;

    return UpdateBudgetAction(
      categoryName: category,
      month: json['month'] as int?,
      year: json['year'] as int?,
      newLimitPiastres: newPiastres,
    );
  }

  static DeleteBudgetAction? _parseDeleteBudget(Map<String, dynamic> json) {
    final category = json['category'] as String?;
    if (category == null || category.isEmpty) return null;

    return DeleteBudgetAction(
      categoryName: category,
      month: json['month'] as int?,
      year: json['year'] as int?,
    );
  }

  static DeleteGoalAction? _parseDeleteGoal(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.isEmpty) return null;

    return DeleteGoalAction(name: name);
  }

  static DeleteRecurringAction? _parseDeleteRecurring(
    Map<String, dynamic> json,
  ) {
    final title = json['title'] as String?;
    if (title == null || title.isEmpty) return null;

    return DeleteRecurringAction(title: title);
  }

  static UpdateWalletAction? _parseUpdateWallet(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.isEmpty) return null;
    return UpdateWalletAction(
      name: name,
      newName: json['new_name'] as String?,
      newType: json['new_type'] as String?,
    );
  }

  static UpdateGoalAction? _parseUpdateGoal(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.isEmpty) return null;
    final rawNewTarget = json['new_target_amount'];
    final newTargetPiastres =
        rawNewTarget != null ? (_toDouble(rawNewTarget) * 100).round() : null;
    return UpdateGoalAction(
      name: name,
      newName: json['new_name'] as String?,
      newTargetAmountPiastres:
          newTargetPiastres != null && newTargetPiastres > 0
              ? newTargetPiastres
              : null,
      newDeadline: json['new_deadline'] as String?,
    );
  }

  static UpdateRecurringAction? _parseUpdateRecurring(
    Map<String, dynamic> json,
  ) {
    final title = json['title'] as String?;
    if (title == null || title.isEmpty) return null;
    final rawNewAmount = json['new_amount'];
    final newPiastres =
        rawNewAmount != null ? (_toDouble(rawNewAmount) * 100).round() : null;
    return UpdateRecurringAction(
      title: title,
      newTitle: json['new_title'] as String?,
      newAmountPiastres:
          newPiastres != null && newPiastres > 0 ? newPiastres : null,
      newFrequency: json['new_frequency'] as String?,
    );
  }

  static UpdateCategoryAction? _parseUpdateCategory(
    Map<String, dynamic> json,
  ) {
    final name = json['name'] as String?;
    if (name == null || name.isEmpty) return null;
    return UpdateCategoryAction(
      name: name,
      newName: json['new_name'] as String?,
      newNameAr: json['new_name_ar'] as String?,
    );
  }

  static CreateCategoryAction? _parseCreateCategory(
    Map<String, dynamic> json,
  ) {
    final name = json['name'] as String?;
    final type = json['type'] as String?;
    if (name == null || name.isEmpty || type == null) return null;
    if (type != 'income' && type != 'expense' && type != 'both') return null;
    return CreateCategoryAction(
      name: name,
      nameAr: json['name_ar'] as String? ?? name,
      type: type,
      iconName: json['icon'] as String? ?? 'category',
      colorHex: json['color'] as String? ?? '#9E9E9E',
    );
  }

  static DeleteWalletAction? _parseDeleteWallet(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    if (name == null || name.isEmpty) return null;
    return DeleteWalletAction(name: name);
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
    this.walletName,
  });

  final String title;

  /// Amount in integer piastres (100 EGP = 10000).
  final int amountPiastres;

  final String type;
  final String categoryName;
  final String? date;
  final String? note;

  /// Optional wallet/account name. When provided, the executor resolves
  /// it by name instead of using the selected/default account.
  /// "cash" routes to the physical Cash system wallet.
  final String? walletName;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'create_transaction',
        'title': title,
        'amount': amountPiastres / 100,
        'type': type,
        'category': categoryName,
        if (date != null) 'date': date,
        if (note != null) 'note': note,
        if (walletName != null) 'wallet': walletName,
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
    this.startDate,
    this.nextDueDate,
    this.endDate,
  });

  final String title;

  /// Amount in integer piastres.
  final int amountPiastres;

  /// One of: once, daily, weekly, monthly, yearly.
  final String frequency;

  final String categoryName;

  /// 'income' or 'expense'.
  final String type;

  /// Optional ISO date for when the recurring rule starts.
  final String? startDate;

  /// Optional ISO date for the next due date (e.g., "due on the 15th").
  final String? nextDueDate;

  /// Optional ISO date for when the recurring rule ends.
  final String? endDate;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'create_recurring',
        'title': title,
        'amount': amountPiastres / 100,
        'frequency': frequency,
        'category': categoryName,
        'type': type,
        if (startDate != null) 'start_date': startDate,
        if (nextDueDate != null) 'next_due_date': nextDueDate,
        if (endDate != null) 'end_date': endDate,
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

/// Action to update a transaction by matching title + amount.
class UpdateTransactionAction extends ChatAction {
  const UpdateTransactionAction({
    required this.title,
    required this.amountPiastres,
    this.date,
    this.newTitle,
    this.newAmountPiastres,
    this.newCategory,
    this.newDate,
    this.newNote,
  });

  // Match criteria.
  final String title;
  final int amountPiastres;
  final String? date;

  // Fields to update (all optional).
  final String? newTitle;
  final int? newAmountPiastres;
  final String? newCategory;
  final String? newDate;
  final String? newNote;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'update_transaction',
        'title': title,
        'amount': amountPiastres / 100,
        if (date != null) 'date': date,
        if (newTitle != null) 'new_title': newTitle,
        if (newAmountPiastres != null) 'new_amount': newAmountPiastres! / 100,
        if (newCategory != null) 'new_category': newCategory,
        if (newDate != null) 'new_date': newDate,
        if (newNote != null) 'new_note': newNote,
      };
}

/// Action to update a budget's limit by matching category + month.
class UpdateBudgetAction extends ChatAction {
  const UpdateBudgetAction({
    required this.categoryName,
    required this.newLimitPiastres,
    this.month,
    this.year,
  });

  final String categoryName;
  final int newLimitPiastres;
  final int? month;
  final int? year;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'update_budget',
        'category': categoryName,
        'new_limit': newLimitPiastres / 100,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      };
}

/// Action to delete a budget by matching category + month.
class DeleteBudgetAction extends ChatAction {
  const DeleteBudgetAction({
    required this.categoryName,
    this.month,
    this.year,
  });

  final String categoryName;
  final int? month;
  final int? year;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'delete_budget',
        'category': categoryName,
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      };
}

/// Action to delete a savings goal by name.
class DeleteGoalAction extends ChatAction {
  const DeleteGoalAction({required this.name});

  final String name;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'delete_goal',
        'name': name,
      };
}

/// Action to delete a recurring rule by title.
class DeleteRecurringAction extends ChatAction {
  const DeleteRecurringAction({required this.title});

  final String title;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'delete_recurring',
        'title': title,
      };
}

/// Action to update a wallet/account by name.
class UpdateWalletAction extends ChatAction {
  const UpdateWalletAction({
    required this.name,
    this.newName,
    this.newType,
  });

  final String name;
  final String? newName;
  final String? newType;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'update_wallet',
        'name': name,
        if (newName != null) 'new_name': newName,
        if (newType != null) 'new_type': newType,
      };
}

/// Action to update a savings goal by name.
class UpdateGoalAction extends ChatAction {
  const UpdateGoalAction({
    required this.name,
    this.newName,
    this.newTargetAmountPiastres,
    this.newDeadline,
  });

  final String name;
  final String? newName;
  final int? newTargetAmountPiastres;
  final String? newDeadline;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'update_goal',
        'name': name,
        if (newName != null) 'new_name': newName,
        if (newTargetAmountPiastres != null)
          'new_target_amount': newTargetAmountPiastres! / 100,
        if (newDeadline != null) 'new_deadline': newDeadline,
      };
}

/// Action to update a recurring rule by title.
class UpdateRecurringAction extends ChatAction {
  const UpdateRecurringAction({
    required this.title,
    this.newTitle,
    this.newAmountPiastres,
    this.newFrequency,
  });

  final String title;
  final String? newTitle;
  final int? newAmountPiastres;
  final String? newFrequency;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'update_recurring',
        'title': title,
        if (newTitle != null) 'new_title': newTitle,
        if (newAmountPiastres != null) 'new_amount': newAmountPiastres! / 100,
        if (newFrequency != null) 'new_frequency': newFrequency,
      };
}

/// Action to update a category's name/nameAr.
class UpdateCategoryAction extends ChatAction {
  const UpdateCategoryAction({
    required this.name,
    this.newName,
    this.newNameAr,
  });

  final String name;
  final String? newName;
  final String? newNameAr;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'update_category',
        'name': name,
        if (newName != null) 'new_name': newName,
        if (newNameAr != null) 'new_name_ar': newNameAr,
      };
}

/// Action to create a custom category.
class CreateCategoryAction extends ChatAction {
  const CreateCategoryAction({
    required this.name,
    required this.nameAr,
    required this.type,
    required this.iconName,
    required this.colorHex,
  });

  final String name;
  final String nameAr;
  final String type;
  final String iconName;
  final String colorHex;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'create_category',
        'name': name,
        'name_ar': nameAr,
        'type': type,
        'icon': iconName,
        'color': colorHex,
      };
}

/// Action to archive (delete) a wallet by name.
class DeleteWalletAction extends ChatAction {
  const DeleteWalletAction({required this.name});

  final String name;

  @override
  Map<String, dynamic> toJson() => {
        'action': 'delete_wallet',
        'name': name,
      };
}

/// Status of a pending action in the chat UI (ephemeral, not persisted).
enum ChatActionStatus { pending, confirmed, cancelled, failed }
