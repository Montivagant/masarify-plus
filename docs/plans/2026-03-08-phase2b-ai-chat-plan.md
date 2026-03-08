# Phase 2B: AI Chat — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a conversational AI finance assistant where users ask questions about their money and get data-backed answers from a single persistent chat thread.

**Architecture:** Drift DB v6 with `chat_messages` table, `AiChatService` wrapping extended `OpenRouterService` (multi-turn messages), financial context injected per turn from existing Riverpod providers. Full-screen `ChatScreen` accessed from Hub.

**Tech Stack:** Flutter/Dart, Drift (SQLite), Riverpod 2.x, OpenRouter API, go_router

---

### Task 1: Extend OpenRouterService for multi-turn chat

**Files:**
- Modify: `lib/core/services/ai/openrouter_service.dart`

**Context:** Currently `chatCompletion()` only accepts single `systemPrompt` + `userMessage`, hardcodes a 2-element messages array, and forces `response_format: json_object`. Chat needs: (A) multi-turn messages array, (B) plain text responses (no JSON format).

**Step 1: Add `chatCompletionMultiTurn` method**

Add a new method below the existing `chatCompletion()` — do NOT modify the existing method (SMS enrichment depends on it):

```dart
/// Multi-turn chat completion for conversational AI.
///
/// [messages] is a list of `{'role': 'system'|'user'|'assistant', 'content': '...'}`.
/// Unlike [chatCompletion], this does NOT force JSON response format.
Future<OpenRouterResponse> chatCompletionMultiTurn({
  required List<Map<String, String>> messages,
  String? model,
  double temperature = 0.7,
  int? maxTokens,
}) async {
  final uri = Uri.parse('${AiConfig.openRouterBaseUrl}/chat/completions');

  final body = jsonEncode({
    'model': model ?? AiConfig.defaultModel,
    'messages': messages,
    'temperature': temperature,
    'max_tokens': maxTokens ?? AiConfig.maxResponseTokens,
    'provider': {'zdr': true},
  });

  final response = await http
      .post(
        uri,
        headers: {
          'Authorization': 'Bearer ${AiConfig.openRouterApiKey}',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://masarify.app',
          'X-Title': 'Masarify',
        },
        body: body,
      )
      .timeout(const Duration(seconds: AiConfig.apiTimeoutSeconds));

  if (response.statusCode != 200) {
    final category = response.statusCode == 429
        ? 'rate_limit'
        : response.statusCode == 401
            ? 'unauthorized'
            : response.statusCode >= 500
                ? 'server_error'
                : 'client_error';
    throw OpenRouterException(
      response.statusCode,
      'API error: $category (${response.statusCode})',
    );
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final choices = json['choices'] as List<dynamic>;
  if (choices.isEmpty) {
    throw const OpenRouterException(500, 'Empty choices array');
  }

  final firstChoice = choices[0];
  if (firstChoice is! Map<String, dynamic>) {
    throw const OpenRouterException(500, 'Invalid choice format');
  }
  final message = firstChoice['message'];
  if (message is! Map<String, dynamic>) {
    throw const OpenRouterException(500, 'Invalid message format');
  }
  final content = message['content'] as String? ?? '';

  final usage = json['usage'] as Map<String, dynamic>?;
  final tokensUsed = (usage?['total_tokens'] as int?) ?? 0;

  dev.log(
    'OpenRouter multi-turn OK: ${model ?? AiConfig.defaultModel}, tokens=$tokensUsed',
    name: 'OpenRouterService',
  );
  return OpenRouterResponse(content: content, tokensUsed: tokensUsed);
}
```

**Step 2: Run analyze**

Run: `flutter analyze lib/core/services/ai/openrouter_service.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/services/ai/openrouter_service.dart
git commit -m "feat(ai): add multi-turn chatCompletionMultiTurn to OpenRouterService"
```

---

### Task 2: Create ChatMessageEntity domain entity

**Files:**
- Create: `lib/domain/entities/chat_message_entity.dart`

**Step 1: Create the entity**

```dart
/// Domain entity for a single chat message (user, assistant, or system).
class ChatMessageEntity {
  const ChatMessageEntity({
    required this.id,
    required this.role,
    required this.content,
    required this.tokenCount,
    required this.createdAt,
  });

  final int id;

  /// 'user' | 'assistant' | 'system'
  final String role;

  final String content;

  /// Estimated token count for context window management.
  final int tokenCount;

  final DateTime createdAt;
}
```

