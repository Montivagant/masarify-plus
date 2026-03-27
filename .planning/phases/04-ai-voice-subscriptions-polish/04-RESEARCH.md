# Phase 4: AI, Voice & Subscriptions Polish - Research

**Researched:** 2026-03-27
**Domain:** AI chat UX, voice brand matching, notification scheduling, category intelligence
**Confidence:** HIGH

## Summary

Phase 4 polishes the AI Financial Advisor, voice input, and subscription management features to justify the Pro paywall. The phase is primarily verification + incremental improvement, not greenfield work. Most infrastructure already exists (subscription detection, brand matching, recurring pattern detection, category learning). The critical blocker is **5 compile errors in `chat_screen.dart`** from missing l10n keys that were never added to the ARB files -- these must be fixed first.

The `flutter_local_notifications` package (v17.2.x) supports one-shot future scheduling via `zonedSchedule` without `matchDateTimeComponents`, which is exactly what `BillReminderService` needs. The existing `NotificationService` wrapper just needs a `scheduleOnce` method.

**Primary recommendation:** Fix the 5 missing l10n keys in `chat_screen.dart` first (blocking compile errors), then work outward through the verification tasks (AI-01, AI-02, SUB-02, SUB-04), then the new features (SUB-03, AI-05/SUB-05, AI-06, VOICE-03, CAT-05).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **AI-01 (D-01, D-02):** Verify ChatActionMessages l10n fix from Phase 2. If not complete, wire all action confirmation messages through `context.l10n`. This is a verification + fix task, not greenfield.
- **AI-02 (D-03, D-04):** Verify `FinancialContext.currentDate` call site passes `DateTime.now()`. Likely already working -- just confirm.
- **AI-06 (D-05, D-06, D-07):** Expand transfer keyword list in both EN and AR system prompts (5-8 more Egyptian conversational transfer patterns). No code logic changes -- entirely system prompt string editing in `ai_chat_service.dart`.
- **AI-05/SUB-05 (D-08, D-09, D-10):** Elevate chat subscription suggestion from plain text to interactive card. Voice already works. Chat needs the interactive card upgrade at `chat_screen.dart` line 247.
- **VOICE-03 (D-11, D-12):** Add ~10 missing Egyptian brands to `BrandRegistry`. Verify `TransactionCard` calls `BrandRegistry.match()` and applies brand color.
- **CAT-05 (D-13, D-14, D-15, D-16):** Wire `CategorizationLearningService.suggestFromText()` to `AddRecurringScreen` (title listener + suggestion chip). Show top-2 unbudgeted categories from `budgetSuggestionsProvider` as suggestion chips in `SetBudgetScreen`. Goals have NO category concept -- CAT-05 does not apply.
- **SUB-02 (D-17, D-18):** No schema change needed. `nextDueDate` already exists. Verify date picker labeling is clear across frequency types.
- **SUB-03 (D-19, D-20, D-21):** Add `scheduleOnce(DateTime)` to `NotificationService`. Create `BillReminderService` that reads `upcomingBillsProvider` and schedules notifications 3 days before due date. Call on app startup + when bills update.
- **SUB-04 (D-22, D-23):** Verify `detectedPatternsProvider` and "Recurring Detected" insight card exist and wire through to `AddRecurringScreen(detectedPattern: pattern)`.

### Claude's Discretion
- Exact interactive subscription suggestion card design for AI chat (matching voice style but adapted for chat context)
- How many additional transfer intent phrases to add (minimum 5, maximum 10)
- Whether `BillReminderService` runs on every app resume or only on cold start
- Exact labeling for due date picker across subscription frequency types
- Whether detected pattern insight card uses navigation or bottom sheet to create the subscription

