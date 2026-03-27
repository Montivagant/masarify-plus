---
phase: 2
plan: 3
title: "Account & Subscription Verification"
wave: 1
depends_on: []
requirements: [ACCT-01, ACCT-02, ACCT-03, ACCT-04, ACCT-05, ACCT-06, ACCT-07, ACCT-08, ACCT-09, SUB-01, CAT-01, CAT-02, CAT-03, CAT-04]
bugs: [D-07]
files_modified:
  - lib/features/dashboard/presentation/widgets/account_manage_sheet.dart
  - lib/features/wallets/presentation/screens/wallets_screen.dart
  - lib/features/wallets/presentation/screens/wallet_detail_screen.dart
  - lib/features/wallets/presentation/screens/add_wallet_screen.dart
  - lib/features/onboarding/presentation/screens/onboarding_screen.dart
  - lib/features/onboarding/presentation/widgets/onboarding_pages.dart
  - lib/core/constants/app_navigation.dart
  - lib/l10n/app_en.arb
  - lib/l10n/app_ar.arb
  - lib/data/seed/category_seed.dart
  - lib/core/services/ai/categorization_learning_service.dart
autonomous: true
---

# Plan 2-3: Account & Subscription Verification

**Goal:** Fix archive from reorder modal to use 2-step confirmation (D-07/ACCT-09), verify all 9 account management features (ACCT-01 through ACCT-08), verify "Subscriptions & Bills" rename (SUB-01), and verify all 4 category features (CAT-01 through CAT-04).

---

## Task 1: Fix Archive from Reorder Modal — 2-Step Confirmation (D-07, ACCT-09)

**Problem:** The `_toggleArchive()` in `account_manage_sheet.dart` archives directly without the 2-step confirmation dialog used by the wallets screen. It should show the same `ConfirmDialog.show()` → `ConfirmDialog.show()` flow.

<read_first>
- lib/features/dashboard/presentation/widgets/account_manage_sheet.dart (lines 69-86 — _toggleArchive method)
- lib/features/wallets/presentation/screens/wallets_screen.dart (lines 147-176 — _confirmArchive with 2-step dialog)
- lib/shared/widgets/feedback/confirm_dialog.dart (ConfirmDialog.show API)
</read_first>

<action>
1. In `lib/features/dashboard/presentation/widgets/account_manage_sheet.dart`, replace the `_toggleArchive` method (lines 69-86) with a 2-step confirmation for archive and single-step for unarchive. Import `ConfirmDialog` and add haptic feedback:

   Add imports at the top of the file:
   ```dart
   import 'package:flutter/services.dart';
   import '../../../../shared/widgets/feedback/confirm_dialog.dart';
   ```

2. Replace `_toggleArchive` with:
   ```dart
   Future<void> _toggleArchive(WalletEntity wallet) async {
     final repo = ref.read(walletRepositoryProvider);

     if (wallet.isArchived) {
       // Unarchive — single confirmation
       final confirmed = await ConfirmDialog.show(
         context,
         title: context.l10n.wallet_unarchive_action,
         message: context.l10n.wallet_unarchive_confirm(wallet.name),
       );
       if (!confirmed || !mounted) return;
       await repo.unarchive(wallet.id);
       HapticFeedback.mediumImpact();
     } else {
       // Prevent archiving the default account.
       if (wallet.isDefaultAccount) {
         if (!mounted) return;
         SnackHelper.showError(
           context,
           context.l10n.wallet_cannot_archive_default,
         );
         return;
       }

       // Step 1: Info dialog explaining consequences.
       final proceed = await ConfirmDialog.show(
         context,
         title: context.l10n.wallet_archive_title,
         message: context.l10n.wallet_archive_info,
         confirmLabel: context.l10n.common_continue_label,
       );
       if (!proceed || !mounted) return;

       // Step 2: Confirm with account name.
       final confirmed = await ConfirmDialog.show(
         context,
         title: context.l10n.wallet_archive_action,
         message: context.l10n.wallet_archive_confirm(wallet.name),
         confirmLabel: context.l10n.wallet_archive_action,
         destructive: true,
       );
       if (!confirmed || !mounted) return;

       await repo.archive(wallet.id);
       HapticFeedback.mediumImpact();
     }
     await _loadWallets(); // refresh
   }
   ```

