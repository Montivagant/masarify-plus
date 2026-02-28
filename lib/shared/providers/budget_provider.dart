import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/budget_entity.dart';
import 'repository_providers.dart';

/// Budgets for a given (year, month), enriched with spentAmount.
final budgetsByMonthProvider =
    StreamProvider.family<List<BudgetEntity>, (int, int)>(
  (ref, params) => ref
      .watch(budgetRepositoryProvider)
      .watchByMonth(params.$1, params.$2),
);
