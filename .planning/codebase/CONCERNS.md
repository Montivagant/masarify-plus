# Masarify Codebase Concerns — Technical Debt & Risk Analysis

_Generated 2026-03-27. Severity: HIGH / MEDIUM / LOW._

## 1. Uncommitted Generated Files

**Severity: MEDIUM**
**Status:** `lib/data/database/app_database.g.dart` marked as modified but not staged.

**Issue:**
build_runner output is dirty. May indicate schema changes not yet committed or merge conflicts.

**Fix Approach:**
```bash
dart run build_runner build --delete-conflicting-outputs
git add lib/data/database/app_database.g.dart
```

---

## 2. Untracked New Features (19 files)

**Severity: MEDIUM**
**Files:**
- `lib/core/utils/subscription_detector.dart` (43 lines) — new subscription detection utility
- `lib/core/services/ai/budget_savings_service.dart` (70 lines) — budget analysis service
- `lib/core/utils/wallet_matcher.dart` — transfer detection helper
- `lib/domain/adapters/` — new adapter layer (untracked)
- `lib/features/dashboard/presentation/widgets/account_manage_sheet.dart` — account reordering UI
- `lib/shared/providers/activity_provider.dart` — merged activity stream provider
- Test file: `test/unit/subscription_detector_test.dart` (3.6KB)

**Issue:**
18+ untracked files indicate work-in-progress features not yet integrated. Risk of merge conflicts if branches diverge.

**Fix Approach:**
- Review & test each file
- Integrate or explicitly gitignore staging work
- Run full test suite: `flutter test`

---

## 3. Large Screen Files (Code Smell)

**Severity: MEDIUM**
**Largest files:**
- `lib/features/transactions/presentation/screens/add_transaction_screen.dart` — **1,752 lines**
- `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart` — **1,287 lines**
- `lib/features/settings/presentation/screens/settings_screen.dart` — **1,125 lines**

**Issue:**
Screen files are violating Single Responsibility Principle. These contain business logic, UI, validation, and state management in monolithic blocks. Hard to test, maintain, and reuse components.

**Fix Approach:**
- Extract form fields → separate `FormWidgets` classes
- Extract validation → utility functions in `domain/validators/`
- Extract action handlers → service layer
- Break into smaller, focused screens with shared sub-widgets

**Example:** `AddTransactionScreen` should delegate to:
- `_TransactionCategoryPicker` (component)
- `_TransactionDateField` (component)
- `_TransactionAmountInput` (component)
- Business logic stays in provider (`transaction_provider.dart`)

---

## 4. API Keys & Secrets (Externalized — Safe)

**Severity: LOW (Well-Managed)**
**Files:** `lib/core/config/env.dart`, `lib/core/config/ai_config.dart`

**Current State:**
- OpenRouter API key: injected via `--dart-define=OPENROUTER_API_KEY=...`
- Google AI API key: injected via `--dart-define=GOOGLE_AI_API_KEY=...`
- NO hardcoded secrets in version control ✓

**Status:** SAFE. Keys are loaded at build time; `.gitignore` prevents `.env` files.

---

## 5. Feature Flags State (Strategic Debt)

**Severity: MEDIUM**
**File:** `lib/core/config/app_config.dart`

Current state:
```dart
static const bool kSmsEnabled = false;           // HIDDEN (AI-first pivot)
static const bool kMonetizationEnabled = true;   // ENABLED (P5)
```

**Issues:**
1. SMS code still present (preserved for future Pro tier) — ~200 LOC in SMS parser, detector, review screen
2. SMS UI touchpoints guarded across: `dashboard_screen.dart`, `hub_screen.dart`, `settings_screen.dart`, `add_wallet_screen.dart`, `router.dart`
3. Dead code paths for `kSmsEnabled=true` — slow build, confusing git history

**Fix Approach (Post-Launch):**
- Create feature branch: `chore/remove-sms-feature`
- Delete entirely: `lib/features/sms_parser/`, SMS DAO/table, SMS guards from screens
- One-time cleanup after P5 stable release

---

## 6. Monetization Integration (Incomplete)

**Severity: MEDIUM**
**Status:** `kMonetizationEnabled = true` but integration TBD.

**Issue:**
Flag is enabled; in-app purchase logic not yet present. Screens have placeholder paywalls but no RevenueCat or Google Play Billing integration.

**Fix Approach:**
- Implement `in_app_purchase` package for Google Play Billing
- Add paywall provider & gate premium features
- Test on physical device (emulator has IAP limitations)

---

## 7. Database Schema Version (Current: v13)

**Severity: LOW**
**Last Migration:** `sort_order` column added to wallets for drag-and-drop (v12→v13).

**Risk:**
- 13 migration scripts: ensure rollback logic tested
- Migration `onDowngrade` strategy not documented
- No schema dump for offline reference

**Fix Approach:**
- Add migration versioning comment block to `app_database.dart`
- Document rollback procedure in `MEMORY.md`

---

## 8. Test Coverage Gaps

**Severity: MEDIUM**
**Current:** 12 test files, ~218 tests passing. **No integration/UI tests.**

**Uncovered:**
- `AddTransactionScreen` (1,752 LOC) — **zero tests**
- `VoiceConfirmScreen` (1,287 LOC) — **unit tests only** (no integration)
- Voice transcription error handling
- Transfer creation & reversal
- Budget alert notifications
- Offline sync edge cases

