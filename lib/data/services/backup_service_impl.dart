import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/services/backup_service.dart';
import '../../core/services/crash_log_service.dart';
import '../database/app_database.dart';

/// Concrete implementation of [BackupService].
///
/// - JSON export/import: all 13 DB tables + crash log + schema version.
/// - CSV export: monthly transactions with readable columns.
class BackupServiceImpl implements BackupService {
  BackupServiceImpl(this._db);

  final AppDatabase _db;

  // Hardcoded to avoid creating a throwaway AppDatabase() instance (leaked connection).
  // Must be kept in sync with AppDatabase.schemaVersion.
  static const int _schemaVersion = 10;

  // ── JSON Export ─────────────────────────────────────────────────────────

  @override
  Future<String> exportToJson() async {
    final wallets = await _db.select(_db.wallets).get();
    final categories = await _db.select(_db.categories).get();
    final transactions = await _db.select(_db.transactions).get();
    final transfers = await _db.select(_db.transfers).get();
    final budgets = await _db.select(_db.budgets).get();
    final goals = await _db.select(_db.savingsGoals).get();
    final contributions = await _db.select(_db.goalContributions).get();
    final rules = await _db.select(_db.recurringRules).get();
    final smsLogs = await _db.select(_db.smsParserLogs).get();
    final rates = await _db.select(_db.exchangeRates).get();
    final catMappings = await _db.select(_db.categoryMappings).get();
    final chatMessages = await _db.select(_db.chatMessages).get();
    final parsedEventGroups = await _db.select(_db.parsedEventGroups).get();

    final crashLog = await CrashLogService.readLog();

    final data = {
      'version': _schemaVersion,
      'exportDate': DateTime.now().toIso8601String(),
      'tables': {
        'wallets': wallets.map(_walletToMap).toList(),
        'categories': categories.map(_categoryToMap).toList(),
        'transactions': transactions.map(_transactionToMap).toList(),
        'transfers': transfers.map(_transferToMap).toList(),
        'budgets': budgets.map(_budgetToMap).toList(),
        'savings_goals': goals.map(_goalToMap).toList(),
        'goal_contributions': contributions.map(_contributionToMap).toList(),
        'recurring_rules': rules.map(_ruleToMap).toList(),
        'sms_parser_logs': smsLogs.map(_smsLogToMap).toList(),
        'exchange_rates': rates.map(_rateToMap).toList(),
        'category_mappings': catMappings.map(_categoryMappingToMap).toList(),
        'chat_messages': chatMessages.map(_chatMessageToMap).toList(),
        'parsed_event_groups':
            parsedEventGroups.map(_parsedEventGroupToMap).toList(),
      },
      if (crashLog != null) 'crash_log': crashLog,
    };

    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/masarify_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json',
    );
    await file.writeAsString(json);
    return file.path;
  }

  // ── JSON Import ─────────────────────────────────────────────────────────

  @override
  Future<void> importFromJson(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw FormatException('Backup file not found: $filePath');
    }
    final content = await file.readAsString();

    // C4 fix: parse and validate the entire backup BEFORE deleting any data.
    // Previously clearAllData() ran first, so a corrupted file meant total data loss.
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(content) as Map<String, dynamic>;
    } catch (e) {
      throw FormatException('Invalid backup file: $e');
    }

    final versionRaw = _intN(data['version']);
    if (versionRaw == null || versionRaw > _schemaVersion) {
      throw FormatException('Unsupported backup version: $versionRaw');
    }
    final version = versionRaw;

    final tables = data['tables'] as Map<String, dynamic>?;
    if (tables == null) {
      throw const FormatException('Backup file missing "tables" key');
    }

    // C4 fix: pre-validate all table data can be deserialized before deleting
    _validateTableData(tables, version);

    await _db.transaction(() async {
      // Clear all tables in dependency-safe order.
      // parsed_event_groups FKs to sms_parser_logs → delete child first
      await _db.customStatement('DELETE FROM parsed_event_groups');
      await _db.customStatement('DELETE FROM sms_parser_logs');
      await _db.customStatement('DELETE FROM goal_contributions');
      await _db.customStatement('DELETE FROM recurring_rules');
      await _db.customStatement('DELETE FROM budgets');
      await _db.customStatement('DELETE FROM savings_goals');
      await _db.customStatement('DELETE FROM transfers');
      await _db.customStatement('DELETE FROM transactions');
      await _db.customStatement('DELETE FROM exchange_rates');
      await _db.customStatement('DELETE FROM category_mappings');
      await _db.customStatement('DELETE FROM chat_messages');
      await _db.customStatement('DELETE FROM wallets');
      await _db.customStatement('DELETE FROM categories');

      // Re-insert in dependency-safe order.
      // H13 fix: use insertOnConflictUpdate to handle PK conflicts gracefully
      await _insertAll(tables, 'wallets', _db.wallets, _mapToWallet);
      await _insertAll(tables, 'categories', _db.categories, _mapToCategory);
      await _insertAll(
        tables,
        'transactions',
        _db.transactions,
        _mapToTransaction,
      );
      await _insertAll(tables, 'transfers', _db.transfers, _mapToTransfer);
      await _insertAll(tables, 'budgets', _db.budgets, _mapToBudget);
      await _insertAll(
        tables,
        'savings_goals',
        _db.savingsGoals,
        _mapToGoal,
      );
      await _insertAll(
        tables,
        'goal_contributions',
        _db.goalContributions,
        _mapToContribution,
      );
      await _insertAll(
        tables,
        'recurring_rules',
        _db.recurringRules,
        _mapToRule,
      );
      await _insertAll(
        tables,
        'sms_parser_logs',
        _db.smsParserLogs,
        (m) => _mapToSmsLog(m, version),
      );
      // v8+ table — depends on sms_parser_logs (FK on canonicalLogId)
      await _insertAll(
        tables,
        'parsed_event_groups',
        _db.parsedEventGroups,
        _mapToParsedEventGroup,
      );
      await _insertAll(
        tables,
        'exchange_rates',
        _db.exchangeRates,
        _mapToRate,
      );
      // v5+ tables — gracefully skip if absent in older backups
      await _insertAll(
        tables,
        'category_mappings',
        _db.categoryMappings,
        _mapToCategoryMapping,
      );
      await _insertAll(
        tables,
        'chat_messages',
        _db.chatMessages,
        _mapToChatMessage,
      );
    });
  }

  /// C4 fix: validate all rows can be deserialized without errors.
  void _validateTableData(Map<String, dynamic> tables, int version) {
    // Attempt to deserialize each table — throws on malformed data
    _tryDeserializeAll(tables, 'wallets', _mapToWallet);
    _tryDeserializeAll(tables, 'categories', _mapToCategory);
    _tryDeserializeAll(tables, 'transactions', _mapToTransaction);
    _tryDeserializeAll(tables, 'transfers', _mapToTransfer);
    _tryDeserializeAll(tables, 'budgets', _mapToBudget);
    _tryDeserializeAll(tables, 'savings_goals', _mapToGoal);
    _tryDeserializeAll(tables, 'goal_contributions', _mapToContribution);
    _tryDeserializeAll(tables, 'recurring_rules', _mapToRule);
    _tryDeserializeAll(
      tables,
      'sms_parser_logs',
      (m) => _mapToSmsLog(m, version),
    );
    _tryDeserializeAll(tables, 'exchange_rates', _mapToRate);
    // v5+ tables — may be absent in older backups, _tryDeserializeAll skips null
    _tryDeserializeAll(tables, 'category_mappings', _mapToCategoryMapping);
    _tryDeserializeAll(tables, 'chat_messages', _mapToChatMessage);
    // v8+ table
    _tryDeserializeAll(tables, 'parsed_event_groups', _mapToParsedEventGroup);
  }

  void _tryDeserializeAll<T>(
    Map<String, dynamic> tables,
    String key,
    T Function(Map<String, dynamic>) mapper,
  ) {
    final rows = tables[key] as List<dynamic>?;
    if (rows == null) return;
    for (int i = 0; i < rows.length; i++) {
      try {
        mapper(rows[i] as Map<String, dynamic>);
      } catch (e) {
        throw FormatException('Invalid data in table "$key" at row $i: $e');
      }
    }
  }

  // H13 fix: use insertOrReplace to handle PK conflicts
  Future<void> _insertAll<T extends Table, D>(
    Map<String, dynamic> tables,
    String key,
    TableInfo<T, D> table,
    Insertable<D> Function(Map<String, dynamic>) mapper,
  ) async {
    final rows = tables[key] as List<dynamic>?;
    if (rows == null) return;
    for (final row in rows) {
      await _db.into(table).insert(
            mapper(row as Map<String, dynamic>),
            mode: InsertMode.insertOrReplace,
          );
    }
  }

  // ── CSV Export ──────────────────────────────────────────────────────────

  @override
  Future<String> exportTransactionsToCsv({
    required int year,
    required int month,
  }) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);

    final txs = await (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.transactionDate.isBiggerOrEqualValue(start) &
                t.transactionDate.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
        .get();

    final categories = await _db.select(_db.categories).get();
    final wallets = await _db.select(_db.wallets).get();

    final catMap = {for (final c in categories) c.id: c.name};
    final walletMap = {for (final w in wallets) w.id: w.name};

    final rows = <List<dynamic>>[
      [
        'Date',
        'Title',
        'Amount',
        'Currency',
        'Type',
        'Category',
        'Account',
        'Tags',
        'Source',
        'Location',
        'Notes',
      ],
      ...txs.map(
        (tx) => [
          DateFormat('yyyy-MM-dd HH:mm').format(tx.transactionDate),
          tx.title,
          // Raw decimal for machine-readable CSV; intentionally bypasses
          // MoneyFormatter to avoid locale-dependent formatting (e.g. Arabic digits).
          (tx.amount / 100).toStringAsFixed(2),
          tx.currencyCode,
          tx.type,
          catMap[tx.categoryId] ?? '',
          walletMap[tx.walletId] ?? '',
          tx.tags,
          tx.source,
          tx.locationName ?? '',
          tx.note ?? '',
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/masarify_${year}_${month.toString().padLeft(2, '0')}.csv',
    );
    await file.writeAsString(csv);
    return file.path;
  }

  // ── Serialization helpers ──────────────────────────────────────────────

  Map<String, dynamic> _walletToMap(Wallet w) => {
        'id': w.id,
        'name': w.name,
        'type': w.type,
        'balance': w.balance,
        'currencyCode': w.currencyCode,
        'iconName': w.iconName,
        'colorHex': w.colorHex,
        'isArchived': w.isArchived,
        'displayOrder': w.displayOrder,
        'linkedSenders': w.linkedSenders,
        'isSystemWallet': w.isSystemWallet,
        'createdAt': w.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _categoryToMap(Category c) => {
        'id': c.id,
        'name': c.name,
        'nameAr': c.nameAr,
        'iconName': c.iconName,
        'colorHex': c.colorHex,
        'type': c.type,
        'groupType': c.groupType,
        'isDefault': c.isDefault,
        'isArchived': c.isArchived,
        'displayOrder': c.displayOrder,
      };

  Map<String, dynamic> _transactionToMap(Transaction tx) => {
        'id': tx.id,
        'walletId': tx.walletId,
        'categoryId': tx.categoryId,
        'amount': tx.amount,
        'type': tx.type,
        'currencyCode': tx.currencyCode,
        'title': tx.title,
        'note': tx.note,
        'transactionDate': tx.transactionDate.toIso8601String(),
        'receiptImagePath': tx.receiptImagePath,
        'tags': tx.tags,
        'latitude': tx.latitude,
        'longitude': tx.longitude,
        'locationName': tx.locationName,
        'source': tx.source,
        'rawSourceText': tx.rawSourceText,
        'isRecurring': tx.isRecurring,
        'recurringRuleId': tx.recurringRuleId,
        'goalId': tx.goalId,
        'createdAt': tx.createdAt.toIso8601String(),
        'updatedAt': tx.updatedAt.toIso8601String(),
      };

  Map<String, dynamic> _transferToMap(Transfer t) => {
        'id': t.id,
        'fromWalletId': t.fromWalletId,
        'toWalletId': t.toWalletId,
        'amount': t.amount,
        'fee': t.fee,
        'note': t.note,
        'transferDate': t.transferDate.toIso8601String(),
        'createdAt': t.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _budgetToMap(Budget b) => {
        'id': b.id,
        'categoryId': b.categoryId,
        'month': b.month,
        'year': b.year,
        'limitAmount': b.limitAmount,
        'rollover': b.rollover,
        'rolloverAmount': b.rolloverAmount,
        'createdAt': b.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _goalToMap(SavingsGoal g) => {
        'id': g.id,
        'name': g.name,
        'iconName': g.iconName,
        'colorHex': g.colorHex,
        'targetAmount': g.targetAmount,
        'currentAmount': g.currentAmount,
        'currencyCode': g.currencyCode,
        'deadline': g.deadline?.toIso8601String(),
        'isCompleted': g.isCompleted,
        'keywords': g.keywords,
        'walletId': g.walletId,
        'createdAt': g.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _contributionToMap(GoalContribution c) => {
        'id': c.id,
        'goalId': c.goalId,
        'amount': c.amount,
        'date': c.date.toIso8601String(),
        'note': c.note,
        'walletId': c.walletId,
      };

  Map<String, dynamic> _ruleToMap(RecurringRule r) => {
        'id': r.id,
        'walletId': r.walletId,
        'categoryId': r.categoryId,
        'amount': r.amount,
        'type': r.type,
        'title': r.title,
        'frequency': r.frequency,
        'startDate': r.startDate.toIso8601String(),
        'endDate': r.endDate?.toIso8601String(),
        'nextDueDate': r.nextDueDate.toIso8601String(),
        'isPaid': r.isPaid,
        'paidAt': r.paidAt?.toIso8601String(),
        'linkedTransactionId': r.linkedTransactionId,
        'isActive': r.isActive,
        'lastProcessedDate': r.lastProcessedDate?.toIso8601String(),
      };

  // C3 fix: include aiEnrichmentJson in serialization
  // v8: include semanticFingerprint + transferId
  Map<String, dynamic> _smsLogToMap(SmsParserLog l) => {
        'id': l.id,
        'senderAddress': l.senderAddress,
        'bodyHash': l.bodyHash,
        'body': l.body,
        'parsedStatus': l.parsedStatus,
        'transactionId': l.transactionId,
        'source': l.source,
        'receivedAt': l.receivedAt.toIso8601String(),
        'processedAt': l.processedAt.toIso8601String(),
        'aiEnrichmentJson': l.aiEnrichmentJson,
        'semanticFingerprint': l.semanticFingerprint,
        'transferId': l.transferId,
      };

  Map<String, dynamic> _categoryMappingToMap(CategoryMapping m) => {
        'id': m.id,
        'titlePattern': m.titlePattern,
        'categoryId': m.categoryId,
        'hitCount': m.hitCount,
        'lastUsedAt': m.lastUsedAt,
      };

  Map<String, dynamic> _chatMessageToMap(ChatMessage m) => {
        'id': m.id,
        'role': m.role,
        'content': m.content,
        'tokenCount': m.tokenCount,
        'createdAt': m.createdAt.toIso8601String(),
      };

  Map<String, dynamic> _rateToMap(ExchangeRate r) => {
        'baseCurrency': r.baseCurrency,
        'targetCurrency': r.targetCurrency,
        'rate': r.rate,
        'updatedAt': r.updatedAt.toIso8601String(),
      };

  // ── JSON helpers ─────────────────────────────────────────────────────

  /// Safely cast a JSON number to int. JSON from some platforms (web, JS)
  /// may encode integers as doubles (e.g. 150000.0).
  static int _int(dynamic v) => (v as num).toInt();
  static int? _intN(dynamic v) => v == null ? null : (v as num).toInt();

  // ── Deserialization helpers ────────────────────────────────────────────

  WalletsCompanion _mapToWallet(Map<String, dynamic> m) => WalletsCompanion(
        id: Value(_int(m['id'])),
        name: Value(m['name'] as String),
        type: Value(m['type'] as String),
        balance: Value(_int(m['balance'])),
        currencyCode: Value(m['currencyCode'] as String),
        iconName: Value(m['iconName'] as String),
        colorHex: Value(m['colorHex'] as String),
        isArchived: Value(m['isArchived'] as bool),
        displayOrder: Value(_int(m['displayOrder'])),
        linkedSenders: Value(m['linkedSenders'] as String? ?? '[]'),
        isSystemWallet: Value(m['isSystemWallet'] as bool? ?? false),
        createdAt: Value(DateTime.parse(m['createdAt'] as String)),
      );

  CategoriesCompanion _mapToCategory(Map<String, dynamic> m) =>
      CategoriesCompanion(
        id: Value(_int(m['id'])),
        name: Value(m['name'] as String),
        nameAr: Value(m['nameAr'] as String),
        iconName: Value(m['iconName'] as String),
        colorHex: Value(m['colorHex'] as String),
        type: Value(m['type'] as String),
        groupType: Value(m['groupType'] as String?),
        isDefault: Value(m['isDefault'] as bool),
        isArchived: Value(m['isArchived'] as bool),
        displayOrder: Value(_int(m['displayOrder'])),
      );

  TransactionsCompanion _mapToTransaction(Map<String, dynamic> m) =>
      TransactionsCompanion(
        id: Value(_int(m['id'])),
        walletId: Value(_int(m['walletId'])),
        categoryId: Value(_int(m['categoryId'])),
        amount: Value(_int(m['amount'])),
        type: Value(m['type'] as String),
        currencyCode: Value(m['currencyCode'] as String),
        title: Value(m['title'] as String),
        note: Value(m['note'] as String?),
        transactionDate: Value(DateTime.parse(m['transactionDate'] as String)),
        receiptImagePath: Value(m['receiptImagePath'] as String?),
        tags: Value(m['tags'] as String? ?? ''),
        latitude: Value(m['latitude'] as double?),
        longitude: Value(m['longitude'] as double?),
        locationName: Value(m['locationName'] as String?),
        source: Value(m['source'] as String? ?? 'manual'),
        rawSourceText: Value(m['rawSourceText'] as String?),
        isRecurring: Value(m['isRecurring'] as bool? ?? false),
        recurringRuleId: Value(_intN(m['recurringRuleId'])),
        goalId: Value(_intN(m['goalId'])),
        createdAt: Value(DateTime.parse(m['createdAt'] as String)),
        updatedAt: Value(DateTime.parse(m['updatedAt'] as String)),
      );

  TransfersCompanion _mapToTransfer(Map<String, dynamic> m) =>
      TransfersCompanion(
        id: Value(_int(m['id'])),
        fromWalletId: Value(_int(m['fromWalletId'])),
        toWalletId: Value(_int(m['toWalletId'])),
        amount: Value(_int(m['amount'])),
        fee: Value(_intN(m['fee']) ?? 0),
        note: Value(m['note'] as String?),
        transferDate: Value(DateTime.parse(m['transferDate'] as String)),
        createdAt: Value(DateTime.parse(m['createdAt'] as String)),
      );

  BudgetsCompanion _mapToBudget(Map<String, dynamic> m) => BudgetsCompanion(
        id: Value(_int(m['id'])),
        categoryId: Value(_int(m['categoryId'])),
        month: Value(_int(m['month'])),
        year: Value(_int(m['year'])),
        limitAmount: Value(_int(m['limitAmount'])),
        rollover: Value(m['rollover'] as bool? ?? false),
        rolloverAmount: Value(_intN(m['rolloverAmount']) ?? 0),
        // v2 backups don't have createdAt — let DB default handle it
        createdAt: Value(
          m['createdAt'] != null
              ? DateTime.parse(m['createdAt'] as String)
              : DateTime.now(),
        ),
      );

  SavingsGoalsCompanion _mapToGoal(Map<String, dynamic> m) =>
      SavingsGoalsCompanion(
        id: Value(_int(m['id'])),
        name: Value(m['name'] as String),
        iconName: Value(m['iconName'] as String),
        colorHex: Value(m['colorHex'] as String),
        targetAmount: Value(_int(m['targetAmount'])),
        currentAmount: Value(_intN(m['currentAmount']) ?? 0),
        currencyCode: Value(m['currencyCode'] as String? ?? 'EGP'),
        deadline: Value(
          m['deadline'] != null
              ? DateTime.parse(m['deadline'] as String)
              : null,
        ),
        isCompleted: Value(m['isCompleted'] as bool? ?? false),
        keywords: Value(m['keywords'] as String? ?? '[]'),
        walletId: Value(_intN(m['walletId'])),
        createdAt: Value(DateTime.parse(m['createdAt'] as String)),
      );

  GoalContributionsCompanion _mapToContribution(Map<String, dynamic> m) =>
      GoalContributionsCompanion(
        id: Value(_int(m['id'])),
        goalId: Value(_int(m['goalId'])),
        amount: Value(_int(m['amount'])),
        date: Value(DateTime.parse(m['date'] as String)),
        note: Value(m['note'] as String?),
        walletId: Value(_intN(m['walletId'])),
      );

  RecurringRulesCompanion _mapToRule(Map<String, dynamic> m) =>
      RecurringRulesCompanion(
        id: Value(_int(m['id'])),
        walletId: Value(_int(m['walletId'])),
        categoryId: Value(_int(m['categoryId'])),
        amount: Value(_int(m['amount'])),
        type: Value(m['type'] as String),
        title: Value(m['title'] as String),
        frequency: Value(m['frequency'] as String),
        startDate: Value(DateTime.parse(m['startDate'] as String)),
        endDate: Value(
          m['endDate'] != null ? DateTime.parse(m['endDate'] as String) : null,
        ),
        nextDueDate: Value(DateTime.parse(m['nextDueDate'] as String)),
        isPaid: Value(m['isPaid'] as bool? ?? false),
        paidAt: Value(
          m['paidAt'] != null ? DateTime.parse(m['paidAt'] as String) : null,
        ),
        linkedTransactionId: Value(_intN(m['linkedTransactionId'])),
        isActive: Value(m['isActive'] as bool? ?? true),
        lastProcessedDate: Value(
          m['lastProcessedDate'] != null
              ? DateTime.parse(m['lastProcessedDate'] as String)
              : null,
        ),
      );

  // C3 fix: include aiEnrichmentJson in deserialization, handle v1 backups
  SmsParserLogsCompanion _mapToSmsLog(Map<String, dynamic> m, int version) =>
      SmsParserLogsCompanion(
        id: Value(_int(m['id'])),
        senderAddress: Value(m['senderAddress'] as String),
        bodyHash: Value(m['bodyHash'] as String),
        body: Value(m['body'] as String),
        parsedStatus: Value(m['parsedStatus'] as String),
        transactionId: Value(_intN(m['transactionId'])),
        source: Value((m['source'] as String?) ?? 'sms'),
        receivedAt: Value(DateTime.parse(m['receivedAt'] as String)),
        processedAt: Value(DateTime.parse(m['processedAt'] as String)),
        // v1 backups don't have this field — treat as null
        aiEnrichmentJson: Value(m['aiEnrichmentJson'] as String?),
        // v8 fields — absent in older backups
        semanticFingerprint: Value(m['semanticFingerprint'] as String?),
        transferId: Value(_intN(m['transferId'])),
      );

  ExchangeRatesCompanion _mapToRate(Map<String, dynamic> m) =>
      ExchangeRatesCompanion(
        baseCurrency: Value(m['baseCurrency'] as String),
        targetCurrency: Value(m['targetCurrency'] as String),
        rate: Value((m['rate'] as num).toDouble()),
        updatedAt: Value(DateTime.parse(m['updatedAt'] as String)),
      );

  // v5 table
  CategoryMappingsCompanion _mapToCategoryMapping(Map<String, dynamic> m) =>
      CategoryMappingsCompanion(
        id: Value(_int(m['id'])),
        titlePattern: Value(m['titlePattern'] as String),
        categoryId: Value(_int(m['categoryId'])),
        hitCount: Value(_intN(m['hitCount']) ?? 1),
        lastUsedAt: Value(_int(m['lastUsedAt'])),
      );

  // v6 table
  ChatMessagesCompanion _mapToChatMessage(Map<String, dynamic> m) =>
      ChatMessagesCompanion(
        id: Value(_int(m['id'])),
        role: Value(m['role'] as String),
        content: Value(m['content'] as String),
        tokenCount: Value(_intN(m['tokenCount']) ?? 0),
        createdAt: Value(DateTime.parse(m['createdAt'] as String)),
      );

  // v8 table
  Map<String, dynamic> _parsedEventGroupToMap(ParsedEventGroup g) => {
        'id': g.id,
        'semanticFingerprint': g.semanticFingerprint,
        'canonicalLogId': g.canonicalLogId,
        'amountPiastres': g.amountPiastres,
        'type': g.type,
        'resolvedWalletId': g.resolvedWalletId,
        'eventType': g.eventType,
        'eventTime': g.eventTime.toIso8601String(),
        'createdAt': g.createdAt.toIso8601String(),
      };

  ParsedEventGroupsCompanion _mapToParsedEventGroup(
    Map<String, dynamic> m,
  ) =>
      ParsedEventGroupsCompanion(
        id: Value(_int(m['id'])),
        semanticFingerprint: Value(m['semanticFingerprint'] as String),
        canonicalLogId: Value(_int(m['canonicalLogId'])),
        amountPiastres: Value(_int(m['amountPiastres'])),
        type: Value(m['type'] as String),
        resolvedWalletId: Value(_intN(m['resolvedWalletId'])),
        eventType: Value(m['eventType'] as String? ?? 'transaction'),
        eventTime: Value(DateTime.parse(m['eventTime'] as String)),
        createdAt: Value(DateTime.parse(m['createdAt'] as String)),
      );
}
