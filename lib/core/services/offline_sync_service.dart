import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import '../../data/database/daos/sms_parser_log_dao.dart';
import '../../domain/entities/category_entity.dart';
import 'ai/ai_transaction_parser.dart';
import 'connectivity_service.dart';
import 'notification_transaction_parser.dart';


/// Listens for offline-to-online transitions and enriches pending
/// SMS/notification parser logs that were stored without AI enrichment
/// because the device was offline at the time.
class OfflineSyncService {
  OfflineSyncService({
    required SmsParserLogDao dao,
    required AiTransactionParser aiParser,
    required this.getCategories,
    required ConnectivityService connectivityService,
  })  : _dao = dao,
        _aiParser = aiParser,
        _connectivityService = connectivityService;

  final SmsParserLogDao _dao;
  final AiTransactionParser _aiParser;
  final ConnectivityService _connectivityService;

  /// Callback to get the current categories list.
  /// Uses a callback to avoid stale data.
  final Future<List<CategoryEntity>> Function() getCategories;

  StreamSubscription<bool>? _subscription;
  bool _syncing = false;

  /// Start listening for connectivity changes.
  /// Also immediately syncs if the device is already online and there
  /// are pending unenriched items from a previous session.
  void start() async {
    // Sync any pending items from previous sessions if already online.
    final currentlyOnline = await _connectivityService.isOnline;
    if (currentlyOnline) {
      _onReconnect();
    }

    bool wasOffline = !currentlyOnline;
    _subscription = _connectivityService.onlineStream.listen((online) {
      if (online && wasOffline) {
        _onReconnect();
      }
      wasOffline = !online;
    });
  }

  /// Stop listening.
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// When transitioning offline -> online, enrich pending unenriched logs.
  Future<void> _onReconnect() async {
    if (_syncing) return;
    _syncing = true;

    try {
      dev.log(
        'Online again — syncing pending enrichments',
        name: 'OfflineSyncService',
      );

      final categories = await getCategories();
      if (categories.isEmpty) {
        _syncing = false;
        return;
      }

      final pendingLogs = await _dao.getPendingUnenriched();
      if (pendingLogs.isEmpty) {
        dev.log('No pending unenriched logs', name: 'OfflineSyncService');
        _syncing = false;
        return;
      }

      var enriched = 0;
      for (final log in pendingLogs) {
        // Re-parse to get amount and type
        final parsed = NotificationTransactionParser.parse(
          sender: log.senderAddress,
          body: log.body,
          receivedAt: log.receivedAt,
          source: log.source,
        );
        if (parsed == null) continue;

        try {
          final enrichment = await _aiParser.enrich(
            sender: log.senderAddress,
            body: log.body,
            amountPiastres: parsed.amountPiastres,
            type: parsed.type,
            categories: categories,
          );
          if (enrichment != null) {
            await _dao.updateEnrichment(
              log.id,
              jsonEncode(enrichment.toJson()),
            );
            enriched++;
          }
        } catch (e) {
          dev.log(
            'Enrichment failed for log ${log.id}: $e',
            name: 'OfflineSyncService',
          );
          // Stop on network errors to avoid hammering a broken connection
          break;
        }
      }

      dev.log(
        'Enriched $enriched / ${pendingLogs.length} pending logs',
        name: 'OfflineSyncService',
      );
    } catch (e) {
      dev.log('Sync failed: $e', name: 'OfflineSyncService');
    } finally {
      _syncing = false;
    }
  }
}
