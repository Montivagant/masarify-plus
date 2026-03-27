---
phase: 2
plan: 2
title: "AI & Voice Fixes"
wave: 1
depends_on: []
requirements: [AI-01, AI-03, AI-04, VOICE-01, VOICE-02, VOICE-04]
bugs: [D-04, D-05, D-06, D-08, D-09, D-11, D-12]
files_modified:
  - lib/core/services/ai/chat_response_parser.dart
  - lib/core/services/ai/chat_action_messages.dart
  - lib/features/ai_chat/presentation/screens/chat_screen.dart
  - lib/features/ai_chat/presentation/widgets/message_bubble.dart
  - lib/features/voice_input/presentation/screens/voice_confirm_screen.dart
  - lib/core/utils/wallet_resolver.dart
  - lib/core/utils/wallet_matcher.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_ar.arb
autonomous: true
---

# Plan 2-2: AI & Voice Fixes

**Goal:** Fix AI JSON leaking (D-08/AI-03), AI English in Arabic sessions (D-09), verify markdown rendering (AI-04), fix voice subscription creation to on-tap (D-04/D-05/D-11), fix voice transfer suggesting both missing accounts (D-06/VOICE-02), verify Cash wallet resolution (VOICE-01), and add missing amount prompt (D-12).

---

## Task 1: Fix AI JSON Leaking — Final Safety Net (D-08, AI-03)

**Problem:** Despite the 3-layer parser (`_fencedJsonRegex`, `_bareJsonRegex`, `_extractBalancedJson`), raw JSON still leaks in edge cases: JSON split across chunks, JSON inside markdown code blocks the parser misses, or malformed responses that match none of the 3 patterns. Add a final safety-net strip.

<read_first>
- lib/core/services/ai/chat_response_parser.dart (full file — understand 3-layer parser)
- lib/features/ai_chat/presentation/widgets/message_bubble.dart (where text is rendered)
</read_first>

<action>
1. In `lib/core/services/ai/chat_response_parser.dart`, add a final safety-net method that strips any remaining JSON-like fragments from the text content. Add this static method after `_extractBalancedJson`:

   ```dart
   /// Final safety net: strip any remaining action-JSON fragments that
   /// slipped past the 3-layer parser (e.g., split across stream chunks,
   /// nested in unrecognized markdown, or malformed responses).
   static String _sanitizeRemainingJson(String text) {
     // Strip any bare {...} block containing "action" key.
     var cleaned = text.replaceAll(
       RegExp(r'\{[^{}]*"action"\s*:\s*"[^"]*"[^{}]*\}'),
       '',
     );
     // Strip residual JSON key-value pairs only when they appear near
     // other JSON structure indicators (open brace within 200 chars).
     // This avoids corrupting normal prose that happens to contain
     // words like "title" or "type".
     cleaned = cleaned.replaceAll(
       RegExp(r'(?<=\{[^}]{0,200})"(?:action|type|data|amount|title|category|wallet)":\s*"?[^",}\n]*"?,?\s*'),
       '',
     );
     // Clean up leftover braces and whitespace.
     cleaned = cleaned
         .replaceAll(RegExp(r'[{}]'), '')
         .replaceAll(RegExp(r'\n{3,}'), '\n\n')
         .trim();
     return cleaned.isEmpty ? text : cleaned;
   }
   ```

2. Modify the `parse()` method in the same file. After the existing logic, add a final check before returning any `ParsedChatResponse` whose `textContent` still contains JSON indicators. Wrap the return in the `_sanitizeRemainingJson` pass. Update the method to apply sanitization:

   At the end of the `parse()` method, just before each `return` that includes `textContent`, apply the safety net. The cleanest approach is to add a single wrapper at the end of the method:

   Replace the entire `parse()` method's final structure so that just before the method returns, it runs:
   ```dart
   // Before returning, apply safety-net sanitization.
   final sanitized = _maybeSanitize(result.textContent);
   return ParsedChatResponse(textContent: sanitized, action: result.action);
   ```

   Add the helper:
   ```dart
   /// Apply safety-net only if text still contains JSON indicators.
   static String _maybeSanitize(String text) {
     if (text.contains('"action"') || text.contains('"type":')) {
       return _sanitizeRemainingJson(text);
     }
     return text;
   }
   ```

3. To implement cleanly: refactor `parse()` to capture the result in a local variable before returning, then apply sanitization:
   - Add a local `ParsedChatResponse result;` at the top
   - Assign to `result` instead of returning directly
   - At the end: `return ParsedChatResponse(textContent: _maybeSanitize(result.textContent), action: result.action);`
</action>

