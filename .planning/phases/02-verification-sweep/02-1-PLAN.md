---
phase: 2
plan: 1
title: "Transaction & Transfer Fixes"
wave: 1
depends_on: []
requirements: [TXN-02, TXN-03, TXN-04, TXN-05]
bugs: [D-01, D-02, D-03]
files_modified:
  - lib/shared/providers/activity_provider.dart
  - lib/domain/adapters/transfer_adapter.dart
  - lib/shared/widgets/cards/transaction_card.dart
  - lib/shared/widgets/lists/transaction_list_section.dart
  - lib/shared/providers/transaction_provider.dart
  - lib/features/transactions/presentation/screens/add_transaction_screen.dart
  - lib/features/dashboard/presentation/screens/dashboard_screen.dart
autonomous: true
---

# Plan 2-1: Transaction & Transfer Fixes

**Goal:** Fix per-account transaction list filtering (D-01/D-02), transfer display with counterpart icons (D-03/TXN-04), verify category-first display (TXN-02), cash transaction visibility (TXN-03), and correct account assignment from carousel (TXN-05).

---

## Task 1: Fix activityByWalletProvider Wallet ID Filtering (D-01, D-02)

**Problem:** `activityByWalletProvider(walletId)` returns wrong transactions for specific accounts. The `watchByWallet` query on the transfer DAO correctly filters by `from_wallet_id OR to_wallet_id`, but the regular transaction `watchByWallet` query may not filter correctly, or the merge logic in the provider may be including transactions from other wallets.

<read_first>
- lib/shared/providers/activity_provider.dart (full file — understand merge logic)
- lib/shared/providers/transaction_provider.dart (check transactionsByWalletProvider definition)
- lib/data/database/daos/transaction_dao.dart (check watchByWallet query filter)
- lib/data/repositories/transaction_repository_impl.dart (check watchByWallet mapping)
- lib/domain/repositories/i_transaction_repository.dart (check watchByWallet contract)
</read_first>

<action>
1. Read `lib/data/database/daos/transaction_dao.dart` — verify `watchByWallet(int walletId)` query filters with `WHERE wallet_id = ?`. If the query uses any OR condition or missing WHERE clause, fix it:
   ```dart
   Stream<List<Transaction>> watchByWallet(int walletId, {int limit = 50, int offset = 0}) =>
       (select(transactions)
             ..where((t) => t.walletId.equals(walletId))
             ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)])
             ..limit(limit, offset: offset))
           .watch();
   ```

2. Read `lib/data/repositories/transaction_repository_impl.dart` — verify `watchByWallet(int walletId)` passes `walletId` to the DAO method without transformation.

3. In `lib/shared/providers/activity_provider.dart`, verify the `activityByWalletProvider` properly filters. The current code at line 76-77 correctly filters transfer entries:
   ```dart
   if (fromEntry.walletId == walletId) transferEntries.add(fromEntry);
   if (toEntry.walletId == walletId) transferEntries.add(toEntry);
   ```
   Verify `txStream` (line 56) is watching `watchByWallet(walletId)` — not `watchAll()`.

4. If the transaction DAO's `watchByWallet` is correct, check if there is a stale `transactionsByWalletProvider` in `lib/shared/providers/transaction_provider.dart` that is being used instead of `activityByWalletProvider`. Verify that the dashboard and wallet detail screen use `activityByWalletProvider(walletId)` — not a different provider.

5. After identifying the root cause, apply the fix. The most likely issue is either:
   - The DAO `watchByWallet` has a bug in its WHERE clause, OR
   - A screen is using the wrong provider (e.g., `recentActivityProvider` which shows ALL accounts instead of `activityByWalletProvider(walletId)`)
</action>

<acceptance_criteria>
- grep -r "activityByWalletProvider" lib/ returns usage in dashboard/wallet screens
- grep "walletId.equals" lib/data/database/daos/transaction_dao.dart confirms wallet filter
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 2: Fix TransferAdapter Synthetic Entry walletId Assignment (D-02)

**Problem:** The `transferToActivities()` function may create synthetic entries with incorrect `walletId` values, causing transfers to appear under the wrong account.

<read_first>
- lib/domain/adapters/transfer_adapter.dart (full file — understand ID assignment)
- lib/domain/entities/transfer_entity.dart (understand fromWalletId/toWalletId)
</read_first>

<action>
1. Verify `lib/domain/adapters/transfer_adapter.dart` lines 28-30 assign `walletId: transfer.fromWalletId` for `fromEntry` and lines 45-47 assign `walletId: transfer.toWalletId` for `toEntry`. This is currently correct.

2. Verify that `TransferEntity` has correct field names: `fromWalletId` and `toWalletId`. Check if the Drift-generated model maps columns correctly:
   - Read `lib/data/database/tables/transfers_table.dart` — confirm column names `from_wallet_id` and `to_wallet_id`
   - Read the transfer entity mapping in `lib/data/repositories/transfer_repository_impl.dart` — verify `fromWalletId` maps to `from_wallet_id` column

