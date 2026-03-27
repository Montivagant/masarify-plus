# Requirements: Masarify Play Store Launch

**Defined:** 2026-03-27
**Core Value:** Every transaction recorded effortlessly, offline, in Arabic or English — with an AI advisor that makes spending visible and actionable.

## v1 Requirements

### Home Screen (HOME)

- [ ] **HOME-01**: Full home screen revamp — replace bulky hero cards with modern, clean, sleek design
- [ ] **HOME-02**: "All Accounts" balance card must be visually distinct from individual account cards (it's a summary, not an account)
- [ ] **HOME-03**: Filter and search actions for transactions on home screen
- [ ] **HOME-04**: Quick filter chips (Expense/Income/Transfer/All) on home transaction list
- [ ] **HOME-05**: Eliminate whitespace and blank areas from home screen layout
- [ ] **HOME-06**: Remove Transactions tab entirely — merge all transaction functionality into home screen
- [ ] **HOME-07**: Upcoming bills/subscriptions due displayed on home screen (verify insight card works)

### Transactions (TXN)

- [ ] **TXN-01**: Swipe actions (edit/delete) working on ALL transaction types including transfers — with 2-step confirmation
- [ ] **TXN-02**: Category displayed first in transaction cards (category bold, title/note secondary) — verify this is working
- [ ] **TXN-03**: Cash withdrawal/deposit transactions appear in relevant account transaction lists — verify fix
- [ ] **TXN-04**: Transfer transactions display correctly: X account shows "Transfer to Y" with Y's icon, Y account shows "Transfer from X" with X's icon — one transaction per account
- [ ] **TXN-05**: Transactions added to the correct account (respects selected account from dashboard carousel) — verify fix
- [ ] **TXN-06**: Transaction description field (notes/memo support)
- [ ] **TXN-07**: Review/confirm transaction screen — full UX/UI revamp for clarity and usability

### AI Chat (AI)

- [ ] **AI-01**: AI replies in ONE language matching the user's language — no mixed Arabic+English responses
- [ ] **AI-02**: AI has current date/time awareness (2026, not 2024) — inject date into system prompt
- [ ] **AI-03**: AI chat action responses are clean — no raw JSON leaked to user (verify 3-layer parser fix)
- [ ] **AI-04**: AI message formatting uses rich text (markdown rendered) — no raw asterisks/hashtags (verify flutter_markdown)
- [ ] **AI-05**: AI suggests creating subscriptions/bills based on transaction context and category (same as voice feature)
- [ ] **AI-06**: AI correctly handles transfer requests between two named accounts (e.g., "paid 1000 from CIB to settle NBE debt" → creates transfer, not expense)

### Voice Input (VOICE)

- [ ] **VOICE-01**: Voice correctly detects "Cash" / "كاش" as the system Cash wallet — not suggesting "Create Cash account"
- [ ] **VOICE-02**: Voice transfer detection works for inter-bank transfers with correct amount signs (+/- on each side)
- [ ] **VOICE-03**: Brand icon matching accuracy improved — icons/colors match the context of transcribed audio
- [ ] **VOICE-04**: Voice suggests "Add to Subscriptions & Bills?" based on transaction context/category (verify working)

### Accounts (ACCT)

- [ ] **ACCT-01**: Cash account hidden from Accounts screen entirely — user cannot edit or delete it
- [ ] **ACCT-02**: Default account: editable name, not deletable
- [ ] **ACCT-03**: Archive feature for non-default accounts — hides from home, transactions, analytics, and AI context
- [ ] **ACCT-04**: Archive has 2-step confirmation with explanation of what will happen
- [ ] **ACCT-05**: Archived accounts appear under "Archived" section with strikethrough styling
- [ ] **ACCT-06**: Unarchive flow restores full visibility
- [ ] **ACCT-07**: Starting balance when creating an account (and in onboarding flow) — verify working
- [ ] **ACCT-08**: Drag-and-drop reorder of account cards via expand/modal view — verify working
- [ ] **ACCT-09**: Quick archive from the reorder modal

### Subscriptions & Bills (SUB)

- [ ] **SUB-01**: Rename "Recurring & Bills" to "Subscriptions & Bills" across entire app — verify no remnants
- [ ] **SUB-02**: Due date field on subscriptions/bills
- [ ] **SUB-03**: Notifications for upcoming bills based on due dates and learning patterns
- [ ] **SUB-04**: Auto-detection of monthly bills from spending patterns (learning-based, not SMS)
- [ ] **SUB-05**: AI and voice both suggest creating subscription when detecting recurring-type transactions

### Categories (CAT)

- [ ] **CAT-01**: Enriched default categories — add "Installments" and research more relevant categories for Egyptian market
- [ ] **CAT-02**: Category search in picker
- [ ] **CAT-03**: Smart category ordering — most used / most recent categories shown first (learning-based)
- [ ] **CAT-04**: Category suggestion based on transaction title/note text input
- [ ] **CAT-05**: Category suggestions in budget, goal, and recurring creation flows too

### Onboarding (ONBOARD)

- [ ] **ONBOARD-01**: Remove 5th onboarding page ("What's Your Main Account") — auto-create default bank account
- [ ] **ONBOARD-02**: Polish transitions, skip/back, progress indicator
- [ ] **ONBOARD-03**: Financial disclaimer (AI provides budgeting guidance, not regulated financial advice)

### Subscription Paywall (PAYWALL)

- [ ] **PAYWALL-01**: Free tier enforcement (2 budgets, 1 savings goal limit)
- [ ] **PAYWALL-02**: Pro subscription purchase flow via Google Play Billing
- [ ] **PAYWALL-03**: Paywall UI — AI features listed first, not budgets
- [ ] **PAYWALL-04**: 7-day free trial (fix: wire ensureTrialStarted(), resolve 7 vs 14 day mismatch)
- [ ] **PAYWALL-05**: Store purchaseToken + expiryDate in Drift for cancellation/grace handling
- [ ] **PAYWALL-06**: Restore purchases flow

### Performance (PERF)

- [ ] **PERF-01**: App startup under 2 seconds on mid-range Android (Samsung A14, Xiaomi Redmi 12)
- [ ] **PERF-02**: 60fps scrolling on transaction lists (500+ items)
- [ ] **PERF-03**: Add composite index idx_transactions_wallet_date
- [ ] **PERF-04**: Paginate watchAll() queries, debounce recentActivityProvider
- [ ] **PERF-05**: Verify GlassConfig.deviceFallback activates on low-end GPUs (Mali G57, Helio G8x)

### Settings & Cleanup (CLEAN)

- [ ] **CLEAN-01**: Remove "Notification Parsing" from Settings screen — verify fully removed
- [ ] **CLEAN-02**: Remove another_telephony package from pubspec.yaml (SMS dep, unnecessary Play Store scrutiny)
- [ ] **CLEAN-03**: Switch SCHEDULE_EXACT_ALARM to inexact alarms or WorkManager

### Play Store (STORE)

- [ ] **STORE-01**: Bump targetSdk to 35 — test edge-to-edge display against glassmorphic nav bar
- [ ] **STORE-02**: Play Store listing (title, description, screenshots, feature graphic)
- [ ] **STORE-03**: Privacy policy (HTTPS URL) — declare audio→Gemini, chat→OpenRouter in Data Safety
- [ ] **STORE-04**: App signing and release build
- [ ] **STORE-05**: Content rating questionnaire and target audience declaration
- [ ] **STORE-06**: AI disclosure labels on chat and insight cards

## v2 Requirements

Deferred to post-launch updates (v1.1+).

- **WIDGET-01**: Android Home Screen Widget showing balance/recent transactions
- **LOTTIE-01**: Lottie microinteractions for key user actions
- **IOS-01**: iOS App Store submission
- **SYNC-01**: Cloud sync (optional, preserving offline-first)
- **EXPORT-01**: Transaction export to CSV/PDF
- **SERVER-01**: Server-side subscription validation

## Out of Scope

| Feature | Reason |
|---------|--------|
| SMS Parsing | Feature-flagged off (kSmsEnabled=false). Legal/compliance risk. Pro tier future |
| Streak/Gamification | User explicitly rejected |
| Firebase/Cloud Sync | Offline-first is core value |
| Ads | Subscription-only monetization |
| Multiple pricing tiers | Keep exactly 2: Free + Pro |
| iOS launch | Android first, validate on Play Store |

## Traceability

<!-- Populated during roadmap creation -->

| Requirement | Phase | Status |
|-------------|-------|--------|
| (populated by roadmapper) | | |

**Coverage:**
- v1 requirements: 57 total
- Mapped to phases: 0 (pending roadmap)
- Unmapped: 57

---
*Requirements defined: 2026-03-27*
*Last updated: 2026-03-27 after initialization*
