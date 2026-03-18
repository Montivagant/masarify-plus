import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/wallet_entity.dart';
import 'goal_provider.dart';
import 'repository_providers.dart';

/// Reactive list of all non-archived wallets.
final walletsProvider = StreamProvider<List<WalletEntity>>(
  (ref) => ref.watch(walletRepositoryProvider).watchAll(),
);

/// Single wallet by id — null if not found or archived.
final walletByIdProvider = StreamProvider.family<WalletEntity?, int>((ref, id) {
  return ref.watch(walletRepositoryProvider).watchById(id);
});

/// H4 fix: reactive stream of total balance — auto-updates after mutations.
final totalBalanceProvider = StreamProvider<int>(
  (ref) => ref.watch(walletRepositoryProvider).watchTotalBalance(),
);

/// The mandatory Physical Cash system wallet.
final systemWalletProvider = StreamProvider<WalletEntity?>(
  (ref) => ref.watch(walletRepositoryProvider).watchSystemWallet(),
);

/// Total amount allocated to active goals (sum of currentAmount piastres).
final totalInGoalsProvider = Provider<int>((ref) {
  final goals = ref.watch(activeGoalsProvider).valueOrNull ?? [];
  return goals.fold<int>(0, (sum, g) => sum + g.currentAmount);
});

/// Available balance = total - in goals.
final availableBalanceProvider = Provider<int>((ref) {
  final total = ref.watch(totalBalanceProvider).valueOrNull ?? 0;
  final inGoals = ref.watch(totalInGoalsProvider);
  return total - inGoals;
});
