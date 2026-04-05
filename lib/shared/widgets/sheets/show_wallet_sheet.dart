import 'package:flutter/material.dart';

import '../../../features/wallets/presentation/screens/add_wallet_screen.dart';

/// Re-exported sheet launchers so cross-feature callers import from
/// `shared/` instead of reaching into `features/wallets/`.
Future<void> showWalletSheet(BuildContext context) =>
    AddWalletScreen.show(context);

Future<void> showEditWalletSheet(BuildContext context, int editId) =>
    AddWalletScreen.showEdit(context, editId);
