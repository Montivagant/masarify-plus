import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:another_telephony/telephony.dart';

import '../../data/database/app_database.dart';
import '../../data/database/daos/parsed_event_group_dao.dart';
import '../../data/database/daos/sms_parser_log_dao.dart';
import '../../domain/entities/category_entity.dart';
import '../config/ai_config.dart';
import '../config/app_config.dart';
import 'ai/ai_transaction_parser.dart';
import 'connectivity_service.dart';
import 'notification_transaction_parser.dart';
import 'semantic_fingerprint_service.dart';

/// SMS inbox parser — reuses [NotificationTransactionParser] regex patterns.
///
/// Reads SMS inbox via `another_telephony`, parses financial messages,
/// deduplicates via SHA-256 hash, and stores pending candidates for review.
/// Optionally enriches via AI for better category/merchant extraction.
/// Shares [ParserReviewScreen] with the notification parser flow.
class SmsParserService {
  SmsParserService(
    this._dao, {
    this.aiParser,
    this.categories,
    this.eventGroupDao,
    ConnectivityService? connectivityService,
  }) : _connectivityService = connectivityService ?? ConnectivityService();

  final SmsParserLogDao _dao;
  final AiTransactionParser? aiParser;
  final List<CategoryEntity>? categories;
  final ParsedEventGroupDao? eventGroupDao;
  final ConnectivityService _connectivityService;

  /// Scan SMS inbox for financial messages. No-op if feature is disabled.
  Future<int> scanInbox() async {
    if (!AppConfig.kSmsEnabled) return 0;
    if (!Platform.isAndroid) return 0;

    dev.log(
      'scanInbox: aiParser=${aiParser != null}, '
      'categories=${categories?.length}, hasApiKey=${AiConfig.hasApiKey}',
      name: 'SmsParserService',
    );

    final telephony = Telephony.instance;

    // Read SMS from the last 7 days.
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    final List<SmsMessage> messages;
    try {
      // IM-35 fix: apply date filter at query level to avoid loading full inbox
      messages = await telephony.getInboxSms(
        columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
        filter: SmsFilter.where(SmsColumn.DATE)
            .greaterThan(cutoff.millisecondsSinceEpoch.toString()),
      );
    } catch (_) {
      // Permission not granted or platform error — fail silently.
      return 0;
    }

    var newCount = 0;
    // CR-5 fix: cap AI enrichment to prevent unbounded API calls
    const maxEnrichmentCalls = 20;
    var enrichmentCalls = 0;

    // Only attempt AI enrichment if online
    final isOnline = await _connectivityService.isOnline;

    for (final sms in messages) {
      final address = sms.address ?? '';
      final body = sms.body ?? '';
      final dateMs = sms.date;

      // Skip empty messages.
      if (body.isEmpty || address.isEmpty) continue;

      final receivedAt = dateMs != null
          ? DateTime.fromMillisecondsSinceEpoch(dateMs)
          : DateTime.now();

      // Filter by known financial senders.
      if (!NotificationTransactionParser.isFinancialSender(address)) continue;

      // Parse with shared parser.
      final parsed = NotificationTransactionParser.parse(
        sender: address,
        body: body,
        receivedAt: receivedAt,
        source: 'sms',
      );
      if (parsed == null) continue;

      // Insert-first dedup: try insert with ON CONFLICT DO NOTHING.
      // If the row already exists, getByHash will return the existing row
      // and we skip AI enrichment — avoids wasting an API call on duplicates.
      await _dao.insertLog(
        SmsParserLogsCompanion.insert(
          senderAddress: parsed.senderAddress,
          bodyHash: parsed.bodyHash,
          body: parsed.body,
          parsedStatus: 'pending',
          source: 'sms',
          receivedAt: parsed.receivedAt,
        ),
      );
      final inserted = await _dao.getByHash(parsed.bodyHash);
      if (inserted == null || inserted.aiEnrichmentJson != null) continue;
      // Only count and enrich truly new entries
      if (inserted.source != 'sms') continue;

      // WS3: Semantic fingerprint dedup — check for cross-source duplicates.
      if (eventGroupDao != null) {
        final fingerprints = SemanticFingerprintService.compute(
          senderOrWalletId: parsed.senderAddress,
          amountPiastres: parsed.amountPiastres,
          type: parsed.type,
          receivedAt: parsed.receivedAt,
        );
        final existingGroup =
            await eventGroupDao!.findByFingerprints(fingerprints);
        if (existingGroup != null) {
          await eventGroupDao!.markAsDuplicate(
            inserted.id,
            existingGroup.semanticFingerprint,
          );
          dev.log(
            'SMS dedup: log ${inserted.id} marked as duplicate of group ${existingGroup.id}',
            name: 'SmsParserService',
          );
          continue; // Skip enrichment for duplicates
        }
        // New event — create group.
        await eventGroupDao!.createGroup(
          fingerprint: fingerprints.first,
          canonicalLogId: inserted.id,
          amountPiastres: parsed.amountPiastres,
          type: parsed.type,
          eventTime: parsed.receivedAt,
        );
        await eventGroupDao!.setLogFingerprint(
          inserted.id,
          fingerprints.first,
        );
      }

      // AI enrichment (optional — null on failure). Skipped when offline.
      if (!isOnline) {
        dev.log(
          'SMS enrichment SKIPPED: device is OFFLINE — will enrich on reconnect',
          name: 'SmsParserService',
        );
      } else if (aiParser == null) {
        dev.log(
          'SMS enrichment SKIPPED: aiParser is null — check AiConfig.hasApiKey (${AiConfig.hasApiKey})',
          name: 'SmsParserService',
        );
      } else if (categories == null || categories!.isEmpty) {
        dev.log(
          'SMS enrichment SKIPPED: no categories loaded (${categories?.length})',
          name: 'SmsParserService',
        );
      } else if (enrichmentCalls >= maxEnrichmentCalls) {
        dev.log(
          'SMS enrichment SKIPPED: reached max calls ($maxEnrichmentCalls)',
          name: 'SmsParserService',
        );
      }
      if (isOnline &&
          aiParser != null &&
          categories != null &&
          categories!.isNotEmpty &&
          enrichmentCalls < maxEnrichmentCalls) {
        enrichmentCalls++;
        dev.log(
          'SMS enrichment: calling AI for "$address" (call $enrichmentCalls/$maxEnrichmentCalls)',
          name: 'SmsParserService',
        );
        final enrichment = await aiParser!.enrich(
          sender: address,
          body: body,
          amountPiastres: parsed.amountPiastres,
          type: parsed.type,
          categories: categories!,
        );
        dev.log(
          'SMS enrichment result: ${enrichment != null ? "success" : "null"}',
          name: 'SmsParserService',
        );
        if (enrichment != null) {
          await _dao.updateEnrichment(
            inserted.id,
            jsonEncode(enrichment.toJson()),
          );
        }
      }
      newCount++;
    }

    dev.log(
      'scanInbox complete: $newCount new, $enrichmentCalls AI calls made',
      name: 'SmsParserService',
    );
    return newCount;
  }
}