### Deferred Ideas (OUT OF SCOPE)
- **CAT-05 for Goals:** Goals have no category concept. Adding one would require schema changes. Deferred to future milestone.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AI-01 | AI replies in ONE language matching user's language | Missing l10n keys found (5 compile errors). ChatActionMessages already uses l10n injection pattern. Fix is adding missing ARB keys. |
| AI-02 | AI has current date/time awareness | VERIFIED COMPLETE: `FinancialContext.currentDate` is populated with `now` (DateTime.now()) in `chat_provider.dart` line 141. System prompts inject date string. |
| AI-05 | AI suggests creating subscriptions/bills from transaction context | `SubscriptionDetector` + `ExecutionResult.subscriptionSuggestion` pipeline exists. Gap is chat UI: plain text instead of interactive card. Voice `DraftCard._buildSubscriptionSuggestion` is the reference pattern. |
| AI-06 | AI correctly handles transfer requests between named accounts | Full pipeline exists (`CreateTransferAction`, `_executeTransfer`, `WalletMatcher`). Gap is limited transfer keywords in system prompt (4 Arabic verbs). Expand to 10+. |
| VOICE-03 | Brand icon matching accuracy improved | `BrandRegistry` has 50+ brands, `TransactionCard` accepts `brandInfo` and `_BrandIconCircle` renders it. `transaction_list_section.dart` calls `BrandRegistry.match(tx.title)`. Wiring is complete. Gap is missing brands. |
| SUB-02 | Due date field on subscriptions/bills | VERIFIED COMPLETE: `nextDueDate` column exists (non-nullable). `AddRecurringScreen` has date pickers. May need labeling clarity check. |
| SUB-03 | Notifications for upcoming bills | `NotificationService` lacks `scheduleOnce`. `upcomingBillsProvider` already computes bills due within 7 days. Need new `BillReminderService` + `scheduleOnce` method. |
| SUB-04 | Auto-detection of monthly bills from spending patterns | `detectedPatternsProvider` + `RecurringPatternDetector` already work. Insight card exists in `insight_cards_zone.dart` (Priority 4). Routes to `AppRoutes.recurringAdd` with `DetectedPattern` as extra. VERIFIED COMPLETE. |
| SUB-05 | AI and voice both suggest creating subscription for recurring-type transactions | Voice works (`DraftCard._buildSubscriptionSuggestion`). Chat needs interactive card upgrade. Same as AI-05. |
| CAT-05 | Category suggestions in budget, goal, and recurring creation flows | `CategorizationLearningService.suggestFromText()` exists. Not wired to `AddRecurringScreen` or `SetBudgetScreen`. `budgetSuggestionsProvider` available for budget screen. Goals out of scope. |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Money = INTEGER piastres. `100 EGP = 10000`. Never double. `MoneyFormatter` for display.
- 100% offline-first. No Firebase/internet for core features.
- RTL-first. Every screen validated in Arabic RTL.
- Design tokens are LAW: `context.colors`, `AppIcons.*`, `AppSizes.*`, `context.appTheme.*`.
- MasarifyDS components always. Never build layout primitives inline in screen files.
- `domain/` = pure Dart only (zero Flutter/Drift imports).
- NEVER `setState` in screens (except AnimationController and ephemeral form state).
- NEVER `Navigator.push()` -- use `context.go()` / `context.push()`.
- Every screen: `ConsumerWidget` or `ConsumerStatefulWidget`.
- Import ordering: `../../` before `../`.
- All user-facing strings via `context.l10n.*`. New keys in BOTH `app_en.arb` AND `app_ar.arb`.
- `dart format` on every `.dart` file after Edit/Write.
- `flutter analyze lib/` must be zero issues.

## Standard Stack

### Core (Already Installed)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_local_notifications | ^17.2.3 (resolved 17.2.4) | Local push notifications | Only Flutter notification plugin with `zonedSchedule` for one-shot future scheduling |
| flutter_riverpod | ^2.6.1 | State management | Project standard; all providers follow StreamProvider/FutureProvider pattern |
| go_router | ^14.3.0 | Navigation | Project standard; `context.push()` / `context.pop()` |
| timezone | ^0.9.4 | TZ-aware scheduling | Required by flutter_local_notifications for `zonedSchedule` |

### Supporting (Already Installed)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| shared_preferences | ^2.3.2 | Persist bill reminder preference | `PreferencesService.notifyBillReminder` already exists |
| connectivity_plus | ^7.0.0 | Online/offline detection | AI features graceful degradation |

### Alternatives Considered
None -- all libraries are already installed and established in the project. No new dependencies needed.

## Architecture Patterns

