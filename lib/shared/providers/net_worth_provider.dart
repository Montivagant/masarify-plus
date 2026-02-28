import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'wallet_provider.dart';

/// Net worth breakdown computed from wallet balances.
class NetWorthData {
  const NetWorthData({
    required this.assets,
    required this.liabilities,
    required this.netWorth,
  });

  /// Sum of non-credit-card wallet balances (piastres).
  final int assets;

  /// Sum of credit card wallet balances (piastres, positive = debt).
  final int liabilities;

  /// assets - liabilities (piastres).
  final int netWorth;
}

/// Computes net worth from all non-archived wallets.
/// Assets = cash + bank + mobile_wallet + savings balances.
/// Liabilities = credit_card balances (treated as debt).
final netWorthProvider = Provider<AsyncValue<NetWorthData>>((ref) {
  final walletsAsync = ref.watch(walletsProvider);

  return walletsAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (wallets) {
      int assets = 0;
      int liabilities = 0;

      for (final w in wallets) {
        if (w.type == 'credit_card') {
          // M19 fix: negative CC balance = debt (liability),
          // positive CC balance (overpaid) = asset.
          if (w.balance < 0) {
            liabilities += w.balance.abs();
          } else {
            assets += w.balance;
          }
        } else {
          assets += w.balance;
        }
      }

      return AsyncData(
        NetWorthData(
          assets: assets,
          liabilities: liabilities,
          netWorth: assets - liabilities,
        ),
      );
    },
  );
});
