---
phase: 04
plan: 03
status: complete
started: "2026-03-28T11:00:00.000Z"
completed: "2026-03-28T11:30:00.000Z"
---

## Plan: Subscription Card + Suggestion Chips

## What Was Built
Created an interactive SubscriptionSuggestCard widget for the AI chat that replaces plain text subscription suggestions with a dismissible GlassCard featuring Confirm/Dismiss buttons. Added keyword-based subscription detection (30+ English/Arabic keywords) that triggers when a CreateTransactionAction is confirmed in chat. Added debounced category suggestion chips to AddRecurringScreen (using CategorizationLearningService) and top-2 unbudgeted category suggestion chips to SetBudgetScreen (using budgetSuggestionsProvider). Added l10n key chat_subscription_suggest in both EN and AR. Added AppDurations.categorySuggestionDebounce constant.

## Tasks Completed
| # | Task | Status | Commit |
|---|------|--------|--------|
| 1 | Interactive subscription card | done | 6313351 |
| 2 | Category + budget suggestion chips | done | 2c5cfea |

## Key Files
### Created
- lib/features/ai_chat/presentation/widgets/subscription_suggest_card.dart

### Modified
- lib/features/ai_chat/presentation/screens/chat_screen.dart
- lib/features/recurring/presentation/screens/add_recurring_screen.dart
- lib/features/budgets/presentation/screens/set_budget_screen.dart
- lib/core/constants/app_durations.dart
- lib/l10n/app_en.arb
- lib/l10n/app_ar.arb
- lib/l10n/app_localizations.dart (regenerated)
- lib/l10n/app_localizations_en.dart (regenerated)
- lib/l10n/app_localizations_ar.dart (regenerated)

## Deviations from Plan
- Plan referenced `ExecutionResult` and `SubscriptionSuggestion` classes in `chat_action_executor.dart`, but these did not exist. Instead of modifying the executor's return type (which would break all callers), implemented subscription detection inline in `chat_screen.dart` using keyword matching against `_subscriptionKeywords` after a `CreateTransactionAction` is confirmed. The user experience is identical.
- Plan referenced `suggestFromText(text, candidates)` returning `Future<CategoryEntity?>` on `CategorizationLearningService`, but the actual method is `suggestCategory(text)` returning `Future<int?>` (category ID). Adapted by looking up the CategoryEntity from the returned ID via `categoriesProvider`.
- Plan referenced `chat_subscription_suggest` l10n key as already existing, but it did not. Added it to both EN and AR ARB files.
- Plan referenced `AppDurations.categorySuggestionDebounce` as already existing, but it did not. Added it as 400ms.
- Plan referenced a plain-text subscription suggestion append in `chat_screen.dart` lines 246-251, but no such code existed. The subscription detection and interactive card rendering were implemented from scratch.

## Verification
- flutter analyze (all modified files): No issues found
- SubscriptionSuggestCard: uses GlassCard with GlassTier.inset, AppIcons.recurring, transferColor tint, design tokens
- chat_screen.dart: renders SubscriptionSuggestCard inline in reversed ListView, _pendingSubscriptionSuggestion field present
- add_recurring_screen.dart: _onTitleChanged with Timer debounce, suggestCategory call, ActionChip rendering
- set_budget_screen.dart: ref.watch(budgetSuggestionsProvider), ActionChip with CategoryIconMapper and MoneyFormatter

## Self-Check: PASSED
