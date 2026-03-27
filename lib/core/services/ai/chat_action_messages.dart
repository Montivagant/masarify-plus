/// Pre-resolved l10n messages for [ChatActionExecutor].
///
/// Resolved from `context.l10n` in the UI layer and injected into the
/// executor, keeping it free of Flutter/l10n dependencies.
class ChatActionMessages {
  const ChatActionMessages({
    required this.invalidAmount,
    required this.invalidTarget,
    required this.invalidBudgetLimit,
    required this.categoryNotFound,
    required this.noActiveWallet,
    required this.budgetExists,
    required this.walletExists,
    required this.walletNotFound,
    required this.transferSameWallet,
    required this.txNotFound,
    required this.goalCreated,
    required this.txRecorded,
    required this.budgetCreated,
    required this.recurringCreated,
    required this.walletCreated,
    required this.transferCreated,
    required this.txDeleted,
  });

  // ── Errors (simple strings) ───────────────────────────────────────────
  final String invalidAmount;
  final String invalidTarget;
  final String invalidBudgetLimit;
  final String noActiveWallet;
  final String walletExists;
  final String transferSameWallet;

  // ── Errors (parameterized) ────────────────────────────────────────────
  final String Function(String name, String available) categoryNotFound;
  final String Function(String category) budgetExists;
  final String Function(String title) txNotFound;
  final String Function(String name) walletNotFound;

  // ── Success (parameterized) ───────────────────────────────────────────
  final String Function(String name, String amount) goalCreated;
  final String Function(String title, String amount) txRecorded;
  final String Function(String amount, String category) budgetCreated;
  final String Function(String title, String frequency, String amount)
      recurringCreated;
  final String Function(String name, String amount) walletCreated;
  final String Function(String amount, String from, String to) transferCreated;
  final String Function(String title, String amount) txDeleted;
}