### Recommended Project Structure
No new files/directories beyond:
```
lib/
├── core/services/
│   ├── bill_reminder_service.dart       # NEW: schedules bill notifications
│   └── notification_service.dart        # MODIFY: add scheduleOnce()
├── core/services/ai/
│   └── ai_chat_service.dart             # MODIFY: expand transfer keywords
├── core/constants/
│   └── brand_registry.dart              # MODIFY: add ~10 Egyptian brands
├── features/ai_chat/presentation/
│   ├── screens/chat_screen.dart         # MODIFY: interactive subscription card
│   └── widgets/subscription_suggest_card.dart  # NEW: extracted widget
├── features/recurring/presentation/
│   └── screens/add_recurring_screen.dart # MODIFY: title→category suggestion
├── features/budgets/presentation/
│   └── screens/set_budget_screen.dart   # MODIFY: budget suggestion chips
└── l10n/
    ├── app_en.arb                        # MODIFY: add missing keys
    └── app_ar.arb                        # MODIFY: add missing keys
```

### Pattern 1: One-Shot Notification Scheduling
**What:** `zonedSchedule` without `matchDateTimeComponents` fires once at the specified time.
**When to use:** Bill reminders scheduled 3 days before due date.
**Example:**
```dart
// Source: Context7 /maikub/flutter_local_notifications — verified HIGH confidence
await _plugin.zonedSchedule(
  id,           // int: rule.id + 100_000
  title,        // String
  body,         // String
  scheduledDate, // tz.TZDateTime: due date minus 3 days
  notificationDetails,
  androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
  // NO matchDateTimeComponents → fires once, not repeating
  payload: payload,
);
```
**Confidence:** HIGH -- Context7 example confirms omitting `matchDateTimeComponents` produces a one-shot notification.

### Pattern 2: Interactive Card in Chat Messages
**What:** Instead of appending plain text for subscription suggestions, render a widget card with Confirm/Dismiss buttons.
**When to use:** After `ExecutionResult.subscriptionSuggestion` is non-null in chat action execution.
**Reference pattern:** `DraftCard._buildSubscriptionSuggestion` in voice flow (lines 578-634):
```dart
// Source: lib/features/voice_input/presentation/widgets/draft_card.dart
Widget _buildSubscriptionSuggestion(BuildContext context) {
  return GlassCard(
    tier: GlassTier.inset,
    tintColor: context.appTheme.transferColor.withValues(alpha: AppSizes.opacityXLight),
    child: Row(
      children: [
        Icon(AppIcons.recurring, color: context.appTheme.transferColor),
        Expanded(child: Text(context.l10n.voice_confirm_subscription_suggest)),
        TextButton(onPressed: onDismiss, child: Text(context.l10n.common_dismiss)),
        FilledButton(onPressed: onAccept, child: Text(context.l10n.common_save)),
      ],
    ),
  );
}
```
**Chat adaptation:** Instead of appending text to `followUpContent`, insert a separate message with metadata that the message bubble renderer recognizes as a subscription suggestion card. Or: render the card inline in the `_onConfirmAction` flow as a transient widget below the success message.

### Pattern 3: Category Suggestion from Title Input
**What:** Listen to `_titleController` text changes, debounce, call `suggestFromText()`, show inline chip.
**When to use:** `AddRecurringScreen` title field -- most valuable touchpoint because subscription titles are unique/learnable.
**Example:**
```dart
// Debounced listener on _titleController
_titleController.addListener(_onTitleChanged);

Future<void> _onTitleChanged() async {
  final text = _titleController.text.trim();
  if (text.length < 3 || _categoryId != null) return; // already selected
  final cats = ref.read(categoriesProvider).valueOrNull ?? [];
  final compatible = cats.where((c) => c.type == _type || c.type == 'both').toList();
  final suggestion = await ref.read(categorizationLearningServiceProvider).suggestFromText(text, compatible);
  if (mounted && suggestion != null && _categoryId == null) {
    setState(() => _suggestedCategory = suggestion);
  }
}
```

