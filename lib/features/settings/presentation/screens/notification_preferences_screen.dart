import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// [Phase 4 stub] — Full implementation in Phase 4 Task 4.4.
class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppAppBar(title: context.l10n.settings_notification_parser),
      body: Center(child: Text(context.l10n.common_coming_soon)),
    );
  }
}
