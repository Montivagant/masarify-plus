import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/wallet_entity.dart';
import '../../../domain/repositories/i_budget_repository.dart';
import '../../../domain/repositories/i_goal_repository.dart';
import '../../../domain/repositories/i_recurring_rule_repository.dart';
import '../../../domain/repositories/i_transaction_repository.dart';
import '../../../domain/repositories/i_transfer_repository.dart';
import '../../../domain/repositories/i_wallet_repository.dart';
import '../../constants/voice_dictionary.dart';
import '../../utils/money_formatter.dart';
import '../../utils/subscription_detector.dart';
import '../../utils/wallet_matcher.dart';
import 'chat_action.dart';
import 'chat_action_messages.dart';

/// Result of a chat action execution.
class ExecutionResult {
  const ExecutionResult(this.message, {this.subscriptionSuggestion});
  final String message;
  final SubscriptionSuggestion? subscriptionSuggestion;
}

/// Returned when a created transaction looks like a recurring subscription.
class SubscriptionSuggestion {
  const SubscriptionSuggestion({
    required this.title,
    required this.categoryName,
  });
  final String title;
  final String categoryName;
}

/// Default color for AI-created goals (matches AppColors.defaultColorHex).
const _kDefaultGoalColorHex = '#1A6B5E';

/// Executes confirmed [ChatAction]s by calling the appropriate repository.
///
/// [ChatAction.fromJson] already validates structural correctness (amount > 0,
/// recognised type). This executor defensively re-checks amounts and performs
/// business-logic validation: category matching against live DB data and wallet
/// availability. Throws [ArgumentError] with a user-friendly message on failure.
class ChatActionExecutor {
  const ChatActionExecutor({
    required IGoalRepository goalRepo,
    required ITransactionRepository txRepo,
    required IBudgetRepository budgetRepo,
    required IRecurringRuleRepository recurringRepo,
    required IWalletRepository walletRepo,
    required ITransferRepository transferRepo,
  })  : _goalRepo = goalRepo,
        _txRepo = txRepo,
        _budgetRepo = budgetRepo,
        _recurringRepo = recurringRepo,
        _walletRepo = walletRepo,
        _transferRepo = transferRepo;

  final IGoalRepository _goalRepo;
  final ITransactionRepository _txRepo;
  final IBudgetRepository _budgetRepo;
  final IRecurringRuleRepository _recurringRepo;
  final IWalletRepository _walletRepo;
  final ITransferRepository _transferRepo;

  /// Execute [action] and return an [ExecutionResult] with the success message
  /// and optional subscription suggestion.
  ///
  /// Throws [ArgumentError] if validation fails (with a user-friendly message).
  Future<ExecutionResult> execute(
    ChatAction action, {
    required List<CategoryEntity> categories,
    required List<WalletEntity> wallets,
    required ChatActionMessages messages,
    int? selectedWalletId,
  }) async {
    return switch (action) {
      CreateGoalAction() => _executeGoal(action, messages),
      CreateTransactionAction() => _executeTransaction(
          action,
          categories,
          wallets,
          messages,
          selectedWalletId,
        ),
      CreateBudgetAction() => _executeBudget(action, categories, messages),
      CreateRecurringAction() => _executeRecurring(
          action,
          categories,
          wallets,
          messages,
          selectedWalletId,
        ),
      CreateWalletAction() => _executeWallet(action, messages),
      CreateTransferAction() => _executeTransfer(action, wallets, messages),
      DeleteTransactionAction() =>
        _executeDeleteTransaction(action, messages, selectedWalletId),
    };
  }

  Future<ExecutionResult> _executeGoal(
    CreateGoalAction action,
    ChatActionMessages m,
  ) async {
    if (action.targetAmountPiastres <= 0) {
      throw ArgumentError(m.invalidTarget);
    }

    DateTime? deadline;
    if (action.deadline != null) {
      deadline = DateTime.tryParse(action.deadline!);
    }

    await _goalRepo.createGoal(
      name: action.name,
      iconName: 'goals',
      colorHex: _kDefaultGoalColorHex,
      targetAmount: action.targetAmountPiastres,
      deadline: deadline,
    );

    final formatted = MoneyFormatter.format(action.targetAmountPiastres);
    return ExecutionResult(m.goalCreated(action.name, formatted));
  }

