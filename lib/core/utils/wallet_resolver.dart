import '../../domain/entities/wallet_entity.dart';

/// Resolves which wallet a parsed SMS/notification belongs to
/// by matching sender address against wallets' linkedSenders.
///
/// Pure utility — no Flutter/Drift imports (safe for domain layer).
abstract final class WalletResolver {
  /// Returns the wallet ID whose linkedSenders contain a case-insensitive
  /// match for [sender]. Returns `null` if no wallet matches.
  static int? resolve(String sender, List<WalletEntity> wallets) {
    final senderLower = sender.toLowerCase();
    for (final wallet in wallets) {
      if (wallet.isArchived) continue;
      for (final pattern in wallet.linkedSenders) {
        if (senderLower.contains(pattern.toLowerCase())) {
          return wallet.id;
        }
      }
    }
    return null;
  }
}
