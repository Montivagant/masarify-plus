import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/transfer_entity.dart';
import 'repository_providers.dart';
import 'wallet_provider.dart';

/// Single transfer by id — auto-invalidates when wallets change (transfer
/// mutations always adjust wallet balances, so walletsProvider re-fires).
final transferByIdProvider =
    FutureProvider.autoDispose.family<TransferEntity?, int>((ref, id) {
  ref.watch(walletsProvider);
  return ref.read(transferRepositoryProvider).getById(id);
});