**Step 2: Run analyze**

Run: `flutter analyze lib/domain/entities/chat_message_entity.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/domain/entities/chat_message_entity.dart
git commit -m "feat(ai): add ChatMessageEntity domain entity"
```

---

### Task 3: Create chat_messages Drift table + DAO + DB v6 migration

**Files:**
- Create: `lib/data/database/tables/chat_messages_table.dart`
- Create: `lib/data/database/daos/chat_message_dao.dart`
- Modify: `lib/data/database/app_database.dart`

**Step 1: Create the Drift table**

File: `lib/data/database/tables/chat_messages_table.dart`

```dart
import 'package:drift/drift.dart';

/// Persistent chat messages for AI conversation.
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get role => text()(); // 'user' | 'assistant' | 'system'
  TextColumn get content => text()();
  IntColumn get tokenCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}
```

**Step 2: Create the DAO**

File: `lib/data/database/daos/chat_message_dao.dart`

```dart
import 'package:drift/drift.dart';

import '../../../domain/entities/chat_message_entity.dart';
import '../app_database.dart';
import '../tables/chat_messages_table.dart';

part 'chat_message_dao.g.dart';

@DriftAccessor(tables: [ChatMessages])
class ChatMessageDao extends DatabaseAccessor<AppDatabase>
    with _$ChatMessageDaoMixin {
  ChatMessageDao(super.db);

  /// Insert a new message and return its ID.
  Future<int> insertMessage({
    required String role,
    required String content,
    required int tokenCount,
  }) {
    return into(chatMessages).insert(
      ChatMessagesCompanion.insert(
        role: role,
        content: content,
        tokenCount: Value(tokenCount),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Watch all messages ordered by creation time (oldest first).
  Stream<List<ChatMessageEntity>> watchAll() {
    final query = select(chatMessages)
      ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]);
    return query.map((row) => ChatMessageEntity(
          id: row.id,
          role: row.role,
          content: row.content,
          tokenCount: row.tokenCount,
          createdAt: row.createdAt,
        )).watch();
  }

  /// Delete all messages (clear chat).
  Future<int> deleteAll() => delete(chatMessages).go();
}
```

**Step 3: Update app_database.dart**

In `lib/data/database/app_database.dart`:

1. Add import for the new table and DAO:
```dart
import 'daos/chat_message_dao.dart';
import 'tables/chat_messages_table.dart';
```

2. Add `ChatMessages` to the `tables` list in `@DriftDatabase`
3. Add `ChatMessageDao` to the `daos` list in `@DriftDatabase`
4. Bump `schemaVersion` from `5` to `6`
5. Add migration block after the `from < 5` block:
```dart
if (from < 6) {
  await m.createTable(chatMessages);
}
```

**Step 4: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Generates `app_database.g.dart` and `chat_message_dao.g.dart`

**Step 5: Run analyze**

Run: `flutter analyze lib/`
Expected: No issues found

**Step 6: Commit**

```bash
git add lib/data/database/tables/chat_messages_table.dart lib/data/database/daos/chat_message_dao.dart lib/data/database/app_database.dart lib/data/database/app_database.g.dart lib/data/database/daos/chat_message_dao.g.dart
git commit -m "feat(db): add chat_messages table, DAO, and v6 migration"
```

---

### Task 4: Create AiChatService with FinancialContext

**Files:**
- Create: `lib/core/services/ai/ai_chat_service.dart`

**Context:** This service wraps `OpenRouterService.chatCompletionMultiTurn()`. It builds a system prompt with the user's current financial snapshot, manages token budgets, and returns assistant responses. Uses `MoneyFormatter.formatCompact()` for display values.

**Step 1: Create the service**

