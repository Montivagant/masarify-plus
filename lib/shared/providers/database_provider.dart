import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/budget_dao.dart';
import '../../data/database/daos/category_dao.dart';
import '../../data/database/daos/chat_message_dao.dart';
import '../../data/database/daos/goal_dao.dart';
import '../../data/database/daos/recurring_rule_dao.dart';
import '../../data/database/daos/sms_parser_log_dao.dart';
import '../../data/database/daos/transaction_dao.dart';
import '../../data/database/daos/transfer_dao.dart';
import '../../data/database/daos/wallet_dao.dart';

/// Single AppDatabase instance for the app lifetime.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── DAO providers (all derived from databaseProvider) ────────────────────────

final walletDaoProvider = Provider<WalletDao>(
  (ref) => ref.watch(databaseProvider).walletDao,
);

final categoryDaoProvider = Provider<CategoryDao>(
  (ref) => ref.watch(databaseProvider).categoryDao,
);

final transactionDaoProvider = Provider<TransactionDao>(
  (ref) => ref.watch(databaseProvider).transactionDao,
);

final transferDaoProvider = Provider<TransferDao>(
  (ref) => ref.watch(databaseProvider).transferDao,
);

final budgetDaoProvider = Provider<BudgetDao>(
  (ref) => ref.watch(databaseProvider).budgetDao,
);

final goalDaoProvider = Provider<GoalDao>(
  (ref) => ref.watch(databaseProvider).goalDao,
);

final recurringRuleDaoProvider = Provider<RecurringRuleDao>(
  (ref) => ref.watch(databaseProvider).recurringRuleDao,
);

final smsParserLogDaoProvider = Provider<SmsParserLogDao>(
  (ref) => ref.watch(databaseProvider).smsParserLogDao,
);

final chatMessageDaoProvider = Provider<ChatMessageDao>(
  (ref) => ref.watch(databaseProvider).chatMessageDao,
);
