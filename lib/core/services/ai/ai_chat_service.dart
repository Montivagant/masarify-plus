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
  });

  final int totalBalance;
  final int monthlyIncome;
  final int monthlyExpense;
  final List<String> budgetStatus;
  final List<String> goalStatus;
  final List<String> topCategories;
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
    final goals = ctx.goalStatus.isEmpty
        ? 'No active goals'
        : ctx.goalStatus.join(', ');
    final cats = ctx.topCategories.isEmpty
        ? 'No spending data yet'
        : ctx.topCategories.join(', ');

    return 'You are Masarify (مصاريفي), a personal finance assistant for an Egyptian user.\n'
        'Answer in the same language the user writes in.\n'
        'Keep responses concise (max 150 words). Use numbers from the provided context.\n'
        'Never invent data — only reference what\'s provided.\n'
        '\n'
        'Current financial snapshot:\n'
        '- Balance: $balance EGP\n'
        '- This month: $income income, $expense expenses\n'
        '- Budgets: $budgets\n'
        '- Goals: $goals\n'
        '- Top categories: $cats';
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

    // Always include the last message (the user's just-sent message)
    // even if it alone exceeds the token budget.
    if (result.isEmpty) {
      result.add(allMessages.last);
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
      for (final msg in trimmed)
        {'role': msg.role, 'content': msg.content},
    ];

    dev.log(
      'AiChat: sending ${messages.length} messages '
      '(${trimmed.fold<int>(0, (s, m) => s + m.tokenCount)} history tokens)',
      name: 'AiChatService',
    );

    // Try each free model in the fallback chain.
    assert(AiConfig.chatFallbackChain.isNotEmpty, 'chatFallbackChain must not be empty');
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
