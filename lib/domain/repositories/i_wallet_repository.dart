import '../entities/wallet_entity.dart';

abstract interface class IWalletRepository {
  /// Reactive stream of all non-archived wallets, ordered by displayOrder.
  Stream<List<WalletEntity>> watchAll();

  Future<List<WalletEntity>> getAll();

  Future<WalletEntity?> getById(int id);

  Stream<WalletEntity?> watchById(int id);

  /// Returns the new wallet's id.
  Future<int> create({
    required String name,
    required String type,
    required int initialBalance,
    String currencyCode = 'EGP',
    String iconName = 'wallet',
    String colorHex = '#1A6B5E',
    int displayOrder = 0,
    List<String> linkedSenders = const [],
    bool isDefaultAccount = false,
  });

  Future<bool> update(WalletEntity wallet);

  Future<bool> archive(int id);

  /// Unarchive a wallet (set isArchived = false).
  Future<bool> unarchive(int id);

  /// All wallets INCLUDING archived — for the Wallets management screen.
  Stream<List<WalletEntity>> watchAllIncludingArchived();

  /// Check if a wallet with [name] already exists (optionally excluding [excludeId]).
  Future<bool> existsByName(String name, {int? excludeId});

  /// Check if a wallet has transactions or transfers referencing it.
  Future<bool> hasReferences(int walletId);

  /// Adjust balance by [deltaPiastres] within a Drift transaction.
  Future<void> adjustBalance(int id, int deltaPiastres);

  /// Total balance across all non-archived wallets (piastres).
  Future<int> getTotalBalance();

  /// Reactive stream of total balance across all non-archived wallets.
  Stream<int> watchTotalBalance();

  /// WS3d: Add a sender address to a wallet's linkedSenders (if not present).
  Future<void> addLinkedSender(int walletId, String sender);

  /// The mandatory Physical Cash system wallet.
  Future<WalletEntity?> getSystemWallet();

  /// Reactive stream of the system wallet.
  Stream<WalletEntity?> watchSystemWallet();

  /// Ensure the Physical Cash system wallet exists. Returns its id.
  /// [localizedName] overrides the default English name for l10n support.
  Future<int> ensureSystemWalletExists({String? localizedName});

  /// The mandatory default bank account (fallback for transaction assignment).
  Future<WalletEntity?> getDefaultAccount();

  /// Reactive stream of the default account.
  Stream<WalletEntity?> watchDefaultAccount();

  /// Batch-update sort orders for carousel drag-and-drop reordering.
  Future<void> updateSortOrders(List<({int id, int sortOrder})> updates);

  /// All wallets INCLUDING archived — one-shot Future variant.
  Future<List<WalletEntity>> getAllIncludingArchived();

  /// Ensure a default bank account exists. Returns its id.
  /// [localizedName] overrides the default English name for l10n support.
  Future<int> ensureDefaultAccountExists({String? localizedName});
}