3. Verify the l10n keys used are already defined:
   - `wallet_archive_title` -- exists
   - `wallet_archive_info` -- exists
   - `wallet_archive_confirm` -- exists (parameterized with `name`)
   - `wallet_archive_action` -- exists
   - `wallet_unarchive_action` -- exists
   - `wallet_unarchive_confirm` -- exists (parameterized with `name`)
   - `wallet_cannot_archive_default` -- exists
   - `common_continue_label` -- verify exists, if not add it
</action>

<acceptance_criteria>
- grep "ConfirmDialog.show" lib/features/dashboard/presentation/widgets/account_manage_sheet.dart confirms 2-step dialog
- grep "wallet_archive_title" lib/features/dashboard/presentation/widgets/account_manage_sheet.dart confirms info dialog
- grep "wallet_archive_confirm" lib/features/dashboard/presentation/widgets/account_manage_sheet.dart confirms name confirmation
- grep "HapticFeedback" lib/features/dashboard/presentation/widgets/account_manage_sheet.dart confirms haptic feedback
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 2: Verify Cash Wallet Hidden from Accounts Screen (ACCT-01)

**Problem:** The system Cash wallet should be completely hidden from the Accounts (Wallets) screen. User cannot see, edit, or delete it.

<read_first>
- lib/features/wallets/presentation/screens/wallets_screen.dart (wallet list filtering)
- lib/shared/providers/wallet_provider.dart (allWalletsProvider, walletsProvider)
</read_first>

<action>
1. Read `lib/features/wallets/presentation/screens/wallets_screen.dart` — find where the wallet list is filtered. Look for a filter like:
   ```dart
   final userWallets = wallets.where((w) => !w.isSystemWallet).toList();
   ```

2. Verify `allWalletsProvider` or the provider used by wallets_screen includes a system wallet filter. The screen should show non-system wallets only.

3. Verify `WalletEntity` has an `isSystemWallet` field that correctly identifies the Cash wallet.

4. No code changes expected if filter is in place. If missing, add the filter. Document verification.
</action>

<acceptance_criteria>
- grep "isSystemWallet" lib/features/wallets/presentation/screens/wallets_screen.dart confirms system wallet filter
- Behavioral check: verify no edit or delete route/action exists for system wallets (e.g., grep for isSystemWallet guards before delete/edit actions in wallet_detail_screen.dart and wallets_screen.dart)
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 3: Verify Default Account — Editable Name, Not Deletable (ACCT-02)

**Problem:** The default account should have an editable name but the delete button should be disabled.

<read_first>
- lib/features/wallets/presentation/screens/wallet_detail_screen.dart (delete guard for default account)
- lib/features/wallets/presentation/screens/add_wallet_screen.dart (edit mode for default account)
</read_first>

<action>
1. Read `lib/features/wallets/presentation/screens/wallet_detail_screen.dart` — find the delete button/action. Verify it checks `wallet.isDefaultAccount` and disables/hides the delete option.

2. Read the edit wallet screen (may be `add_wallet_screen.dart` in edit mode or a dedicated screen) — verify the name field is editable even for the default account.

3. Verify `WalletEntity.isDefaultAccount` correctly identifies the default account.

4. No code changes expected. Document verification.
</action>

<acceptance_criteria>
- grep "isDefaultAccount" lib/features/wallets/presentation/screens/wallet_detail_screen.dart confirms delete guard
</acceptance_criteria>

---

## Task 4: Verify Archive Flow with 2-Step Confirmation (ACCT-03, ACCT-04)

**Problem:** Archive from the wallets screen should use a 2-step confirmation dialog explaining what will happen.

<read_first>
- lib/features/wallets/presentation/screens/wallets_screen.dart (lines 147-176 — _confirmArchive)
</read_first>

<action>
1. The wallets_screen.dart already has the 2-step `_confirmArchive` method (verified in pre-reading). Confirm:
   - Step 1: `ConfirmDialog.show` with `wallet_archive_title` and `wallet_archive_info`
   - Step 2: `ConfirmDialog.show` with `wallet_archive_action` and `wallet_archive_confirm(name)`, destructive: true

2. Verify `wallet_archive_info` l10n string contains the full explanation of consequences (hidden from home, transactions hidden, balance excluded, AI excluded).

3. No code changes expected. Document verification.
</action>