### Anti-Patterns to Avoid
- **Hardcoded strings in action messages:** All user-facing strings must go through `context.l10n`. The missing l10n keys in `chat_screen.dart` are a direct violation.
- **setState for provider data:** Category suggestions should flow through the existing provider chain, not raw setState. However, ephemeral suggestion state (shown/dismissed) is acceptable as setState per CLAUDE.md.
- **Blocking notifications on main thread:** `BillReminderService` scheduling should be fire-and-forget on app startup, not awaited in the widget tree.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| One-shot future notifications | Custom AlarmManager integration | `zonedSchedule` without `matchDateTimeComponents` | Handles timezone, boot persistence, battery optimization |
| Category matching from text | Custom string matching | `CategorizationLearningService.suggestFromText()` | Already has learned patterns + keyword fallback |
| Subscription detection | Custom keyword lists | `SubscriptionDetector.isSubscriptionLike()` | Already handles category-based + keyword-based detection |
| Brand matching | Custom search | `BrandRegistry.match()` | 50+ brands with Arabic keywords, specificity ordering |
| Recurring pattern detection | Custom analysis | `RecurringPatternDetector.detect()` | Groups by (categoryId, amount), detects frequency, confidence scoring |
| Budget suggestions | Custom spending analysis | `budgetSuggestionsProvider` | Already computes top unbudgeted categories with monthly averages |

**Key insight:** This phase is about wiring existing infrastructure to more touch points, not building new analytical engines.

## Critical Finding: 5 Compile Errors in chat_screen.dart

**Confidence:** HIGH (verified via `flutter analyze`)

`lib/features/ai_chat/presentation/screens/chat_screen.dart` has 5 `undefined_getter`/`undefined_method` errors:

| Line | Missing Key | Type | Fix |
|------|------------|------|-----|
| 69 | `l10n.recap_prime_message` | getter | Add to `app_en.arb` + `app_ar.arb` |
| 224 | `l10n.chat_action_wallet_not_found` | getter (parameterized: `String name`) | Add to both ARB files |
| 225 | `l10n.chat_action_transfer_same_wallet` | getter (simple string) | Add to both ARB files |
| 232 | `l10n.chat_action_transfer_created` | getter (parameterized: `String amount, String from, String to`) | Add to both ARB files |
| 250 | `l10n.chat_subscription_suggest` | method (parameterized: `String title`) | Add to both ARB files |

**Impact:** These prevent the app from compiling successfully with this screen. This MUST be the first task in Phase 4.

**Root cause:** Phase 2 added the `ChatActionMessages` class with transfer-related fields and the subscription suggestion text, but never added the corresponding ARB keys.

## AI-02 Verification: ALREADY COMPLETE

**Confidence:** HIGH (verified by reading source code)

In `lib/shared/providers/chat_provider.dart` line 141:
```dart
return FinancialContext(
    ...
    currentDate: now,  // `now` is DateTime.now() from line ~70
    ...
);
```

The system prompt in `ai_chat_service.dart` lines 106-128 properly formats `ctx.currentDate` into `CURRENT DATE & TIME: 2026-03-27 14:30 (Thursday)` with day names in both EN and AR.

**However:** Line 277 in the Arabic prompt uses `DateTime.now()` directly instead of `ctx.currentDate` for budget month/year:
```dart
'create_budget: {"action":"create_budget","category":"Food","limit":3000,"month":${DateTime.now().month},"year":${DateTime.now().year}}\n'
```
This should be `${now.month}` and `${now.year}` for consistency (the EN version on line 201 correctly uses `${now.month}` and `${now.year}` which reference `ctx.currentDate`). This is a minor bug.

## SUB-04 Verification: ALREADY COMPLETE

**Confidence:** HIGH (verified by reading source code)

In `insight_cards_zone.dart` lines 114-133:
- `detectedPatternsProvider` is watched (line 115)
- Takes first detected pattern (line 116)
- Routes to `AppRoutes.recurringAdd` with `extra: p` (the `DetectedPattern` object) (lines 129-130)

In `app_router.dart` lines 270-277:
```dart
GoRoute(
  path: AppRoutes.recurringAdd,
  pageBuilder: (_, state) => _slideUpPage(
    state: state,
    child: AddRecurringScreen(detectedPattern: state.extra as DetectedPattern?),
  ),
),
```

The `AddRecurringScreen._prefillFromPattern` (lines 87-111) correctly pre-fills title, amount, frequency, type, startDate, and categoryId. Full pipeline verified.

## VOICE-03: BrandRegistry.match() Wiring Verification

**Confidence:** HIGH (verified by reading source code)

In `transaction_list_section.dart` line 117:
```dart
brandInfo: tx.type == 'transfer' ? null : BrandRegistry.match(tx.title),
```

`TransactionCard` accepts `brandInfo` (line 33 of `transaction_card.dart`) and renders `_BrandIconCircle` when non-null (line 179-180). The wiring is complete.

