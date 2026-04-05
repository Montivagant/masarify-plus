import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/wallet_entity.dart';
import 'repository_providers.dart';

/// Reactive list of all non-archived wallets.
final walletsProvider = StreamProvider<List<WalletEntity>>(
  (ref) => ref.watch(walletRepositoryProvider).watchAll(),
);

/// All wallets INCLUDING archived — for the Wallets management screen.
final allWalletsProvider = StreamProvider<List<WalletEntity>>(
  (ref) => ref.watch(walletRepositoryProvider).watchAllIncludingArchived(),
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
