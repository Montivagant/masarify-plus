import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/bill_repository_impl.dart';
import '../../data/repositories/budget_repository_impl.dart';
import '../../data/repositories/category_repository_impl.dart';
import '../../data/repositories/goal_repository_impl.dart';
import '../../data/repositories/recurring_rule_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/transfer_repository_impl.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../data/services/backup_service_impl.dart';
import '../../data/services/pdf_export_service.dart';
import '../../domain/repositories/i_bill_repository.dart';
import '../../domain/repositories/i_budget_repository.dart';
import '../../domain/repositories/i_category_repository.dart';
import '../../domain/repositories/i_goal_repository.dart';
import '../../domain/repositories/i_recurring_rule_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../domain/repositories/i_transfer_repository.dart';
import '../../domain/repositories/i_wallet_repository.dart';
import 'database_provider.dart';

final walletRepositoryProvider = Provider<IWalletRepository>(
  (ref) => WalletRepositoryImpl(ref.watch(walletDaoProvider)),
);

final categoryRepositoryProvider = Provider<ICategoryRepository>(
  (ref) => CategoryRepositoryImpl(
    ref.watch(categoryDaoProvider),
    ref.watch(databaseProvider),
  ),
);

final transactionRepositoryProvider = Provider<ITransactionRepository>(
  (ref) => TransactionRepositoryImpl(
    ref.watch(transactionDaoProvider),
    ref.watch(walletDaoProvider),
    ref.watch(databaseProvider),
    ref.watch(categoryDaoProvider),
  ),
);

final transferRepositoryProvider = Provider<ITransferRepository>(
  (ref) => TransferRepositoryImpl(
    ref.watch(transferDaoProvider),
    ref.watch(walletDaoProvider),
    ref.watch(databaseProvider),
  ),
);

final budgetRepositoryProvider = Provider<IBudgetRepository>(
  (ref) => BudgetRepositoryImpl(
    ref.watch(budgetDaoProvider),
    ref.watch(transactionDaoProvider),
    ref.watch(walletDaoProvider),
  ),
);

final goalRepositoryProvider = Provider<IGoalRepository>(
  (ref) => GoalRepositoryImpl(
    ref.watch(goalDaoProvider),
    ref.watch(databaseProvider),
  ),
);

final recurringRuleRepositoryProvider = Provider<IRecurringRuleRepository>(
  (ref) => RecurringRuleRepositoryImpl(ref.watch(recurringRuleDaoProvider)),
);

final billRepositoryProvider = Provider<IBillRepository>(
  (ref) => BillRepositoryImpl(
    ref.watch(billDaoProvider),
    ref.watch(transactionDaoProvider),
    ref.watch(walletDaoProvider),
    ref.watch(databaseProvider),
  ),
);

final backupServiceProvider = Provider<BackupServiceImpl>(
  (ref) => BackupServiceImpl(ref.watch(databaseProvider)),
);

final pdfExportServiceProvider = Provider<PdfExportService>(
  (ref) => PdfExportService(ref.watch(databaseProvider)),
);
