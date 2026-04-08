import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/budget_dao.dart';
import 'daos/category_dao.dart';
import 'daos/category_mapping_dao.dart';
import 'daos/chat_message_dao.dart';
import 'daos/goal_dao.dart';
import 'daos/parsed_event_group_dao.dart';
import 'daos/recurring_rule_dao.dart';
import 'daos/sms_parser_log_dao.dart';
import 'daos/subscription_record_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/transfer_dao.dart';
import 'daos/wallet_dao.dart';
import 'tables/budgets_table.dart';
import 'tables/categories_table.dart';
import 'tables/category_mappings_table.dart';
import 'tables/chat_messages_table.dart';
import 'tables/goal_contributions_table.dart';
import 'tables/parsed_event_groups_table.dart';
import 'tables/recurring_rules_table.dart';
import 'tables/savings_goals_table.dart';
import 'tables/sms_parser_logs_table.dart';
import 'tables/subscription_records_table.dart';
import 'tables/transactions_table.dart';
import 'tables/transfers_table.dart';
import 'tables/wallets_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Wallets,
    Categories,
    Transactions,
    Transfers,
    Budgets,
    SavingsGoals,
    GoalContributions,
    RecurringRules,
    SmsParserLogs,
    CategoryMappings,
    ChatMessages,
    ParsedEventGroups,
    SubscriptionRecords,
  ],
  daos: [
    WalletDao,
    CategoryDao,
    TransactionDao,
    TransferDao,
    BudgetDao,
    GoalDao,
    RecurringRuleDao,
    SmsParserLogDao,
    CategoryMappingDao,
    ChatMessageDao,
    ParsedEventGroupDao,
    SubscriptionRecordDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Current schema version — referenced by both migrations and backup service.
  static const int currentSchemaVersion = 18;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(smsParserLogs, smsParserLogs.aiEnrichmentJson);
          }
          if (from < 3) {
            await m.addColumn(budgets, budgets.createdAt);
            // Clean up duplicate budgets before adding unique index
            await customStatement('''
              DELETE FROM budgets WHERE id NOT IN (
                SELECT MIN(id) FROM budgets
                GROUP BY category_id, year, month
              )
            ''');
          }
          if (from < 4) {
            // Add bill-tracking columns to recurring_rules
            await m.addColumn(recurringRules, recurringRules.isPaid);
            await m.addColumn(recurringRules, recurringRules.paidAt);
            await m.addColumn(
              recurringRules,
              recurringRules.linkedTransactionId,
            );

            // Remove autoLog column — SQLite >=3.35 supports ALTER TABLE DROP COLUMN
            // but to be safe with older Android devices, just leave it (Drift ignores unmapped columns).
            // The column was already removed from the table definition above,
            // so Drift won't generate code for it.

            // Migrate bills -> recurring_rules (if bills table still exists from older schema)
            final billsTables = await m.database
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type='table' AND name='bills'",
                )
                .get();
            if (billsTables.isNotEmpty) {
              final billRows = await customSelect('SELECT * FROM bills').get();
              for (final row in billRows) {
                await customStatement(
                  'INSERT INTO recurring_rules (wallet_id, category_id, amount, type, title, frequency, start_date, end_date, next_due_date, is_paid, paid_at, linked_transaction_id, is_active, last_processed_date) '
                  "VALUES (?, ?, ?, 'expense', ?, 'once', ?, NULL, ?, ?, ?, ?, 1, NULL)",
                  [
                    row.read<int>('wallet_id'),
                    row.read<int>('category_id'),
                    row.read<int>('amount'),
                    row.read<String>('name'),
                    row.read<DateTime>('due_date').millisecondsSinceEpoch,
                    row.read<DateTime>('due_date').millisecondsSinceEpoch,
                    row.read<bool>('is_paid') ? 1 : 0,
                    row
                        .readNullable<DateTime>('paid_at')
                        ?.millisecondsSinceEpoch,
                    row.readNullable<int>('linked_transaction_id'),
                  ],
                );
              }
              // Drop bills table after migration
              await customStatement('DROP TABLE IF EXISTS bills');
            }
          }
          if (from < 5) {
            await m.createTable(categoryMappings);
          }
          if (from < 6) {
            await m.createTable(chatMessages);
          }
          if (from < 7) {
            await m.addColumn(wallets, wallets.linkedSenders);
          }
          if (from < 8) {
            // WS3: Semantic fingerprint deduplication.
            await m.createTable(parsedEventGroups);
            await m.addColumn(
              smsParserLogs,
              smsParserLogs.semanticFingerprint,
            );
            // WS3b: Transfer link for ATM withdrawals.
            await m.addColumn(smsParserLogs, smsParserLogs.transferId);
          }
          if (from < 9) {
            // A1: Add isSystemWallet flag to wallets.
            await m.addColumn(wallets, wallets.isSystemWallet);

            // A1: Add walletId FK to goal_contributions for deduction tracking.
            await m.addColumn(goalContributions, goalContributions.walletId);

            // A1: Migrate 'cash' wallets → 'physical_cash' and flag system wallet.
            final cashWallets = await customSelect(
              "SELECT id FROM wallets WHERE type = 'cash' ORDER BY id ASC",
            ).get();

            if (cashWallets.isNotEmpty) {
              // Mark first cash wallet as the system wallet.
              await customStatement(
                "UPDATE wallets SET is_system_wallet = 1, type = 'physical_cash' "
                'WHERE id = ?',
                [cashWallets.first.read<int>('id')],
              );
              // Rename remaining cash wallets (if any).
              await customStatement(
                "UPDATE wallets SET type = 'physical_cash' WHERE type = 'cash'",
              );
            } else {
              // No cash wallet — create the mandatory system wallet.
              await customStatement(
                'INSERT INTO wallets (name, type, balance, currency_code, '
                'icon_name, color_hex, is_archived, display_order, '
                "is_system_wallet, linked_senders) VALUES ('Cash', "
                "'physical_cash', 0, 'EGP', 'wallet', '#1A6B5E', 0, -1, 1, "
                "'[]')",
              );
            }

            // A1: Migrate 'savings' wallets → 'bank' (savings type removed).
            await customStatement(
              "UPDATE wallets SET type = 'bank' WHERE type = 'savings'",
            );
          }
          if (from < 10) {
            // Seed "ATM" category for cash withdrawal/deposit transactions.
            await customStatement(
              'INSERT OR IGNORE INTO categories '
              '(name, name_ar, icon_name, type, is_default, display_order) '
              "VALUES ('ATM', 'صراف آلي', 'bank', 'both', 1, 99)",
            );
          }
          if (from < 11) {
            // Add isDefaultAccount flag to wallets.
            await m.addColumn(wallets, wallets.isDefaultAccount);

            // Ensure exactly one non-system wallet is marked as default.
            final existing = await customSelect(
              'SELECT id FROM wallets WHERE is_default_account = 1',
            ).get();
            if (existing.isEmpty) {
              // Mark the first non-system bank wallet as default, or create one.
              final banks = await customSelect(
                'SELECT id FROM wallets '
                'WHERE is_system_wallet = 0 AND is_archived = 0 '
                'ORDER BY id ASC LIMIT 1',
              ).get();
              if (banks.isNotEmpty) {
                await customStatement(
                  'UPDATE wallets SET is_default_account = 1 WHERE id = ?',
                  [banks.first.read<int>('id')],
                );
              } else {
                await customStatement(
                  'INSERT INTO wallets (name, type, balance, currency_code, '
                  'icon_name, color_hex, is_archived, display_order, '
                  'is_system_wallet, is_default_account, linked_senders) '
                  "VALUES ('Default', 'bank', 0, 'EGP', 'bank', '#1A6B5E', "
                  "0, 0, 0, 1, '[]')",
                );
              }
            }
          }
          if (from < 12) {
            // Seed 12 new expense categories for existing users.
            // Uses INSERT OR IGNORE to prevent duplicates on fresh installs
            // (where CategorySeed already inserted them).
            const newCats = [
              "('Installments', 'أقساط', 'credit_score', '#E67E22', 'expense', 'needs', 1, 0, 17)",
              "('Insurance', 'تأمين', 'shield', '#2ECC71', 'expense', 'needs', 1, 0, 18)",
              "('Fuel & Parking', 'وقود ومواقف', 'local_gas_station', '#E74C3C', 'expense', 'needs', 1, 0, 19)",
              "('Maintenance', 'صيانة', 'build', '#95A5A6', 'expense', 'needs', 1, 0, 20)",
              "('Kids & Family', 'أطفال وعائلة', 'child_care', '#F39C12', 'expense', 'wants', 1, 0, 21)",
              "('Pets', 'حيوانات أليفة', 'pets', '#8E44AD', 'expense', 'wants', 1, 0, 22)",
              "('Café & Coffee', 'كافيه وقهوة', 'coffee', '#6F4E37', 'expense', 'wants', 1, 0, 23)",
              "('Home Supplies', 'مستلزمات منزلية', 'weekend', '#1ABC9C', 'expense', 'wants', 1, 0, 24)",
              "('Charity & Zakat', 'صدقة وزكاة', 'volunteer_activism', '#27AE60', 'expense', 'wants', 1, 0, 25)",
              "('ATM & Bank Fees', 'رسوم بنكية', 'account_balance', '#34495E', 'expense', 'needs', 1, 0, 26)",
              "('Delivery & Shipping', 'توصيل وشحن', 'local_shipping', '#D35400', 'expense', 'wants', 1, 0, 27)",
              "('Savings Transfer', 'تحويل للادخار', 'savings', '#16A085', 'expense', 'wants', 1, 0, 28)",
            ];
            for (final values in newCats) {
              await customStatement(
                'INSERT OR IGNORE INTO categories '
                '(name, name_ar, icon_name, color_hex, type, group_type, '
                'is_default, is_archived, display_order) VALUES $values',
              );
            }

            // Shift existing default income categories to order 29-34.
            await customStatement(
              'UPDATE categories SET display_order = display_order + 12 '
              'WHERE type = \'income\' AND is_default = 1',
            );
          }
          if (from < 13) {
            // Add sortOrder column for carousel drag-and-drop reordering.
            await m.addColumn(wallets, wallets.sortOrder);
            // Initialize sortOrder to match existing id ordering.
            await customStatement('UPDATE wallets SET sort_order = id');
          }
          if (from < 14) {
            // Create subscription_records table for IAP purchase tracking.
            await m.createTable(subscriptionRecords);
          }
          if (from < 15) {
            // v15: Added ON DELETE (RESTRICT/SET NULL/CASCADE) to FK columns
            // in table definitions. SQLite does not support altering FK
            // constraints on existing tables, so these only take effect on
            // fresh installs via onCreate. Existing users are protected by
            // repo-level cleanup (category archive, goal delete, etc.).
          }
          if (from < 16) {
            // C2 fix: v16 — FK enforcement for pre-v15 users.
            //
            // Ideally we would rebuild tables with proper FK constraints using
            // the SQLite table-rebuild pattern (create temp → copy → drop →
            // rename). However, this is risky for a production app with 14
            // tables and complex FK relationships — a failed rebuild could
            // cause data loss. Pre-v15 users are protected by repo-level
            // enforcement (validation in repositories, cascade deletes in
            // repository methods). Fresh v15+ installs already have proper
            // FK constraints from CREATE TABLE.
            //
            // The composite index below is also created in _createIndexes()
            // (idempotent), but including it here documents the intent for
            // the v16 migration.
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_transactions_category_date '
              'ON transactions(category_id, transaction_date DESC)',
            );
          }
          if (from < 17) {
            // v17: Remove unused exchange_rates stub table (no app logic was
            // ever built on top of it). DROP IF EXISTS is safe for users
            // who never had the table (fresh installs skip this path).
            await customStatement('DROP TABLE IF EXISTS exchange_rates');
          }
          if (from < 18) {
            await customStatement(
              "ALTER TABLE budgets ADD COLUMN period TEXT NOT NULL DEFAULT 'monthly'",
            );
          }
          // Indexes are idempotent (IF NOT EXISTS) — always safe to re-run.
          await _createIndexes();
        },
        // C1 fix: enable FK enforcement — without this, .references()
        // declarations are cosmetic and orphaned rows are silently accepted.
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  /// Shared index creation for both onCreate and onUpgrade paths.
  Future<void> _createIndexes() async {
    // Transactions
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_date '
      'ON transactions(transaction_date DESC)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_wallet '
      'ON transactions(wallet_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_category '
      'ON transactions(category_id)',
    );
    // Transfers
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transfers_from_wallet '
      'ON transfers(from_wallet_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transfers_to_wallet '
      'ON transfers(to_wallet_id)',
    );
    // Budgets
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_budgets_year_month '
      'ON budgets(year, month)',
    );
    // uniqueKeys on Budgets only applies to CREATE TABLE (fresh installs).
    // Upgraded databases need this explicit index to enforce the constraint.
    // v18: includes period column to support daily/weekly/monthly/yearly budgets.
    await customStatement(
      'DROP INDEX IF EXISTS idx_budgets_cat_year_month',
    );
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_budgets_cat_year_month_period '
      'ON budgets(category_id, year, month, period)',
    );
    // Goal contributions
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_goal_contributions_goal_id '
      'ON goal_contributions(goal_id)',
    );
    // Category mappings
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_category_mappings_pattern '
      'ON category_mappings(title_pattern)',
    );
    // Chat messages
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at '
      'ON chat_messages(created_at)',
    );
    // Parsed event groups — fingerprint lookup
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_parsed_event_groups_fingerprint '
      'ON parsed_event_groups(semantic_fingerprint)',
    );
    // Recurring rules — scheduler queries by due date
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_recurring_rules_due '
      'ON recurring_rules(next_due_date) WHERE is_active = 1',
    );
    // SMS parser logs — pending status filter
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_sms_logs_status '
      'ON sms_parser_logs(parsed_status)',
    );
    // Transfers — order by date
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transfers_date '
      'ON transfers(transfer_date DESC)',
    );
    // Only one system wallet allowed
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_wallets_system '
      'ON wallets(is_system_wallet) WHERE is_system_wallet = 1',
    );
    // Only one default account allowed
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_wallets_default '
      'ON wallets(is_default_account) WHERE is_default_account = 1',
    );
    // Composite index for "recent transactions per wallet" queries.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_wallet_date '
      'ON transactions(wallet_id, transaction_date DESC)',
    );
    // Recurring rules by wallet — for "all rules for this wallet" queries.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_recurring_rules_wallet '
      'ON recurring_rules(wallet_id)',
    );
    // H4 fix: composite index for sumByCategoryAndMonth budget progress queries.
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_transactions_category_date '
      'ON transactions(category_id, transaction_date DESC)',
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'masarify_db');
  }
}