```dart
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

  /// Total balance across all accounts (piastres).
  final int totalBalance;

  /// This month's income total (piastres).
  final int monthlyIncome;

  /// This month's expense total (piastres).
  final int monthlyExpense;

  /// Human-readable budget status lines.
  final List<String> budgetStatus;

  /// Human-readable goal progress lines.
  final List<String> goalStatus;

  /// Top spending categories this month: "Category: amount".
  final List<String> topCategories;
}

/// Conversational AI finance assistant wrapping OpenRouter.
class AiChatService {
  const AiChatService(this._openRouter);

  final OpenRouterService _openRouter;

  /// Estimated tokens reserved for the system prompt + financial context.
  static const int _systemTokenBudget = 500;

  /// Max tokens for conversation history sent to LLM.
  static const int _historyTokenBudget = 3500;

  /// Builds the system prompt with current financial snapshot.
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

    return '''You are Masarify (مصاريفي), a personal finance assistant for an Egyptian user.
Answer in the same language the user writes in.
Keep responses concise (max 150 words). Use numbers from the provided context.
Never invent data — only reference what's provided.

Current financial snapshot:
- Balance: $balance EGP
- This month: $income income, $expense expenses
- Budgets: $budgets
- Goals: $goals
- Top categories: $cats''';
  }

  /// Selects the most recent messages that fit within [_historyTokenBudget].
  List<ChatMessageEntity> _trimHistory(List<ChatMessageEntity> allMessages) {
    final result = <ChatMessageEntity>[];
    var tokenSum = 0;
    // Walk backwards (newest first) and accumulate until budget exceeded.
    for (var i = allMessages.length - 1; i >= 0; i--) {
      final msg = allMessages[i];
      if (tokenSum + msg.tokenCount > _historyTokenBudget) break;
      tokenSum += msg.tokenCount;
      result.insert(0, msg);
    }
    return result;
  }

  /// Estimate token count for a string (~1 token per 4 chars).
  static int estimateTokens(String text) => (text.length / 4).ceil();

  /// Send a user message and get an assistant response.
  ///
  /// [allMessages] should include the new user message already appended.
  /// Returns the assistant's reply text and token count.
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

    return _openRouter.chatCompletionMultiTurn(
      messages: messages,
      temperature: 0.7,
      maxTokens: AiConfig.maxResponseTokens,
    );
  }
}
```

**Step 2: Run analyze**

Run: `flutter analyze lib/core/services/ai/ai_chat_service.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/core/services/ai/ai_chat_service.dart
git commit -m "feat(ai): add AiChatService with financial context injection"
```

---

### Task 5: Create chat providers

**Files:**
- Create: `lib/shared/providers/chat_provider.dart`

**Context:** Three providers: `chatMessageDaoProvider` (DAO singleton), `chatMessagesProvider` (StreamProvider watching DB), `financialContextProvider` (computed from existing providers), `aiChatServiceProvider` (service singleton).

Existing providers to reuse:
- `totalBalanceProvider` — `lib/shared/providers/wallet_provider.dart`
- `budgetsByMonthProvider` — `lib/shared/providers/budget_provider.dart`
- `activeGoalsProvider` — `lib/shared/providers/goal_provider.dart`
- `transactionsByMonthProvider` — `lib/shared/providers/transaction_provider.dart`
- `categoriesProvider` — `lib/shared/providers/category_provider.dart`
- `databaseProvider` — `lib/shared/providers/database_provider.dart`
- `localeProvider` — `lib/shared/providers/theme_provider.dart`

**Step 1: Create the provider file**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/ai/ai_chat_service.dart';
import '../../core/services/ai/openrouter_service.dart';
import '../../core/utils/money_formatter.dart';
import '../../data/database/daos/chat_message_dao.dart';
import '../../domain/entities/chat_message_entity.dart';
import 'budget_provider.dart';
import 'category_provider.dart';
import 'database_provider.dart';
import 'goal_provider.dart';
import 'theme_provider.dart';
import 'transaction_provider.dart';
import 'wallet_provider.dart';

// ── DAO ─────────────────────────────────────────────────────────────────

final chatMessageDaoProvider = Provider<ChatMessageDao>(
  (ref) => ref.watch(databaseProvider).chatMessageDao,
);

// ── Chat messages stream ────────────────────────────────────────────────

final chatMessagesProvider = StreamProvider<List<ChatMessageEntity>>(
  (ref) => ref.watch(chatMessageDaoProvider).watchAll(),
);

// ── AI Chat Service ─────────────────────────────────────────────────────

final aiChatServiceProvider = Provider<AiChatService>(
  (ref) => const AiChatService(OpenRouterService()),
);

// ── Financial Context ───────────────────────────────────────────────────