**Missing brands to add** (based on CONTEXT.md D-11 + Egyptian market research):
1. Anghami (music streaming, popular in Egypt)
2. Disney+ (launched in MENA region)
3. Paymob (payment gateway, merchant payments)
4. OSN+ (streaming, formerly Orbit Showtime)
5. Webook (event ticketing)
6. El-Ezaby Pharmacy (pharmacy chain)
7. Seoudi Market (grocery chain)
8. Rabbit (scooter rental, Cairo)
9. Wasla (public transport app)
10. Appetito (food delivery)

## SUB-03: NotificationService.scheduleOnce Implementation

**Confidence:** HIGH (Context7 verified)

The existing `scheduleDaily` uses `zonedSchedule` with `matchDateTimeComponents: DateTimeComponents.time` for daily repeat. A `scheduleOnce` method simply omits `matchDateTimeComponents`:

```dart
static Future<void> scheduleOnce({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
  String? payload,
}) async {
  final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);

  await _plugin.zonedSchedule(
    id,
    title,
    body,
    tzDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'masarify_bills',
        'Bill Reminders',
        channelDescription: 'Upcoming bill and subscription reminders',
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    payload: payload,
  );
}
```

**BillReminderService design:**
- Reads `upcomingBillsProvider` (bills due within 7 days)
- For each bill: schedule notification at `nextDueDate - 3 days`
- Use notification ID: `rule.id + 100_000` (existing convention from `NotificationService` comments)
- Check `PreferencesService.notifyBillReminder` before scheduling (preference already exists, defaults to `true`)
- Cancel stale reminders on each refresh (cancel old IDs before scheduling new ones)
- Call on app startup in `main.dart` and reactively when `upcomingBillsProvider` updates

**Recommendation for discretion (cold start vs. every resume):** Cold start only. Bill data changes infrequently and `upcomingBillsProvider` is 7-day window. Re-scheduling on every resume would be redundant. If a user creates a new subscription, the reactive update from the provider will handle it.

## AI-06: Transfer Keywords Expansion

**Confidence:** HIGH (reading existing prompts)

Current transfer detection keywords:
- **EN prompt (line 207):** "حولت, سديت, نقلت, transferred" (3 Arabic + 1 English, mixed in the English prompt)
- **AR prompt (line 283):** "حولت, سديت, نقلت, transferred" (same 4)

**Recommended additions (Egyptian colloquial Arabic + English patterns):**

Arabic additions:
1. "دفعت على" (paid on / paid towards -- used for settling debts between accounts)
2. "حولت من...لـ" / "حولت من...على" (transferred from...to)
3. "سددت" (settled/paid off -- stronger form of سديت)
4. "نقلت فلوس" (moved money)
5. "وديت فلوس" (took money to -- colloquial Cairo)
6. "بعت فلوس" (sent money -- used for mobile wallet transfers)

English additions:
7. "moved money from...to"
8. "paid...from...to settle"
9. "settle" / "pay off" (debt-settlement language)
10. "top up" / "topped up" (mobile wallet recharge)

**Implementation:** Pure string edits in `_buildSystemPrompt` (EN) and `_buildArabicPrompt` (AR). Add to the `TRANSFER DETECTION` / `كشف التحويلات` paragraphs.

## AI-05/SUB-05: Interactive Subscription Card Design

**Confidence:** MEDIUM (design decision -- discretion area)

**Current behavior (chat_screen.dart line 247-250):**
```dart
if (result.subscriptionSuggestion != null) {
  followUpContent += '\n\n${l10n.chat_subscription_suggest(result.subscriptionSuggestion!.title)}';
}
```
This appends plain text to the assistant's follow-up message. The text itself (`chat_subscription_suggest`) doesn't even exist as a l10n key.

**Recommended approach:**
1. Do NOT embed subscription suggestion as text in the message content.
2. Instead, after successful action execution, insert a separate "system" message with a special content marker (e.g., `[SUBSCRIPTION_SUGGEST:title:categoryName]`).
3. In the message bubble renderer, detect this marker and render the interactive card widget.
4. **Simpler alternative:** Store the `SubscriptionSuggestion` in widget state and render it as a transient card below the last message, similar to how action confirmation cards work. This avoids polluting the message history with UI artifacts.

