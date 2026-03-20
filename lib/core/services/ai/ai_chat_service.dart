import 'dart:developer' as dev;

import '../../../domain/entities/chat_message_entity.dart';
import '../../config/ai_config.dart';
import '../../utils/money_formatter.dart';
import 'openrouter_service.dart';

/// Snapshot of the user's current financial state, injected into the
/// system prompt each turn.
class FinancialContext {
  const FinancialContext({
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpense,
    required this.budgetStatus,
    required this.goalStatus,
    required this.topCategories,
    required this.userLocale,
    required this.categoryList,
    this.walletList = const [],
    this.unbudgetedHighSpend = const [],
    this.savingsRate = 0,
    this.recurringCount = 0,
    this.activeBudgetCount = 0,
    this.activeGoalCount = 0,
  });

  final int totalBalance;
  final int monthlyIncome;
  final int monthlyExpense;
  final List<String> budgetStatus;
  final List<String> goalStatus;
  final List<String> topCategories;

  /// 'en' or 'ar' — explicit locale for AI language selection.
  final String userLocale;

  /// Available categories for action matching, e.g. 'Food (طعام)|expense'.
  final List<String> categoryList;

  /// User's wallet/account names, e.g. 'CIB (bank)', 'Vodafone Cash (mobile_wallet)'.
  final List<String> walletList;

  /// Unbudgeted categories with significant spending (>500 EGP/mo).
  final List<String> unbudgetedHighSpend;

  /// Savings rate = (income - expense) / income * 100, or 0 if no income.
  final int savingsRate;

  /// Number of active recurring rules.
  final int recurringCount;

  /// Number of active budgets this month.
  final int activeBudgetCount;

  /// Number of active (non-completed) goals.
  final int activeGoalCount;
}

/// Conversational AI finance assistant wrapping OpenRouter.
class AiChatService {
  const AiChatService(this._openRouter);

  final OpenRouterService _openRouter;

  static const int _historyTokenBudget = 3500;

  String _buildSystemPrompt(FinancialContext ctx) {
    final balance = MoneyFormatter.formatCompact(ctx.totalBalance);
    final income = MoneyFormatter.formatCompact(ctx.monthlyIncome);
    final expense = MoneyFormatter.formatCompact(ctx.monthlyExpense);
    final budgets = ctx.budgetStatus.isEmpty
        ? 'No active budgets'
        : ctx.budgetStatus.join(', ');
    final goals =
        ctx.goalStatus.isEmpty ? 'No active goals' : ctx.goalStatus.join(', ');
    final cats = ctx.topCategories.isEmpty
        ? 'No spending data yet'
        : ctx.topCategories.join(', ');
    final langName = ctx.userLocale == 'ar' ? 'Arabic' : 'English';
    final categoryNames =
        ctx.categoryList.isEmpty ? 'None' : ctx.categoryList.join(', ');
    final unbudgeted = ctx.unbudgetedHighSpend.isEmpty
        ? ''
        : '\n- Unbudgeted high-spend: ${ctx.unbudgetedHighSpend.join(', ')}';
    final savingsInfo =
        ctx.monthlyIncome > 0 ? '\n- Savings rate: ${ctx.savingsRate}%' : '';
    final walletNames =
        ctx.walletList.isEmpty ? 'No accounts' : ctx.walletList.join(', ');
    final walletCount = ctx.walletList.length;

    return '⚡ LANGUAGE RULE (HIGHEST PRIORITY): You MUST respond in $langName. Every word of your reply must be in $langName.\n'
        'EXCEPTION: If user writes in Franco-Arab/Arabezi (Arabic in Latin letters, e.g. "3ayz", "7aga", "el", "kda", "ana"), ALWAYS respond in Arabic.\n'
        '\n'
        'You are Masarify (مصاريفي), a helpful and thoughtful financial advisor for an Egyptian user.\n'
        'Use provided data only. Be helpful but thorough.\n'
        '\n'
        'FINANCIAL SNAPSHOT:\n'
        '- Balance: $balance | Income: $income | Expense: $expense$savingsInfo\n'
        '- Accounts ($walletCount): $walletNames\n'
        '- Budgets (${ctx.activeBudgetCount}): $budgets\n'
        '- Goals (${ctx.activeGoalCount}): $goals\n'
        '- Top spending: $cats\n'
        '- Recurring rules: ${ctx.recurringCount}$unbudgeted\n'
        '\n'
        'ADVISOR BEHAVIOR:\n'
        '1. IDENTIFY GAPS: No budgets + has income? Suggest creating budgets. Savings rate < 20%? Warn.\n'
        '2. FLAG ISSUES: Budget > monthly income? Warn. Goal deadline passed? Note it. Budget at > 80%? Alert.\n'
        '3. SUGGEST: After creating a transaction, suggest a budget if category is unbudgeted and spend > 500 EGP/mo.\n'
        '4. **INFER WHEN OBVIOUS, ASK WHEN AMBIGUOUS**:\n'
        '   - Amount: ALWAYS required from the user — never guess.\n'
        '   - Category: Infer from keywords (e.g. "uber"→Transport, "kfc"→Food). Use the category list. Only ask if truly ambiguous.\n'
        '   - Account: If only 1 account exists, use it automatically. If multiple, infer from name if the user mentions one. Only ask if ambiguous.\n'
        '   - Type: Default to "expense" unless user says income/salary/received/deposited. Cash withdrawal/deposit only if explicit.\n'
        '   - Date: Default to today unless user specifies ("yesterday", "last Friday", a specific date).\n'
        '   - Month/Year: Default to current month for budgets unless specified.\n'
        '   - Frequency: Default to "monthly" for recurring unless specified.\n'
        '   - NEVER assume the amount. ALWAYS confirm the complete action before generating JSON.\n'
        '5. **DISCUSS BEFORE CREATING**: If the user asks for advice, planning help, or general questions, '
        'have a conversation and suggest options — do NOT immediately generate an action JSON. '
        'Only create actions when the user clearly and explicitly requests a specific action with enough details.\n'
        '6. CONTEXT-AWARE: Reference actual data. "Your Food is at 85% with 10 days left."\n'
        '7. **USE YOUR DATA**: You already have the user\'s accounts, categories, budgets, goals, and spending. '
        'NEVER ask "what\'s your budget?" or "how much did you spend?" — you KNOW. '
        'Reference specific numbers from the snapshot. Answer data questions directly.\n'
        '\n'
        'ACTIONS (one JSON block per response, amounts in EGP):\n'
        'Categories: $categoryNames\n'
        '\n'
        'create_transaction: {"action":"create_transaction","title":"X","amount":150,"type":"expense","category":"Food","date":"2026-03-09","note":"opt"}\n'
        'create_goal: {"action":"create_goal","name":"X","target_amount":5000,"deadline":"2026-12-31"}\n'
        'create_budget: {"action":"create_budget","category":"Food","limit":3000,"month":3,"year":2026}\n'
        'create_recurring: {"action":"create_recurring","title":"X","amount":200,"frequency":"monthly","category":"Bills","type":"expense"}\n'
        'create_wallet: {"action":"create_wallet","name":"CIB","type":"bank","initial_balance":5000}\n'
        'delete_transaction: {"action":"delete_transaction","title":"X","amount":250,"date":"2026-03-09"}\n'
        '\n'
        'One action/response. Valid JSON with double quotes. Never assume amounts.\n';
  }