<acceptance_criteria>
- grep "wallet_archive_info" lib/features/wallets/presentation/screens/wallets_screen.dart confirms info dialog
- grep "wallet_archive_confirm" lib/features/wallets/presentation/screens/wallets_screen.dart confirms 2-step
</acceptance_criteria>

---

## Task 5: Verify Archived Accounts Display with Strikethrough (ACCT-05)

**Problem:** Archived accounts should appear under an "Archived" section with strikethrough styling.

<read_first>
- lib/features/wallets/presentation/screens/wallets_screen.dart (archived section rendering)
</read_first>

<action>
1. Verify wallets_screen.dart splits wallets into `activeWallets` and `archivedWallets` sections.

2. Verify the archived section header shows `wallet_archived_section` l10n label.

3. Verify archived wallet cards have `TextDecoration.lineThrough` on the name:
   ```dart
   style: isArchived ? nameStyle?.copyWith(decoration: TextDecoration.lineThrough) : nameStyle,
   ```

4. No code changes expected. Document verification.
</action>

<acceptance_criteria>
- grep "TextDecoration.lineThrough" lib/features/wallets/presentation/screens/wallets_screen.dart confirms strikethrough
- grep "wallet_archived_section" lib/features/wallets/presentation/screens/wallets_screen.dart confirms section header
</acceptance_criteria>

---

## Task 6: Verify Unarchive Restores Visibility (ACCT-06)

**Problem:** Unarchiving an account should restore it in home carousel, transaction lists, analytics, and AI context.

<read_first>
- lib/shared/providers/wallet_provider.dart (walletsProvider — how archived wallets are filtered)
- lib/shared/providers/activity_provider.dart (archivedWalletIdsProvider filter)
</read_first>

<action>
1. Read `lib/shared/providers/wallet_provider.dart` — verify `walletsProvider` returns only non-archived wallets:
   ```dart
   final walletsProvider = StreamProvider<List<WalletEntity>>(
     (ref) => ref.watch(walletRepositoryProvider).watchAll(),
   );
   ```
   Where `watchAll()` filters `WHERE is_archived = 0`.

2. Read `lib/shared/providers/activity_provider.dart` — verify `archivedWalletIdsProvider` feeds the archive filter for `recentActivityProvider`.

3. Verify that unarchiving (setting `isArchived = false`) automatically makes the wallet visible again through the reactive stream — no manual cache invalidation needed.

4. No code changes expected. Document verification.
</action>

<acceptance_criteria>
- grep "archivedWalletIdsProvider" lib/shared/providers/activity_provider.dart confirms archive filter
- grep "isArchived" lib/shared/providers/wallet_provider.dart confirms provider-level filter
- grep "isArchived" lib/data/repositories/wallet_repository_impl.dart confirms repository-level filter
</acceptance_criteria>

---

## Task 7: Verify Starting Balance in Account Creation and Onboarding (ACCT-07)

**Problem:** Starting balance field should be present during account creation and in the onboarding flow.

<read_first>
- lib/features/wallets/presentation/screens/add_wallet_screen.dart (starting balance field)
- lib/features/onboarding/presentation/widgets/onboarding_pages.dart (onboarding account setup page)
</read_first>

<action>
1. Read `lib/features/wallets/presentation/screens/add_wallet_screen.dart` — verify there is an `initialBalance` or `startingBalance` field that accepts an amount in piastres:
   ```dart
   AmountInput(
     initialPiastres: _initialBalance,
     onAmountChanged: (amount) => _initialBalance = amount,
     ...
   ),
   ```

2. Verify the `create()` call passes `initialBalance`:
   ```dart
   await ref.read(walletRepositoryProvider).create(
     name: _name,
     type: _type,
     initialBalance: _initialBalance,
   );
   ```

3. Read `lib/features/onboarding/presentation/widgets/onboarding_pages.dart` — find the account setup page (page 4 or 5) and verify it includes a starting balance field.

4. No code changes expected. Document verification.
</action>

<acceptance_criteria>
- grep "initialBalance\|startingBalance\|starting_balance" lib/features/wallets/presentation/screens/add_wallet_screen.dart confirms field
- grep "initialBalance\|startingBalance" lib/features/onboarding/presentation/widgets/onboarding_pages.dart confirms onboarding field
</acceptance_criteria>

---

## Task 8: Verify Drag-and-Drop Reorder (ACCT-08)