**Fix Approach:**
- Add integration tests for transaction flow: `test/integration/add_transaction_flow_test.dart`
- Mock repository layer; test screen interactions
- Target 70%+ coverage on critical paths (transactions, voice, transfers)

---

## 9. Fragile Navigation (Router Coupling)

**Severity: MEDIUM**
**File:** `lib/app/router/app_router.dart` (397 lines)

**Issues:**
1. Deep route nesting: `TransactionDetail → VoiceConfirm → AddTransaction` → back history fragile
2. No error handling for invalid route parameters (e.g., nonexistent wallet ID)
3. Route parameters not validated before construction

**Example Risk:** VoiceConfirmScreen expects `selectedAccountIdProvider` to exist; if user navigates directly to voice from cold start, provider might be uninitialized.

**Fix Approach:**
- Add route validation guards: `onException` callback in GoRouter
- Validate route params before pushing: `if (!walletIds.contains(id)) context.go('/home')`
- Add breadcrumb logging for debugging navigation chains

---

## 10. Missing Boundary Tests

**Severity: MEDIUM**
**Patterns:**

Missing edge-case tests:
- Negative amounts (should be rejected) — **no test**
- Zero amount transactions — **no test**
- Very large amounts (e.g., 999,999 EGP) — **no test**
- Date selection in past/future — **no test**
- Category-less transactions (null category) — **no test**

**Fix Approach:**
- Add `test/unit/transaction_validation_edge_cases_test.dart`
- Test all property validators with boundary values
- Add fuzzing for amount field (0, -1, max int, etc.)

---

## 11. Drift Generated Code (app_database.g.dart)

**Severity: LOW**
**Size:** 12,408 lines (largest file in codebase).

**Issue:**
While generated files are expected, this is unusually large. Indicates schema complexity. Future migrations will add more lines.

**Mitigation:** Keep source file clean; ensure schema normalization before migrations.

---

## 12. L10n Files Auto-Generated

**Severity: LOW**
**Files:**
- `lib/l10n/app_localizations.dart` (5,324 lines)
- `lib/l10n/app_localizations_en.dart` (2,815 lines)
- `lib/l10n/app_localizations_ar.dart` (2,790 lines)

**Do NOT edit directly.** Always edit `app_en.arb` / `app_ar.arb`, then run:
```bash
flutter gen-l10n
```

---

## 13. SMS Parser Orphaned Code (Feature Flagged OFF)

**Severity: MEDIUM**
**Files:**
- `lib/features/sms_parser/` (entire feature)
- `lib/core/services/sms_parser_service.dart`
- `lib/data/tables/sms_parser_logs_table.dart`
- UI guards in 5+ screens

**Status:** Preserved for future Pro tier; currently unreachable (`kSmsEnabled=false`).

**Risk:**
- Dead code adds maintenance burden
- Stale imports, outdated patterns
- Confusion for new contributors

**Post-Launch Action:**
- Branch: `chore/remove-sms-feature` after stable P5 release
- Delete feature entirely; remove guards and imports
- Or: Create separate `pro/` branch if planning tiered release

---

## 14. Offline-First Edge Cases (Not Fully Tested)

**Severity: MEDIUM**
**Status:** Connectivity handling in place; offline sync heuristics unvalidated.

**Issues:**
- Background AI services assume internet (may fail silently if offline)
- No test for transaction creation → enrichment retry cycle
- Category learning service offline behavior not documented

**Fix Approach:**
- Add `test/integration/offline_sync_test.dart`
- Mock `connectivity_plus` to simulate network transitions
- Verify enrichment queue persists across app restarts

---

## Summary Table

| Concern | Severity | Impact | Owner |
|---------|----------|--------|-------|
| Uncommitted .g.dart file | MEDIUM | Build reproducibility | DevOps |
| 19 untracked new files | MEDIUM | Merge conflict risk | Developer |
| 1,752-line screen file | MEDIUM | Maintainability, testability | Refactor |
| Large screen files (3) | MEDIUM | Code smell, SRP violation | Refactor |
| Feature flag debt (SMS) | MEDIUM | Dead code burden | Post-launch |
| Monetization incomplete | MEDIUM | Missing revenue | Feature dev |
| Test coverage gaps | MEDIUM | Regression risk | QA |
| Fragile navigation | MEDIUM | UX crashes | Router audit |
| Missing boundary tests | MEDIUM | Data integrity risk | QA |
| Orphaned SMS code | MEDIUM | Maintenance burden | Chore |
| Offline edge cases | MEDIUM | Silent failures | Testing |

---

## Recommendations (Priority Order)

1. **IMMEDIATE:** Commit `app_database.g.dart` or rebuild & review dirty state
2. **WEEK 1:** Integrate/gitignore 19 untracked files; run full test suite
3. **WEEK 2:** Break down `AddTransactionScreen` (1,752 LOC) into component widgets + extracted logic
4. **WEEK 3:** Add integration tests for transaction & voice flows
5. **POST-LAUNCH:** Remove SMS feature entirely; remove dead code guards
6. **ONGOING:** Add boundary tests for all entity validators

No CRITICAL severity issues found. Codebase is structurally sound; concerns are refactoring & completeness.