3. If the mapping is correct but the data is wrong, add a debug assertion in `transferToActivities()` to validate IDs are positive:
   ```dart
   assert(transfer.fromWalletId > 0, 'fromWalletId must be positive');
   assert(transfer.toWalletId > 0, 'toWalletId must be positive');
   assert(transfer.fromWalletId != transfer.toWalletId, 'from and to must differ');
   ```

4. If no bug is found in the adapter itself, the issue is likely in Task 1 (DAO query). Document findings.
</action>

<acceptance_criteria>
- grep "walletId: transfer.fromWalletId" lib/domain/adapters/transfer_adapter.dart confirms correct from-entry
- grep "walletId: transfer.toWalletId" lib/domain/adapters/transfer_adapter.dart confirms correct to-entry
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 3: Fix Transfer Display — Counterpart Icon and Label (D-03, TXN-04)

**Problem:** Transfer cards do not show the counterpart wallet's icon. Account X's list should show "Transfer to Y" with Y's wallet-type icon, and Account Y's list should show "Received from X" with X's wallet-type icon.

<read_first>
- lib/shared/widgets/lists/transaction_list_section.dart (lines 116-151 — transfer icon/label resolution)
- lib/shared/widgets/cards/transaction_card.dart (lines 79-91 — how transferCounterpartIcon is used)
- lib/domain/adapters/transfer_adapter.dart (counterpartWalletId function)
- lib/features/dashboard/presentation/screens/dashboard_screen.dart (how walletInfoResolver is passed)
</read_first>

<action>
1. In `lib/shared/widgets/lists/transaction_list_section.dart`, lines 122-133, the transfer counterpart resolution already exists. Verify the `walletInfoResolver` is being passed from the dashboard screen. If `walletInfoResolver` is `null`, transfers will render without icons.

