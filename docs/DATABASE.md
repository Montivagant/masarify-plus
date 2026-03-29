# Database

Drift ORM (SQLite) with type-safe DAOs, reactive streams, and versioned migrations.

**Schema Version:** 14
**File:** `lib/data/database/app_database.dart`
**Tables:** 14 | **DAOs:** 13

## Tables

| # | Table | Key Columns | Notes |
|---|-------|-------------|-------|
| 1 | `Wallets` | id, name, balance (int piastres), currency, isArchived, isDefault, sortOrder | sortOrder added v13 for drag-and-drop reordering |
| 2 | `Categories` | id, name, nameAr, type (expense/income), icon, color, sortOrder, isDefault | 34 defaults seeded on first launch |
| 3 | `Transactions` | id, walletId, categoryId, amount (int piastres), type, title, date, note | FK to Wallets + Categories |
| 4 | `Transfers` | id, fromWalletId, toWalletId, amount (int piastres), date, note | Never counted as income/expense |
| 5 | `Budgets` | id, categoryId, limitAmount (int piastres), period, startDate | Spending computed from Transactions |
| 6 | `SavingsGoals` | id, name, targetAmount, currentAmount, deadline, isCompleted | Contributions tracked separately |
| 7 | `GoalContributions` | id, goalId, amount, date, note | FK to SavingsGoals |
| 8 | `RecurringRules` | id, walletId, categoryId, amount, frequency, nextDueDate, autoLog, isBill | Bills merged here in v4 migration |
| 9 | `SmsParserLogs` | id, smsHash, sender, body, parsedAmount, status, aiEnrichmentJson | Dedup via SHA-256 hash |
| 10 | `ExchangeRates` | id, fromCurrency, toCurrency, rate, fetchedAt | Cached for offline use |
| 11 | `CategoryMappings` | id, title, categoryId, frequency | Auto-categorization learning table (v12) |
| 12 | `ChatMessages` | id, role, content, actionJson, timestamp | AI chat history |
| 13 | `ParsedEventGroups` | id, groupHash, status | SMS batch deduplication |
| 14 | `SubscriptionRecords` | id, productId, purchaseToken, status, expiryDate, validatedAt | IAP tracking (v14) |

## DAOs

| # | DAO | Table(s) | Key Operations |
|---|-----|----------|----------------|
| 1 | `WalletDao` | Wallets | CRUD, balance update (atomic), reorder, archive/unarchive |
| 2 | `CategoryDao` | Categories | CRUD, reorder, seed defaults |
| 3 | `TransactionDao` | Transactions | CRUD, filter (date/category/wallet/type), pagination, sum by type/month |
| 4 | `TransferDao` | Transfers | CRUD, list by wallet |
| 5 | `BudgetDao` | Budgets | CRUD, spent computation from Transactions stream |
| 6 | `GoalDao` | SavingsGoals, GoalContributions | CRUD for both, contribution total |
| 7 | `RecurringRuleDao` | RecurringRules | CRUD, overdue detection, next-due scheduling |
| 8 | `SmsParserLogDao` | SmsParserLogs | CRUD, dedup check, status updates |
| 9 | `ExchangeRateDao` | ExchangeRates | Upsert, lookup by currency pair |
| 10 | `CategoryMappingDao` | CategoryMappings | Learn title→category, lookup by title |
| 11 | `ChatMessageDao` | ChatMessages | CRUD, list by conversation |
| 12 | `ParsedEventGroupDao` | ParsedEventGroups | CRUD, dedup check |
| 13 | `SubscriptionRecordDao` | SubscriptionRecords | CRUD, active subscription check, expiry validation |

## Indices

| Index | Table | Columns | Purpose |
|-------|-------|---------|---------|
| `idx_transactions_wallet_date` | Transactions | walletId, date | Fast wallet-filtered queries |
| `idx_recurring_rules_wallet` | RecurringRules | walletId | Fast recurring rule lookup |

## Migration History

| Version | Change |
|---------|--------|
| v1 | Initial schema (10 tables) |
| v2 | `aiEnrichmentJson` column added to SmsParserLogs |
| v4 | Bills table merged into RecurringRules (`isBill` flag added) |
| v12 | CategoryMappings table added (auto-categorization learning) |
| v13 | `sortOrder` column added to Wallets (drag-and-drop reordering) |
| v14 | SubscriptionRecords table added (IAP tracking) |

## Key Design Rules

- **Money = integer piastres.** `100 EGP = 10000`. Never `double`. Use `MoneyFormatter` for display.
- **Transfers are NOT income/expense.** They live in their own table and never inflate analytics.
- **Archived wallets are invisible.** Excluded from balance totals, transaction queries, analytics, and AI context.
- **All queries are reactive.** DAOs return `Stream<T>` which propagate through providers to the UI.
- **Migrations are versioned.** Every schema change bumps `schemaVersion` and adds a migration in `onUpgrade`.
- **Generated files are protected.** Never edit `*.g.dart` — edit the source `.dart` and run `build_runner`.
