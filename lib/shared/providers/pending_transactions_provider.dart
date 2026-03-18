import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/sms_parser_log_entity.dart';
import 'repository_providers.dart';

/// Pending parsed notification/SMS transactions awaiting user review.
///
/// Reactive stream — auto-updates when new logs are inserted or status changes.
final pendingParsedTransactionsProvider =
    StreamProvider<List<SmsParserLogEntity>>((ref) {
  final repo = ref.watch(smsParserLogRepositoryProvider);
  return repo.watchPending();
});

/// Lightweight count-only provider for dashboard badge and nav dots.
/// Uses COUNT query — does NOT load full rows with body/enrichment JSON.
final pendingCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(smsParserLogRepositoryProvider);
  return repo.watchPendingCount();
});
