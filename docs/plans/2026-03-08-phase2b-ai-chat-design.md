# Phase 2B: AI Chat — Design

## Context

Masarify has a mature AI infrastructure: OpenRouter LLM integration (multi-model fallback), Gemini audio, SMS enrichment, and 4 heuristic background AI services. Phase 2B adds a conversational finance assistant where users ask questions about their money and get data-backed answers.

## Decisions

- **Architecture:** Full conversational chat with DB persistence (Drift, v6 migration)
- **LLM:** Existing OpenRouterService — no new API integration
- **No streaming:** Request-response with typing indicator (keeps HTTP layer simple)
- **Single thread:** One continuous conversation (no multiple chats), matches personal assistant model
- **Entry point:** Hub screen → "AI Assistant" section
- **Offline:** Chat history viewable, sending disabled with inline message

---

## Data Model

**DB table `chat_messages` (v6):**

| Column | Type | Notes |
|--------|------|-------|
| id | INTEGER PK | Auto-increment |
| role | TEXT NOT NULL | 'user' \| 'assistant' \| 'system' |
| content | TEXT NOT NULL | Message text |
| token_count | INTEGER DEFAULT 0 | For context window management |
| created_at | DATETIME NOT NULL | When sent/received |

No conversations table — single continuous thread.

**Domain entity: `ChatMessageEntity`**
- `id`, `role`, `content`, `tokenCount`, `createdAt`

---

## AI Chat Service

**Service: `AiChatService`** wraps `OpenRouterService.chatCompletion()`.

```
sendMessage(userMessage, recentHistory, financialContext) → String
```

**`FinancialContext`** — snapshot injected into system prompt each turn:
- Total balance across accounts
- This month's income/expense totals
- Budget status (which are at risk)
- Active savings goals + progress
- Top 3 spending categories this month

Computed from existing providers: `totalBalanceProvider`, `monthlyIncomeProvider`, `monthlyExpenseProvider`, `budgetsByMonthProvider`, `activeGoalsProvider`, `categoryBreakdownProvider`.

**System prompt:**
```
You are Masarify (مصاريفي), a personal finance assistant for an Egyptian user.
Answer in the same language the user writes in.
Keep responses concise (max 150 words). Use numbers from the provided context.
Never invent data — only reference what's provided.

Current financial snapshot:
- Balance: {balance} EGP
- This month: {income} income, {expense} expenses
- Budgets: {budgetStatus}
- Goals: {goalStatus}
- Top categories: {topCategories}
```

**Token management:**
- Estimate: ~1 token per 4 chars
- System prompt + context ≈ 500 tokens reserved
- Conversation history: take newest messages until ~3500 tokens
- Response budget: 1024 tokens (existing `AiConfig.maxResponseTokens`)
- Older messages stay in DB for scroll-back but aren't sent to LLM

**Error handling:** Errors shown as inline assistant-style messages (not SnackBars):
- Rate limit → "Too many requests, try again shortly"
- Timeout → "Response timed out, try again"
- Unauthorized → "API key issue, check settings"

---

## UI

**Screen: `ChatScreen`** — `ConsumerStatefulWidget` at `AppRoutes.chat`.

- `AppAppBar`: title "Masarify AI", clear-chat action (trash icon with confirmation dialog)
- `ListView.builder`: reversed, auto-scroll to newest
- Bottom input bar: `TextField` + send `IconButton`, disabled when offline or loading
- Typing indicator: 3 animated dots while waiting for LLM

**Message bubbles:**
- User: right-aligned, primary color tint, `GlassCard`
- Assistant: left-aligned, surface color, small icon avatar, `GlassCard`
- RTL-aware via `EdgeInsetsDirectional`

**Entry point:** Hub screen → new "AI Assistant" section with chat row.

**Navigation:** `context.push(AppRoutes.chat)` — full-screen, no bottom nav.

---

## Providers

| Provider | Type | Purpose |
|----------|------|---------|
| `chatMessagesProvider` | `StreamProvider<List<ChatMessageEntity>>` | Watches DB stream |
| `aiChatServiceProvider` | `Provider<AiChatService>` | Singleton |
| `financialContextProvider` | `Provider<FinancialContext>` | Computed snapshot |

---

## New Files

| File | Type |
|------|------|
| `lib/data/database/tables/chat_messages_table.dart` | Drift table |
| `lib/data/database/daos/chat_message_dao.dart` | Drift DAO |
| `lib/domain/entities/chat_message_entity.dart` | Domain entity |
| `lib/core/services/ai/ai_chat_service.dart` | Service |
| `lib/features/ai_chat/presentation/screens/chat_screen.dart` | Screen |
| `lib/features/ai_chat/presentation/widgets/message_bubble.dart` | Widget |
| `lib/features/ai_chat/presentation/widgets/typing_indicator.dart` | Widget |
| `lib/shared/providers/chat_provider.dart` | Providers |

## Modified Files

| File | Change |
|------|--------|
| `lib/data/database/app_database.dart` | v6 migration, add table + DAO |
| `lib/features/hub/presentation/screens/hub_screen.dart` | Add AI Assistant entry |
| `lib/app/router/app_router.dart` | Add chat route |
| `lib/core/constants/app_routes.dart` | Add `chat` constant |
| `lib/l10n/app_en.arb` / `app_ar.arb` | New strings |
| `lib/l10n/app_localizations*.dart` | Generated |

## L10n Keys

| Key | EN | AR |
|-----|----|----|
| `chat_title` | `"Masarify AI"` | `"مصاريفي AI"` |
| `chat_input_hint` | `"Ask about your finances..."` | `"اسأل عن مصاريفك..."` |
| `chat_clear` | `"Clear chat"` | `"مسح المحادثة"` |
| `chat_clear_confirm` | `"Delete all messages?"` | `"حذف كل الرسائل؟"` |
| `chat_offline` | `"You're offline — chat requires internet"` | `"أنت غير متصل — المحادثة تحتاج إنترنت"` |
| `chat_error_rate_limit` | `"Too many requests, try again shortly"` | `"طلبات كثيرة، حاول بعد قليل"` |
| `chat_error_timeout` | `"Response timed out, try again"` | `"انتهت المهلة، حاول مرة أخرى"` |
| `hub_section_ai` | `"AI Assistant"` | `"مساعد ذكي"` |

## Verification

1. `dart run build_runner build --delete-conflicting-outputs` (after DB table + DAO)
2. `flutter analyze lib/` — zero issues
3. `flutter test` — all pass
4. Manual testing:
   - Send message → typing indicator → response appears
   - Scroll back through history after app restart → messages persisted
   - Toggle offline → input disabled, inline message shown
   - Clear chat → confirmation dialog → messages deleted
   - Test AR/RTL — bubbles flip, input RTL
   - Long conversation → older messages drop from LLM context but remain in scroll-back
