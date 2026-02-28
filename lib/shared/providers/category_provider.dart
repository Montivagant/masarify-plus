import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category_entity.dart';
import 'repository_providers.dart';

/// All categories (non-archived), ordered by displayOrder.
final categoriesProvider = StreamProvider<List<CategoryEntity>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// Expense categories only — derived from [categoriesProvider] to avoid
/// duplicate Drift stream subscriptions on the same table.
final expenseCategoriesProvider = Provider<AsyncValue<List<CategoryEntity>>>(
  (ref) => ref.watch(categoriesProvider).whenData(
        (cats) => cats
            .where((c) => c.type == 'expense' || c.type == 'both')
            .toList(),
      ),
);

/// Income categories only — derived from [categoriesProvider] to avoid
/// duplicate Drift stream subscriptions on the same table.
final incomeCategoriesProvider = Provider<AsyncValue<List<CategoryEntity>>>(
  (ref) => ref.watch(categoriesProvider).whenData(
        (cats) => cats
            .where((c) => c.type == 'income' || c.type == 'both')
            .toList(),
      ),
);