2. Read `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — find where `TransactionListSection` is constructed. Verify it passes a `walletInfoResolver` callback. If it does NOT pass one, add it:
   ```dart
   walletInfoResolver: (walletId) {
     final wallet = wallets.where((w) => w.id == walletId).firstOrNull;
     if (wallet == null) return null;
     return (
       icon: AppIcons.walletType(wallet.type),
       name: wallet.name,
     );
   },
   ```

3. In `lib/shared/widgets/cards/transaction_card.dart`, verify line 81 correctly uses `transferCounterpartIcon ?? categoryIcon`. The fallback to `categoryIcon` means if no counterpart icon is provided, it uses the category icon (which for transfers with `categoryId: 0` would be a generic icon). This is correct behavior.

4. Verify the `_amountPrefix` getter at line 55-59 handles transfers correctly. Currently transfers return `''` (empty). For sender entries, the prefix should be `'\u2212'` (minus) and for receiver entries `'+'`. Update:
   ```dart
   String get _amountPrefix {
     if (transaction.type == 'transfer') {
       // Check tags for sender/receiver role
       final tags = transaction.tags;
       if (tags.contains('role:sender')) return '\u2212';
       if (tags.contains('role:receiver')) return '+';
       return '';
     }
     return switch (transaction.type) {
       'income' => '+',
       _ => '\u2212',
     };
   }
   ```

5. In `TransactionCard`, import `transfer_adapter.dart` to use `isTransferSender()`:
   ```dart
   import '../../../domain/adapters/transfer_adapter.dart';
   ```
   Then update the `_amountPrefix` getter to use it:
   ```dart
   String get _amountPrefix => switch (transaction.type) {
     'income' => '+',
     'transfer' => isTransferSender(transaction.tags) ? '\u2212' : '+',
     _ => '\u2212',
   };
   ```
</action>

<acceptance_criteria>
- grep "walletInfoResolver" lib/features/dashboard/presentation/screens/dashboard_screen.dart confirms resolver is passed
- grep "role:sender" lib/shared/widgets/cards/transaction_card.dart confirms transfer sign logic
- grep "transferCounterpartIcon" lib/shared/widgets/cards/transaction_card.dart confirms icon usage
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 4: Verify Category-First Display in TransactionCard (TXN-02)

**Problem:** Category should display first (bold) with title/note as secondary. Need to verify this is working correctly.

<read_first>
- lib/shared/widgets/cards/transaction_card.dart (lines 186-219 — the two-line column)
</read_first>

<action>
1. Verify `lib/shared/widgets/cards/transaction_card.dart` `_CardContent.build()`:
   - Line 192-198: First line should be `categoryName` with `fontWeight: FontWeight.w600` — already correct
   - Line 203-210: Second line should be `transaction.title` with `color: context.colors.outline` — already correct

2. For transfers, verify `categoryName` is overridden by `transferDisplayName` (line 84):
   ```dart
   categoryName: transferDisplayName ?? categoryName,
   ```
   This means transfers show "Transfer to X" as the primary bold text, which is correct.

3. No code changes expected — mark TXN-02 as verified. If the display is wrong, the issue is in how `categoryName` is resolved by the caller (the categoryResolver function). Check that `categoryResolver(0)` (for transfers with categoryId=0) returns a sensible name like "Transfer" rather than an empty string.
</action>

<acceptance_criteria>
- grep "fontWeight: FontWeight.w600" lib/shared/widgets/cards/transaction_card.dart confirms bold category name
- grep "categoryName" lib/shared/widgets/cards/transaction_card.dart confirms category-first display
- grep "transferDisplayName ?? categoryName" lib/shared/widgets/cards/transaction_card.dart confirms transfer override
</acceptance_criteria>

---

## Task 5: Verify Cash Transaction Visibility (TXN-03)

**Problem:** Cash withdrawal/deposit transactions should appear in the relevant bank account's transaction list, not only in "All Accounts."

<read_first>
- lib/shared/providers/activity_provider.dart (activityByWalletProvider — filter logic)
- lib/data/database/daos/transfer_dao.dart (watchByWallet query)
</read_first>

<action>
1. Cash withdrawals and deposits are stored as Transfer records (from bank→cash or cash→bank). The `activityByWalletProvider` uses `transferRepositoryProvider.watchByWallet(walletId)` which queries transfers where `from_wallet_id = walletId OR to_wallet_id = walletId`.

2. Verify `lib/data/database/daos/transfer_dao.dart` `watchByWallet()` query:
   ```dart
   ..where((t) => t.fromWalletId.equals(walletId) | t.toWalletId.equals(walletId))
   ```
   This should already capture cash withdrawals (bank→cash where bank=walletId) and cash deposits (cash→bank where bank=walletId).

3. If a cash withdrawal from Bank A is stored as `fromWalletId=bankA, toWalletId=cashWallet`, then viewing Bank A's list should show it via `fromEntry.walletId == walletId` (line 76). Viewing the cash wallet's list should show it via `toEntry.walletId == walletId` (line 77).

4. If the issue is that cash transactions DON'T appear, the bug is likely in how transfers are displayed — the `transferToActivities()` sets `type: 'transfer'` for cash entries. Verify the transaction list section doesn't filter out `type == 'transfer'` entries.

5. No code changes expected unless a bug is found. Document verification result.
</action>

<acceptance_criteria>
- grep "fromWalletId.equals(walletId) | toWalletId.equals(walletId)" lib/data/database/daos/transfer_dao.dart confirms both-direction filter
- grep "type: 'transfer'" lib/domain/adapters/transfer_adapter.dart confirms transfer entries have correct type
</acceptance_criteria>

---

## Task 6: Verify Correct Account Assignment from Dashboard Carousel (TXN-05)

**Problem:** New transactions should respect the `selectedAccountIdProvider` from the dashboard carousel selection.

<read_first>
- lib/features/transactions/presentation/screens/add_transaction_screen.dart (wallet ID initialization)
- lib/shared/providers/selected_account_provider.dart (selected account provider)
- lib/features/dashboard/presentation/widgets/account_carousel.dart (carousel → selectedAccountIdProvider wiring)
</read_first>

<action>
1. Read `lib/features/transactions/presentation/screens/add_transaction_screen.dart` — find where `_walletId` or similar is initialized. It should read from `selectedAccountIdProvider`:
   ```dart
   final selectedId = ref.read(selectedAccountIdProvider);
   ```

2. Verify `lib/shared/providers/selected_account_provider.dart` exists and contains:
   ```dart
   final selectedAccountIdProvider = StateProvider<int?>((ref) => null);
   ```

3. Verify `lib/features/dashboard/presentation/widgets/account_carousel.dart` writes to `selectedAccountIdProvider` on page change:
   ```dart
   ref.read(selectedAccountIdProvider.notifier).state = walletId;
   ```

4. If AddTransactionScreen does NOT read the selected account, add it:
   - In `initState()` or the equivalent initialization, set the wallet dropdown default:
   ```dart
   _selectedWalletId = ref.read(selectedAccountIdProvider) ?? _defaultWalletId;
   ```

5. Verify the FAB (Floating Action Button) on the dashboard does NOT override the wallet selection when navigating to AddTransactionScreen.
</action>

<acceptance_criteria>
- grep "selectedAccountIdProvider" lib/features/transactions/presentation/screens/add_transaction_screen.dart confirms carousel selection is read
- grep "selectedAccountIdProvider" lib/features/dashboard/presentation/widgets/account_carousel.dart confirms carousel writes selection
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 7: Run Full Analysis and Verify

<read_first>
- (none — this is a verification-only task)
</read_first>

<action>
1. Run `flutter analyze lib/` — must report zero issues.
2. Run `flutter test test/unit/` — ensure no regressions.
3. Verify all 4 requirements are addressed:
   - TXN-02: Category-first display verified
   - TXN-03: Cash transactions visible in account lists
   - TXN-04: Transfer cards show counterpart icon and "Transfer to/from" labels
   - TXN-05: New transactions respect carousel selection
4. Verify all 3 bugs are addressed:
   - D-01/D-02: Per-account transaction lists show correct data
   - D-03: Transfer counterpart icon displays correctly
</action>

<acceptance_criteria>
- flutter analyze lib/ reports "No issues found!"
- flutter test completes with zero failures
</acceptance_criteria>
