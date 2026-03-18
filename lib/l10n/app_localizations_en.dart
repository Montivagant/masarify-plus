// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Masarify';

  @override
  String get appTagline => 'Track Every Pound. Own Your Money.';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_transactions => 'Transactions';

  @override
  String get nav_budgets => 'Budgets';

  @override
  String get nav_analytics => 'Analytics';

  @override
  String get nav_more => 'More';

  @override
  String get dashboard_title => 'Masarify';

  @override
  String get dashboard_net_balance => 'Net Balance';

  @override
  String get dashboard_income => 'Income';

  @override
  String get dashboard_expense => 'Expense';

  @override
  String get dashboard_recent_transactions => 'Recent';

  @override
  String get dashboard_see_all => 'See All';

  @override
  String get dashboard_quick_add_expense => '+ Expense';

  @override
  String get dashboard_quick_add_income => '+ Income';

  @override
  String get dashboard_spending_overview => 'Spending Overview';

  @override
  String get dashboard_budget_alerts => 'Budget Alerts';

  @override
  String get dashboard_manage_budgets => 'Manage Budgets';

  @override
  String get dashboard_welcome_empty => 'Welcome to Masarify!';

  @override
  String get dashboard_welcome_empty_sub =>
      'Tap + to add your first transaction';

  @override
  String get transactions_title => 'Transactions';

  @override
  String get transactions_search_hint => 'Search transactions...';

  @override
  String get transactions_filter => 'Filter';

  @override
  String get transactions_empty_title => 'No transactions yet';

  @override
  String get transactions_empty_sub => 'Tap + to add your first one';

  @override
  String get transactions_add => 'Add Transaction';

  @override
  String get transaction_type_expense => 'Expense';

  @override
  String get transaction_type_income => 'Income';

  @override
  String get transaction_type_transfer => 'Transfer';

  @override
  String get transaction_title_label => 'Title';

  @override
  String get transaction_title_hint => 'e.g. Coffee, Grocery run...';

  @override
  String get transaction_note => 'Note';

  @override
  String get transaction_date => 'Date';

  @override
  String get transaction_wallet => 'Account';

  @override
  String get transaction_category => 'Category';

  @override
  String get transaction_tags => 'Tags';

  @override
  String get transaction_location => 'Location';

  @override
  String get transaction_all_categories => 'All Categories';

  @override
  String get transaction_amount_hint => '0.00';

  @override
  String get transaction_save => 'Save';

  @override
  String get transaction_saved => 'Transaction saved';

  @override
  String get transaction_deleted => 'Transaction deleted';

  @override
  String get transaction_undo => 'Undo';

  @override
  String get transaction_source_voice => 'Voice';

  @override
  String get transaction_source_sms => 'SMS';

  @override
  String get transaction_source_notification => 'Notification';

  @override
  String get transaction_source_import => 'Import';

  @override
  String get wallets_title => 'Accounts';

  @override
  String get wallets_add => 'Add Account';

  @override
  String get wallets_transfer => 'Transfer';

  @override
  String get wallet_type_physical_cash => 'Cash';

  @override
  String get wallet_type_bank => 'Bank Account';

  @override
  String get wallet_type_mobile_wallet => 'Mobile Wallet';

  @override
  String get wallet_type_credit_card => 'Credit Card';

  @override
  String get wallet_type_prepaid_card => 'Prepaid Card';

  @override
  String get wallet_type_investment => 'Investment Account';

  @override
  String get wallet_name_hint => 'Account name';

  @override
  String get wallet_initial_balance => 'Initial Balance';

  @override
  String get wallet_delete_warning =>
      'Cannot delete account with existing transactions';

  @override
  String get wallet_balance => 'Balance';

  @override
  String get categories_title => 'Categories';

  @override
  String get categories_expense => 'Expense';

  @override
  String get categories_income => 'Income';

  @override
  String get category_add => 'Add Category';

  @override
  String get category_name_en => 'Name (English)';

  @override
  String get category_name_ar => 'Name (Arabic)';

  @override
  String get category_name_label => 'Category Name';

  @override
  String get category_name_hint => 'e.g. Coffee, Groceries';

  @override
  String get category_icon => 'Icon';

  @override
  String get category_color => 'Color';

  @override
  String get category_type => 'Type';

  @override
  String get category_delete_default_warning =>
      'Default categories cannot be deleted';

  @override
  String get budgets_title => 'Budgets';

  @override
  String get budgets_empty_title => 'No budgets set';

  @override
  String get budgets_empty_sub => 'Set monthly limits to control spending';

  @override
  String get budget_set => 'Set Budget';

  @override
  String get budget_limit => 'Monthly Limit';

  @override
  String get budget_rollover => 'Rollover unused amount';

  @override
  String get budget_spent => 'Spent';

  @override
  String get budget_remaining => 'Remaining';

  @override
  String budget_alert_80(String category) {
    return '$category budget at 80%';
  }

  @override
  String budget_alert_100(String category) {
    return '$category budget exceeded!';
  }

  @override
  String get goals_title => 'Goals';

  @override
  String get goals_empty_title => 'No savings goals';

  @override
  String get goals_empty_sub => 'Set a goal and start saving';

  @override
  String get goal_add => 'Create Goal';

  @override
  String get goal_target => 'Target Amount';

  @override
  String get goal_deadline => 'Target Date (optional)';

  @override
  String get goal_keywords => 'Auto-match keywords';

  @override
  String get goal_contribute => 'Add Money';

  @override
  String get goal_completed => 'Goal Completed! 🎉';

  @override
  String get goal_overdue => 'Overdue';

  @override
  String goal_progress(int percent) {
    return '$percent% reached';
  }

  @override
  String get recurring_add => 'Add Recurring';

  @override
  String get recurring_edit => 'Edit Recurring';

  @override
  String get recurring_frequency_daily => 'Daily';

  @override
  String get recurring_frequency_weekly => 'Weekly';

  @override
  String get recurring_frequency_monthly => 'Monthly';

  @override
  String get recurring_frequency_yearly => 'Yearly';

  @override
  String get recurring_frequency_custom => 'Custom';

  @override
  String get recurring_next_due => 'Next due';

  @override
  String get recurring_and_bills_title => 'Recurring & Bills';

  @override
  String get recurring_overdue => 'Overdue';

  @override
  String get recurring_upcoming_bills => 'Upcoming Bills';

  @override
  String get recurring_paid => 'Paid';

  @override
  String get recurring_mark_paid => 'Mark Paid';

  @override
  String get recurring_mark_paid_confirm =>
      'Mark this bill as paid? A transaction will be recorded.';

  @override
  String get recurring_bill_paid_success => 'Bill marked as paid';

  @override
  String get recurring_due_date_label => 'Due';

  @override
  String get recurring_frequency_once => 'One-time';

  @override
  String get reports_title => 'Analytics';

  @override
  String get reports_overview => 'Overview';

  @override
  String get reports_categories => 'Categories';

  @override
  String get reports_trends => 'Trends';

  @override
  String get reports_comparison => 'Comparison';

  @override
  String get reports_empty_title => 'Not enough data';

  @override
  String get reports_empty_sub => 'Add some transactions to see insights';

  @override
  String get calendar_title => 'Calendar';

  @override
  String get calendar_empty_title => 'No activity this month';

  @override
  String get chat_title => 'Masarify AI';

  @override
  String get chat_input_hint => 'Ask about your finances...';

  @override
  String get chat_clear => 'Clear chat';

  @override
  String get chat_clear_confirm => 'Delete all messages?';

  @override
  String get chat_offline => 'You\'re offline — chat requires internet';

  @override
  String get chat_error_rate_limit => 'Too many requests, try again shortly';

  @override
  String get chat_error_unauthorized => 'API key issue, check settings';

  @override
  String get chat_error_timeout => 'Response timed out, try again';

  @override
  String get chat_error_generic => 'Something went wrong, try again';

  @override
  String get chat_action_confirm => 'Confirm';

  @override
  String get chat_action_cancel => 'Cancel';

  @override
  String get chat_action_retry => 'Retry';

  @override
  String get chat_action_confirmed => 'Created successfully!';

  @override
  String get chat_action_cancelled => 'Cancelled';

  @override
  String get chat_action_failed => 'Failed — try again?';

  @override
  String get chat_action_goal_title => 'Create Savings Goal';

  @override
  String get chat_action_tx_title => 'Create Transaction';

  @override
  String get hub_title => 'More';

  @override
  String get hub_section_money => 'Money';

  @override
  String get hub_section_reports => 'Reports';

  @override
  String get hub_section_planning => 'Planning';

  @override
  String get hub_section_ai => 'AI Assistant';

  @override
  String get hub_section_app => 'App';

  @override
  String get hub_wallets => 'Accounts';

  @override
  String get hub_analytics => 'Analytics';

  @override
  String get hub_calendar => 'Calendar';

  @override
  String get hub_recurring => 'Recurring';

  @override
  String get hub_settings => 'Settings';

  @override
  String get hub_backup => 'Backup & Export';

  @override
  String get hub_about => 'About';

  @override
  String get hub_help => 'Help & FAQ';

  @override
  String get hub_active => 'active';

  @override
  String get hub_in_progress => 'in progress';

  @override
  String get hub_new_label => 'new';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_general => 'General';

  @override
  String get settings_security => 'Security';

  @override
  String get settings_data => 'Data';

  @override
  String get settings_about => 'About';

  @override
  String get settings_language => 'Language';

  @override
  String get settings_currency => 'Currency';

  @override
  String get settings_theme => 'Theme';

  @override
  String get settings_theme_light => 'Light';

  @override
  String get settings_theme_dark => 'Dark';

  @override
  String get settings_theme_system => 'System';

  @override
  String get settings_first_day_of_week => 'First Day of Week';

  @override
  String get settings_first_day_of_month => 'First Day of Month';

  @override
  String get settings_pin_setup => 'Set PIN';

  @override
  String get settings_pin_change => 'Change PIN';

  @override
  String get settings_biometric => 'Biometric Login';

  @override
  String get settings_auto_lock => 'Auto-lock';

  @override
  String get settings_auto_lock_subtitle => 'Lock app after inactivity';

  @override
  String get settings_auto_lock_immediate => 'Immediate';

  @override
  String get settings_auto_lock_1_min => 'After 1 minute';

  @override
  String get settings_auto_lock_5_min => 'After 5 minutes';

  @override
  String get settings_pin_enabled => 'PIN enabled';

  @override
  String get settings_pin_disabled => 'PIN removed';

  @override
  String get settings_biometric_enabled => 'Biometric login enabled';

  @override
  String get settings_biometric_disabled => 'Biometric login disabled';

  @override
  String get settings_biometric_unavailable =>
      'Biometric authentication not available on this device';

  @override
  String get settings_verify_pin_first => 'Verify your current PIN';

  @override
  String settings_pin_lockout(String duration) {
    return 'Too many attempts. Try again in $duration.';
  }

  @override
  String get settings_clear_data => 'Clear All Data';

  @override
  String get settings_clear_data_confirm => 'Type DELETE to confirm';

  @override
  String get settings_voice_input => 'Voice Input';

  @override
  String get settings_notification_parser => 'Notification Parser';

  @override
  String get settings_sms_parser => 'SMS Parser';

  @override
  String get settings_language_changed => 'Language changed';

  @override
  String get backup_title => 'Backup & Export';

  @override
  String get backup_export_json => 'Export Backup (JSON)';

  @override
  String get backup_restore => 'Restore Backup';

  @override
  String get backup_export_csv => 'Export as CSV';

  @override
  String get backup_export_pdf => 'Export PDF Report';

  @override
  String get backup_success => 'Backup created successfully';

  @override
  String get backup_restore_success => 'Data restored successfully';

  @override
  String get backup_error_invalid => 'Invalid backup file';

  @override
  String get backup_error_version => 'This backup requires a newer version';

  @override
  String get backup_confirm_restore_title => 'Restore Backup?';

  @override
  String get backup_confirm_restore_body =>
      'This will replace all current data with the backup. This action cannot be undone.';

  @override
  String get backup_select_month => 'Select Month';

  @override
  String get backup_exporting => 'Exporting...';

  @override
  String get backup_restoring => 'Restoring...';

  @override
  String get backup_export_json_subtitle =>
      'Full database backup for transfer or safekeeping';

  @override
  String get backup_restore_subtitle => 'Replace all data from a backup file';

  @override
  String get backup_export_csv_subtitle =>
      'Monthly transactions in spreadsheet format';

  @override
  String get backup_export_pdf_subtitle => 'Monthly financial summary report';

  @override
  String get auth_pin_setup_title => 'Set PIN';

  @override
  String get auth_pin_setup_subtitle =>
      'Create a 6-digit PIN to protect your data';

  @override
  String get auth_pin_confirm => 'Confirm PIN';

  @override
  String get auth_pin_mismatch => 'PINs don\'t match. Try again.';

  @override
  String get auth_pin_entry_title => 'Enter PIN';

  @override
  String get auth_pin_wrong => 'Incorrect PIN';

  @override
  String get auth_biometric_prompt => 'Authenticate to open Masarify';

  @override
  String get auth_use_pin => 'Use PIN instead';

  @override
  String get onboarding_page1_title => 'Take Control of Your Money';

  @override
  String get onboarding_page1_subtitle => 'Track Every Pound. Own Your Money.';

  @override
  String get onboarding_page1_cta => 'Get Started';

  @override
  String get onboarding_page2_title => 'What\'s your starting balance?';

  @override
  String get onboarding_page2_subtitle =>
      'We\'ll create a Cash account for you. You can change this later.';

  @override
  String get onboarding_page2_cta => 'Start Tracking';

  @override
  String get onboarding_page2_skip => 'Skip';

  @override
  String get splash_loading => 'Loading...';

  @override
  String get common_save => 'Save';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_edit => 'Edit';

  @override
  String get common_close => 'Close';

  @override
  String get common_confirm => 'Confirm';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_back => 'Back';

  @override
  String get common_done => 'Done';

  @override
  String get common_next => 'Next';

  @override
  String get common_skip => 'Skip';

  @override
  String get common_error_generic => 'Something went wrong. Please try again.';

  @override
  String get common_invalid_amount => 'Invalid amount';

  @override
  String get common_error_db => 'Database error. Please restart the app.';

  @override
  String get common_empty_list => 'Nothing here yet';

  @override
  String get common_loading => 'Loading...';

  @override
  String get common_grant_permission => 'Grant Permission';

  @override
  String get common_maybe_later => 'Maybe Later';

  @override
  String get permission_mic_title => 'Microphone Access';

  @override
  String get permission_mic_body =>
      'Masarify uses your microphone to record voice commands. Audio is sent to Google AI for transcription when you have internet access. Nothing is stored permanently.';

  @override
  String get permission_location_title => 'Location Access';

  @override
  String get permission_location_body =>
      'Masarify can tag your transaction with the location name. This is completely optional.';

  @override
  String get location_detect => 'Detect Location';

  @override
  String get location_detecting => 'Detecting…';

  @override
  String get location_hint => 'e.g. Maadi, Cairo';

  @override
  String get location_failed => 'Could not detect location';

  @override
  String get permission_notification_title => 'Notification Access';

  @override
  String get permission_notification_body =>
      'Masarify can read bank notifications to automatically detect transactions. Nothing is sent to any server.';

  @override
  String get error_amount_zero => 'Amount must be greater than zero';

  @override
  String get error_category_required => 'Please select a category';

  @override
  String get error_wallet_required => 'Please select an account';

  @override
  String get error_name_required => 'Name is required';

  @override
  String get error_pin_too_short => 'PIN must be 6 digits';

  @override
  String get voice_tap_to_start => 'Tap the mic to start';

  @override
  String get voice_listening => 'Recording...';

  @override
  String get voice_processing => 'Processing...';

  @override
  String get voice_confirm_title => 'Review Transactions';

  @override
  String get voice_confirm_all => 'Confirm All';

  @override
  String get voice_remove => 'Remove';

  @override
  String get voice_unavailable => 'Voice input is not available on this device';

  @override
  String get voice_error_no_service =>
      'Voice input is not available. Please check your internet connection.';

  @override
  String get voice_error_no_locale =>
      'No language packs found for speech recognition. Please install one in your device settings.';

  @override
  String get voice_error_speech =>
      'Speech recognition error. Please try again.';

  @override
  String get voice_no_results => 'Nothing detected. Please try again.';

  @override
  String get voice_ai_error => 'AI parsing failed. Please try again.';

  @override
  String get voice_permission_denied =>
      'Microphone permission is required for voice input';

  @override
  String get voice_retry => 'Try Again';

  @override
  String get voice_ai_parsing => 'Analyzing with AI...';

  @override
  String get permission_allow => 'Allow';

  @override
  String get permission_deny => 'Deny';

  @override
  String get sms_review_title => 'Transactions Found';

  @override
  String get parsed_transactions_title => 'Auto-detected Transactions';

  @override
  String get sms_review_approve => 'Approve';

  @override
  String get sms_review_skip => 'Skip';

  @override
  String get sms_review_edit => 'Edit';

  @override
  String sms_new_found(int count) {
    return '$count transaction(s) found — tap to review';
  }

  @override
  String get parser_no_pending => 'No pending transactions to review';

  @override
  String get parser_no_pending_filtered =>
      'No transactions for this source — try \"All\"';

  @override
  String get parser_approved_msg => 'Transaction approved';

  @override
  String get parser_skipped_msg => 'Transaction skipped';

  @override
  String get parser_approve_all => 'Approve All';

  @override
  String get parser_ai_category => 'Suggested Category';

  @override
  String get parser_ai_merchant => 'Merchant';

  @override
  String get parser_ai_note => 'Note';

  @override
  String get parser_enrich => 'Enrich';

  @override
  String get parser_enrich_all => 'Enrich All';

  @override
  String get parser_enriching => 'Enriching…';

  @override
  String get parser_possible_duplicate => 'Possible duplicate';

  @override
  String parser_similar_exists(String date) {
    return 'Similar transaction found ($date)';
  }

  @override
  String get parser_wallet_label => 'Account';

  @override
  String get parser_source_all => 'All';

  @override
  String get parser_source_sms => 'SMS';

  @override
  String get parser_source_notification => 'Notifications';

  @override
  String get parser_approve_as_transfer => 'Approve as Transfer';

  @override
  String get parser_atm_detected => 'ATM Withdrawal';

  @override
  String get parser_select_cash_wallet => 'Select cash wallet';

  @override
  String get parser_duplicate_exists =>
      'Similar transaction already exists. Create anyway?';

  @override
  String parser_auto_resolved(int count) {
    return '$count parsed transaction(s) matched and auto-resolved';
  }

  @override
  String get settings_smart_detection => 'Smart Detection';

  @override
  String get settings_smart_detection_subtitle =>
      'Auto-detect transactions from SMS and notifications';

  @override
  String get settings_ai_models => 'AI & Models';

  @override
  String dashboard_pending_review(int count) {
    return '$count transaction(s) to review';
  }

  @override
  String get dashboard_pending_review_action => 'Review';

  @override
  String goal_link_prompt(String goalName) {
    return 'This looks like it relates to your \'$goalName\'. Link it?';
  }

  @override
  String get goal_link_action => 'Link';

  @override
  String get goal_dismiss => 'Dismiss';

  @override
  String get transfer_from => 'From';

  @override
  String get transfer_to => 'To';

  @override
  String get transfer_fee => 'Transfer Fee (optional)';

  @override
  String get language_en => 'English';

  @override
  String get language_ar => 'Arabic (العربية)';

  @override
  String get language_system => 'System Default';

  @override
  String get pro_badge => 'PRO';

  @override
  String get pro_feature_title => 'Premium Feature';

  @override
  String pro_feature_body(String featureName) {
    return '$featureName is available for PRO subscribers only.\nComing very soon!';
  }

  @override
  String get pro_upgrade => 'Upgrade to Pro';

  @override
  String get subscription_title => 'Pro Subscription';

  @override
  String get paywall_title => 'Masarify Pro';

  @override
  String get common_ok => 'OK';

  @override
  String get common_error_title => 'An error occurred';

  @override
  String get common_all => 'All';

  @override
  String get common_save_changes => 'Save Changes';

  @override
  String get date_today => 'Today';

  @override
  String get date_yesterday => 'Yesterday';

  @override
  String get transaction_edit_title => 'Edit Transaction';

  @override
  String get transaction_detail_title => 'Transaction Details';

  @override
  String get transaction_not_found => 'Transaction not found';

  @override
  String get transaction_delete_title => 'Delete Transaction';

  @override
  String get transaction_delete_confirm =>
      'Are you sure you want to delete this transaction?';

  @override
  String transaction_deleted_message(String title) {
    return 'Deleted \"$title\"';
  }

  @override
  String get transaction_source_label => 'Source';

  @override
  String get transaction_source_manual => 'Manual';

  @override
  String get transaction_no_results => 'No results';

  @override
  String get transaction_try_different => 'Try a different search term';

  @override
  String get transaction_filter_type_title => 'Filter by Type';

  @override
  String get transaction_filter_all => 'All';

  @override
  String get transaction_filter_expenses => 'Expenses';

  @override
  String get transaction_filter_income => 'Income';

  @override
  String get transaction_filter_expenses_chip => 'Expenses';

  @override
  String get transaction_filter_income_chip => 'Income';

  @override
  String get transaction_optional_details => 'Additional details';

  @override
  String get transaction_note_hint => 'Add an optional note...';

  @override
  String get transaction_category_picker => 'Select Category';

  @override
  String get transaction_wallet_picker => 'Select Account';

  @override
  String get wallet_detail_title => 'Account Details';

  @override
  String get wallet_not_found => 'Account not found';

  @override
  String get wallet_add_title => 'New Account';

  @override
  String get wallet_edit_title => 'Edit Account';

  @override
  String get wallet_delete_title => 'Delete Account';

  @override
  String get wallet_delete_confirm =>
      'Are you sure you want to delete this account?';

  @override
  String get wallet_cannot_delete_title => 'Cannot Delete Account';

  @override
  String get wallet_name_label => 'Account Name';

  @override
  String get wallet_name_hint_example => 'e.g. Main Account';

  @override
  String get wallet_name_duplicate =>
      'An account with this name already exists';

  @override
  String get wallet_total_balance => 'Total Balance';

  @override
  String get wallet_current_balance => 'Current Balance';

  @override
  String get wallet_transactions_header => 'Account Transactions';

  @override
  String get wallet_no_transactions_sub =>
      'No transactions recorded for this account yet';

  @override
  String get wallet_cannot_delete_body =>
      'This account has transactions.\nDelete or move them before deleting the account.';

  @override
  String get wallet_type_label => 'Account Type';

  @override
  String get wallet_color_label => 'Account Color';

  @override
  String get wallet_add_button => 'Add Account';

  @override
  String get wallet_type_physical_cash_short => 'Cash';

  @override
  String get wallet_type_bank_short => 'Bank';

  @override
  String get wallet_type_mobile_wallet_short => 'Wallet';

  @override
  String get wallet_type_credit_card_short => 'Credit';

  @override
  String get wallet_type_prepaid_card_short => 'Prepaid';

  @override
  String get wallet_type_investment_short => 'Invest';

  @override
  String get wallet_system_badge => 'System';

  @override
  String get wallet_cannot_archive_system =>
      'The Cash wallet cannot be archived';

  @override
  String get balance_available => 'Available';

  @override
  String get balance_in_goals => 'In Goals';

  @override
  String get goal_link_sheet_title => 'Save to goal?';

  @override
  String goal_link_sheet_subtitle(Object goalName) {
    return 'Would you like to allocate to $goalName?';
  }

  @override
  String get goal_link_sheet_save => 'Save to Goal';

  @override
  String get goal_contribution_from_wallet => 'From account';

  @override
  String goal_contribution_deducted(Object walletName) {
    return 'Deducted from $walletName';
  }

  @override
  String get onboarding_physical_cash_note =>
      'Your cash-in-hand wallet is created automatically';

  @override
  String get wallet_linked_senders_label => 'Linked SMS Senders';

  @override
  String get wallet_linked_senders_hint => 'e.g. CIB, NBE, BankMisr';

  @override
  String get wallet_linked_senders_subtitle =>
      'Match auto-detected transactions to this account';

  @override
  String get wallets_empty_title => 'No accounts yet';

  @override
  String get wallets_empty_sub => 'Add your first account to start tracking';

  @override
  String get wallets_transfer_button => 'Transfer Between Accounts';

  @override
  String get category_add_title => 'New Category';

  @override
  String get category_edit_title => 'Edit Category';

  @override
  String get category_delete_title => 'Delete Category';

  @override
  String category_delete_confirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get category_default_title => 'Default Category';

  @override
  String get category_default_chip => 'Default';

  @override
  String get category_name_ar_label => 'Category Name (Arabic)';

  @override
  String get category_name_ar_hint => 'e.g. Coffee, Transport, Subscription';

  @override
  String get category_name_en_label => 'Category Name (English)';

  @override
  String get category_group_needs => 'Needs';

  @override
  String get category_group_wants => 'Wants';

  @override
  String get category_group_savings => 'Savings';

  @override
  String get categories_empty_title => 'No categories';

  @override
  String get categories_empty_sub =>
      'Add a category to classify your transactions';

  @override
  String get budget_total_label => 'Total';

  @override
  String get budget_spent_label => 'Spent';

  @override
  String get budget_rollover_title => 'Budget Rollover';

  @override
  String get budgets_empty_sub_long =>
      'Set a budget for each category to control your spending';

  @override
  String get goal_detail_title => 'Goal Details';

  @override
  String get goal_not_found => 'Goal not found';

  @override
  String get goal_add_title => 'New Savings Goal';

  @override
  String get goal_edit_title => 'Edit Goal';

  @override
  String get goal_name_label => 'Goal Name';

  @override
  String get goal_name_hint => 'e.g. Japan Trip, New Car';

  @override
  String get goal_detail_add_savings => 'Add Savings';

  @override
  String get goal_already_funded => 'This goal is already fully funded.';

  @override
  String get goal_detail_no_savings => 'No savings yet';

  @override
  String get goal_detail_no_savings_sub => 'Add your first amount to this goal';

  @override
  String get goal_saved_label => 'Saved';

  @override
  String get goal_target_label => 'Target';

  @override
  String get goal_remaining_label => 'Remaining';

  @override
  String get goal_completed_chip => 'Completed';

  @override
  String get goal_target_required => 'Enter a target amount';

  @override
  String get goal_delete_title => 'Delete Goal';

  @override
  String get goal_delete_confirm =>
      'Are you sure you want to delete this goal and all contributions?';

  @override
  String get goal_delete_contribution_confirm =>
      'Are you sure you want to delete this contribution?';

  @override
  String get budget_delete_title => 'Delete Budget';

  @override
  String get budget_delete_confirm =>
      'Are you sure you want to delete this budget?';

  @override
  String get goals_empty_sub_long =>
      'Set a savings goal and start achieving it';

  @override
  String get transfer_title => 'Transfer Between Accounts';

  @override
  String get transfer_amount_label => 'Amount';

  @override
  String get transfer_note_label => 'Note (Optional)';

  @override
  String get transfer_confirm_button => 'Confirm Transfer';

  @override
  String get transfer_different_wallets => 'Select two different accounts';

  @override
  String get transfer_from_wallet => 'From Account';

  @override
  String get transfer_to_wallet => 'To Account';

  @override
  String get transfer_select_wallet => 'Select Account';

  @override
  String get transfer_swap => 'Swap';

  @override
  String get transfer_insufficient_title => 'Insufficient Balance';

  @override
  String get transfer_insufficient_body =>
      'Source account balance is less than the transfer amount. Continue anyway?';

  @override
  String get transfer_success => 'Transfer completed successfully';

  @override
  String get settings_appearance => 'Appearance';

  @override
  String get settings_theme_auto => 'Auto';

  @override
  String get settings_data_management => 'Data Management';

  @override
  String get settings_wallets_label => 'Accounts';

  @override
  String get settings_wallets_subtitle => 'Manage your accounts';

  @override
  String get settings_categories_label => 'Categories';

  @override
  String get settings_categories_subtitle =>
      'Customize expense and income categories';

  @override
  String get settings_pin_subtitle => 'Protect the app with a PIN code';

  @override
  String get settings_biometric_subtitle => 'Biometric authentication';

  @override
  String get settings_backup_section => 'Backup';

  @override
  String get settings_backup_label => 'Backup & Export';

  @override
  String get settings_backup_subtitle => 'Export your data or import a backup';

  @override
  String get settings_danger_zone => 'Danger Zone';

  @override
  String get settings_clear_data_label => 'Delete All Data';

  @override
  String get settings_clear_data_subtitle => 'Clear everything and start fresh';

  @override
  String get settings_clear_data_title => 'Delete All Data';

  @override
  String get settings_clear_data_warning =>
      'This action cannot be undone.\nAll accounts, transactions, budgets, and goals will be deleted.';

  @override
  String get settings_clear_data_permanent => 'Permanent Delete';

  @override
  String get settings_about_section => 'About';

  @override
  String get settings_version => 'Version';

  @override
  String get settings_help_label => 'Help & Support';

  @override
  String get settings_help_subtitle => 'FAQs and contact';

  @override
  String get settings_first_day_budget_cycle =>
      'First Day of Month (Budget Cycle)';

  @override
  String get settings_currency_egp => 'EGP — Egyptian Pound';

  @override
  String get settings_currency_usd => '\$ — US Dollar';

  @override
  String get settings_currency_eur => '€ — Euro';

  @override
  String get settings_currency_sar => 'SAR — Saudi Riyal';

  @override
  String get settings_currency_aed => 'AED — UAE Dirham';

  @override
  String get settings_currency_kwd => 'KWD — Kuwaiti Dinar';

  @override
  String get settings_day_saturday => 'Saturday';

  @override
  String get settings_day_sunday => 'Sunday';

  @override
  String get settings_day_monday => 'Monday';

  @override
  String get settings_pin_lock_label => 'Lock with PIN';

  @override
  String get settings_budget_cycle_subtitle =>
      'Determines the start of the monthly budget cycle';

  @override
  String get common_coming_soon => 'Coming Soon';

  @override
  String get dashboard_income_label => 'Income';

  @override
  String get dashboard_expense_label => 'Expenses';

  @override
  String get dashboard_no_transactions => 'No transactions yet';

  @override
  String get dashboard_start_tracking =>
      'Start by recording your first transaction to track your money';

  @override
  String get dashboard_failed_balance => 'Failed to load balance';

  @override
  String get dashboard_failed_transactions => 'Failed to load transactions';

  @override
  String get dashboard_failed_spending => 'Failed to load spending overview';

  @override
  String get dashboard_failed_budgets => 'Failed to load budget alerts';

  @override
  String get dashboard_voice => 'Voice';

  @override
  String get balance_income_label => 'Income';

  @override
  String get balance_expense_label => 'Expenses';

  @override
  String get onboarding_feature_wallets => 'Multiple Accounts';

  @override
  String get onboarding_feature_budgets => 'Smart Budgets';

  @override
  String get onboarding_feature_goals => 'Savings Goals';

  @override
  String get onboarding_feature_reports => 'Detailed Reports';

  @override
  String get onboarding_language_prompt => 'Choose your language';

  @override
  String get onboarding_page1_body =>
      'Track every pound, plan your future,\nand live worry-free about money.';

  @override
  String get onboarding_page2_body =>
      'Enter your current balance to start accurately.\n(Optional — you can change it later)';

  @override
  String get onboarding_saving => 'Saving...';

  @override
  String get onboarding_default_wallet_name => 'Cash';

  @override
  String get onboarding_account_name_label => 'Account Name';

  @override
  String get onboarding_account_name_hint => 'e.g. Cash, CIB, Vodafone Cash';

  @override
  String get onboarding_account_type_label => 'Account Type';

  @override
  String get goal_active_section => 'Active';

  @override
  String get goal_completed_section => 'Completed';

  @override
  String goal_days_remaining(int daysLeft) {
    return '$daysLeft days remaining';
  }

  @override
  String get goal_pick_date => 'Pick a date';

  @override
  String get goal_remove_date => 'Remove date';

  @override
  String get goal_keyword_hint => 'e.g. travel, trip, flight';

  @override
  String get month_1 => 'January';

  @override
  String get month_2 => 'February';

  @override
  String get month_3 => 'March';

  @override
  String get month_4 => 'April';

  @override
  String get month_5 => 'May';

  @override
  String get month_6 => 'June';

  @override
  String get month_7 => 'July';

  @override
  String get month_8 => 'August';

  @override
  String get month_9 => 'September';

  @override
  String get month_10 => 'October';

  @override
  String get month_11 => 'November';

  @override
  String get month_12 => 'December';

  @override
  String get month_previous => 'Previous month';

  @override
  String get month_next => 'Next month';

  @override
  String get dashboard_other_category => 'Other';

  @override
  String get dashboard_total => 'Total';

  @override
  String get recurring_active => 'Active Recurring';

  @override
  String get recurring_paused => 'Paused';

  @override
  String get recurring_pause => 'Pause';

  @override
  String get recurring_resume => 'Resume';

  @override
  String get recurring_frequency_label => 'Frequency';

  @override
  String get recurring_start_date => 'Start Date';

  @override
  String get recurring_end_date => 'End Date (optional)';

  @override
  String get recurring_end_date_required => 'End Date';

  @override
  String get recurring_empty_title => 'No Recurring Rules';

  @override
  String get recurring_empty_sub =>
      'Set up recurring transactions to save time';

  @override
  String get recurring_delete_title => 'Delete Recurring';

  @override
  String get recurring_delete_confirm =>
      'Are you sure you want to delete this recurring transaction?';

  @override
  String get recurring_confirm_activate =>
      'Activate this recurring transaction? It will start creating transactions automatically.';

  @override
  String get recurring_confirm_pause =>
      'Pause this recurring transaction? No new transactions will be created until reactivated.';

  @override
  String get recurring_title_label => 'Title';

  @override
  String get recurring_title_hint => 'e.g. Rent, Internet, Salary';

  @override
  String get recurring_type_label => 'Transaction Type';

  @override
  String get recurring_saved => 'Recurring transaction saved';

  @override
  String get calendar_no_transactions_day => 'No transactions on this day';

  @override
  String get calendar_day_income => 'Income';

  @override
  String get calendar_day_expense => 'Expenses';

  @override
  String get reports_period_7d => '7 Days';

  @override
  String get reports_period_30d => '30 Days';

  @override
  String get reports_period_90d => '90 Days';

  @override
  String get reports_income_vs_expense => 'Income vs Expense';

  @override
  String get reports_top_categories => 'Top Categories';

  @override
  String get reports_this_month => 'This Month';

  @override
  String get reports_last_month => 'Last Month';

  @override
  String get reports_vs_last_month => 'vs last month';

  @override
  String get reports_no_data => 'No transactions in this period';

  @override
  String get reports_total_income => 'Total Income';

  @override
  String get reports_total_expense => 'Total Expense';

  @override
  String get reports_net => 'Net';

  @override
  String get reports_daily_average => 'Daily Average';

  @override
  String reports_category_rank(int rank) {
    return '#$rank';
  }

  @override
  String get balance_show => 'Show';

  @override
  String get balance_hide => 'Hide';

  @override
  String get goal_status_completed => 'Completed';

  @override
  String get goal_status_overdue => 'Overdue';

  @override
  String get goal_status_last_day => 'Last day';

  @override
  String get goal_status_one_day => '1 day remaining';

  @override
  String goal_status_days_remaining(int days) {
    return '$days days remaining';
  }

  @override
  String goal_status_months_remaining(int months) {
    return '$months month(s) remaining';
  }

  @override
  String get budget_exceeded => 'Exceeded!';

  @override
  String get common_search => 'Search';

  @override
  String get common_search_hint => 'Search...';

  @override
  String get common_clear => 'Clear';

  @override
  String get common_date => 'Date';

  @override
  String get common_amount => 'Amount';

  @override
  String get common_delete_action => 'Delete';

  @override
  String get settings_delete_confirm_word => 'DELETE';

  @override
  String get recurring_amount_label => 'Amount';

  @override
  String get budget_edit_title => 'Edit Budget';

  @override
  String get goal_contribution_note => 'Note (Optional)';

  @override
  String get goal_icon_label => 'Icon';

  @override
  String get goal_color_label => 'Color';

  @override
  String get quick_add_title => 'Quick Add';

  @override
  String get quick_add_voice => 'Voice Input';

  @override
  String get settings_notification_parser_subtitle =>
      'Auto-detect transactions from bank notifications';

  @override
  String get settings_sms_parser_subtitle =>
      'Scan SMS inbox for bank transaction messages';

  @override
  String get permission_sms_title => 'SMS Access';

  @override
  String get permission_sms_body =>
      'Masarify can scan your SMS inbox to detect bank transactions. Messages are parsed locally on your device. You can optionally tap \'Enrich\' on any parsed transaction to use AI for category and merchant detection.';

  @override
  String get fab_expense => 'Expense';

  @override
  String get fab_income => 'Income';

  @override
  String get fab_voice => 'Voice';

  @override
  String get wallet_archive_balance_warning =>
      'This account still has a remaining balance. The balance will be excluded from your totals after archiving.';

  @override
  String get notif_prefs_title => 'Notification Settings';

  @override
  String get notif_section_budget => 'Budget Alerts';

  @override
  String get notif_budget_warning => 'Budget Warning (80%)';

  @override
  String get notif_budget_warning_sub =>
      'Notify when spending reaches 80% of budget';

  @override
  String get notif_budget_exceeded => 'Budget Exceeded (100%)';

  @override
  String get notif_budget_exceeded_sub => 'Notify when a budget is fully spent';

  @override
  String get notif_section_bills => 'Bills & Recurring';

  @override
  String get notif_bill_reminder => 'Bill Reminders';

  @override
  String get notif_bill_reminder_sub =>
      'Remind about upcoming bills before due date';

  @override
  String get notif_recurring_reminder => 'Recurring Transactions';

  @override
  String get notif_recurring_reminder_sub =>
      'Notify when recurring transactions are due';

  @override
  String get notif_section_goals => 'Goals';

  @override
  String get notif_goal_milestone => 'Goal Milestones';

  @override
  String get notif_goal_milestone_sub =>
      'Celebrate when you reach 25%, 50%, 75%, and 100% of a goal';

  @override
  String get notif_section_daily => 'Daily Reminder';

  @override
  String get notif_daily_reminder => 'Log Your Expenses';

  @override
  String get notif_daily_reminder_sub =>
      'A gentle reminder to log today\'s transactions';

  @override
  String get notif_daily_reminder_time => 'Reminder Time';

  @override
  String get notif_section_quiet => 'Quiet Hours';

  @override
  String get notif_quiet_hours => 'Enable Quiet Hours';

  @override
  String get notif_quiet_hours_sub =>
      'Pause all notifications during set hours';

  @override
  String get notif_quiet_start => 'Start';

  @override
  String get notif_quiet_end => 'End';

  @override
  String get period_3_months => '3M';

  @override
  String get period_6_months => '6M';

  @override
  String get period_1_year => '1Y';

  @override
  String get pdf_report_title => 'Masarify Monthly Report';

  @override
  String get pdf_top_categories => 'Top Categories';

  @override
  String get pdf_transactions => 'Transactions';

  @override
  String get pdf_income => 'Income';

  @override
  String get pdf_expense => 'Expense';

  @override
  String get pdf_net => 'Net';

  @override
  String get pdf_col_date => 'Date';

  @override
  String get pdf_col_title => 'Title';

  @override
  String get pdf_col_amount => 'Amount';

  @override
  String get pdf_col_type => 'Type';

  @override
  String get pdf_col_category => 'Category';

  @override
  String get pdf_col_wallet => 'Account';

  @override
  String get pdf_page_label => 'Page';

  @override
  String get pdf_of_label => 'of';

  @override
  String get pdf_unknown_category => 'Unknown';

  @override
  String get dashboard_all_accounts => 'All Accounts';

  @override
  String get voice_offline_message =>
      'AI parsing needs internet. You can add the transaction manually.';

  @override
  String get dashboard_offline_banner =>
      'Offline — AI features unavailable. Add transactions manually.';

  @override
  String get budget_over_by => 'Over by';

  @override
  String get dashboard_month_summary => 'This Month';

  @override
  String get dashboard_month_net => 'Net';

  @override
  String get dashboard_vs_last_month => 'vs last month';

  @override
  String get dashboard_insights => 'Insights';

  @override
  String dashboard_insight_spending_up(int percent) {
    return '+$percent% spending pace';
  }

  @override
  String dashboard_insight_spending_down(int percent) {
    return '$percent% less spending';
  }

  @override
  String get dashboard_insight_parsed_transactions =>
      'Auto-detected Transactions';

  @override
  String insight_recurring_detected(String title) {
    return 'Monthly: $title — add as recurring?';
  }

  @override
  String insight_weekly_detected(String title) {
    return 'Weekly: $title — add as recurring?';
  }

  @override
  String insight_over_budget_prediction(String category, String amount) {
    return '$category may exceed budget by $amount';
  }

  @override
  String insight_budget_suggestion(String amount, String category) {
    return 'Set a $amount budget for $category?';
  }

  @override
  String get hub_planning_title => 'Planning';

  @override
  String get hub_section_accounts => 'Accounts';

  @override
  String get hub_section_goals_budgets => 'Budgets & Goals';

  @override
  String get hub_section_recurring => 'Recurring & Bills';

  @override
  String get nav_planning => 'Planning';

  @override
  String get dashboard_quick_add => 'Quick Add';

  @override
  String quick_add_saved(String title) {
    return '$title added';
  }

  @override
  String get common_undo => 'Undo';

  @override
  String get auto_detected_transactions => 'Auto-detected Transactions';

  @override
  String get dashboard_chat_tooltip => 'AI Assistant';

  @override
  String get chat_action_budget_title => 'Create Budget';

  @override
  String get chat_action_recurring_title => 'Create Recurring';

  @override
  String get chat_action_wallet_title => 'Create Account';

  @override
  String get chat_action_delete_title => 'Delete Transaction';

  @override
  String chat_budget_created(String category) {
    return 'Budget created for $category';
  }

  @override
  String chat_recurring_created(String title) {
    return 'Recurring rule \"$title\" created';
  }

  @override
  String chat_wallet_created(String name) {
    return 'Account \"$name\" created';
  }

  @override
  String get chat_transaction_deleted => 'Transaction deleted';

  @override
  String get chat_confirm_delete =>
      'Are you sure you want to delete this transaction?';

  @override
  String get chat_no_match_category => 'Could not find a matching category';

  @override
  String get chat_no_active_wallet => 'No active account available';

  @override
  String get chat_budget_exists => 'A budget already exists for this category';

  @override
  String get chat_wallet_name_taken =>
      'An account with this name already exists';

  @override
  String get quick_start_title => 'Quick Start';

  @override
  String get quick_start_subtitle => 'Set up your finances in a few steps';

  @override
  String get quick_start_step_wallets => 'How do you manage your money?';

  @override
  String get quick_start_step_categories => 'What do you spend most on?';

  @override
  String get quick_start_step_budgets => 'Set monthly budgets';

  @override
  String get quick_start_step_bills => 'Any regular bills?';

  @override
  String get quick_start_step_goals => 'Saving for something?';

  @override
  String get quick_start_source_cash => 'Cash only';

  @override
  String get quick_start_source_bank => 'Bank account';

  @override
  String get quick_start_source_mobile => 'Mobile wallet';

  @override
  String get quick_start_source_multiple => 'Multiple sources';

  @override
  String get quick_start_category_food => 'Food';

  @override
  String get quick_start_category_rent => 'Rent';

  @override
  String get quick_start_category_transport => 'Transport';

  @override
  String get quick_start_category_bills => 'Bills';

  @override
  String get quick_start_category_shopping => 'Shopping';

  @override
  String get quick_start_category_health => 'Health';

  @override
  String get quick_start_category_education => 'Education';

  @override
  String get quick_start_category_other => 'Other';

  @override
  String get quick_start_budget_hint => 'Monthly limit';

  @override
  String get quick_start_bill_internet => 'Internet';

  @override
  String get quick_start_bill_phone => 'Phone';

  @override
  String get quick_start_bill_electricity => 'Electricity';

  @override
  String get quick_start_bill_gas => 'Gas';

  @override
  String get quick_start_bill_gym => 'Gym';

  @override
  String get quick_start_bill_subscription => 'Subscription';

  @override
  String get quick_start_goal_emergency => 'Emergency fund';

  @override
  String get quick_start_goal_vacation => 'Vacation';

  @override
  String get quick_start_goal_car => 'Car';

  @override
  String get quick_start_goal_wedding => 'Wedding';

  @override
  String get quick_start_goal_education => 'Education';

  @override
  String get quick_start_goal_custom => 'Custom';

  @override
  String get quick_start_goal_target => 'Target amount';

  @override
  String get quick_start_source_other => 'Other';

  @override
  String get quick_start_custom_wallet_name => 'Account name';

  @override
  String get quick_start_bill_other => 'Custom bill';

  @override
  String get quick_start_bill_name_hint => 'Bill name';

  @override
  String get quick_start_goal_custom_name => 'Goal name';

  @override
  String get quick_start_wallet_type_label => 'Account type';

  @override
  String get quick_start_done_title => 'You\'re all set!';

  @override
  String get quick_start_done_subtitle => 'Your finances are ready to track';

  @override
  String get quick_start_tip_title => 'Quick start your finances';

  @override
  String get quick_start_tip_subtitle =>
      'Set up budgets, bills, and goals in seconds';

  @override
  String get quick_start_add_another => 'Add another?';

  @override
  String get quick_start_adjust => 'Adjust?';

  @override
  String get quick_start_amount_label => 'Amount';

  @override
  String get backup_cloud_title => 'Cloud Backup';

  @override
  String get backup_sign_in_google => 'Sign in with Google';

  @override
  String get backup_sign_out => 'Sign Out';

  @override
  String backup_signed_in_as(String email) {
    return 'Signed in as $email';
  }

  @override
  String backup_last_date(String date) {
    return 'Last backup: $date';
  }

  @override
  String get backup_now => 'Backup Now';

  @override
  String get backup_restore_drive => 'Restore from Drive';

  @override
  String get backup_encrypting => 'Encrypting...';

  @override
  String get backup_uploading => 'Uploading to Drive...';

  @override
  String get backup_downloading => 'Downloading from Drive...';

  @override
  String get backup_restore_warning =>
      'This will replace ALL local data with the backup. Continue?';

  @override
  String get backup_no_backups => 'No backups found on Google Drive';

  @override
  String get backup_welcome_back => 'Welcome back?';

  @override
  String get backup_start_fresh => 'Start Fresh';

  @override
  String get backup_restore_from_drive => 'Restore from Google Drive';

  @override
  String get backup_offline_error => 'Connect to internet to use cloud backup';

  @override
  String get backup_drive_success => 'Backup saved to Google Drive';

  @override
  String get backup_drive_failed => 'Cloud backup failed. Please try again.';

  @override
  String get backup_pre_reset_offer => 'Save a backup before deleting?';

  @override
  String get backup_pre_reset_drive => 'Backup to Google Drive';

  @override
  String get backup_pre_reset_file => 'Export to file';

  @override
  String get backup_pre_reset_skip => 'No, just delete';

  @override
  String get backup_failed_continue => 'Backup failed. Delete all data anyway?';

  @override
  String voice_wallet_not_found(String name) {
    return 'Account \'\'$name\'\' not found — create it?';
  }

  @override
  String get voice_select_wallet => 'Select account';

  @override
  String voice_confirm_count(int count) {
    return 'Confirm ($count)';
  }

  @override
  String get voice_select_all => 'Select All';

  @override
  String get voice_deselect_all => 'Deselect All';

  @override
  String get voice_wallet_not_matched => 'Account not found';

  @override
  String get common_create => 'Create';

  @override
  String get backup_encryption_warning =>
      'Cloud backups are encrypted and tied to this device. If you reinstall the app or switch devices, you will not be able to restore cloud backups. Use local file backup for device transfers.';

  @override
  String get chat_action_invalid_amount => 'Amount must be greater than zero';

  @override
  String get chat_action_invalid_target =>
      'Target amount must be greater than zero';

  @override
  String get chat_action_invalid_budget_limit =>
      'Budget limit must be greater than zero';

  @override
  String chat_action_category_not_found(String name, String available) {
    return 'Could not match category \"$name\". Available: $available';
  }

  @override
  String get chat_action_no_active_wallet =>
      'No active account available. Please create one first.';

  @override
  String chat_action_budget_exists(String category) {
    return 'A budget already exists for \"$category\" this month';
  }

  @override
  String get chat_action_wallet_exists =>
      'An account with this name already exists';

  @override
  String chat_action_tx_not_found(String title) {
    return 'No transaction found matching \"$title\" with that amount';
  }

  @override
  String chat_action_goal_created(String name, String amount) {
    return 'Goal \"$name\" created with a target of $amount!';
  }

  @override
  String chat_action_tx_recorded(String title, String amount) {
    return 'Transaction \"$title\" of $amount recorded!';
  }

  @override
  String chat_action_budget_created(String amount, String category) {
    return 'Budget of $amount created for \"$category\"!';
  }

  @override
  String chat_action_recurring_created(
      String title, String frequency, String amount) {
    return 'Recurring \"$title\" ($frequency) of $amount created!';
  }

  @override
  String chat_action_wallet_created(String name, String amount) {
    return 'Account \"$name\" created with balance $amount!';
  }

  @override
  String chat_action_tx_deleted(String title, String amount) {
    return 'Transaction \"$title\" of $amount deleted!';
  }

  @override
  String get onboarding_features_title => 'Discover Masarify';

  @override
  String get onboarding_feature_voice_title => 'Voice Input';

  @override
  String get onboarding_feature_voice_body =>
      'Just speak. AI will parse your transactions instantly.';

  @override
  String get onboarding_feature_budget_title => 'Smart Budgets';

  @override
  String get onboarding_feature_budget_body =>
      'Set limits, get alerts, stay on track.';

  @override
  String get onboarding_feature_goal_title => 'Goal Tracking';

  @override
  String get onboarding_feature_goal_body =>
      'Save towards what matters most to you.';

  @override
  String get onboarding_ready_title => 'You\'re All Set!';

  @override
  String get onboarding_ready_body => 'Start tracking your money today.';

  @override
  String get onboarding_ready_cta => 'Start Tracking';
}