final financialContextProvider = Provider<FinancialContext>((ref) {
  final now = DateTime.now();
  final monthKey = (now.year, now.month);
  final lang = ref.watch(localeProvider)?.languageCode ?? 'ar';

  // Balance
  final balance = ref.watch(totalBalanceProvider).valueOrNull ?? 0;

  // This month's income/expense
  final thisMonthTxs =
      ref.watch(transactionsByMonthProvider(monthKey)).valueOrNull ?? [];
  var income = 0;
  var expense = 0;
  for (final tx in thisMonthTxs) {
    if (tx.type == 'income') income += tx.amount;
    if (tx.type == 'expense') expense += tx.amount;
  }

  // Budget status
  final budgets =
      ref.watch(budgetsByMonthProvider(monthKey)).valueOrNull ?? [];
  final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
  final catMap = {for (final c in categories) c.id: c};

  final budgetLines = <String>[];
  for (final b in budgets) {
    final cat = catMap[b.categoryId];
    if (cat == null) continue;
    final pct = (b.progressFraction * 100).round();
    budgetLines.add('${cat.displayName(lang)}: $pct%');
  }

  // Goal status
  final goals = ref.watch(activeGoalsProvider).valueOrNull ?? [];
  final goalLines = <String>[];
  for (final g in goals) {
    final pct =
        g.targetAmount > 0 ? (g.currentAmount * 100 ~/ g.targetAmount) : 0;
    goalLines.add('${g.name}: $pct%');
  }

  // Top 3 spending categories
  final byCat = <int, int>{};
  for (final tx in thisMonthTxs.where((t) => t.type == 'expense')) {
    byCat[tx.categoryId] = (byCat[tx.categoryId] ?? 0) + tx.amount;
  }
  final sortedCats = byCat.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final topCats = sortedCats.take(3).map((e) {
    final cat = catMap[e.key];
    final name = cat?.displayName(lang) ?? '?';
    return '$name: ${MoneyFormatter.formatCompact(e.value)}';
  }).toList();

  return FinancialContext(
    totalBalance: balance,
    monthlyIncome: income,
    monthlyExpense: expense,
    budgetStatus: budgetLines,
    goalStatus: goalLines,
    topCategories: topCats,
  );
});
```

**Step 2: Run analyze**

Run: `flutter analyze lib/shared/providers/chat_provider.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/shared/providers/chat_provider.dart
git commit -m "feat(ai): add chat providers (DAO, messages stream, financial context)"
```

---

### Task 6: Create TypingIndicator widget

**Files:**
- Create: `lib/features/ai_chat/presentation/widgets/typing_indicator.dart`

**Context:** Three animated dots that pulse while waiting for LLM response. Uses `AnimationController` with staggered delays.

**Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';

/// Three pulsing dots shown while waiting for AI response.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  static const _dotCount = 3;
  static const _duration = Duration(milliseconds: 600);
  static const _staggerDelay = Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      _dotCount,
      (i) => AnimationController(vsync: this, duration: _duration),
    );
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();

    // Start staggered animation loop.
    for (var i = 0; i < _dotCount; i++) {
      Future.delayed(_staggerDelay * i, () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_dotCount, (i) {
        return AnimatedBuilder(
          animation: _animations[i],
          builder: (context, _) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: AppSizes.dotSm,
              height: AppSizes.dotSm,
              decoration: BoxDecoration(
                color: context.colors.onSurfaceVariant
                    .withValues(alpha: 0.3 + 0.5 * _animations[i].value),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
```

**Step 2: Run analyze**

Run: `flutter analyze lib/features/ai_chat/presentation/widgets/typing_indicator.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/ai_chat/presentation/widgets/typing_indicator.dart
git commit -m "feat(ai): add TypingIndicator animated dots widget"
```

---

### Task 7: Create MessageBubble widget

**Files:**
- Create: `lib/features/ai_chat/presentation/widgets/message_bubble.dart`

**Context:** User messages: right-aligned, primary color tint, GlassCard. Assistant messages: left-aligned, surface color, small AI icon avatar, GlassCard. RTL-aware via `EdgeInsetsDirectional`. Uses `context.isRtl` for alignment flipping.

**Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../domain/entities/chat_message_entity.dart';
import '../../../../shared/widgets/cards/glass_card.dart';

