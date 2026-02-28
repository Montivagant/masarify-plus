import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/category_entity.dart';
import 'repository_providers.dart';

/// All categories (non-archived), ordered by displayOrder.
final categoriesProvider = StreamProvider<List<CategoryEntity>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

/// Expense categories only — reactive via stream filtering.
final expenseCategoriesProvider = StreamProvider<List<CategoryEntity>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll().map(
        (cats) => cats
            .where((c) => c.type == 'expense' || c.type == 'both')
            .toList(),
      ),
);

/// Income categories only — reactive via stream filtering.
final incomeCategoriesProvider = StreamProvider<List<CategoryEntity>>(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll().map(
        (cats) => cats
            .where((c) => c.type == 'income' || c.type == 'both')
            .toList(),
      ),
);
