import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/ai/ai_chat_service.dart';
import '../../core/services/ai/chat_action_executor.dart';
import '../../core/utils/money_formatter.dart';
import '../../domain/entities/chat_message_entity.dart';
import 'ai_provider.dart';
import 'background_ai_provider.dart';
import 'budget_provider.dart';
import 'category_provider.dart';
import 'goal_provider.dart';
import 'recurring_rule_provider.dart';
import 'repository_providers.dart';
import 'theme_provider.dart';
import 'transaction_provider.dart';
import 'wallet_provider.dart';

// ── 1. Chat messages stream ─────────────────────────────────────────────────

final chatMessagesProvider = StreamProvider<List<ChatMessageEntity>>(
  (ref) => ref.watch(chatMessageRepositoryProvider).watchAll(),
);

// ── 2. AI chat service ──────────────────────────────────────────────────────

final aiChatServiceProvider = Provider<AiChatService>(
  (ref) => AiChatService(ref.watch(openRouterServiceProvider)),
);

// ── 3. Financial context (computed snapshot) ────────────────────────────────

final financialContextProvider = Provider.autoDispose<FinancialContext>((ref) {
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
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
  final lang = ref.watch(localeProvider)?.languageCode ?? 'en';
  final catMap = {for (final cat in categories) cat.id: cat};

  // Budget status lines: "CategoryName: 85%"
  final budgets = ref.watch(budgetsByMonthProvider(monthKey)).valueOrNull ?? [];
  final budgetStatus = <String>[];
  for (final b in budgets) {
    final cat = catMap[b.categoryId];
    final name =
        cat?.displayName(lang) ?? (lang == 'ar' ? 'غير معروف' : 'Unknown');
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
    final name =
        cat?.displayName(lang) ?? (lang == 'ar' ? 'غير معروف' : 'Unknown');
    final formatted = MoneyFormatter.formatCompact(entry.value);
    topCategories.add('$name: $formatted');
  }

  // Category list for AI action matching (name + nameAr + type).
  // When locale is Arabic, put Arabic name first for better AI context.
  final categoryList = categories
      .where((c) => !c.isArchived)
      .map(
        (c) => lang == 'ar'
            ? '${c.nameAr} (${c.name})|${c.type}'
            : '${c.name} (${c.nameAr})|${c.type}',
      )
      .toList();

  // Unbudgeted categories with significant spending (>500 EGP = 50000 piastres).
  final budgetedCategoryIds = {for (final b in budgets) b.categoryId};
  final unbudgetedHighSpend = <String>[];
  for (final entry in sortedEntries) {
    if (!budgetedCategoryIds.contains(entry.key) && entry.value >= 50000) {
      final cat = catMap[entry.key];
      if (cat != null) {
        unbudgetedHighSpend.add(
          '${cat.displayName(lang)}: ${MoneyFormatter.formatCompact(entry.value)}',
        );
      }
    }
  }

  // Savings rate.
  final savingsRate = monthlyIncome > 0
      ? (((monthlyIncome - monthlyExpense) / monthlyIncome) * 100).round()
      : 0;

  // Recurring count.
  final recurringRules = ref.watch(recurringRulesProvider).valueOrNull ?? [];
  final activeRecurringCount = recurringRules.where((r) => r.isActive).length;

  // Wallet/account names for AI context — exclude archived and system Cash.
  // Cash is handled separately as a payment method, not an account.
  final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
  final walletList = wallets
      .where((w) => !w.isArchived && !w.isSystemWallet)
      .map((w) => '${w.name} (${w.type})')
      .toList();

  return FinancialContext(
    totalBalance: balance,
    monthlyIncome: monthlyIncome,
    monthlyExpense: monthlyExpense,
    budgetStatus: budgetStatus,
    goalStatus: goalStatus,
    topCategories: topCategories,
    userLocale: lang,
    currentDate: now,
    categoryList: categoryList,
    walletList: walletList,
    unbudgetedHighSpend: unbudgetedHighSpend,
    savingsRate: savingsRate,
    recurringCount: activeRecurringCount,
    activeBudgetCount: budgets.length,
    activeGoalCount: goals.length,
  );
});

// ── 4. Chat action executor ──────────────────────────────────────────────

final chatActionExecutorProvider = Provider<ChatActionExecutor>((ref) {
  return ChatActionExecutor(
    goalRepo: ref.watch(goalRepositoryProvider),
    txRepo: ref.watch(transactionRepositoryProvider),
    budgetRepo: ref.watch(budgetRepositoryProvider),
    recurringRepo: ref.watch(recurringRuleRepositoryProvider),
    walletRepo: ref.watch(walletRepositoryProvider),
    transferRepo: ref.watch(transferRepositoryProvider),
    learningService: ref.watch(categorizationLearningServiceProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
  );
});