  Future<ExecutionResult> _executeTransaction(
    CreateTransactionAction action,
    List<CategoryEntity> categories,
    List<WalletEntity> wallets,
    ChatActionMessages m,
    int? selectedWalletId,
  ) async {
    if (action.amountPiastres <= 0) {
      throw ArgumentError(m.invalidAmount);
    }

    // Category matching: exact → contains (case-insensitive, both languages).
    final compatibleCats = categories
        .where(
          (c) => !c.isArchived && (c.type == action.type || c.type == 'both'),
        )
        .toList();

    final matched = _matchCategory(action.categoryName, compatibleCats, m);

    // Wallet selection: if AI specified a wallet name, resolve by name.
    // "cash" routes to the system Cash wallet. Otherwise use selected/default.
    final wallet = action.walletName != null
        ? _resolveWalletByName(action.walletName!, wallets, m)
        : _resolveWallet(wallets, m, selectedWalletId);

    // Date parsing.
    final date = action.date != null
        ? DateTime.tryParse(action.date!) ?? DateTime.now()
        : DateTime.now();

    await _txRepo.create(
      walletId: wallet.id,
      categoryId: matched.id,
      amount: action.amountPiastres,
      type: action.type,
      title: action.title,
      transactionDate: date,
      note: action.note,
      source: 'ai_chat',
    );

    // Detect subscription-like transactions for follow-up suggestion.
    SubscriptionSuggestion? suggestion;
    if (action.type == 'expense') {
      final isSubscription = SubscriptionDetector.isSubscriptionLike(
        categoryName: matched.name,
        transactionText: action.title,
      );
      if (isSubscription) {
        suggestion = SubscriptionSuggestion(
          title: action.title,
          categoryName: matched.name,
        );
      }
    }

    final formatted = MoneyFormatter.format(action.amountPiastres);
    return ExecutionResult(
      m.txRecorded(action.title, formatted),
      subscriptionSuggestion: suggestion,
    );
  }

  Future<ExecutionResult> _executeBudget(
    CreateBudgetAction action,
    List<CategoryEntity> categories,
    ChatActionMessages m,
  ) async {
    if (action.limitPiastres <= 0) {
      throw ArgumentError(m.invalidBudgetLimit);
    }

    // Match category by name (expense or both types only for budgets).
    final matched = _matchCategory(
      action.categoryName,
      categories.where((c) => !c.isArchived && c.type != 'income').toList(),
      m,
    );

    final now = DateTime.now();
    final month = action.month ?? now.month;
    final year = action.year ?? now.year;

    // Check if budget already exists for this category + month.
    final existing = await _budgetRepo.getByCategoryAndMonth(
      matched.id,
      year,
      month,
    );
    if (existing != null) {
      throw ArgumentError(m.budgetExists(matched.name));
    }

    await _budgetRepo.create(
      categoryId: matched.id,
      month: month,
      year: year,
      limitAmount: action.limitPiastres,
    );

    final formatted = MoneyFormatter.format(action.limitPiastres);
    return ExecutionResult(m.budgetCreated(formatted, matched.name));
  }

  Future<ExecutionResult> _executeRecurring(
    CreateRecurringAction action,
    List<CategoryEntity> categories,
    List<WalletEntity> wallets,
    ChatActionMessages m,
    int? selectedWalletId,
  ) async {
    if (action.amountPiastres <= 0) {
      throw ArgumentError(m.invalidAmount);
    }

    final compatibleCats = categories
        .where(
          (c) => !c.isArchived && (c.type == action.type || c.type == 'both'),
        )
        .toList();
    final matched = _matchCategory(action.categoryName, compatibleCats, m);

    // Wallet selection.
    final wallet = _resolveWallet(wallets, m, selectedWalletId);

    final now = DateTime.now();
    await _recurringRepo.create(
      walletId: wallet.id,
      categoryId: matched.id,
      amount: action.amountPiastres,
      type: action.type,
      title: action.title,
      frequency: action.frequency,
      startDate: now,
      nextDueDate: now,
    );

    final formatted = MoneyFormatter.format(action.amountPiastres);
    return ExecutionResult(
      m.recurringCreated(action.title, action.frequency, formatted),
    );
  }

  Future<ExecutionResult> _executeWallet(
    CreateWalletAction action,
    ChatActionMessages m,
  ) async {
    // Validate name uniqueness.
    final exists = await _walletRepo.existsByName(action.name);
    if (exists) {
      throw ArgumentError(m.walletExists);
    }

    // Normalize wallet type.
    const validTypes = {
      'physical_cash',
      'bank',
      'mobile_wallet',
      'credit_card',
      'prepaid_card',
      'investment',
    };
    final type = validTypes.contains(action.type) ? action.type : 'bank';

    await _walletRepo.create(
      name: action.name,
      type: type,
      initialBalance: action.initialBalancePiastres,
    );

    final formatted = MoneyFormatter.format(action.initialBalancePiastres);
    return ExecutionResult(m.walletCreated(action.name, formatted));
  }

  Future<ExecutionResult> _executeDeleteTransaction(
    DeleteTransactionAction action,
    ChatActionMessages m,
    int? selectedWalletId,
  ) async {
    // Find matching transaction by title + amount, optionally narrowing by date.
    final now = DateTime.now();
    final searchStart = action.date != null
        ? DateTime.tryParse(action.date!) ??
            now.subtract(const Duration(days: 30))
        : now.subtract(const Duration(days: 30));
    final searchEnd = action.date != null
        ? (DateTime.tryParse(action.date!) ?? now).add(const Duration(days: 1))
        : now.add(const Duration(days: 1));

    final txs = await _txRepo.getByDateRange(searchStart, searchEnd);
    final query = action.title.toLowerCase();

    // Find by title (contains) + exact amount match.
    // If a specific wallet is selected, narrow to that wallet first.
    var matches = txs
        .where(
          (tx) =>
              tx.title.toLowerCase().contains(query) &&
              tx.amount == action.amountPiastres,
        )
        .toList();
    if (selectedWalletId != null) {
      final walletMatches =
          matches.where((tx) => tx.walletId == selectedWalletId).toList();
      if (walletMatches.isNotEmpty) matches = walletMatches;
    }

    if (matches.isEmpty) {
      throw ArgumentError(m.txNotFound(action.title));
    }

    // Delete the most recent match.
    final target = matches.last;
    await _txRepo.delete(target.id);

    final formatted = MoneyFormatter.format(action.amountPiastres);
    return ExecutionResult(m.txDeleted(target.title, formatted));
  }

