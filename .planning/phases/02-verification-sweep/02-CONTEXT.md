# Phase 2: Verification Sweep - Context

**Gathered:** 2026-03-27 (assumptions mode + user runtime testing)
**Status:** Ready for planning

<domain>
## Phase Boundary

Verify every feature shipped in P5 Phases 2-4 actually works at runtime; fix all breakage found. Static analysis confirmed all 23 features have correct code structure — issues are runtime bugs (provider wiring, query filtering, edge cases, locale handling).

</domain>

<decisions>
## Implementation Decisions

### Transaction List Filtering (TXN-03, TXN-05)
- **D-01:** Account X is displaying Account Y's transactions. The `activityByWalletProvider(walletId)` query is returning wrong results. Debug by adding a fresh install test: create 2 accounts, add 1 transaction each, verify each account's list shows only its own transactions. Fix the query filter in the DAO or provider.
- **D-02:** The root cause is likely in how `activityByWalletProvider` merges transactions + transfers via `Rx.combineLatest`. The wallet ID filter may not be applied after the merge, or the TransferAdapter synthetic entries may have wrong wallet IDs.

### Transfer Display (TXN-04)
- **D-03:** Transfer transactions must show the counterpart's icon and title on each account. Account X's list should show "Transfer to Y" with Y's icon. Account Y's list should show "Received from X" with X's icon. Currently the display is wrong — verify `TransferAdapter` sets `walletId` correctly on each synthetic entry, and `TransactionCard` resolves the counterpart wallet for icon display.

### Voice Subscription/Bill Creation (VOICE-04)
- **D-04:** Creating a subscription from voice review screen gives an error. The suggestion button doesn't update after tapping. Fix: the `onAddAsRecurring` callback in `voice_confirm_screen.dart` likely fails silently or doesn't trigger a state rebuild.
- **D-05:** Subscription/bill creation from review screen must be **on-tap** — single tap creates the recurring record and updates the button to show "Added ✓". No multi-step dialog.

### Voice Transfer — Missing Account Suggestions (VOICE-02)
- **D-06:** When voice says "transfer from X to Y" and NEITHER account exists, only one account creation is suggested. Fix: both accounts should be suggested for creation — show two "Create Account X?" and "Create Account Y?" suggestion cards simultaneously.

### Archive Verification (ACCT-09)
- **D-07:** The reorder/manage modal's archive action lacks secondary verification. The `_toggleArchive()` in `account_manage_sheet.dart` must show the same 2-step confirmation dialog as the wallets screen. This was confirmed implemented in static analysis but the archive button in the reorder modal may bypass the confirmation dialog.

### AI JSON Leaking (AI-03)
- **D-08:** Despite the 3-layer parser, raw JSON still appears in some AI responses. The edge case is likely: (1) JSON split across multiple chunks in streaming, (2) JSON embedded in a markdown code block the parser doesn't recognize, or (3) a malformed response that doesn't match any of the 3 regex patterns. Add a final safety net: if the displayed text contains `{"action"` or `"type":`, strip it before rendering.

### AI Language Consistency (AI-01 — pulled forward from Phase 4)
- **D-09:** AI chatbot sends English confirmation messages even when the user speaks Arabic. The `ChatActionMessages` class likely returns hardcoded English strings instead of using `context.l10n`. Fix: all action confirmation messages must use l10n keys, not hardcoded strings.

### Toast/SnackBar Styling (NEW)
- **D-10:** SnackBar notifications are bulky, remain visible too long, appear in center of screen, and require manual dismissal. Fix: style as modern, compact bottom-aligned toast with auto-dismiss after 3 seconds. Use `AppDurations.snackBar` for duration. Apply design tokens (rounded corners, smaller text, subtle background).

### Bill/Subscription On-Tap Creation
- **D-11:** The "Add to Subscriptions & Bills?" suggestion in review screen should create the record on single tap and update the UI to show "Added ✓". Currently it either errors or requires navigation to a separate form.

### Missing Amount Voice Prompt (NEW — pulled from Phase 3)
- **D-12:** When voice input doesn't include an amount, the review screen should display a prominent message: "Amount not detected — please enter the amount to submit." The amount field should be highlighted/focused. The submit button should be disabled until amount > 0.

### Claude's Discretion
- Exact SnackBar/toast styling (as long as it's modern, compact, bottom-aligned, auto-dismiss)
- Whether to add a final regex safety net for JSON leaking or fix the specific edge cases in the 3-layer parser
- How to display the "amount missing" prompt (inline text vs banner vs field highlight)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Transaction Display & Filtering
- `lib/shared/providers/activity_provider.dart` — Rx.combineLatest merge logic
- `lib/domain/adapters/transfer_adapter.dart` — synthetic TransactionEntity creation, walletId assignment
- `lib/shared/widgets/cards/transaction_card.dart` — card rendering, counterpart display
- `lib/shared/widgets/lists/transaction_list_section.dart` — transfer direction labels

### Voice Input & Review
- `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart` — subscription creation, wallet suggestions, amount validation
- `lib/core/utils/subscription_detector.dart` — subscription detection logic
- `lib/core/utils/wallet_matcher.dart` — wallet resolution from voice hints

### AI Chat
- `lib/core/services/ai/chat_response_parser.dart` — 3-layer JSON parser
- `lib/core/services/ai/chat_action_messages.dart` — action confirmation messages (locale check)
- `lib/features/ai_chat/presentation/widgets/message_bubble.dart` — markdown rendering

### Account Management
- `lib/features/dashboard/presentation/widgets/account_manage_sheet.dart` — archive in reorder modal

### App-Wide
- `lib/core/constants/app_durations.dart` — duration tokens
- `lib/core/constants/app_sizes.dart` — size tokens for SnackBar styling

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `ConfirmDialog.show()` in wallets_screen.dart — 2-step confirmation pattern already used for archive, reuse in manage_sheet
- `AppDurations.snackBar` — duration token exists for SnackBar timing
- `context.l10n` — localization accessor already used everywhere, just needs to be used in ChatActionMessages

### Established Patterns
- `activityByWalletProvider(int walletId)` — the main provider for per-account transaction lists
- `TransferAdapter.toTransactionPair()` — creates synthetic entries from Transfer records
- `SubscriptionDetector.isSubscriptionLike()` — category/keyword matching for subscription suggestions

### Integration Points
- `voice_confirm_screen.dart` → `RecurringRulesDao` — subscription creation from voice
- `chat_action_messages.dart` → l10n — locale-aware confirmation messages
- `activity_provider.dart` → `TransferAdapter` — merge point for transactions + transfers

</code_context>

<specifics>
## Specific Ideas

- User explicitly wants on-tap subscription creation (no separate form/navigation)
- Toast must be bottom-aligned, auto-dismiss, compact — "more modern"
- Transfer display: counterpart icon must show on each side (not just text)
- Both missing accounts should be suggested when voice transfer names two non-existent accounts

</specifics>

<deferred>
## Deferred Ideas

- **Set any account as default** — new ACCT requirement, add to Phase 2 or 3 backlog
- **Google sign-in for backup + purchases** — new auth flow, needs its own phase
- **Subscription plans visual screen in onboarding** — Phase 5 (Monetization)
- **Nav/element restructuring** — Phase 3 (Home overhaul)
- **Home screen full revamp** — Phase 3 (already planned)
- **Transaction review screen full UX revamp** — Phase 3 (TXN-07)

</deferred>

---

*Phase: 02-verification-sweep*
*Context gathered: 2026-03-27*
