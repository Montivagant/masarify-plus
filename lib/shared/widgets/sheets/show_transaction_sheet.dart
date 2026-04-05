import 'package:flutter/material.dart';

import '../../../features/transactions/presentation/screens/add_transaction_screen.dart';

/// Re-exported sheet launchers so cross-feature callers import from
/// `shared/` instead of reaching into `features/transactions/`.
Future<void> showTransactionSheet(
  BuildContext context, {
  String initialType = 'expense',
}) =>
    AddTransactionScreen.show(context, initialType: initialType);

Future<void> showEditTransactionSheet(BuildContext context, int editId) =>
    AddTransactionScreen.showEdit(context, editId);