**Problem:** The account manage sheet should support drag-and-drop reordering of account cards.

<read_first>
- lib/features/dashboard/presentation/widgets/account_manage_sheet.dart (ReorderableListView usage)
</read_first>

<action>
1. Verify `account_manage_sheet.dart` uses `ReorderableListView.builder` (line 145) with:
   - `onReorder: _onReorder` callback
   - `ReorderableDragStartListener` on the drag handle icon
   - `_onReorder` persists the new order via `walletRepositoryProvider.updateSortOrders`

2. Verify the sort order is respected: wallets are sorted by `sortOrder` then `id` (line 43-47).

3. No code changes expected. Document verification.
</action>

<acceptance_criteria>
- grep "ReorderableListView" lib/features/dashboard/presentation/widgets/account_manage_sheet.dart confirms drag-and-drop
- grep "ReorderableDragStartListener" lib/features/dashboard/presentation/widgets/account_manage_sheet.dart confirms drag handle is wired
- grep "updateSortOrders" lib/features/dashboard/presentation/widgets/account_manage_sheet.dart confirms persistence
</acceptance_criteria>

---

## Task 9: Verify "Subscriptions & Bills" Rename (SUB-01)

**Problem:** All user-facing instances of "Recurring & Bills" should be renamed to "Subscriptions & Bills". No remnant "Recurring" labels in l10n, navigation tabs, or screen titles.

<read_first>
- lib/l10n/app_en.arb (search for "Recurring")
- lib/l10n/app_ar.arb (search for corresponding Arabic)
- lib/core/constants/app_navigation.dart (tab labels)
- lib/features/hub/presentation/screens/hub_screen.dart (More tab entries)
</read_first>

<action>
1. Search all l10n files for "Recurring" as a user-visible label (not internal code references):
   ```bash
   grep -i "Recurring" lib/l10n/app_en.arb
   ```
   - Any value containing "Recurring & Bills" should be "Subscriptions & Bills"
   - Internal key names like `chat_action_recurring_created` are OK (keys are not user-visible)
   - The value of `chat_action_recurring_created` should say "Subscription" not "Recurring"

2. Search `lib/core/constants/app_navigation.dart` for tab labels — verify the recurring tab label references a l10n key that says "Subscriptions & Bills".

3. Search `lib/features/hub/presentation/screens/hub_screen.dart` — verify the "More" tab entry for subscriptions uses the correct label.

4. Run a broad search:
   ```bash
   grep -rn "Recurring" lib/l10n/app_en.arb | grep -v "@" | grep -v "recurring_"
   ```
   Any user-visible value (not key, not annotation) containing "Recurring" must be changed to "Subscriptions".

5. Fix any remnants found. Both `app_en.arb` and `app_ar.arb` must be updated.

6. Run `flutter gen-l10n` after any changes.
</action>

<acceptance_criteria>
- grep -c '"Recurring & Bills"' lib/l10n/app_en.arb returns 0 (no remnant)
- grep "Subscriptions" lib/l10n/app_en.arb shows the correct labels
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 10: Verify Default Categories — 34 Categories with Installments (CAT-01)

**Problem:** Fresh install should seed 34 default categories, including "Installments" for the Egyptian market.

<read_first>
- lib/data/seed/category_seed.dart (seed list and count)
</read_first>

<action>
1. Read `lib/data/seed/category_seed.dart` — count the number of default categories. Should be 34.

2. Search for "Installments" or "installments" (also check Arabic: "أقساط"):
   ```dart
   grep -i "installment\|أقساط" lib/data/seed/category_seed.dart
   ```

3. If "Installments" category is missing, add it to the seed list:
   ```dart
   CategorySeed(
     nameEn: 'Installments',
     nameAr: 'أقساط',
     iconName: 'credit_card',
     colorHex: '#E57373',
     type: 'expense',
   ),
   ```

4. If count is not 34, document the actual count and any missing categories.
</action>

<acceptance_criteria>
- grep -i "installment\|أقساط" lib/data/seed/category_seed.dart confirms category exists
- The seed list contains 34 entries (count verified via grep or manual inspection)
</acceptance_criteria>

---

## Task 11: Verify Category Search Picker (CAT-02)

**Problem:** Category picker should support search/filter by name in both Arabic and English.

