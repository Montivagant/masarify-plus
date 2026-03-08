import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_listener_wrapper.dart';
import 'database_provider.dart';

/// Provides a singleton [NotificationListenerWrapper] for the app lifetime.
///
/// AI enrichment is NOT injected here — enrichment is user-initiated from
/// the review screen. The listener only does local regex parsing + DB insert.
final notificationListenerProvider =
    Provider<NotificationListenerWrapper>((ref) {
  final dao = ref.watch(smsParserLogDaoProvider);
  final wrapper = NotificationListenerWrapper(dao);

  ref.onDispose(wrapper.dispose);
  return wrapper;
});
