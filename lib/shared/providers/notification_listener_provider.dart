import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_listener_wrapper.dart';
import 'ai_provider.dart';
import 'category_provider.dart';
import 'connectivity_provider.dart';
import 'database_provider.dart';

/// Provides a singleton [NotificationListenerWrapper] for the app lifetime.
///
/// C2 fix: use ref.read + ref.listen for categories/aiParser to avoid
/// full provider rebuild (and listener disposal) on every category change.
/// Previously ref.watch caused the wrapper to be disposed and recreated
/// without start() being called, silently killing notification parsing.
final notificationListenerProvider =
    Provider<NotificationListenerWrapper>((ref) {
  final dao = ref.watch(smsParserLogDaoProvider);
  final aiParser = ref.read(aiTransactionParserProvider);
  final categories = ref.read(categoriesProvider).valueOrNull;
  final connectivity = ref.read(connectivityServiceProvider);
  final wrapper = NotificationListenerWrapper(
    dao,
    aiParser: aiParser,
    categories: categories,
    connectivityService: connectivity,
  );

  // Update categories in-place without disposing the wrapper
  ref.listen(categoriesProvider, (_, next) {
    wrapper.categories = next.valueOrNull;
  });

  ref.onDispose(wrapper.dispose);
  return wrapper;
});
