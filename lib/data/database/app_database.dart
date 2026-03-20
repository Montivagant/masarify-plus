import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/budget_dao.dart';
import 'daos/category_dao.dart';
import 'daos/category_mapping_dao.dart';
import 'daos/chat_message_dao.dart';
import 'daos/exchange_rate_dao.dart';
import 'daos/goal_dao.dart';
import 'daos/parsed_event_group_dao.dart';
import 'daos/recurring_rule_dao.dart';
import 'daos/sms_parser_log_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/transfer_dao.dart';
import 'daos/wallet_dao.dart';
import 'tables/budgets_table.dart';
import 'tables/categories_table.dart';
import 'tables/category_mappings_table.dart';
import 'tables/chat_messages_table.dart';
import 'tables/exchange_rates_table.dart';
import 'tables/goal_contributions_table.dart';
import 'tables/parsed_event_groups_table.dart';
import 'tables/recurring_rules_table.dart';
import 'tables/savings_goals_table.dart';
import 'tables/sms_parser_logs_table.dart';
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
    ExchangeRates,
    CategoryMappings,
    ChatMessages,
    ParsedEventGroups,
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
    ExchangeRateDao,
    CategoryMappingDao,
    ChatMessageDao,
    ParsedEventGroupDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 11;

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
            try {
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
            } catch (_) {
              // Bills table may not exist on fresh installs — that's fine
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
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_budgets_cat_year_month '
      'ON budgets(category_id, year, month)',
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
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'masarify_db');
  }
}