**Reference pattern from voice (`DraftCard._buildSubscriptionSuggestion`):**
- `GlassCard` with `GlassTier.inset`
- Transfer-color tint
- `AppIcons.recurring` icon
- l10n text + Dismiss (TextButton) + Save (FilledButton)
- On Save: navigate to `AppRoutes.recurringAdd` with pre-filled data

**Chat adaptation considerations:**
- Chat doesn't have the full `EditableDraft` context. It has `SubscriptionSuggestion(title, categoryName)`.
- On "Save", navigate to `AddRecurringScreen` with no `DetectedPattern` but with the title pre-filled via a new optional parameter or query parameters.
- On "Dismiss", remove the card from state.

## CAT-05: Category Suggestions in Budget and Recurring Screens

### AddRecurringScreen (D-14)
**What to add:** `_titleController.addListener` that debounces and calls `suggestFromText()`. Show a suggestion chip above the category picker when a match is found and no category is manually selected.

**Key consideration:** The `_titleController` already exists. The screen already imports `CategoryEntity` and watches `categoriesProvider`. Adding the listener is straightforward. The `CategorizationLearningService` is available via `categorizationLearningServiceProvider`.

**Debounce:** Use a simple `_debounceTimer` (Timer) to avoid calling on every keystroke. 500ms debounce is appropriate.

### SetBudgetScreen (D-15)
**What to add:** Show top-2 unbudgeted categories from `budgetSuggestionsProvider` as suggestion chips above the manual category picker.

**Key consideration:** `SetBudgetScreen` does NOT have a text input for category. It uses a modal bottom sheet picker. The suggestions should appear as tappable chips at the top of the form, before the "Select Category" button. Tapping a suggestion chip sets `_categoryId` directly.

**`budgetSuggestionsProvider`** (in `background_ai_provider.dart`) already computes `BudgetSuggestion` objects with `categoryId` and `monthlyAvg`. This is ready to use.

## Common Pitfalls

### Pitfall 1: Missing l10n Keys Cause Silent Failures
**What goes wrong:** Code references `l10n.someKey` that doesn't exist in ARB files. Flutter gen-l10n doesn't generate the getter. Compile error.
**Why it happens:** l10n keys added in code but forgotten in ARB files (happened in Phase 2 for transfer actions).
**How to avoid:** After adding ANY `l10n.*` reference in Dart code, immediately add the key to BOTH `app_en.arb` AND `app_ar.arb`. Run `flutter gen-l10n` to verify.
**Warning signs:** `flutter analyze` reports `undefined_getter` on `AppLocalizations`.

### Pitfall 2: Notification ID Collisions
**What goes wrong:** Two different notification sources use the same ID, causing one to silently overwrite the other.
**Why it happens:** No centralized ID allocation scheme.
**How to avoid:** Follow existing convention: bill reminders use `rule.id + 100_000`. Daily recap uses `99999`. Keep new IDs in the 100_000+ range keyed to rule IDs.
**Warning signs:** Notifications stop appearing or show wrong content.

### Pitfall 3: zonedSchedule Scheduling in the Past
**What goes wrong:** Scheduling a notification for a date that has already passed. On Android, the notification fires immediately (unexpected). On iOS, it may be silently dropped.
**Why it happens:** `nextDueDate - 3 days` may already be in the past if the user opens the app after the reminder window.
**How to avoid:** Always check `scheduledDate.isAfter(DateTime.now())` before calling `scheduleOnce`. Skip scheduling for past dates.
**Warning signs:** Notifications firing immediately on app open.

### Pitfall 4: Async Gap in Widget State
**What goes wrong:** `await suggestFromText()` returns after widget is disposed. Calling `setState` crashes.
**Why it happens:** User navigates away while async category lookup is in progress.
**How to avoid:** Always check `if (!mounted) return;` after every await in `ConsumerStatefulWidget` methods.
**Warning signs:** "setState() called after dispose()" errors in console.

### Pitfall 5: Arabic Prompt Hardcoded DateTime.now()
**What goes wrong:** The Arabic system prompt (line 277 of `ai_chat_service.dart`) uses `DateTime.now()` directly for budget month/year in the JSON example, bypassing the `ctx.currentDate` injection.
**Why it happens:** Copy-paste inconsistency between EN and AR prompt builders.
**How to avoid:** Use `now.month` and `now.year` (from `ctx.currentDate`) consistently in both prompts.
**Warning signs:** Budget JSON examples in AR prompt show stale month/year if `ctx.currentDate` were ever mocked for testing.

