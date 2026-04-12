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
  // M-1 fix: use allWalletsProvider so archived wallet names still resolve
  // in transfer labels (e.g. "CIB -> NBE" even if NBE is archived).
  final wallets = ref.watch(allWalletsProvider).valueOrNull ?? [];

  final walletNames = {for (final w in wallets) w.id: w.name};
  final walletCurrencies = {for (final w in wallets) w.id: w.currencyCode};

  return Rx.combineLatest2(
    txRepo.watchAll(limit: 500),
    xferRepo.watchAll(),
    (List<TransactionEntity> txList, transfers) {
      final transferEntries = transfersToActivities(
        transfers,
        walletNames: walletNames,
        walletCurrencies: walletCurrencies,
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
  // M-1 fix: use allWalletsProvider so archived wallet names still resolve
  // in transfer labels.
  final wallets = ref.watch(allWalletsProvider).valueOrNull ?? [];

  final walletNames = {for (final w in wallets) w.id: w.name};
  final walletCurrencies = {for (final w in wallets) w.id: w.currencyCode};

  return Rx.combineLatest2(
    txRepo.watchByWallet(walletId),
    xferRepo.watchByWallet(walletId),
    (List<TransactionEntity> txList, transfers) {
      final transferEntries = transfersToActivities(
        transfers,
        filterWalletId: walletId,
        walletNames: walletNames,
        walletCurrencies: walletCurrencies,
      );
      final merged = [...txList, ...transferEntries]
        ..sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return merged;
    },
  );
});