<acceptance_criteria>
- grep "_sanitizeRemainingJson" lib/core/services/ai/chat_response_parser.dart confirms safety net exists
- grep "_maybeSanitize" lib/core/services/ai/chat_response_parser.dart confirms it is called
- grep '"action"' lib/core/services/ai/chat_response_parser.dart shows the detection pattern
- Unit test: sanitizer does NOT corrupt valid prose containing words like "title" or "type" (e.g., `"The title of this category is Food"` must pass through unchanged)
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 2: Fix AI English Confirmations in Arabic Sessions (D-09)

**Problem:** AI chatbot sends English confirmation messages when user's locale is Arabic. The `ChatActionMessages` class is already wired to `context.l10n` in `chat_screen.dart` (lines 216-234), and both English and Arabic l10n keys exist for all `chat_action_*` strings. The bug is likely that `l10n` is resolved from a context that does not have the correct locale, OR the `ChatActionExecutor` has hardcoded English fallback strings.

<read_first>
- lib/features/ai_chat/presentation/screens/chat_screen.dart (lines 180-260 — where l10n and ChatActionMessages are resolved)
- lib/core/services/ai/chat_action_messages.dart (full file — check for hardcoded strings)
- lib/core/services/ai/chat_action_executor.dart (check for hardcoded English fallback strings)
</read_first>

<action>
1. Read `lib/core/services/ai/chat_action_executor.dart` — search for any hardcoded English strings like `"Transaction"`, `"recorded"`, `"created"`, `"Budget"`, `"Account"`, `"Transfer"`. If found, replace with the appropriate `messages.*` field.

2. In `lib/features/ai_chat/presentation/screens/chat_screen.dart`, verify that `l10n` is resolved from `context.l10n` (which respects the app locale), NOT from a raw `Localizations.of<AppLocalizations>(context)` that might default to English.

3. Check for any `BuildContext` scope issues: if the `l10n` is captured in a callback that runs after the context is no longer valid, it would fall back to the default locale. Verify the `l10n` is captured before any async gap:
   ```dart
   final l10n = context.l10n; // Must be captured BEFORE await
   ```

4. Read `lib/core/services/ai/chat_action_executor.dart` — look for the `execute()` method's return value. If it returns strings not from `messages`, those are the hardcoded English strings causing D-09. Replace all hardcoded strings with the corresponding `messages.*` field.

5. If `ChatActionExecutor.execute()` has any string interpolation like:
   ```dart
   return "Transaction '$title' of $amount recorded!";
   ```
   Replace with:
   ```dart
   return messages.txRecorded(title, formattedAmount);
   ```
</action>

<acceptance_criteria>
- grep -c "Transaction\|recorded\|created\|Budget\|Account" lib/core/services/ai/chat_action_executor.dart returns 0 (no hardcoded English strings)
- grep "messages\." lib/core/services/ai/chat_action_executor.dart shows all strings come from messages parameter
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 3: Verify AI Markdown Rendering (AI-04)

**Problem:** AI messages should render via `flutter_markdown` — no raw asterisks or hashtags visible to the user.

<read_first>
- lib/features/ai_chat/presentation/widgets/message_bubble.dart (full file — find MarkdownBody usage)
- pubspec.yaml (confirm flutter_markdown dependency)
</read_first>

<action>
1. Read `lib/features/ai_chat/presentation/widgets/message_bubble.dart` — verify assistant messages use `MarkdownBody` widget:
   ```dart
   MarkdownBody(
     data: message.content,
     styleSheet: MarkdownStyleSheet(...)
   )
   ```
   If they use plain `Text()` instead, replace with `MarkdownBody`.

2. Verify `pubspec.yaml` includes `flutter_markdown` as a dependency.

3. Verify the `MarkdownStyleSheet` uses design tokens:
   - `p` style should use `context.textStyles.bodyMedium`
   - `h1`/`h2` should use `context.textStyles.titleMedium`/`titleSmall`
   - Link color should use `context.colors.primary`

4. If markdown is already working, verify there are no edge cases where raw markdown leaks (e.g., the `textContent` from the parser still containing `**bold**` that renders as asterisks). This would indicate `MarkdownBody` is not being used for that code path.

5. No code changes expected if already implemented. Document verification.
</action>

<acceptance_criteria>
- grep "MarkdownBody" lib/features/ai_chat/presentation/widgets/message_bubble.dart confirms markdown widget usage
- grep "flutter_markdown" pubspec.yaml confirms dependency
</acceptance_criteria>

---

## Task 4: Fix Voice Subscription Creation — On-Tap with "Added" State (D-04, D-05, D-11, VOICE-04)

