import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'wallet_provider.dart';

/// Index in the carousel: 0 = total (all accounts), 1+ = specific account.
final selectedAccountIndexProvider = StateProvider<int>((ref) => 0);

/// Derived: null = show all, int = specific wallet ID.
final selectedAccountIdProvider = Provider<int?>((ref) {
  final index = ref.watch(selectedAccountIndexProvider);
  if (index == 0) return null;
  final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
  if (index - 1 < wallets.length) return wallets[index - 1].id;
  return null;
});