## Code Examples

### scheduleOnce for BillReminderService
```dart
// Source: Verified against Context7 /maikub/flutter_local_notifications + existing scheduleDaily pattern
static Future<void> scheduleOnce({
  required int id,
  required String title,
  required String body,
  required DateTime scheduledDate,
  String? payload,
}) async {
  final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
  // Guard: don't schedule in the past
  if (tzDate.isBefore(tz.TZDateTime.now(tz.local))) return;

  await _plugin.zonedSchedule(
    id,
    title,
    body,
    tzDate,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'masarify_bills',
        'Bill Reminders',
        channelDescription: 'Upcoming bill and subscription reminders',
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    // No matchDateTimeComponents → one-shot, not repeating
    payload: payload,
  );
}
```

### BillReminderService Skeleton
```dart
// Source: project pattern from NotificationService + upcomingBillsProvider
class BillReminderService {
  static const _reminderDaysBeforeDue = 3;

  static Future<void> scheduleReminders({
    required List<RecurringRuleEntity> upcomingBills,
    required bool enabled,
  }) async {
    if (!enabled) return;

    for (final bill in upcomingBills) {
      final reminderDate = bill.nextDueDate.subtract(
        const Duration(days: _reminderDaysBeforeDue),
      );
      final notifId = bill.id + 100000; // Existing convention

      // Cancel any existing reminder for this bill before re-scheduling
      await NotificationService.cancelScheduled(notifId);

      await NotificationService.scheduleOnce(
        id: notifId,
        title: bill.title,
        body: 'Due in $_reminderDaysBeforeDue days',  // Use l10n in real impl
        scheduledDate: reminderDate,
        payload: 'bill_${bill.id}',
      );
    }
  }
}
```

### Interactive Subscription Card for Chat (adapted from voice)
```dart
// Source: adapted from DraftCard._buildSubscriptionSuggestion
Widget _buildChatSubscriptionCard(BuildContext context, SubscriptionSuggestion suggestion) {
  return GlassCard(
    tier: GlassTier.inset,
    tintColor: context.appTheme.transferColor.withValues(alpha: AppSizes.opacityXLight),
    padding: const EdgeInsetsDirectional.symmetric(
      horizontal: AppSizes.md, vertical: AppSizes.sm,
    ),
    child: Row(
      children: [
        Icon(AppIcons.recurring, size: AppSizes.iconSm, color: context.appTheme.transferColor),
        const SizedBox(width: AppSizes.sm),
        Expanded(child: Text(context.l10n.voice_confirm_subscription_suggest)),
        TextButton(onPressed: () => _dismissSuggestion(), child: Text(context.l10n.common_dismiss)),
        FilledButton(
          onPressed: () => context.push(AppRoutes.recurringAdd),
          child: Text(context.l10n.common_save),
        ),
      ],
    ),
  );
}
```

### Category Suggestion Chip Pattern
```dart
// Source: project pattern, adapted for AddRecurringScreen
CategoryEntity? _suggestedCategory;
Timer? _debounceTimer;

void _onTitleChanged() {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
    final text = _titleController.text.trim();
    if (text.length < 3 || _categoryId != null) return;
    final cats = ref.read(categoriesProvider).valueOrNull ?? [];
    final compatible = cats.where((c) => c.type == _type || c.type == 'both').toList();
    final service = ref.read(categorizationLearningServiceProvider);
    final suggestion = await service.suggestFromText(text, compatible);
    if (mounted && _categoryId == null) {
      setState(() => _suggestedCategory = suggestion);
    }
  });
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `zonedSchedule` positional params | `zonedSchedule` named params (v18+) | flutter_local_notifications v18 | Project uses v17 -- positional params still work. No migration needed. |
| Bare JSON in AI responses | Fenced ```json blocks | Phase 2 (3-layer parser) | System prompt already instructs fenced JSON |
| SMS-based transaction detection | AI voice + proactive chat | Phase 4 (AI-first pivot) | SMS feature-flagged off |

