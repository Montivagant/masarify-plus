import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'daos/budget_dao.dart';
import 'daos/category_dao.dart';
import 'daos/exchange_rate_dao.dart';
import 'daos/goal_dao.dart';
import 'daos/recurring_rule_dao.dart';
import 'daos/sms_parser_log_dao.dart';
import 'daos/transaction_dao.dart';
import 'daos/transfer_dao.dart';
import 'daos/wallet_dao.dart';
import 'tables/budgets_table.dart';
import 'tables/categories_table.dart';
import 'tables/exchange_rates_table.dart';
import 'tables/goal_contributions_table.dart';
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

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
              final billRows =
                  await customSelect('SELECT * FROM bills').get();
              for (final row in billRows) {
                await customStatement(
                  'INSERT INTO recurring_rules (wallet_id, category_id, amount, type, title, frequency, start_date, end_date, next_due_date, is_paid, paid_at, linked_transaction_id, is_active, last_processed_date) '
                  "VALUES (?, ?, ?, 'expense', ?, 'once', ?, ?, ?, ?, ?, ?, 1, NULL)",
                  [
                    row.read<int>('wallet_id'),
                    row.read<int>('category_id'),
                    row.read<int>('amount'),
                    row.read<String>('name'),
                    row.read<DateTime>('due_date').millisecondsSinceEpoch,
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
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_budgets_cat_year_month '
      'ON budgets(category_id, year, month)',
    );
    // Goal contributions
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_goal_contributions_goal_id '
      'ON goal_contributions(goal_id)',
    );
  }

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'masarify_db');
  }
}
