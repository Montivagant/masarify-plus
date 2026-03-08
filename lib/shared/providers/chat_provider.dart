import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/ai/ai_chat_service.dart';
import '../../core/utils/money_formatter.dart';
import '../../data/database/daos/chat_message_dao.dart';
import '../../domain/entities/chat_message_entity.dart';
import 'ai_provider.dart';
import 'budget_provider.dart';
import 'category_provider.dart';
import 'database_provider.dart';
import 'goal_provider.dart';
import 'theme_provider.dart';
import 'transaction_provider.dart';
import 'wallet_provider.dart';

// ── 1. ChatMessageDao ───────────────────────────────────────────────────────

final chatMessageDaoProvider = Provider<ChatMessageDao>(
  (ref) => ref.watch(databaseProvider).chatMessageDao,
);

// ── 2. Chat messages stream ─────────────────────────────────────────────────

final chatMessagesProvider = StreamProvider<List<ChatMessageEntity>>(
  (ref) => ref.watch(chatMessageDaoProvider).watchAll(),
);

// ── 3. AI chat service ──────────────────────────────────────────────────────

final aiChatServiceProvider = Provider<AiChatService>(
  (ref) => AiChatService(ref.watch(openRouterServiceProvider)),
);

// ── 4. Financial context (computed snapshot) ────────────────────────────────

final financialContextProvider = Provider<FinancialContext>((ref) {
  final now = DateTime.now();
  final monthKey = (now.year, now.month);

  // Total balance (piastres)
  final balance = ref.watch(totalBalanceProvider).valueOrNull ?? 0;

  // This month's transactions
  final txs =
      ref.watch(transactionsByMonthProvider(monthKey)).valueOrNull ?? [];

  int monthlyIncome = 0;
  int monthlyExpense = 0;
  final expenseByCategory = <int, int>{};

  for (final tx in txs) {
    if (tx.type == 'income') {
      monthlyIncome += tx.amount;
    } else if (tx.type == 'expense') {
      monthlyExpense += tx.amount;
      expenseByCategory[tx.categoryId] =
          (expenseByCategory[tx.categoryId] ?? 0) + tx.amount;
    }
  }

  // Categories map for display names
  final categories =
      ref.watch(categoriesProvider).valueOrNull ?? [];
  final lang =
      ref.watch(localeProvider)?.languageCode ?? 'en';
  final catMap = {for (final cat in categories) cat.id: cat};

  // Budget status lines: "CategoryName: 85%"
  final budgets =
      ref.watch(budgetsByMonthProvider(monthKey)).valueOrNull ?? [];
  final budgetStatus = <String>[];
  for (final b in budgets) {
    final cat = catMap[b.categoryId];
    final name = cat?.displayName(lang) ?? 'Unknown';
    final pct = (b.progressFraction * 100).round();
    budgetStatus.add('$name: $pct%');
  }

  // Goal status lines: "GoalName: 60%"
  final goals = ref.watch(activeGoalsProvider).valueOrNull ?? [];
  final goalStatus = <String>[];
  for (final g in goals) {
    final pct = g.targetAmount > 0
        ? ((g.currentAmount / g.targetAmount) * 100).round().clamp(0, 100)
        : 0;
    goalStatus.add('${g.name}: $pct%');
  }

  // Top 3 expense categories by amount
  final sortedEntries = expenseByCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topCategories = <String>[];
  for (final entry in sortedEntries.take(3)) {
    final cat = catMap[entry.key];
    final name = cat?.displayName(lang) ?? 'Unknown';
    final formatted = MoneyFormatter.formatCompact(entry.value);
    topCategories.add('$name: $formatted');
  }

  return FinancialContext(
    totalBalance: balance,
    monthlyIncome: monthlyIncome,
    monthlyExpense: monthlyExpense,
    budgetStatus: budgetStatus,
    goalStatus: goalStatus,
    topCategories: topCategories,
  );
});
