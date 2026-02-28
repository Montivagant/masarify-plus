import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// [Phase 5 stub] — Full implementation in Phase 5 Task 5.2.
/// Gated by kMonetizationEnabled — NEVER shown when false.
class SubscriptionScreen extends ConsumerWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppAppBar(title: context.l10n.subscription_title),
      body: Center(child: Text(context.l10n.common_coming_soon)),
    );
  }
}
