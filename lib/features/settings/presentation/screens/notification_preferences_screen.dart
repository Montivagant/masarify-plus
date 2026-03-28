import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Per-type notification preference toggles.
///
/// Persists to SharedPreferences via [PreferencesService].
/// Sections: Budget alerts, Bills & Recurring, Goals, Daily reminder,
/// Quiet hours.
class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  // Local toggles — initialised from prefs in didChangeDependencies.
  bool _budgetWarning = true;
  bool _budgetExceeded = true;
  bool _billReminder = true;
  bool _recurringReminder = true;
  bool _goalMilestone = true;
  bool _dailyReminder = false;
  int _dailyHour = 20;
  int _dailyMinute = 0;
  bool _quietHours = false;
  int _quietStart = 22;
  int _quietEnd = 7;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await ref.read(preferencesFutureProvider.future);
    if (!mounted) return;
    setState(() {
      _budgetWarning = prefs.notifyBudgetWarning;
      _budgetExceeded = prefs.notifyBudgetExceeded;
      _billReminder = prefs.notifyBillReminder;
      _recurringReminder = prefs.notifyRecurring;
      _goalMilestone = prefs.notifyGoalMilestone;
      _dailyReminder = prefs.notifyDailyReminder;
      _dailyHour = prefs.dailyReminderHour;
      _dailyMinute = prefs.dailyReminderMinute;
      _quietHours = prefs.quietHoursEnabled;
      _quietStart = prefs.quietHoursStart;
      _quietEnd = prefs.quietHoursEnd;
    });
  }

  Future<void> _setDailyReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _dailyHour, minute: _dailyMinute),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dailyHour = picked.hour;
      _dailyMinute = picked.minute;
    });
    final prefs = await ref.read(preferencesFutureProvider.future);
    await prefs.setDailyReminderTime(picked.hour, picked.minute);
    if (_dailyReminder) {
      await _scheduleRecap(picked.hour, picked.minute);
    }
  }

  Future<void> _scheduleRecap(int hour, int minute) async {
    // Cache l10n before potential async gap (context may become invalid).
    final title = context.l10n.recap_notification_title;
    final body = context.l10n.recap_notification_body;
    await NotificationService.scheduleDaily(
      id: NotificationService.recapNotificationId,
      title: title,
      body: body,
      hour: hour,
      minute: minute,
      payload: 'recap',
    );
  }

  Future<void> _setQuietHour({required bool isStart}) async {
    final initial = isStart ? _quietStart : _quietEnd;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial, minute: 0),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _quietStart = picked.hour;
      } else {
        _quietEnd = picked.hour;
      }
    });
    final prefs = await ref.read(preferencesFutureProvider.future);
    await prefs.setQuietHours(_quietStart, _quietEnd);
  }

  /// H-14: Request POST_NOTIFICATIONS permission on Android 13+ when user
  /// first enables any toggle. Returns true if granted (or pre-13 device).
  Future<bool> _ensureNotificationPermission() async {
    final granted = await NotificationService.requestPermission();
    // requestPermission() returns false on denial; true on grant or pre-API 33.
    if (!granted && mounted) {
      SnackHelper.showError(context, context.l10n.notif_permission_denied);
    }
    return granted;
  }

  String _formatTime(int hour, int minute) {
    final time = TimeOfDay(hour: hour, minute: minute);
    return time.format(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppAppBar(title: l10n.notif_prefs_title),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
        children: [
          // ── Budget Alerts ─────────────────────────────────────
          _SectionTitle(title: l10n.notif_section_budget),
          SwitchListTile(
            title:
                Text('${l10n.notif_budget_warning}${l10n.notif_coming_soon}'),
            subtitle: Text(l10n.notif_budget_warning_sub),
            value: _budgetWarning,
            onChanged: (v) async {
              if (v && !await _ensureNotificationPermission()) return;
              setState(() => _budgetWarning = v);
              final prefs = await ref.read(preferencesFutureProvider.future);
              if (!mounted) return;
              await prefs.setNotifyBudgetWarning(v);
            },
          ),
          SwitchListTile(
            title:
                Text('${l10n.notif_budget_exceeded}${l10n.notif_coming_soon}'),
            subtitle: Text(l10n.notif_budget_exceeded_sub),
            value: _budgetExceeded,
            onChanged: (v) async {
              if (v && !await _ensureNotificationPermission()) return;
              setState(() => _budgetExceeded = v);
              final prefs = await ref.read(preferencesFutureProvider.future);
              if (!mounted) return;
              await prefs.setNotifyBudgetExceeded(v);
            },
          ),

          const Divider(height: 1),

          // ── Bills & Recurring ─────────────────────────────────
          _SectionTitle(title: l10n.notif_section_bills),
          SwitchListTile(
            title: Text(l10n.notif_bill_reminder),
            subtitle: Text(l10n.notif_bill_reminder_sub),
            value: _billReminder,
            onChanged: (v) async {
              if (v && !await _ensureNotificationPermission()) return;
              setState(() => _billReminder = v);
              final prefs = await ref.read(preferencesFutureProvider.future);
              if (!mounted) return;
              await prefs.setNotifyBillReminder(v);
            },
          ),
          SwitchListTile(
            title: Text(l10n.notif_recurring_reminder),
            subtitle: Text(l10n.notif_recurring_reminder_sub),
            value: _recurringReminder,
            onChanged: (v) async {
              if (v && !await _ensureNotificationPermission()) return;
              setState(() => _recurringReminder = v);
              final prefs = await ref.read(preferencesFutureProvider.future);
              if (!mounted) return;
              await prefs.setNotifyRecurring(v);
            },
          ),

          const Divider(height: 1),

          // ── Goals ─────────────────────────────────────────────
          _SectionTitle(title: l10n.notif_section_goals),
          SwitchListTile(
            title:
                Text('${l10n.notif_goal_milestone}${l10n.notif_coming_soon}'),
            subtitle: Text(l10n.notif_goal_milestone_sub),
            value: _goalMilestone,
            onChanged: (v) async {
              if (v && !await _ensureNotificationPermission()) return;
              setState(() => _goalMilestone = v);
              final prefs = await ref.read(preferencesFutureProvider.future);
              if (!mounted) return;
              await prefs.setNotifyGoalMilestone(v);
            },
          ),

          const Divider(height: 1),

          // ── Daily Spending Recap ───────────────────────────────
          _SectionTitle(title: l10n.settings_daily_recap),
          SwitchListTile(
            title: Text(l10n.notif_daily_reminder),
            subtitle: Text(l10n.settings_daily_recap_subtitle),
            value: _dailyReminder,
            onChanged: (v) async {
              if (v && !await _ensureNotificationPermission()) return;
              setState(() => _dailyReminder = v);
              final prefs = await ref.read(preferencesFutureProvider.future);
              if (!mounted) return;
              await prefs.setNotifyDailyReminder(v);
              if (v) {
                await _scheduleRecap(_dailyHour, _dailyMinute);
              } else {
                await NotificationService.cancelScheduled(
                  NotificationService.recapNotificationId,
                );
              }
            },
          ),
          if (_dailyReminder)
            ListTile(
              title: Text(l10n.settings_recap_time),
              trailing: Text(
                _formatTime(_dailyHour, _dailyMinute),
                style: context.textStyles.bodyLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: _setDailyReminderTime,
            ),

          const Divider(height: 1),

          // ── Quiet Hours ───────────────────────────────────────
          _SectionTitle(title: l10n.notif_section_quiet),
          SwitchListTile(
            title: Text(l10n.notif_quiet_hours),
            subtitle: Text(l10n.notif_quiet_hours_sub),
            value: _quietHours,
            onChanged: (v) async {
              if (v && !await _ensureNotificationPermission()) return;
              setState(() => _quietHours = v);
              final prefs = await ref.read(preferencesFutureProvider.future);
              if (!mounted) return;
              await prefs.setQuietHoursEnabled(v);
            },
          ),
          if (_quietHours) ...[
            ListTile(
              title: Text(l10n.notif_quiet_start),
              trailing: Text(
                _formatTime(_quietStart, 0),
                style: context.textStyles.bodyLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _setQuietHour(isStart: true),
            ),
            ListTile(
              title: Text(l10n.notif_quiet_end),
              trailing: Text(
                _formatTime(_quietEnd, 0),
                style: context.textStyles.bodyLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _setQuietHour(isStart: false),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSizes.screenHPadding,
        AppSizes.lg,
        AppSizes.screenHPadding,
        AppSizes.xs,
      ),
      child: Text(
        title,
        style: context.textStyles.titleSmall?.copyWith(
          color: context.colors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