**Problem:** The "Add to Subscriptions & Bills?" button on VoiceConfirmScreen navigates to the AddRecurringScreen instead of creating the record on-tap. It should: (1) create the recurring record directly on single tap, (2) update the button to show "Added" with a checkmark, (3) not navigate away.

<read_first>
- lib/features/voice_input/presentation/screens/voice_confirm_screen.dart (lines 315-333 — onAddAsRecurring callback, lines 1255-1269 — subscription suggestion UI)
- lib/domain/repositories/i_recurring_rule_repository.dart (create method signature)
- lib/shared/providers/repository_providers.dart (recurringRuleRepositoryProvider)
</read_first>

<action>
1. In `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart`, add a new field to `_EditableDraft`:
   ```dart
   bool recurringAdded = false;
   ```

2. Replace the `onAddAsRecurring` callback (lines 315-333) to create the record directly instead of navigating:
   ```dart
   onAddAsRecurring: draft.showRecurringSuggestion && !draft.recurringAdded
       ? () async {
           try {
             final repo = ref.read(recurringRuleRepositoryProvider);
             await repo.create(
               walletId: draft.walletId!,
               categoryId: draft.categoryId!,
               amount: draft.amountPiastres,
               type: draft.type,
               title: draft.titleController.text.trim().isNotEmpty
                   ? draft.titleController.text.trim()
                   : draft.rawText,
               frequency: 'monthly',
               startDate: draft.transactionDate,
               nextDueDate: draft.transactionDate.add(const Duration(days: 30)),
             );
             if (mounted) {
               setState(() => draft.recurringAdded = true);
             }
           } catch (_) {
             if (mounted) {
               SnackHelper.showError(context, context.l10n.common_error_generic);
             }
           }
         }
       : null,
   ```

3. Add `recurringRuleRepositoryProvider` import at the top of the file:
   ```dart
   import '../../../../shared/providers/repository_providers.dart';
   ```
   (Verify this import already exists — it likely does since the file already uses `ref.read(transactionRepositoryProvider)`.)

4. Update the `_DraftCard` to accept and display the "added" state. Add a new parameter:
   ```dart
   final bool recurringAdded;
   ```

5. Update the subscription suggestion UI (around line 1256-1269) to show "Added" state:
   ```dart
   if (onAddAsRecurring != null || recurringAdded)
     Padding(
       padding: const EdgeInsets.only(top: AppSizes.sm),
       child: recurringAdded
           ? Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Icon(AppIcons.checkCircle, size: AppSizes.iconXs, color: context.appTheme.incomeColor),
                 const SizedBox(width: AppSizes.xs),
                 Text(
                   context.l10n.voice_recurring_added,
                   style: context.textStyles.bodySmall?.copyWith(
                     color: context.appTheme.incomeColor,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
               ],
             )
           : TextButton.icon(
               onPressed: onAddAsRecurring,
               icon: const Icon(AppIcons.recurring, size: AppSizes.iconXs),
               label: Text(context.l10n.voice_add_as_recurring),
               style: TextButton.styleFrom(
                 padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
                 visualDensity: VisualDensity.compact,
               ),
             ),
     ),
   ```

6. Pass `recurringAdded: draft.recurringAdded` when constructing `_DraftCard`.

7. Add l10n key to both ARB files:
   - `lib/l10n/app_en.arb`: `"voice_recurring_added": "Added to Subscriptions & Bills"`
   - `lib/l10n/app_ar.arb`: `"voice_recurring_added": "تمت الإضافة للاشتراكات والفواتير"`

8. Run `flutter gen-l10n` to regenerate localization files.
</action>

<acceptance_criteria>
- grep "recurringAdded" lib/features/voice_input/presentation/screens/voice_confirm_screen.dart confirms added state field
- grep "voice_recurring_added" lib/l10n/app_en.arb confirms l10n key exists
- grep "voice_recurring_added" lib/l10n/app_ar.arb confirms Arabic l10n key exists
- grep "repo.create" lib/features/voice_input/presentation/screens/voice_confirm_screen.dart confirms direct creation
- grep -v "context.push.*recurringAdd" lib/features/voice_input/presentation/screens/voice_confirm_screen.dart confirms no navigation to add screen
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 5: Fix Voice Transfer — Suggest BOTH Missing Accounts (D-06, VOICE-02)

**Problem:** When voice says "transfer from X to Y" and NEITHER account exists, only one "Create Account?" suggestion appears. Both missing accounts should be suggested simultaneously.

