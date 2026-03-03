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
  String get transaction_wallet => 'Wallet';

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
  String get wallets_title => 'Wallets';

  @override
  String get wallets_add => 'Add Wallet';

  @override
  String get wallets_transfer => 'Transfer';

  @override
  String get wallet_type_cash => 'Cash';

  @override
  String get wallet_type_bank => 'Bank Account';

  @override
  String get wallet_type_mobile_wallet => 'Mobile Wallet';

  @override
  String get wallet_type_credit_card => 'Credit Card';

  @override
  String get wallet_type_savings => 'Savings';

  @override
  String get wallet_name_hint => 'Wallet name';

  @override
  String get wallet_initial_balance => 'Initial Balance';

  @override
  String get wallet_delete_warning =>
      'Cannot delete wallet with existing transactions';

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
  String get recurring_title => 'Recurring';

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
  String get recurring_bill_paid_success => 'Bill marked as paid';

  @override
  String get recurring_due_date_label => 'Due';

  @override
  String get recurring_frequency_once => 'One-time';

  @override
  String get recurring_frequency_custom => 'Custom';

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
  String get hub_title => 'More';

  @override
  String get hub_section_money => 'Money';

  @override
  String get hub_section_reports => 'Reports';

  @override
  String get hub_section_planning => 'Planning';

  @override
  String get hub_section_app => 'App';

  @override
  String get hub_wallets => 'Wallets';

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
  String get settings_clear_data => 'Clear All Data';

  @override
  String get settings_clear_data_confirm => 'Type DELETE to confirm';

  @override
  String get settings_smart_input => 'Smart Input';

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
      'We\'ll create a Cash wallet for you. You can change this later.';

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
      'Masarify uses your microphone to let you add transactions by speaking. Your audio is never stored or sent anywhere.';

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
      'Masarify can read bank/wallet notifications to automatically detect transactions. Nothing is sent to any server.';

  @override
  String get error_amount_zero => 'Amount must be greater than zero';

  @override
  String get error_category_required => 'Please select a category';

  @override
  String get error_wallet_required => 'Please select a wallet';

  @override
  String get error_name_required => 'Name is required';

  @override
  String get error_pin_too_short => 'PIN must be 6 digits';

  @override
  String get voice_tap_to_start => 'Tap the mic to start';

  @override
  String get voice_listening => 'Listening...';

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
      'Speech recognition is not available. Please ensure Google app is installed and updated.';

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
  String get transaction_wallet_picker => 'Select Wallet';

  @override
  String get wallet_detail_title => 'Wallet Details';

  @override
  String get wallet_not_found => 'Wallet not found';

  @override
  String get wallet_add_title => 'New Wallet';

  @override
  String get wallet_edit_title => 'Edit Wallet';

  @override
  String get wallet_delete_title => 'Delete Wallet';

  @override
  String get wallet_delete_confirm =>
      'Are you sure you want to delete this wallet?';

  @override
  String get wallet_cannot_delete_title => 'Cannot Delete Wallet';

  @override
  String get wallet_name_label => 'Wallet Name';

  @override
  String get wallet_name_hint_example => 'e.g. Main Wallet';

  @override
  String get wallet_name_duplicate => 'A wallet with this name already exists';

  @override
  String get wallet_total_balance => 'Total Balance';

  @override
  String get wallet_current_balance => 'Current Balance';

  @override
  String get wallet_transactions_header => 'Wallet Transactions';

  @override
  String get wallet_no_transactions_sub =>
      'No transactions recorded for this wallet yet';

  @override
  String get wallet_cannot_delete_body =>
      'This wallet has transactions.\nDelete or move them before deleting the wallet.';

  @override
  String get wallet_type_label => 'Wallet Type';

  @override
  String get wallet_color_label => 'Wallet Color';

  @override
  String get wallet_add_button => 'Add Wallet';

  @override
  String get wallet_type_cash_short => 'Cash';

  @override
  String get wallet_type_bank_short => 'Bank';

  @override
  String get wallet_type_mobile_wallet_short => 'Mobile Wallet';

  @override
  String get wallet_type_credit_card_short => 'Credit';

  @override
  String get wallet_type_savings_short => 'Savings';

  @override
  String get wallets_empty_title => 'No wallets yet';

  @override
  String get wallets_empty_sub => 'Add your first wallet to start tracking';

  @override
  String get wallets_transfer_button => 'Transfer Between Wallets';

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
  String get transfer_title => 'Transfer Between Wallets';

  @override
  String get transfer_amount_label => 'Amount';

  @override
  String get transfer_note_label => 'Note (Optional)';

  @override
  String get transfer_confirm_button => 'Confirm Transfer';

  @override
  String get transfer_different_wallets => 'Select two different wallets';

  @override
  String get transfer_from_wallet => 'From Wallet';

  @override
  String get transfer_to_wallet => 'To Wallet';

  @override
  String get transfer_select_wallet => 'Select Wallet';

  @override
  String get transfer_swap => 'Swap';

  @override
  String get transfer_insufficient_title => 'Insufficient Balance';

  @override
  String get transfer_insufficient_body =>
      'Source wallet balance is less than the transfer amount. Continue anyway?';

  @override
  String get transfer_success => 'Transfer completed successfully';

  @override
  String get settings_appearance => 'Appearance';

  @override
  String get settings_theme_auto => 'Auto';

  @override
  String get settings_data_management => 'Data Management';

  @override
  String get settings_wallets_label => 'Wallets';

  @override
  String get settings_wallets_subtitle => 'Manage your wallets and accounts';

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
      'This action cannot be undone.\nAll wallets, transactions, budgets, and goals will be deleted.';

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
  String get onboarding_feature_wallets => 'Multiple Wallets';

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
  String get day_saturday => 'Saturday';

  @override
  String get day_sunday => 'Sunday';

  @override
  String get day_monday => 'Monday';

  @override
  String get day_tuesday => 'Tuesday';

  @override
  String get day_wednesday => 'Wednesday';

  @override
  String get day_thursday => 'Thursday';

  @override
  String get day_friday => 'Friday';

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
      'Masarify can scan your SMS inbox to detect bank transactions. Messages are parsed locally. If AI enrichment is enabled, transaction text may be sent to an AI service (OpenRouter) for category and merchant detection.';

  @override
  String get settings_ai_model => 'AI Model';

  @override
  String get settings_ai_model_subtitle =>
      'Choose which AI model processes voice input';

  @override
  String get settings_ai_model_auto => 'Auto (Recommended)';

  @override
  String get settings_ai_model_gemini_flash => 'Gemini 2.0 Flash';

  @override
  String get settings_ai_model_gemma_27b => 'Gemma 3 27B';

  @override
  String get settings_ai_model_qwen3_4b => 'Qwen3 4B';

  @override
  String get fab_expense => 'Expense';

  @override
  String get fab_income => 'Income';

  @override
  String get fab_voice => 'Voice';

  @override
  String get wallet_archive_balance_warning =>
      'This wallet still has a remaining balance. The balance will be excluded from your totals after archiving.';

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
  String get pdf_col_wallet => 'Wallet';
}
