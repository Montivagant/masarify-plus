# Phase 4: AI, Voice & Subscriptions Polish - Context

**Gathered:** 2026-03-27 (auto mode — codebase analysis)
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the AI Financial Advisor and voice input into a seamless, differentiated experience that justifies the Pro paywall. Requirements: AI-01, AI-02, AI-05, AI-06, VOICE-03, SUB-02, SUB-03, SUB-04, SUB-05, CAT-05.

</domain>

<decisions>
## Implementation Decisions

### AI Language Enforcement (AI-01)
- **D-01:** The model-level language rule already exists in both EN and AR system prompts (`⚡ LANGUAGE RULE (HIGHEST PRIORITY): You MUST respond in {language}`). The remaining gap is `ChatActionMessages` which may still return hardcoded English strings for action confirmations. Verify if Phase 2 fix (D-09) was completed. If not, wire all action confirmation messages through `context.l10n`.
- **D-02:** This is a verification + fix task, not greenfield work.

### AI Date Context (AI-02)
- **D-03:** Date injection infrastructure exists — `FinancialContext.currentDate` field, `DateTime.now()` used in prompt formatting, `CURRENT DATE & TIME` string embedded in both EN and AR prompts. Verify the call site (wherever `FinancialContext` is constructed) passes `currentDate: DateTime.now()`. If it does, AI-02 is already complete. If missing, add it.
- **D-04:** This is a verification task. Likely already working — just confirm.

### Transfer Intent Detection (AI-06)
- **D-05:** Full transfer pipeline exists: `CreateTransferAction` sealed class, `_executeTransfer` in executor, `WalletMatcher.match()` for fuzzy wallet resolution. The system prompt already has transfer detection instructions with 4 Arabic verb keywords.
- **D-06:** Expand the transfer keyword list in both EN and AR prompts to cover ambiguous phrasing: "paid...to settle", "cleared credit card", "سددت", "دفعت على", "حولت من...لـ", "from X to Y", "دفعت من CIB عشان أسدد NBE". Add 5-8 more Egyptian conversational transfer patterns.
- **D-07:** No code logic changes needed — this is entirely system prompt string editing in `ai_chat_service.dart`.

### Subscription Detection in AI Chat (AI-05, SUB-05)
- **D-08:** The detection logic already works — `SubscriptionDetector.isSubscriptionLike()` is called in `_executeTransaction` and returns `SubscriptionSuggestion` on `ExecutionResult`. Voice already shows an interactive card via `DraftCard._buildSubscriptionSuggestion`.
- **D-09:** The gap is in AI chat: `chat_screen.dart` line 247 appends plain text ("Add to Subscriptions?") instead of showing an interactive action card. Elevate this to an interactive confirm/dismiss widget matching what voice does.
- **D-10:** Both voice AND chat should prompt "Add to Subscriptions & Bills?" for recurring-pattern transactions. Voice already works. Chat needs the interactive card upgrade.

### Brand Icon Resolution (VOICE-03)
- **D-11:** `BrandRegistry` has 50+ brands with ~120 keywords including Arabic transliterations. The `match()` function works. Identified missing brands: Anghami, Disney+, Paymob, Capiter, Tap — add ~10 Egyptian brands.
- **D-12:** Verify `TransactionCard` calls `BrandRegistry.match()` and applies `BrandInfo.color` to the icon background. If not wired, add the call. The brand color display path and category icon path are separate — both must work.

### Category Suggestions Cross-Feature (CAT-05)
- **D-13:** `CategorizationLearningService.suggestFromText()` exists and works. It's used in `AddTransactionScreen` but NOT in `SetBudgetScreen` or `AddRecurringScreen`.
- **D-14:** For `AddRecurringScreen`: Wire `_titleController.addListener` → `suggestFromText()` → show category suggestion chip inline above the category picker. This is the highest-value touch point (subscription titles are unique/learnable).
- **D-15:** For `SetBudgetScreen`: Show top-2 unbudgeted categories from `budgetSuggestionsProvider` (already computed in `background_ai_provider.dart`) as suggestion chips before the manual picker.
- **D-16:** Goals have NO category concept — `AddGoalScreen` has name, amount, deadline, color, icon, keywords but no category field. **CAT-05 does not apply to goals.** Do not add a category field to goals.

### Subscription Due Dates (SUB-02)
- **D-17:** **No schema change needed.** `RecurringRules` table already has `nextDueDate` (non-nullable dateTime). `AddRecurringScreen` already has date pickers for both one-time bills (`recurring_due_date_label` → "Due") and repeating subscriptions (`_startDate` → sets `nextDueDate`). The ROADMAP description ("Add a dueDate field if not already present") is incorrect — it already exists.
- **D-18:** Verify the date picker is clearly labeled and accessible for all frequency types, not just `_isOnce`. If the UX is confusing, improve labeling. No DB migration needed.

### Bill Reminder Notifications (SUB-03)
- **D-19:** `NotificationService` has `scheduleDaily()` (repeating) and `show()` (immediate) but NO `scheduleOnce(DateTime)` for scheduling a future one-shot notification. Add this method using `flutter_local_notifications`'s `zonedSchedule` without `matchDateTimeComponents`.
- **D-20:** Create a `BillReminderService` that reads `upcomingBillsProvider` (already computed — bills due within 7 days) and schedules a notification 3 days before each due date. Use notification ID `rule.id + 100_000` for deduplication (existing convention documented in NotificationService).
- **D-21:** Call `BillReminderService` on app startup (in `main.dart` or a lifecycle listener). Also call when `upcomingBillsProvider` updates if the user creates/edits a subscription.