  List<ChatMessageEntity> _trimHistory(List<ChatMessageEntity> allMessages) {
    if (allMessages.isEmpty) return [];

    final result = <ChatMessageEntity>[];
    var tokenSum = 0;
    for (var i = allMessages.length - 1; i >= 0; i--) {
      final msg = allMessages[i];
      if (tokenSum + msg.tokenCount > _historyTokenBudget) break;
      tokenSum += msg.tokenCount;
      result.insert(0, msg);
    }

    // Always include at least the last user message, even if it alone
    // exceeds the token budget. Walk backward to find one.
    if (result.isEmpty) {
      for (var i = allMessages.length - 1; i >= 0; i--) {
        if (allMessages[i].role == 'user') {
          result.add(allMessages[i]);
          break;
        }
      }
      // Ultimate fallback: use the very last message regardless of role.
      if (result.isEmpty) result.add(allMessages.last);
    }

    // Ensure context window doesn't start with an assistant reply
    // (no preceding user question would confuse the model).
    while (result.length > 1 && result.first.role == 'assistant') {
      result.removeAt(0);
    }
    return result;
  }

  static int estimateTokens(String text) => (text.length / 4).ceil();

  Future<OpenRouterResponse> sendMessage({
    required List<ChatMessageEntity> allMessages,
    required FinancialContext financialContext,
  }) async {
    final systemPrompt = _buildSystemPrompt(financialContext);
    final trimmed = _trimHistory(allMessages);

    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
      for (final msg in trimmed) {'role': msg.role, 'content': msg.content},
    ];

    dev.log(
      'AiChat: sending ${messages.length} messages '
      '(${trimmed.fold<int>(0, (s, m) => s + m.tokenCount)} history tokens)',
      name: 'AiChatService',
    );

    // Try each free model in the fallback chain.
    assert(
      AiConfig.chatFallbackChain.isNotEmpty,
      'chatFallbackChain must not be empty',
    );
    Object? lastError;
    for (final model in AiConfig.chatFallbackChain) {
      try {
        return await _openRouter.chatCompletionMultiTurn(
          messages: messages,
          model: model,
          maxTokens: AiConfig.maxResponseTokens,
        );
      } on OpenRouterException catch (e) {
        if (e.isUnauthorized) rethrow; // 401 won't be fixed by switching models
        lastError = e;
        dev.log(
          'Model $model failed (${e.statusCode}), trying next...',
          name: 'AiChatService',
        );
      } catch (e) {
        // Network errors (SocketException, TimeoutException, etc.)
        lastError = e;
        dev.log(
          'Model $model failed ($e), trying next...',
          name: 'AiChatService',
        );
      }
    }
    final error = lastError;
    if (error is Exception) throw error;
    if (error is Error) throw error;
    throw Exception('All chat models failed: $error');
  }
}