<read_first>
- lib/features/voice_input/presentation/screens/voice_confirm_screen.dart (lines 113-145 — transfer wallet matching, lines 761-789 — _createWalletFromHint, lines 1140-1224 — unmatched hint UI)
</read_first>

<action>
1. The current code (lines 113-145) already sets `draft.unmatchedHint` for the source wallet and `draft.unmatchedToHint` for the destination wallet. However, the UI only shows a "Create" button for `unmatchedHint` (source), not for `unmatchedToHint` (destination).

2. In `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart`, find the `unmatchedToHint` display (around line 1211-1224). Currently it shows red error text but NO creation button. Add a "Create" button:

   Replace lines 1211-1224:
   ```dart
   if (draft.unmatchedToHint != null)
     Padding(
       padding: const EdgeInsetsDirectional.only(start: AppSizes.sm),
       child: TextButton(
         onPressed: () => _createToWalletFromHint(draft),
         style: TextButton.styleFrom(
           padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
           visualDensity: VisualDensity.compact,
         ),
         child: Text(
           context.l10n.voice_create_wallet_instead(draft.unmatchedToHint!),
           style: context.textStyles.bodySmall?.copyWith(
             color: cs.primary,
           ),
         ),
       ),
     ),
   ```

3. Add a new `_createToWalletFromHint` method similar to `_createWalletFromHint` but for the destination wallet:
   ```dart
   Future<void> _createToWalletFromHint(_EditableDraft draft) async {
     final duplicateMsg = context.l10n.wallet_name_duplicate;
     final genericMsg = context.l10n.common_error_generic;
     final hintName = draft.unmatchedToHint!;
     try {
       final newId = await ref.read(walletRepositoryProvider).create(
             name: hintName,
             type: 'bank',
             initialBalance: 0,
           );
       if (mounted) {
         setState(() {
           for (final d in _editableDrafts) {
             if (d.unmatchedToHint == hintName) {
               d.toWalletId = newId;
               d.unmatchedToHint = null;
             }
           }
         });
       }
     } on ArgumentError {
       if (mounted) SnackHelper.showError(context, duplicateMsg);
     } catch (_) {
       if (mounted) SnackHelper.showError(context, genericMsg);
     }
   }
   ```

4. Pass `onCreateToWalletFromHint` callback to `_DraftCard`:
   - Add parameter: `final VoidCallback? onCreateToWalletFromHint;`
   - Pass from parent: `onCreateToWalletFromHint: draft.unmatchedToHint != null ? () => _createToWalletFromHint(draft) : null,`
</action>

<acceptance_criteria>
- grep "_createToWalletFromHint" lib/features/voice_input/presentation/screens/voice_confirm_screen.dart confirms method exists
- grep "onCreateToWalletFromHint" lib/features/voice_input/presentation/screens/voice_confirm_screen.dart confirms callback wired
- grep "unmatchedToHint" lib/features/voice_input/presentation/screens/voice_confirm_screen.dart shows both source and destination hint handling
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 6: Verify Voice Cash Wallet Resolution (VOICE-01)

**Problem:** Saying "Cash" or "كاش" should resolve to the system Cash wallet, not suggest creating a new "Cash" account.

<read_first>
- lib/core/utils/wallet_matcher.dart (isCashWalletHint method)
- lib/features/voice_input/presentation/screens/voice_confirm_screen.dart (lines 117-118, 149-150 — cash wallet resolution)
</read_first>

<action>
1. Read `lib/core/utils/wallet_matcher.dart` — verify `isCashWalletHint()` matches both English and Arabic cash keywords:
   ```dart
   static bool isCashWalletHint(String hint) {
     final lower = hint.toLowerCase().trim();
     return _cashKeywords.contains(lower);
   }
   ```
   Verify `_cashKeywords` includes: `'cash'`, `'كاش'`, `'نقد'`, `'نقدي'`, `'physical_cash'`, `'فلوس'`.

2. In `voice_confirm_screen.dart`, lines 117-118 already check:
   ```dart
   if (cashWallet != null && WalletMatcher.isCashWalletHint(draft.walletHint!)) {
     draft.walletId = cashWallet.id;
   }
   ```
   This should work. Verify `systemWalletProvider` returns the correct system Cash wallet:
   ```dart
   final cashWallet = ref.read(systemWalletProvider).valueOrNull;
   ```

3. If `isCashWalletHint` does not include common keywords, add them. Common Arabic/English cash references:
   - `'cash'`, `'Cash'`, `'CASH'`
   - `'كاش'`, `'نقد'`, `'نقدي'`, `'فلوس'`, `'كاش فلوس'`

4. Verify that the `isCashWalletHint` comparison is case-insensitive by checking it uses `.toLowerCase()`.

