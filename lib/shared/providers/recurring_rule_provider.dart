import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recurring_rule_entity.dart';
import 'repository_providers.dart';

/// All recurring rules (active, paused, and paid).
final recurringRulesProvider = StreamProvider<List<RecurringRuleEntity>>(
  (ref) => ref.watch(recurringRuleRepositoryProvider).watchAll(),
);
