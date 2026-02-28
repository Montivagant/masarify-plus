import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/wallet_entity.dart';
import 'repository_providers.dart';

/// Reactive list of all non-archived wallets.
final walletsProvider = StreamProvider<List<WalletEntity>>(
  (ref) => ref.watch(walletRepositoryProvider).watchAll(),
);

/// Single wallet by id — null if not found or archived.
final walletByIdProvider =
    StreamProvider.family<WalletEntity?, int>((ref, id) {
  return ref.watch(walletRepositoryProvider).watchById(id);
});

/// H4 fix: reactive stream of total balance — auto-updates after mutations.
final totalBalanceProvider = StreamProvider<int>(
  (ref) => ref.watch(walletRepositoryProvider).watchTotalBalance(),
);
