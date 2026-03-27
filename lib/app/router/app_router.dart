import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_durations.dart';
import '../../core/constants/app_routes.dart';
import '../../core/services/ai/recurring_pattern_detector.dart';
import '../../core/services/app_lock_service.dart';
import '../../core/utils/voice_transaction_parser.dart';
import '../../features/ai_chat/presentation/screens/chat_screen.dart';
import '../../features/auth/presentation/screens/pin_entry_screen.dart';
import '../../features/auth/presentation/screens/pin_setup_screen.dart';
import '../../features/budgets/presentation/screens/budgets_screen.dart';
import '../../features/budgets/presentation/screens/set_budget_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/categories/presentation/screens/add_category_screen.dart';
import '../../features/categories/presentation/screens/categories_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/goals/presentation/screens/add_goal_screen.dart';
import '../../features/goals/presentation/screens/goal_detail_screen.dart';
import '../../features/goals/presentation/screens/goals_screen.dart';
import '../../features/hub/presentation/screens/hub_screen.dart';
import '../../features/monetization/presentation/screens/paywall_screen.dart';
import '../../features/monetization/presentation/screens/subscription_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/quick_start/presentation/screens/quick_start_screen.dart';
import '../../features/recurring/presentation/screens/add_recurring_screen.dart';
import '../../features/recurring/presentation/screens/recurring_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/backup_export_screen.dart';
import '../../features/settings/presentation/screens/notification_preferences_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/sms_parser/presentation/screens/parser_review_screen.dart';
import '../../features/transactions/presentation/screens/add_transaction_screen.dart';
import '../../features/transactions/presentation/screens/transaction_detail_screen.dart';
import '../../features/voice_input/presentation/screens/voice_confirm_screen.dart';
import '../../features/wallets/presentation/screens/add_wallet_screen.dart';
import '../../features/wallets/presentation/screens/transfer_screen.dart';
import '../../features/wallets/presentation/screens/wallet_detail_screen.dart';
import '../../features/wallets/presentation/screens/wallets_screen.dart';
import '../../shared/widgets/navigation/app_nav_bar.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Shared fade transition for pushed screens.
CustomTransitionPage<T> _fadePage<T>({
  required Widget child,
  required GoRouterState state,
}) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );

