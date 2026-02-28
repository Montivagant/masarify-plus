import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/bill_entity.dart';
import 'repository_providers.dart';

/// All bills ordered by due date.
final billsProvider = StreamProvider<List<BillEntity>>(
  (ref) => ref.watch(billRepositoryProvider).watchAll(),
);

/// Unpaid bills only, ordered by due date.
final unpaidBillsProvider = StreamProvider<List<BillEntity>>(
  (ref) => ref.watch(billRepositoryProvider).watchUnpaid(),
);
