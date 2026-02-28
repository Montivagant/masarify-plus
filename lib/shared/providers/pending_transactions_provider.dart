import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import 'database_provider.dart';

/// Pending parsed notification/SMS transactions awaiting user review.
///
/// Reactive stream — auto-updates when new logs are inserted or status changes.
final pendingParsedTransactionsProvider =
    StreamProvider<List<SmsParserLog>>((ref) {
  final dao = ref.watch(smsParserLogDaoProvider);
  return dao.watchPending();
});
