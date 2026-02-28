import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database/app_database.dart';
import 'database_provider.dart';

/// Pending parsed notification/SMS transactions awaiting user review.
///
/// Returns logs with parsedStatus == 'pending', most recent first.
final pendingParsedTransactionsProvider =
    FutureProvider<List<SmsParserLog>>((ref) async {
  final dao = ref.watch(smsParserLogDaoProvider);
  return dao.getPending();
});