  Future<ExecutionResult> _executeTransfer(
    CreateTransferAction action,
    List<WalletEntity> wallets,
    ChatActionMessages m,
  ) async {
    if (action.amountPiastres <= 0) {
      throw ArgumentError(m.invalidAmount);
    }

    // Exclude archived and system Cash — transfers between user accounts only.
    // Cash transfers use dedicated cash_withdrawal/cash_deposit types.
    final activeWallets =
        wallets.where((w) => !w.isArchived && !w.isSystemWallet).toList();
    if (activeWallets.isEmpty) {
      throw ArgumentError(m.noActiveWallet);
    }

    // Resolve from-wallet using WalletMatcher.
    final fromWallet =
        WalletMatcher.match(action.fromWalletName, activeWallets);
    if (fromWallet == null) {
      throw ArgumentError(m.walletNotFound(action.fromWalletName));
    }

    // Resolve to-wallet using WalletMatcher.
    final toWallet = WalletMatcher.match(action.toWalletName, activeWallets);
    if (toWallet == null) {
      throw ArgumentError(m.walletNotFound(action.toWalletName));
    }

    // Ensure from != to.
    if (fromWallet.id == toWallet.id) {
      throw ArgumentError(m.transferSameWallet);
    }

    // Date parsing.
    final date = action.date != null
        ? DateTime.tryParse(action.date!) ?? DateTime.now()
        : DateTime.now();

    await _transferRepo.create(
      fromWalletId: fromWallet.id,
      toWalletId: toWallet.id,
      amount: action.amountPiastres,
      note: action.note,
      transferDate: date,
    );

    final formatted = MoneyFormatter.format(action.amountPiastres);
    return ExecutionResult(
      m.transferCreated(formatted, fromWallet.name, toWallet.name),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────

  WalletEntity _resolveWallet(
    List<WalletEntity> wallets,
    ChatActionMessages m,
    int? selectedWalletId,
  ) {
    // Exclude archived and system Cash wallet — Cash is a payment method,
    // not a user account. Cash transfers use dedicated cash_withdrawal type.
    final activeWallets =
        wallets.where((w) => !w.isArchived && !w.isSystemWallet).toList();
    if (activeWallets.isEmpty) {
      throw ArgumentError(m.noActiveWallet);
    }

    // 1. If a specific wallet is selected (dashboard chip), use it.
    if (selectedWalletId != null) {
      final match = activeWallets.where((w) => w.id == selectedWalletId);
      if (match.isNotEmpty) return match.first;
      // Selected wallet was deleted/archived — fall through to default.
    }

    // 2. Otherwise, prefer the user's default account.
    final defaultWallet =
        activeWallets.where((w) => w.isDefaultAccount).firstOrNull;
    return defaultWallet ?? activeWallets.first;
  }

  /// Resolve wallet by name from AI JSON. Handles the special "cash" keyword
  /// by routing to the system Cash wallet. Other names use WalletMatcher.
  WalletEntity _resolveWalletByName(
    String name,
    List<WalletEntity> wallets,
    ChatActionMessages m,
  ) {
    // Special case: "cash" → system Cash wallet.
    if (VoiceDictionary.cashWalletKeywordSet
        .contains(name.toLowerCase().trim())) {
      final systemWallet = wallets.where((w) => w.isSystemWallet).firstOrNull;
      if (systemWallet != null) return systemWallet;
    }

    // Normal case: match against non-system, non-archived wallets.
    final activeWallets =
        wallets.where((w) => !w.isArchived && !w.isSystemWallet).toList();
    final match = WalletMatcher.match(name, activeWallets);
    if (match != null) return match;

    throw ArgumentError(m.walletNotFound(name));
  }

  /// Shared category matching logic: exact → contains (case-insensitive, both languages).
  CategoryEntity _matchCategory(
    String categoryName,
    List<CategoryEntity> candidates,
    ChatActionMessages m,
  ) {
    final query = categoryName.toLowerCase();

    // Exact match on name or nameAr.
    for (final c in candidates) {
      if (c.name.toLowerCase() == query || c.nameAr.toLowerCase() == query) {
        return c;
      }
    }

    // Contains match (minimum 3 chars to avoid false positives).
    if (query.length >= 3) {
      for (final c in candidates) {
        if (c.name.toLowerCase().contains(query) ||
            c.nameAr.toLowerCase().contains(query)) {
          return c;
        }
      }
    }

    final available = candidates.take(10).map((c) => c.name).join(', ');
    throw ArgumentError(m.categoryNotFound(categoryName, available));
  }
}
