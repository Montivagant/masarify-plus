import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/i_wallet_repository.dart';
import '../database/app_database.dart';
import '../database/daos/wallet_dao.dart';

class WalletRepositoryImpl implements IWalletRepository {
  const WalletRepositoryImpl(this._dao, this._db);

  final WalletDao _dao;
  final AppDatabase _db;

  // ── Streams ──────────────────────────────────────────────────────────────

  @override
  Stream<List<WalletEntity>> watchAll() =>
      _dao.watchAll().map((list) => list.map(_toEntity).toList());

  @override
  Stream<WalletEntity?> watchById(int id) =>
      _dao.watchById(id).map((w) => w != null ? _toEntity(w) : null);

  // ── Queries ───────────────────────────────────────────────────────────────

  @override
  Future<List<WalletEntity>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<WalletEntity?> getById(int id) async {
    final row = await _dao.getById(id);
    return row != null ? _toEntity(row) : null;
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  @override
  Future<bool> existsByName(String name, {int? excludeId}) =>
      _dao.existsByName(name, excludeId: excludeId);

  @override
  Future<bool> hasReferences(int walletId) => _dao.hasReferences(walletId);

  @override
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
  }) async {
    // Atomic: check + insert in one transaction to prevent TOCTOU race
    return _db.transaction(() async {
      final exists = await _dao.existsByName(name);
      if (exists) {
        throw ArgumentError('A wallet with name "$name" already exists');
      }
      // If marking as default, clear existing default first (unique index).
      if (isDefaultAccount) {
        await _db.customStatement(
          'UPDATE wallets SET is_default_account = 0 '
          'WHERE is_default_account = 1',
        );
      }
      return _dao.insertWallet(
        WalletsCompanion.insert(
          name: name,
          type: type,
          balance: Value(initialBalance),
          currencyCode: Value(currencyCode),
          iconName: Value(iconName),
          colorHex: Value(colorHex),
          displayOrder: Value(displayOrder),
          linkedSenders: Value(jsonEncode(linkedSenders)),
          isDefaultAccount: Value(isDefaultAccount),
        ),
      );
    });
  }

  @override
  Future<bool> update(WalletEntity wallet) async {
    // Atomic: check + update in one transaction to prevent TOCTOU race
    return _db.transaction(() async {
      final exists = await _dao.existsByName(wallet.name, excludeId: wallet.id);
      if (exists) {
        throw ArgumentError(
          'A wallet with name "${wallet.name}" already exists',
        );
      }
      return _dao.saveWallet(
        WalletsCompanion(
          id: Value(wallet.id),
          name: Value(wallet.name),
          type: Value(wallet.type),
          // NOTE: balance intentionally excluded — only adjustBalance() may
          // change the balance to prevent stale-snapshot overwrites (C2 fix).
          currencyCode: Value(wallet.currencyCode),
          iconName: Value(wallet.iconName),
          colorHex: Value(wallet.colorHex),
          isArchived: Value(wallet.isArchived),
          displayOrder: Value(wallet.displayOrder),
          linkedSenders: Value(jsonEncode(wallet.linkedSenders)),
        ),
      );
    });
  }

  @override
  Future<bool> archive(int id) => _dao.archive(id);

  @override
  Future<WalletEntity?> getSystemWallet() async {
    final row = await _dao.getSystemWallet();
    return row != null ? _toEntity(row) : null;
  }

  @override
  Stream<WalletEntity?> watchSystemWallet() =>
      _dao.watchSystemWallet().map((w) => w != null ? _toEntity(w) : null);

  @override
  Future<int> ensureSystemWalletExists({String? localizedName}) async {
    return _db.transaction(() async {
      final existing = await _dao.getSystemWallet();
      if (existing != null) return existing.id;
      return _dao.insertWallet(
        WalletsCompanion.insert(
          name: localizedName ?? 'Cash',
          type: 'physical_cash',
          balance: const Value(0),
          displayOrder: const Value(-1),
          isSystemWallet: const Value(true),
        ),
      );
    });
  }

  @override
  Future<WalletEntity?> getDefaultAccount() async {
    final row = await _dao.getDefaultAccount();
    return row != null ? _toEntity(row) : null;
  }

  @override
  Stream<WalletEntity?> watchDefaultAccount() =>
      _dao.watchDefaultAccount().map((w) => w != null ? _toEntity(w) : null);

  @override
  Future<int> ensureDefaultAccountExists({String? localizedName}) async {
    return _db.transaction(() async {
      final existing = await _dao.getDefaultAccount();
      if (existing != null) return existing.id;
      return _dao.insertWallet(
        WalletsCompanion.insert(
          name: localizedName ?? 'Default',
          type: 'bank',
          balance: const Value(0),
          isDefaultAccount: const Value(true),
        ),
      );
    });
  }

  @override
  Future<void> adjustBalance(int id, int deltaPiastres) =>
      _dao.adjustBalance(id, deltaPiastres);

  @override
  Future<int> getTotalBalance() => _dao.getTotalBalance();

  @override
  Stream<int> watchTotalBalance() => _dao.watchTotalBalance();

  // ── Mapping ───────────────────────────────────────────────────────────────

  static WalletEntity _toEntity(Wallet w) => WalletEntity(
        id: w.id,
        name: w.name,
        type: w.type,
        balance: w.balance,
        currencyCode: w.currencyCode,
        iconName: w.iconName,
        colorHex: w.colorHex,
        isArchived: w.isArchived,
        displayOrder: w.displayOrder,
        createdAt: w.createdAt,
        linkedSenders: _decodeSenders(w.linkedSenders),
        isSystemWallet: w.isSystemWallet,
        isDefaultAccount: w.isDefaultAccount,
      );

  @override
  Future<void> addLinkedSender(int walletId, String sender) async {
    final upperSender = sender.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    if (upperSender.isEmpty) return;

    // Atomic read-check-write to prevent duplicate senders from concurrent calls.
    await _db.transaction(() async {
      final row = await (_db.select(_db.wallets)
            ..where((w) => w.id.equals(walletId)))
          .getSingleOrNull();
      if (row == null) return;

      final existing = _decodeSenders(row.linkedSenders);
      if (existing.any(
        (s) => s.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '') == upperSender,
      )) {
        return; // Already linked
      }

      final updatedSenders = [...existing, sender];
      await (_db.update(_db.wallets)..where((w) => w.id.equals(walletId)))
          .write(
        WalletsCompanion(
          linkedSenders: Value(jsonEncode(updatedSenders)),
        ),
      );
    });
  }

  static List<String> _decodeSenders(String json) {
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }
}
