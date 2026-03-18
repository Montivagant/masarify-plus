import '../../../domain/repositories/i_budget_repository.dart';
import '../../../domain/repositories/i_goal_repository.dart';
import '../../../domain/repositories/i_recurring_rule_repository.dart';
import '../../../domain/repositories/i_wallet_repository.dart';

/// Default smart budget amounts (piastres) per category keyword.
const _kDefaultBudgets = <String, int>{
  'Food': 300000, // 3000 EGP
  'Rent': 500000,
  'Transport': 150000,
  'Bills': 200000,
  'Shopping': 200000,
  'Health': 100000,
  'Education': 200000,
  'Other': 150000,
};

/// Default color for quick-start-created goals.
const _kDefaultGoalColorHex = '#1A6B5E';

/// Orchestrates Quick Start wizard CRUD — 100% offline, zero AI tokens.
class QuickStartService {
  const QuickStartService({
    required IWalletRepository walletRepo,
    required IBudgetRepository budgetRepo,
    required IRecurringRuleRepository recurringRepo,
    required IGoalRepository goalRepo,
  })  : _walletRepo = walletRepo,
        _budgetRepo = budgetRepo,
        _recurringRepo = recurringRepo,
        _goalRepo = goalRepo;

  final IWalletRepository _walletRepo;
  final IBudgetRepository _budgetRepo;
  final IRecurringRuleRepository _recurringRepo;
  final IGoalRepository _goalRepo;

  /// Create a wallet if one with the given [name] doesn't already exist.
  Future<void> createWalletIfNeeded({
    required String name,
    required String type,
    int initialBalance = 0,
  }) async {
    final exists = await _walletRepo.existsByName(name);
    if (exists) return;
    await _walletRepo.create(
      name: name,
      type: type,
      initialBalance: initialBalance,
    );
  }

  /// Create budgets for selected categories at default or custom amounts.
  Future<void> createBudgets({
    required Map<int, int> categoryAmounts,
    required int month,
    required int year,
  }) async {
    for (final entry in categoryAmounts.entries) {
      final existing = await _budgetRepo.getByCategoryAndMonth(
        entry.key,
        year,
        month,
      );
      if (existing != null) continue;
      await _budgetRepo.create(
        categoryId: entry.key,
        month: month,
        year: year,
        limitAmount: entry.value,
      );
    }
  }

  /// Create a recurring rule for a bill.
  Future<void> createRecurringBill({
    required int walletId,
    required int categoryId,
    required int amount,
    required String title,
    required String frequency,
  }) async {
    final now = DateTime.now();
    await _recurringRepo.create(
      walletId: walletId,
      categoryId: categoryId,
      amount: amount,
      type: 'expense',
      title: title,
      frequency: frequency,
      startDate: now,
      nextDueDate: now,
    );
  }

  /// Create a savings goal.
  Future<void> createGoal({
    required String name,
    required int targetAmount,
    DateTime? deadline,
  }) async {
    await _goalRepo.createGoal(
      name: name,
      iconName: 'goals',
      colorHex: _kDefaultGoalColorHex,
      targetAmount: targetAmount,
      deadline: deadline,
    );
  }

  /// Get default budget amount (piastres) for a category keyword.
  static int defaultBudgetFor(String categoryKeyword) =>
      _kDefaultBudgets[categoryKeyword] ?? 150000;
}
