import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

import '../../domain/adapters/transfer_adapter.dart';
import '../../domain/entities/transaction_entity.dart';
import 'repository_providers.dart';
import 'wallet_provider.dart';

/// Unified activity stream: merges transactions + synthetic transfer entries,
/// sorted by date descending. Shows ALL accounts.
///
/// This is the single source of truth for "all recent activity" on the
/// dashboard when no specific account is selected.
final recentActivityProvider = StreamProvider<List<TransactionEntity>>((ref) {
  final txRepo = ref.watch(transactionRepositoryProvider);
  final xferRepo = ref.watch(transferRepositoryProvider);
  final wallets = ref.watch(walletsProvider).valueOrNull ?? [];

  final walletNames = {for (final w in wallets) w.id: w.name};

  return Rx.combineLatest2(
    txRepo.watchAll(),
    xferRepo.watchAll(),
    (List<TransactionEntity> txList, transfers) {
      final transferEntries = transfersToActivities(
        transfers,
        walletNames: walletNames,
      );
      final merged = [...txList, ...transferEntries]
        ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return merged;
    },
  );
});

/// Unified activity stream for a specific wallet: merges transactions +
/// synthetic transfer entries that involve this wallet, sorted by date desc.
///
/// Used by dashboard (per-account carousel) and wallet detail screen.
final activityByWalletProvider =
    StreamProvider.family<List<TransactionEntity>, int>((ref, walletId) {
  final txRepo = ref.watch(transactionRepositoryProvider);
  final xferRepo = ref.watch(transferRepositoryProvider);
  final wallets = ref.watch(walletsProvider).valueOrNull ?? [];

  final walletNames = {for (final w in wallets) w.id: w.name};

  return Rx.combineLatest2(
    txRepo.watchByWallet(walletId),
    xferRepo.watchByWallet(walletId),
    (List<TransactionEntity> txList, transfers) {
      final transferEntries = transfersToActivities(
        transfers,
        filterWalletId: walletId,
        walletNames: walletNames,
      );
      final merged = [...txList, ...transferEntries]
        ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return merged;
    },
  );
});
