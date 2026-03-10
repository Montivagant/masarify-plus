import '../../../domain/entities/category_entity.dart';
import '../../../domain/entities/wallet_entity.dart';
import '../../../domain/repositories/i_goal_repository.dart';
import '../../../domain/repositories/i_transaction_repository.dart';
import '../../utils/money_formatter.dart';
import 'chat_action.dart';

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
  })  : _goalRepo = goalRepo,
        _txRepo = txRepo;

  final IGoalRepository _goalRepo;
  final ITransactionRepository _txRepo;

  /// Execute [action] and return a success message string.
  ///
  /// Throws [ArgumentError] if validation fails (with a user-friendly message).
  Future<String> execute(
    ChatAction action, {
    required List<CategoryEntity> categories,
    required List<WalletEntity> wallets,
    required String locale,
    int? selectedWalletId,
  }) async {
    return switch (action) {
      CreateGoalAction() => _executeGoal(action, locale),
      CreateTransactionAction() =>
        _executeTransaction(action, categories, wallets, locale, selectedWalletId),
    };
  }

  Future<String> _executeGoal(CreateGoalAction action, String locale) async {
    if (action.targetAmountPiastres <= 0) {
      throw ArgumentError(
        locale == 'ar'
            ? 'المبلغ المستهدف يجب أن يكون أكبر من صفر'
            : 'Target amount must be greater than zero',
      );
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
    return locale == 'ar'
        ? 'تم إنشاء هدف "${action.name}" بمبلغ مستهدف $formatted!'
        : 'Goal "${action.name}" created with a target of $formatted!';
  }

  Future<String> _executeTransaction(
    CreateTransactionAction action,
    List<CategoryEntity> categories,
    List<WalletEntity> wallets,
    String locale,
    int? selectedWalletId,
  ) async {
    if (action.amountPiastres <= 0) {
      throw ArgumentError(
        locale == 'ar'
            ? 'المبلغ يجب أن يكون أكبر من صفر'
            : 'Amount must be greater than zero',
      );
    }

    // Category matching: exact → contains (case-insensitive, both languages).
    final query = action.categoryName.toLowerCase();
    final compatibleCats = categories
        .where((c) =>
            !c.isArchived &&
            (c.type == action.type || c.type == 'both'),)
        .toList();

    CategoryEntity? matched;

    // Exact match on name or nameAr.
    for (final c in compatibleCats) {
      if (c.name.toLowerCase() == query || c.nameAr.toLowerCase() == query) {
        matched = c;
        break;
      }
    }

    // Contains match (only for queries of meaningful length to avoid
    // false positives like "a" matching "Salary", "Transportation", etc.).
    if (matched == null && query.length >= 3) {
      for (final c in compatibleCats) {
        if (c.name.toLowerCase().contains(query) ||
            c.nameAr.toLowerCase().contains(query)) {
          matched = c;
          break;
        }
      }
    }

    if (matched == null) {
      final available = compatibleCats
          .take(10)
          .map((c) => c.name)
          .join(', ');
      throw ArgumentError(
        locale == 'ar'
            ? 'لم يتم العثور على فئة "${action.categoryName}". المتاح: $available'
            : 'Could not match category "${action.categoryName}". Available: $available',
      );
    }

    // Wallet selection: prefer the user's currently-selected account,
    // then fall back to the first non-archived wallet.
    final activeWallets = wallets.where((w) => !w.isArchived).toList();
    if (activeWallets.isEmpty) {
      throw ArgumentError(
        locale == 'ar'
            ? 'لا يوجد حساب نشط. يرجى إنشاء حساب أولاً.'
            : 'No active account available. Please create one first.',
      );
    }
    final wallet = selectedWalletId != null
        ? activeWallets.firstWhere(
            (w) => w.id == selectedWalletId,
            orElse: () => activeWallets.first,
          )
        : activeWallets.first;

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

    final formatted = MoneyFormatter.format(action.amountPiastres);
    return locale == 'ar'
        ? 'تم تسجيل معاملة "${action.title}" بمبلغ $formatted!'
        : 'Transaction "${action.title}" of $formatted recorded!';
  }
}
