import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/goal_contribution_entity.dart';
import '../../domain/entities/savings_goal_entity.dart';
import 'repository_providers.dart';

/// Active (incomplete) savings goals.
final activeGoalsProvider = StreamProvider<List<SavingsGoalEntity>>(
  (ref) => ref.watch(goalRepositoryProvider).watchActive(),
);

/// Completed savings goals.
final completedGoalsProvider = StreamProvider<List<SavingsGoalEntity>>(
  (ref) => ref.watch(goalRepositoryProvider).watchCompleted(),
);

/// Single goal by ID — avoids watching full active+completed lists.
final goalByIdProvider = FutureProvider.family<SavingsGoalEntity?, int>(
  (ref, id) => ref.watch(goalRepositoryProvider).getById(id),
);

/// Contributions for a specific goal.
final goalContributionsProvider =
    StreamProvider.family<List<GoalContributionEntity>, int>(
  (ref, goalId) =>
      ref.watch(goalRepositoryProvider).watchContributions(goalId),
);
