/// All route name constants for Masarify.
/// NEVER use raw strings for route names — use these constants.
abstract final class AppRoutes {
  // ── Shell / Auth ──────────────────────────────────────────────────────
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String pinSetup = '/auth/pin-setup';
  static const String pinEntry = '/auth/pin-entry';

  // ── Main shell ────────────────────────────────────────────────────────
  static const String dashboard = '/';
  static const String transactions = '/transactions';
  static const String transactionAdd = '/transactions/add';
  static const String transactionEdit = '/transactions/:id/edit';
  static const String transactionDetail = '/transactions/:id';
  static const String budgets = '/budgets';
  static const String budgetSet = '/budgets/set';
  static const String budgetEdit = '/budgets/:id/edit';
  static const String goals = '/goals';
  static const String goalAdd = '/goals/add';
  static const String goalEdit = '/goals/:id/edit';
  static const String goalDetail = '/goals/:id';
  static const String hub = '/more';

  // ── Wallets ───────────────────────────────────────────────────────────
  static const String wallets = '/wallets';
  static const String walletAdd = '/wallets/add';
  static const String walletEdit = '/wallets/:id/edit';
  static const String walletDetail = '/wallets/:id';
  static const String transfer = '/transfer';

  // ── Categories ────────────────────────────────────────────────────────
  static const String categories = '/categories';
  static const String categoryAdd = '/categories/add';
  static const String categoryEdit = '/categories/:id/edit';

  // ── Recurring & Bills ─────────────────────────────────────────────────
  static const String recurring = '/recurring';
  static const String recurringAdd = '/recurring/add';
  static const String recurringEdit = '/recurring/:id/edit';
  static const String bills = '/bills';
  static const String billAdd = '/bills/add';
  static const String billEdit = '/bills/:id/edit';

  // ── Smart input ───────────────────────────────────────────────────────
  static const String voiceConfirm = '/voice/confirm';
  static const String parserReview = '/parser/review';

  // ── Reports ─────────────────────────────────────────────────────────
  static const String analytics = '/analytics';
  static const String calendar = '/calendar';
  static const String reports = '/reports';
  static const String netWorth = '/net-worth';

  // ── Settings ──────────────────────────────────────────────────────────
  static const String settings = '/settings';
  static const String settingsBackup = '/settings/backup';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsSubscription = '/settings/subscription';

  // ── Monetization (Phase 5) ────────────────────────────────────────────
  static const String paywall = '/paywall';

  // ── Parametric helpers ──────────────────────────────────────────────────
  static String walletDetailPath(int id) => '/wallets/$id';
  static String editWalletPath(int id) => '/wallets/$id/edit';
  static String transactionDetailPath(int id) => '/transactions/$id';
  static String editCategoryPath(int id) => '/categories/$id/edit';
  static String goalDetailPath(int id) => '/goals/$id';
  static String editGoalPath(int id) => '/goals/$id/edit';
}