### Recurring Pattern Detection Surfacing (SUB-04)
- **D-22:** `detectedPatternsProvider` already runs `RecurringPatternDetector` on 90 days of transactions, deduplicates against existing rules. `AddRecurringScreen` already accepts `DetectedPattern?` and pre-fills all fields via `_prefillFromPattern()`.
- **D-23:** Verify the "Recurring Detected" insight card in `insight_cards_zone.dart` exists and correctly links to `AddRecurringScreen(detectedPattern: pattern)`. If the insight card is missing or not tapping through, wire it. From MEMORY.md the insight card order includes "RecurringDetected" — so it likely exists.

### Claude's Discretion
- Exact interactive subscription suggestion card design for AI chat (matching voice style but adapted for chat context)
- How many additional transfer intent phrases to add (minimum 5, maximum 10)
- Whether `BillReminderService` runs on every app resume or only on cold start
- Exact labeling for due date picker across subscription frequency types
- Whether detected pattern insight card uses navigation or bottom sheet to create the subscription

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### AI Chat & System Prompt
- `lib/core/services/ai/ai_chat_service.dart` — System prompts (EN lines 105-220, AR lines 221-310), FinancialContext injection, language rule
- `lib/core/services/ai/chat_action_executor.dart` — Action execution, `_executeTransaction`, `_executeTransfer`, subscription detection
- `lib/core/services/ai/chat_action.dart` — Action types including `CreateTransferAction`, `CreateRecurringAction`
- `lib/core/services/ai/chat_action_messages.dart` — Action confirmation messages (l10n check)
- `lib/core/services/ai/chat_response_parser.dart` — 3-layer JSON parser

### Voice & Brand Matching
- `lib/core/constants/brand_registry.dart` — 50+ brands, match() function, Egyptian brand keywords
- `lib/core/utils/category_icon_mapper.dart` — Category → icon mapping
- `lib/core/utils/subscription_detector.dart` — `isSubscriptionLike()` for both voice and chat
- `lib/features/voice_input/presentation/widgets/draft_card.dart` — `_buildSubscriptionSuggestion` (reference pattern for chat)

### AI Chat UI
- `lib/features/ai_chat/presentation/screens/chat_screen.dart` — Line 247: text append for subscription suggestion (needs upgrade)
- `lib/features/ai_chat/presentation/widgets/message_bubble.dart` — Message rendering

### Category Suggestions
- `lib/core/services/ai/categorization_learning_service.dart` — `suggestFromText()` method
- `lib/shared/providers/background_ai_provider.dart` — `budgetSuggestionsProvider`, `detectedPatternsProvider`, `upcomingBillsProvider`
- `lib/features/recurring/presentation/screens/add_recurring_screen.dart` — Category picker, `DetectedPattern` support, `_titleController`
- `lib/features/budgets/presentation/screens/set_budget_screen.dart` — Category picker (manual only, needs suggestion chips)

### Notifications & Subscriptions
- `lib/core/services/notification_service.dart` — `scheduleDaily()`, `show()`, ID convention (`rule.id + 100_000`)
- `lib/core/services/preferences_service.dart` — `notifyBillReminder` preference
- `lib/data/database/tables/recurring_rules_table.dart` — `nextDueDate` column (already exists)
- `lib/core/services/ai/recurring_pattern_detector.dart` — Pattern detection logic

### Dashboard Integration
- `lib/features/dashboard/presentation/widgets/insight_cards_zone.dart` — Insight cards (verify RecurringDetected card)

### Design System
- `lib/shared/widgets/cards/transaction_card.dart` — Brand color display (VOICE-03 wiring check)
- `lib/shared/widgets/feedback/snack_helper.dart` — Success feedback

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `SubscriptionDetector.isSubscriptionLike()` — Pure Dart, works for both voice and chat
- `BrandRegistry.match()` — 50+ brands with Arabic keywords, returns `BrandInfo`
- `WalletMatcher.match()` — Fuzzy wallet resolution for transfer detection
- `upcomingBillsProvider` — Already computes bills due within 7 days
- `detectedPatternsProvider` — Already runs pattern detection on 90 days of transactions
- `budgetSuggestionsProvider` — Already computes top unbudgeted categories
- `CategorizationLearningService.suggestFromText()` — Category suggestion from text input
- `DraftCard._buildSubscriptionSuggestion` — Interactive subscription card pattern (voice)
- `AddRecurringScreen(detectedPattern:)` — Pre-fill from detected pattern already works
- `FinancialContext.currentDate` — Date injection already in system prompt

### Established Patterns
- Riverpod provider chain: `StreamProvider` → Repository → DAO → Drift
- AI action types: sealed `ChatAction` subclasses parsed from model response
- Notification IDs: `rule.id + 100_000` convention for subscription reminders
- System prompt: separate EN/AR blocks with locale switch

### Integration Points
- `chat_screen.dart` line 247 — subscription suggestion text → interactive card
- `ai_chat_service.dart` — system prompt string edits for transfer keywords
- `notification_service.dart` — add `scheduleOnce` method
- `brand_registry.dart` — append missing Egyptian brands
- `add_recurring_screen.dart` — wire title → category suggestion
- `set_budget_screen.dart` — add suggestion chips from `budgetSuggestionsProvider`
- `insight_cards_zone.dart` — verify detected pattern card wiring

</code_context>

<specifics>
## Specific Ideas

No specific requirements — auto mode used codebase-derived recommendations for all decisions.

</specifics>

<deferred>
## Deferred Ideas

- **CAT-05 for Goals:** Goals have no category concept. Adding one would require schema changes and is a new capability, not polish. Deferred to future milestone.

</deferred>

---

*Phase: 04-ai-voice-subscriptions-polish*
*Context gathered: 2026-03-27 (auto mode)*