/// A single chat message bubble — user (right) or assistant (left).
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessageEntity message;

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Align(
      alignment: _isUser
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: context.screenWidth * 0.78,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSizes.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            textDirection: _isUser ? TextDirection.rtl : TextDirection.ltr,
            children: [
              if (!_isUser) ...[
                CircleAvatar(
                  radius: AppSizes.iconXs,
                  backgroundColor:
                      cs.primaryContainer.withValues(alpha: AppSizes.opacityLight4),
                  child: Icon(
                    AppIcons.ai,
                    size: AppSizes.iconXs,
                    color: cs.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
              ],
              Flexible(
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.md,
                    vertical: AppSizes.sm + AppSizes.xs,
                  ),
                  tintColor: _isUser
                      ? cs.primary.withValues(alpha: AppSizes.opacityLight)
                      : cs.surfaceContainerHighest
                          .withValues(alpha: AppSizes.opacityLight4),
                  child: Text(
                    message.content,
                    style: context.textStyles.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Run analyze**

Run: `flutter analyze lib/features/ai_chat/presentation/widgets/message_bubble.dart`
Expected: No issues found

**Step 3: Commit**

```bash
git add lib/features/ai_chat/presentation/widgets/message_bubble.dart
git commit -m "feat(ai): add MessageBubble widget with RTL-aware layout"
```

---

### Task 8: Add L10n strings

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`
- Modify: `lib/l10n/app_localizations.dart`
- Modify: `lib/l10n/app_localizations_en.dart`
- Modify: `lib/l10n/app_localizations_ar.dart`

**Step 1: Add keys to app_en.arb**

Add these entries (in alphabetical order among existing keys):

```json
"chat_title": "Masarify AI",
"chat_input_hint": "Ask about your finances...",
"chat_clear": "Clear chat",
"chat_clear_confirm": "Delete all messages?",
"chat_offline": "You're offline — chat requires internet",
"chat_error_rate_limit": "Too many requests, try again shortly",
"chat_error_timeout": "Response timed out, try again",
"chat_error_generic": "Something went wrong, try again",
"hub_section_ai": "AI Assistant"
```

**Step 2: Add keys to app_ar.arb**

```json
"chat_title": "مصاريفي AI",
"chat_input_hint": "اسأل عن مصاريفك...",
"chat_clear": "مسح المحادثة",
"chat_clear_confirm": "حذف كل الرسائل؟",
"chat_offline": "أنت غير متصل — المحادثة تحتاج إنترنت",
"chat_error_rate_limit": "طلبات كثيرة، حاول بعد قليل",
"chat_error_timeout": "انتهت المهلة، حاول مرة أخرى",
"chat_error_generic": "حدث خطأ، حاول مرة أخرى",
"hub_section_ai": "مساعد ذكي"
```

**Step 3: Update app_localizations.dart**

Add abstract getters for each key:

```dart
String get chat_title;
String get chat_input_hint;
String get chat_clear;
String get chat_clear_confirm;
String get chat_offline;
String get chat_error_rate_limit;
String get chat_error_timeout;
String get chat_error_generic;
String get hub_section_ai;
```

**Step 4: Update app_localizations_en.dart**

Add implementations returning EN values.

**Step 5: Update app_localizations_ar.dart**

Add implementations returning AR values.

**Step 6: Run analyze**

Run: `flutter analyze lib/l10n/`
Expected: No issues found

**Step 7: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ar.arb lib/l10n/app_localizations.dart lib/l10n/app_localizations_en.dart lib/l10n/app_localizations_ar.dart
git commit -m "feat(l10n): add AI chat localization strings (EN + AR)"
```

---

### Task 9: Create ChatScreen

**Files:**
- Create: `lib/features/ai_chat/presentation/screens/chat_screen.dart`

**Context:** `ConsumerStatefulWidget` with:
- `AppAppBar` titled "Masarify AI", with clear-chat trash icon action (confirmation dialog)
- `ListView.builder` reversed for auto-scroll-to-bottom
- Bottom input bar: `TextField` + send `IconButton`, disabled when offline or loading
- Typing indicator shown while waiting for LLM
- Offline inline message when disconnected
- Error messages shown as assistant-style inline messages (not SnackBars)
- Watches `chatMessagesProvider`, `isOnlineProvider`
- Uses `chatMessageDaoProvider` to insert messages, `aiChatServiceProvider` to send

**Step 1: Create the screen**

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/ai/ai_chat_service.dart';
import '../../../../core/services/ai/openrouter_service.dart';
import '../../../../shared/providers/chat_provider.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear();
    setState(() => _isSending = true);

    final dao = ref.read(chatMessageDaoProvider);
    final service = ref.read(aiChatServiceProvider);
    final financialCtx = ref.read(financialContextProvider);

    // Insert user message.
    final tokenCount = AiChatService.estimateTokens(text);
    await dao.insertMessage(
      role: 'user',
      content: text,
      tokenCount: tokenCount,
    );

    try {
      // Read current messages (including the one just inserted).
      final allMessages =
          ref.read(chatMessagesProvider).valueOrNull ?? [];

      final response = await service.sendMessage(
        allMessages: allMessages,
        financialContext: financialCtx,
      );

      await dao.insertMessage(
        role: 'assistant',
        content: response.content,
        tokenCount: AiChatService.estimateTokens(response.content),
      );
    } on OpenRouterException catch (e) {
      final errorMsg = e.isRateLimit
          ? context.l10n.chat_error_rate_limit
          : context.l10n.chat_error_generic;
      await dao.insertMessage(
        role: 'assistant',
        content: errorMsg,
        tokenCount: AiChatService.estimateTokens(errorMsg),
      );
    } on TimeoutException {
      final errorMsg = context.l10n.chat_error_timeout;
      await dao.insertMessage(
        role: 'assistant',
        content: errorMsg,
        tokenCount: AiChatService.estimateTokens(errorMsg),
      );
    } catch (_) {
      final errorMsg = context.l10n.chat_error_generic;
      await dao.insertMessage(
        role: 'assistant',
        content: errorMsg,
        tokenCount: AiChatService.estimateTokens(errorMsg),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _clearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.chat_clear),
        content: Text(ctx.l10n.chat_clear_confirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.common_delete),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(chatMessageDaoProvider).deleteAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(chatMessagesProvider);
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;
    final messages = messagesAsync.valueOrNull ?? [];

    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.chat_title,
        actions: [
          IconButton(
            icon: const Icon(AppIcons.delete),
            onPressed: messages.isEmpty ? null : _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          if (!isOnline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              color: context.appTheme.expenseColor
                  .withValues(alpha: AppSizes.opacityLight),
              child: Text(
                context.l10n.chat_offline,
                style: context.textStyles.labelSmall,
                textAlign: TextAlign.center,
              ),
            ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenHPadding,
                vertical: AppSizes.sm,
              ),
              itemCount: messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                // Typing indicator at position 0 (bottom of reversed list).
                if (_isSending && index == 0) {
                  return const Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: AppSizes.sm),
                      child: TypingIndicator(),
                    ),
                  );
                }

                final msgIndex = _isSending
                    ? messages.length - index
                    : messages.length - 1 - index;
                if (msgIndex < 0 || msgIndex >= messages.length) {
                  return const SizedBox.shrink();
                }
                return MessageBubble(message: messages[msgIndex]);
              },
            ),
          ),

          // Input bar
          Container(
            padding: EdgeInsets.only(
              left: AppSizes.md,
              right: AppSizes.sm,
              top: AppSizes.sm,
              bottom: MediaQuery.paddingOf(context).bottom + AppSizes.sm,
            ),
            decoration: BoxDecoration(
              color: context.colors.surface,
              border: Border(
                top: BorderSide(
                  color: context.colors.outlineVariant
                      .withValues(alpha: AppSizes.opacityLight4),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: isOnline && !_isSending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: context.l10n.chat_input_hint,
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    minLines: 1,
                    maxLines: 4,
                  ),
                ),
                IconButton(
                  onPressed: isOnline && !_isSending ? _send : null,
                  icon: Icon(
                    AppIcons.send,
                    color: isOnline && !_isSending
                        ? context.colors.primary
                        : context.colors.onSurface
                            .withValues(alpha: AppSizes.opacityLight4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**Step 2: Verify `AppIcons.send` exists, add if not**

Check `lib/core/constants/app_icons.dart` for a `send` icon. If missing, add:
```dart
static const IconData send = PhosphorIconsFill.paperPlaneRight;
```

**Step 3: Run analyze**

Run: `flutter analyze lib/features/ai_chat/`
Expected: No issues found

**Step 4: Commit**

```bash
git add lib/features/ai_chat/presentation/screens/chat_screen.dart
git commit -m "feat(ai): add ChatScreen with message list, input bar, typing indicator"
```

---

### Task 10: Add route and Hub entry point

**Files:**
- Modify: `lib/core/constants/app_routes.dart`
- Modify: `lib/app/router/app_router.dart`
- Modify: `lib/features/hub/presentation/screens/hub_screen.dart`

**Step 1: Add route constant**

In `lib/core/constants/app_routes.dart`, add in the "Smart input" section:

```dart
static const String chat = '/chat';
```

**Step 2: Add route to router**

In `lib/app/router/app_router.dart`:

1. Add import:
```dart
import '../../features/ai_chat/presentation/screens/chat_screen.dart';
```

2. Add route near the other smart input routes (after `parserReview`):
```dart
GoRoute(
  path: AppRoutes.chat,
  pageBuilder: (_, state) => _fadePage(
    state: state,
    child: const ChatScreen(),
  ),
),
```

**Step 3: Add Hub entry**

In `lib/features/hub/presentation/screens/hub_screen.dart`, add an "AI Assistant" section BEFORE the bottom `SizedBox`:

```dart
// ── AI Assistant ──────────────────────────────────────────────
_section(context, context.l10n.hub_section_ai, [
  _tile(
    context,
    context.l10n.chat_title,
    AppIcons.ai,
    AppRoutes.chat,
  ),
]),
```

**Step 4: Run analyze**

Run: `flutter analyze lib/`
Expected: No issues found

**Step 5: Commit**

```bash
git add lib/core/constants/app_routes.dart lib/app/router/app_router.dart lib/features/hub/presentation/screens/hub_screen.dart
git commit -m "feat(ai): add chat route, Hub AI Assistant section entry point"
```

---

### Task 11: Full verification

**Step 1: Run build_runner**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: Completes with no errors

**Step 2: Run analyze**

Run: `flutter analyze lib/`
Expected: No issues found

**Step 3: Run tests**

Run: `flutter test`
Expected: All tests pass

**Step 4: Final commit (if any fixups needed)**

If any issues were found and fixed in steps 1-3, commit the fixes.

---

## Dependency Order

```
1. OpenRouterService extension (Task 1) — no deps
2. ChatMessageEntity (Task 2) — no deps
3. DB table + DAO + migration (Task 3) — depends on 2
4. AiChatService (Task 4) — depends on 1
5. Chat providers (Task 5) — depends on 3, 4
6. TypingIndicator (Task 6) — no deps
7. MessageBubble (Task 7) — depends on 2
8. L10n strings (Task 8) — no deps
9. ChatScreen (Task 9) — depends on 5, 6, 7, 8
10. Route + Hub entry (Task 10) — depends on 9, 8
11. Full verification (Task 11) — depends on all
```

Tasks 1, 2, 6, 8 can run in parallel. Tasks 3+4 can run in parallel after 1+2.

---

## Key Existing Utilities to Reuse

- `OpenRouterService` — `lib/core/services/ai/openrouter_service.dart`
- `AiConfig` — `lib/core/config/ai_config.dart`
- `MoneyFormatter.formatCompact()` — `lib/core/utils/money_formatter.dart`
- `AppAppBar` — `lib/shared/widgets/navigation/app_app_bar.dart`
- `GlassCard` — `lib/shared/widgets/cards/glass_card.dart`
- `AppIcons.ai` — `lib/core/constants/app_icons.dart`
- `isOnlineProvider` — `lib/shared/providers/connectivity_provider.dart`
- `totalBalanceProvider` — `lib/shared/providers/wallet_provider.dart`
- `budgetsByMonthProvider` — `lib/shared/providers/budget_provider.dart`
- `activeGoalsProvider` — `lib/shared/providers/goal_provider.dart`
- `transactionsByMonthProvider` — `lib/shared/providers/transaction_provider.dart`
- `categoriesProvider` — `lib/shared/providers/category_provider.dart`
- `databaseProvider` — `lib/shared/providers/database_provider.dart`
- `localeProvider` — `lib/shared/providers/theme_provider.dart`
- `_fadePage()` — `lib/app/router/app_router.dart`
- `context.l10n`, `context.colors`, `context.appTheme`, `context.isRtl` — `lib/core/extensions/build_context_extensions.dart`

---

## Verification

1. `dart run build_runner build --delete-conflicting-outputs` — after DB table + DAO
2. `flutter analyze lib/` — zero issues
3. `flutter test` — all pass
4. Manual testing:
   - Hub → AI Assistant section → tap → ChatScreen opens
   - Send message → typing indicator → response appears
   - Scroll back through history after app restart → messages persisted
   - Toggle offline → input disabled, inline banner shown
   - Clear chat → confirmation dialog → messages deleted
   - Test AR/RTL — bubbles flip, input RTL
   - Long conversation → older messages drop from LLM context but remain in scroll-back
   - Rate limit / timeout → error shown as inline message (not SnackBar)