/// E8: Slide-up + fade transition for add/create routes.
CustomTransitionPage<T> _slideUpPage<T>({
  required Widget child,
  required GoRouterState state,
}) =>
    CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: AppDurations.pageTransition,
      transitionsBuilder: (_, animation, __, child) {
        final tween = Tween(begin: const Offset(0, 0.05), end: Offset.zero);
        return SlideTransition(
          position: tween.animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );

/// C4 fix: safe int parsing for route parameters — returns null on malformed IDs.
int? _parseId(GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '');

/// H2 fix: routes that are allowed without PIN authentication.
const _publicRoutes = {
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.pinSetup,
  AppRoutes.pinEntry,
};

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  // H2 fix: global redirect guard to prevent deep-link PIN bypass.
  // AppLockService.requiresAuth is set by splash screen when PIN is enabled.
  // AppLockService.isUnlocked is set by PinEntryScreen on successful auth.
  redirect: (context, state) {
    final path = state.matchedLocation;
    if (_publicRoutes.contains(path)) return null;

    final lock = AppLockService.instance;
    if (lock.requiresAuth && !lock.isUnlocked) {
      return AppRoutes.pinEntry;
    }
    return null;
  },
  routes: [
    // ── Full-screen routes (no bottom nav) ────────────────────────────────────
    GoRoute(
      path: AppRoutes.splash,
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, __) => const OnboardingScreen(),
    ),

    // Auth
    GoRoute(
      path: AppRoutes.pinSetup,
      builder: (_, __) => const PinSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.pinEntry,
      builder: (_, __) => const PinEntryScreen(),
    ),

    // Transactions — static routes before parameterised ones
    GoRoute(
      path: AppRoutes.transactionAdd,
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return _slideUpPage(
          state: state,
          child: AddTransactionScreen(
            initialType: extra?['type'] as String? ?? 'expense',
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.transactionEdit,
      redirect: (_, state) =>
          _parseId(state) == null ? AppRoutes.dashboard : null,
      builder: (context, state) =>
          AddTransactionScreen(editId: _parseId(state)!),
    ),
    GoRoute(
      path: AppRoutes.transactionDetail,
      redirect: (_, state) =>
          _parseId(state) == null ? AppRoutes.dashboard : null,
      pageBuilder: (context, state) => _fadePage(
        state: state,
        child: TransactionDetailScreen(id: _parseId(state)!),
      ),
    ),

    // Wallets — static routes before parameterised ones
    GoRoute(
      path: AppRoutes.wallets,
      builder: (_, __) => const WalletsScreen(),
    ),
    GoRoute(
      path: AppRoutes.walletAdd,
      pageBuilder: (_, state) => _slideUpPage(
        state: state,
        child: const AddWalletScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.walletEdit,
      redirect: (_, state) =>
          _parseId(state) == null ? AppRoutes.dashboard : null,
      builder: (context, state) => AddWalletScreen(editId: _parseId(state)!),
    ),
    GoRoute(
      path: AppRoutes.walletDetail,
      redirect: (_, state) =>
          _parseId(state) == null ? AppRoutes.dashboard : null,
      builder: (context, state) => WalletDetailScreen(id: _parseId(state)!),
    ),
    GoRoute(
      path: AppRoutes.transfer,
      builder: (_, __) => const TransferScreen(),
    ),

    // Categories — static routes before parameterised ones
    GoRoute(
      path: AppRoutes.categories,
      builder: (_, __) => const CategoriesScreen(),
    ),
    GoRoute(
      path: AppRoutes.categoryAdd,
      pageBuilder: (_, state) => _slideUpPage(
        state: state,
        child: const AddCategoryScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.categoryEdit,
      redirect: (_, state) =>
          _parseId(state) == null ? AppRoutes.dashboard : null,
      builder: (context, state) => AddCategoryScreen(editId: _parseId(state)!),
    ),

    // Budgets — standalone list (pushed from Hub)
    GoRoute(
      path: AppRoutes.budgets,
      builder: (_, __) => const BudgetsScreen(),
    ),
    // Budgets (push routes over the shell)
    GoRoute(
      path: AppRoutes.budgetSet,
      pageBuilder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return _slideUpPage(
          state: state,
          child: SetBudgetScreen(
            initialYear: extra?['year'] as int?,
            initialMonth: extra?['month'] as int?,
          ),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.budgetEdit,
      redirect: (_, state) =>
          _parseId(state) == null ? AppRoutes.dashboard : null,
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SetBudgetScreen(
          editId: _parseId(state)!,
          initialYear: extra?['year'] as int?,
          initialMonth: extra?['month'] as int?,
        );
      },
    ),

    // Goals — static routes before parameterised ones
    // Note: /goals/add must precede /goals/:id to avoid shadowing.
    GoRoute(
      path: AppRoutes.goalAdd,
      pageBuilder: (_, state) => _slideUpPage(
        state: state,
        child: const AddGoalScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.goalEdit,
      redirect: (_, state) =>
          _parseId(state) == null ? AppRoutes.dashboard : null,
      builder: (context, state) => AddGoalScreen(editId: _parseId(state)!),
    ),
    GoRoute(
      path: AppRoutes.goalDetail,
      redirect: (_, state) =>
          _parseId(state) == null ? AppRoutes.dashboard : null,
      builder: (context, state) => GoalDetailScreen(id: _parseId(state)!),
    ),
    // Standalone goals list — for deep-link access (e.g. from notifications).
    GoRoute(
      path: AppRoutes.goals,
      builder: (_, __) => const GoalsScreen(),
    ),

    // Recurring — static routes before parameterised ones
    GoRoute(
      path: AppRoutes.recurringAdd,
      pageBuilder: (_, state) => _slideUpPage(
        state: state,
        child: AddRecurringScreen(
          detectedPattern: state.extra as DetectedPattern?,
        ),
      ),
    ),
    GoRoute(
      path: AppRoutes.recurringEdit,
      redirect: (_, state) =>
          _parseId(state) == null ? AppRoutes.dashboard : null,
      builder: (context, state) => AddRecurringScreen(editId: _parseId(state)!),
    ),

    // Smart input
    GoRoute(
      path: AppRoutes.voiceConfirm,
      pageBuilder: (_, state) => _slideUpPage(
        child: VoiceConfirmScreen(
          drafts: state.extra as List<VoiceTransactionDraft>? ?? [],
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRoutes.parserReview,
      redirect: (_, __) => AppConfig.kSmsEnabled ? null : AppRoutes.dashboard,
      builder: (_, __) => const ParserReviewScreen(),
    ),
    GoRoute(
      path: AppRoutes.chat,
      pageBuilder: (_, state) => _fadePage(
        state: state,
        child: ChatScreen(
          recapMode: state.uri.queryParameters['mode'] == 'recap',
        ),
      ),
    ),
    // Reports
    GoRoute(
      path: AppRoutes.calendar,
      builder: (_, __) => const CalendarScreen(),
    ),
    GoRoute(
      path: AppRoutes.reports,
      builder: (_, __) => const ReportsScreen(),
    ),
    // Settings
    GoRoute(
      path: AppRoutes.settings,
      pageBuilder: (_, state) => _fadePage(
        state: state,
        child: const SettingsScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.settingsBackup,
      builder: (_, __) => const BackupExportScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsNotifications,
      builder: (_, __) => const NotificationPreferencesScreen(),
    ),
    GoRoute(
      path: AppRoutes.settingsSubscription,
      builder: (_, __) => const SubscriptionScreen(),
    ),

    // Quick Start wizard
    GoRoute(
      path: AppRoutes.quickStart,
      builder: (_, __) => const QuickStartScreen(),
    ),

    // Monetization (Phase 5)
    GoRoute(
      path: AppRoutes.paywall,
      builder: (_, __) => const PaywallScreen(),
    ),

    // ── Stateful shell (4-tab bottom nav + center FAB) ──────────────────────
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: _rootNavigatorKey,
      builder: (_, __, shell) => AppScaffoldShell(navigationShell: shell),
      branches: [
        // Tab 0: Home / Dashboard
        StatefulShellBranch(
          navigatorKey: _shellNavigatorKey,
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              builder: (_, __) => const DashboardScreen(),
            ),
          ],
        ),
        // Tab 1: Recurring & Bills
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.recurring,
              builder: (_, __) => const RecurringScreen(),
            ),
          ],
        ),
        // Tab 2: Analytics (top-level — budget moved to Hub)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.analytics,
              builder: (_, __) => const ReportsScreen(),
            ),
          ],
        ),
        // Tab 3: More / Hub (now includes Budgets & Goals)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.hub,
              builder: (_, __) => const HubScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