<read_first>
- lib/features/voice_input/presentation/screens/voice_confirm_screen.dart (lines 570-632 — _showCategoryPicker)
- lib/features/transactions/presentation/screens/add_transaction_screen.dart (category picker)
</read_first>

<action>
1. Read the category picker implementations:
   - `voice_confirm_screen.dart` `_showCategoryPicker` — check if there is a search/filter TextField
   - `add_transaction_screen.dart` — check the category picker

2. If the picker does NOT have a search field, add one:
   - Add a `TextField` at the top of the picker sheet
   - Filter the category list by matching `displayName` against the search query
   - Use case-insensitive matching

3. The category picker should filter by both `nameEn` and `nameAr` (via `displayName(locale)`).

4. Verify the category entity has a `displayName(String locale)` method that returns the correct language name.

5. If search already exists in `add_transaction_screen.dart` but not in `voice_confirm_screen.dart`, add it to both.
</action>

<acceptance_criteria>
- grep "TextField\|searchQuery\|search" in the category picker implementation confirms search exists
- The picker filters categories as the user types
</acceptance_criteria>

---

## Task 12: Verify Smart Category Ordering (CAT-03)

**Problem:** Most-used and most-recent categories should appear first in the picker, driven by `CategorizationLearningService`.

<read_first>
- lib/core/services/ai/categorization_learning_service.dart (frequency data)
- lib/features/transactions/presentation/screens/add_transaction_screen.dart (category picker ordering)
</read_first>

<action>
1. Read `lib/core/services/ai/categorization_learning_service.dart` — verify it exposes a method to get category usage counts or rankings:
   ```dart
   Future<Map<int, int>> getCategoryUsageCounts();
   ```
   Or a method to sort categories by frequency.

2. Read the category picker in `add_transaction_screen.dart` — verify categories are sorted by usage frequency before being displayed. Expected pattern:
   ```dart
   categories.sort((a, b) => (usageCounts[b.id] ?? 0).compareTo(usageCounts[a.id] ?? 0));
   ```

3. If smart ordering is not implemented, note this for implementation. The ordering should be:
   1. Categories with usage count > 0, sorted by count descending
   2. All other categories in default seed order

4. Document verification or implementation status.
</action>

<acceptance_criteria>
- grep "sort\|frequency\|usageCount\|categoryMapping" in category picker code confirms ordering logic
</acceptance_criteria>

---

## Task 13: Verify Category Suggestion from Transaction Title (CAT-04)

**Problem:** Typing a transaction title should trigger a category suggestion based on learned mappings.

<read_first>
- lib/features/transactions/presentation/screens/add_transaction_screen.dart (title field and category suggestion)
- lib/core/services/ai/categorization_learning_service.dart (suggestCategory method)
</read_first>

<action>
1. Read `add_transaction_screen.dart` — find the title TextField. Check if there is an `onChanged` callback that calls the categorization service:
   ```dart
   onChanged: (value) {
     _debouncer.run(() {
       final suggestion = categorizationService.suggestCategory(value);
       if (suggestion != null) setState(() => _categoryId = suggestion);
     });
   },
   ```

2. Read `categorization_learning_service.dart` — verify `suggestCategory(String title)` method exists and returns a category ID based on learned title→category mappings.

3. If the wiring is missing, document it. The core logic may already exist in the service but not be wired to the UI.

4. Document verification status.
</action>

<acceptance_criteria>
- grep "suggestCategory\|categorySuggestion" lib/features/transactions/presentation/screens/add_transaction_screen.dart confirms wiring
- grep "suggestCategory" lib/core/services/ai/categorization_learning_service.dart confirms method exists
</acceptance_criteria>

---

## Task 14: Run Full Analysis and Verify

<read_first>
- (none — verification-only task)
</read_first>

<action>
1. Run `flutter gen-l10n` if any ARB files were modified.
2. Run `flutter analyze lib/` — must report zero issues.
3. Run `flutter test test/unit/` — ensure no regressions.
4. Verify all 14 requirements are addressed:
   - ACCT-01 through ACCT-09: All account management features verified or fixed
   - SUB-01: No remnant "Recurring" labels
   - CAT-01 through CAT-04: Categories verified
5. Verify bug D-07 is fixed:
   - Archive from reorder modal uses 2-step confirmation
</action>

<acceptance_criteria>
- flutter analyze lib/ reports "No issues found!"
- flutter test completes with zero failures
</acceptance_criteria>