**Deprecated/outdated:**
- `flutter_local_notifications` v17.2.x is current for the project, though v21.0.0 exists. The project's `pubspec.yaml` pins `^17.2.3`. The positional `zonedSchedule` API works fine at this version. No need to upgrade.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (built-in) |
| Config file | None (Flutter default) |
| Quick run command | `flutter test test/unit/` |
| Full suite command | `flutter test` |

### Phase Requirements to Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AI-01 | All ChatActionMessages l10n keys exist and resolve | unit | `flutter test test/unit/chat_action_messages_l10n_test.dart -x` | Wave 0 |
| AI-02 | FinancialContext.currentDate populated correctly | unit | `flutter test test/unit/financial_context_test.dart -x` | Wave 0 |
| AI-06 | Transfer keywords present in EN and AR prompts | unit | `flutter test test/unit/transfer_keywords_test.dart -x` | Wave 0 |
| VOICE-03 | BrandRegistry.match() finds new Egyptian brands | unit | `flutter test test/unit/brand_registry_test.dart -x` | Wave 0 |
| SUB-03 | BillReminderService schedules correct dates | unit | `flutter test test/unit/bill_reminder_service_test.dart -x` | Wave 0 |
| SUB-04 | DetectedPattern insight card routes correctly | manual-only | Visual verification | N/A |
| AI-05/SUB-05 | Subscription suggestion card renders in chat | manual-only | Visual verification | N/A |
| CAT-05 | Category suggestion triggers from title input | unit | `flutter test test/unit/category_suggestion_test.dart -x` | Existing: subscription_detector_test.dart covers detector |
| SUB-02 | Due date picker present and labeled | manual-only | Visual verification | N/A |

### Sampling Rate
- **Per task commit:** `flutter test test/unit/`
- **Per wave merge:** `flutter test && flutter analyze lib/`
- **Phase gate:** Full suite green + `flutter analyze lib/` zero issues before `/gsd:verify-work`

### Wave 0 Gaps
- [ ] `test/unit/brand_registry_test.dart` -- covers VOICE-03 (new brands match correctly)
- [ ] `test/unit/bill_reminder_service_test.dart` -- covers SUB-03 (scheduling logic, past-date guard)
- [ ] Missing l10n keys must be added before any test that imports `chat_screen.dart` can compile

*(Existing `test/unit/subscription_detector_test.dart` covers the detection logic used by AI-05/SUB-05)*

## Open Questions

1. **flutter_local_notifications v17 zonedSchedule exact parameter syntax**
   - What we know: Context7 shows named params (`id:`, `title:`, etc.) but existing code uses positional params successfully.
   - What's unclear: The v17 API may use positional params while v18+ switched to named. Need to match the existing `scheduleDaily` pattern (positional) for consistency.
   - Recommendation: Copy the exact parameter pattern from the existing `scheduleDaily` method (lines 116-134 of `notification_service.dart`) and simply omit `matchDateTimeComponents`.

2. **Chat subscription card: transient widget vs. persisted message**
   - What we know: Voice uses a widget embedded in the draft card. Chat persists messages to DB.
   - What's unclear: Should the subscription suggestion be persisted as a special message type, or shown as a transient widget that disappears on dismiss/accept?
   - Recommendation: Transient widget stored in `_ChatScreenState` -- simpler, no DB schema changes, and suggestions lose relevance after the session anyway.

## Environment Availability

Step 2.6: SKIPPED (no external dependencies identified). All tools and libraries are already installed in the project. Phase is code/config-only changes.

## Sources

### Primary (HIGH confidence)
- Context7 `/maikub/flutter_local_notifications` -- `zonedSchedule` API, one-shot vs. repeating distinction
- Codebase analysis -- all file readings verified against actual source code
- `flutter analyze lib/features/ai_chat/presentation/screens/chat_screen.dart` -- 5 compile errors confirmed

### Secondary (MEDIUM confidence)
- Egyptian brand market knowledge for VOICE-03 brand additions -- based on general knowledge of Egyptian fintech/retail ecosystem

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all libraries already installed and verified
- Architecture: HIGH -- all patterns derived from existing codebase, verified by reading source
- Pitfalls: HIGH -- compile errors confirmed via flutter analyze, notification scheduling verified via Context7
- Brand additions: MEDIUM -- based on general Egyptian market knowledge, not formal research

**Research date:** 2026-03-27
**Valid until:** 2026-04-27 (stable phase -- no moving targets)
