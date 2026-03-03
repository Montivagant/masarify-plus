import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recurring_rule_entity.dart';
import 'repository_providers.dart';

/// All recurring rules (active + paused).
final recurringRulesProvider = StreamProvider<List<RecurringRuleEntity>>(
  (ref) => ref.watch(recurringRuleRepositoryProvider).watchAll(),
);

/// All unpaid one-time bills, ordered by due date.
final unpaidBillsProvider = StreamProvider<List<RecurringRuleEntity>>(
  (ref) => ref.watch(recurringRuleRepositoryProvider).watchUnpaid(),
);