5. No code changes expected if keywords are comprehensive. If missing keywords are found, add them to `_cashKeywords`.
</action>

<acceptance_criteria>
- grep "isCashWalletHint" lib/core/utils/wallet_matcher.dart confirms method exists
- grep "cash\|كاش\|نقد" lib/core/utils/wallet_matcher.dart confirms Arabic+English keywords
- grep "toLowerCase" lib/core/utils/wallet_matcher.dart confirms case-insensitive
</acceptance_criteria>

---

## Task 7: Add Missing Amount Prompt in Voice Review (D-12)

**Problem:** When voice input doesn't detect an amount, the review screen should show a prominent "Amount not detected" message with the amount field highlighted and submit button disabled until amount > 0.

<read_first>
- lib/features/voice_input/presentation/screens/voice_confirm_screen.dart (lines 349-380 — submit button, lines 1271-1281 — AmountInput)
</read_first>

<action>
1. The submit button (line 358-360) already disables when `_saving || includedCount == 0`. The validation in `_confirmAll` (line 410) already checks `draft.amountPiastres <= 0` and shows an error. But D-12 asks for a PROACTIVE inline prompt, not just a validation error.

2. In `_DraftCard`, add a prominent "Amount not detected" banner above the AmountInput when `draft.amountPiastres == 0`. Add this before the AmountInput (around line 1271):
   ```dart
   // Missing amount prompt
   if (draft.amountPiastres <= 0) ...[
     const SizedBox(height: AppSizes.sm),
     Container(
       padding: const EdgeInsets.symmetric(
         horizontal: AppSizes.md,
         vertical: AppSizes.sm,
       ),
       decoration: BoxDecoration(
         color: context.appTheme.expenseColor.withValues(alpha: AppSizes.opacityLight2),
         borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
       ),
       child: Row(
         children: [
           Icon(
             AppIcons.warningCircle,
             size: AppSizes.iconXs,
             color: context.appTheme.expenseColor,
           ),
           const SizedBox(width: AppSizes.sm),
           Flexible(
             child: Text(
               context.l10n.voice_amount_missing,
               style: context.textStyles.bodySmall?.copyWith(
                 color: context.appTheme.expenseColor,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ),
         ],
       ),
     ),
   ],
   ```

3. Add l10n keys:
   - `lib/l10n/app_en.arb`: `"voice_amount_missing": "Amount not detected \u2014 please enter the amount"`
   - `lib/l10n/app_ar.arb`: `"voice_amount_missing": "لم يتم تحديد المبلغ \u2014 يرجى إدخال المبلغ"`

4. Set `autofocus: true` on the AmountInput when amount is 0 to draw attention:
   ```dart
   AmountInput(
     initialPiastres: draft.amountPiastres,
     onAmountChanged: onAmountChanged,
     autofocus: draft.amountPiastres <= 0,
     compact: true,
   ),
   ```
   Note: the `autofocus` param already exists on `AmountInput`.

5. Run `flutter gen-l10n` to regenerate localization files.
</action>

<acceptance_criteria>
- grep "voice_amount_missing" lib/l10n/app_en.arb confirms l10n key exists
- grep "voice_amount_missing" lib/l10n/app_ar.arb confirms Arabic l10n key exists
- grep "amountPiastres <= 0" lib/features/voice_input/presentation/screens/voice_confirm_screen.dart confirms zero-amount check
- grep "warningCircle\|voice_amount_missing" lib/features/voice_input/presentation/screens/voice_confirm_screen.dart confirms warning UI
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 8: Run Full Analysis and Verify

<read_first>
- (none — verification-only task)
</read_first>

<action>
1. Run `flutter gen-l10n` to regenerate localization files from updated ARB files.
2. Run `flutter analyze lib/` — must report zero issues.
3. Run `flutter test test/unit/` — ensure no regressions.
4. Verify all 5 requirements are addressed:
   - AI-03: JSON safety net added
   - AI-04: Markdown rendering verified
   - VOICE-01: Cash wallet resolution verified
   - VOICE-02: Both missing transfer accounts suggested
   - VOICE-04: On-tap subscription creation with "Added" state
5. Verify all 7 bugs are addressed:
   - D-04/D-05/D-11: Subscription creation is on-tap, no navigation
   - D-06: Both missing accounts suggested for voice transfers
   - D-08: JSON safety net strips residual fragments
   - D-09: All action messages use l10n, no hardcoded English
   - D-12: Missing amount prompt displayed
</action>

<acceptance_criteria>
- flutter analyze lib/ reports "No issues found!"
- flutter test completes with zero failures
</acceptance_criteria>
