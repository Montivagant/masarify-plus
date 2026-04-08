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
  String get appBrandEnglish => 'Masarify';

  @override
  String get appBrandArabic => 'مصاريفي';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_analytics => 'Analytics';

  @override
  String get nav_subscriptions => 'Bills';

  @override
  String get dashboard_title => 'Masarify';

  @override
  String get dashboard_income => 'Income';

  @override
  String get dashboard_expense => 'Expense';

  @override
  String get dashboard_welcome_empty => 'Welcome to Masarify!';

  @override
  String get dashboard_welcome_empty_sub =>
      'Tap + to add your first transaction';

  @override
  String get transactions_title => 'Transactions';

  @override
  String get transactions_empty_title => 'No transactions yet';

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
  String get transaction_location => 'Location';

  @override
  String get transaction_amount_hint => '0.00';

  @override
  String get transaction_save => 'Save';

  @override
  String get transaction_saved => 'Transaction saved';

  @override
  String get transaction_deleted => 'Transaction deleted';

  @override
  String get transaction_source_voice => 'Voice';

  @override
  String get transaction_source_sms => 'SMS';

  @override
  String get transaction_source_notification => 'Notification';

  @override
  String get transaction_source_import => 'Import';

  @override
  String get transaction_source_ai_chat => 'AI Assistant';

  @override
  String get transaction_source_recurring => 'Recurring Rule';

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
  String get categories_title => 'Categories';

  @override
  String get categories_expense => 'Expense';

  @override
  String get categories_income => 'Income';

  @override
  String get category_add => 'Add Category';

  @override
  String get category_name_label => 'Category Name';

  @override
  String get category_name_hint => 'e.g. Coffee, Groceries';

  @override
  String get category_name_duplicate =>
      'A category with this name already exists';

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
  String budget_progress_a11y(String category, String percent) {
    return '$category: $percent';
  }

  @override
  String get budget_spent => 'Spent';

  @override
  String get budget_remaining => 'Remaining';

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
  String get goal_completed => 'Goal Completed! 🎉';

  @override
  String get goal_overdue => 'Overdue';

  @override
  String get recurring_add => 'Add Subscription';

  @override
  String get recurring_edit => 'Edit Subscription';

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
  String get recurring_and_bills_title => 'Subscriptions & Bills';

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
  String get reports_all_accounts => 'All Accounts';

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
  String get hub_section_ai => 'AI Assistant';

  @override
  String get hub_section_app => 'App';

  @override
  String get hub_wallets => 'Accounts';

  @override
  String get hub_active => 'active';

  @override
  String get hub_in_progress => 'in progress';

  @override
  String get settings_title => 'Settings';

  @override
  String get settings_general => 'General';

  @override
  String get settings_security => 'Security';

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
  String get settings_pin_change => 'Change PIN';

  @override
  String get settings_biometric => 'Biometric Login';

  @override
  String get settings_auto_lock => 'Auto-lock';

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
  String get backup_confirm_restore_title => 'Restore Backup?';

  @override
  String get backup_confirm_restore_body =>
      'This will replace all current data with the backup. This action cannot be undone.';

  @override
  String get backup_select_month => 'Select Month';

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
  String get csv_header_date => 'Date';

  @override
  String get csv_header_title => 'Title';

  @override
  String get csv_header_amount => 'Amount';

  @override
  String get csv_header_currency => 'Currency';

  @override
  String get csv_header_type => 'Type';

  @override
  String get csv_header_category => 'Category';

  @override
  String get csv_header_account => 'Account';

  @override
  String get csv_header_tags => 'Tags';

  @override
  String get csv_header_source => 'Source';

  @override
  String get csv_header_location => 'Location';

  @override
  String get csv_header_notes => 'Notes';

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
  String get common_none => 'None';

  @override
  String get common_next => 'Next';

  @override
  String get common_skip => 'Skip';

  @override
  String get common_error_generic => 'Something went wrong. Please try again.';

  @override
  String get common_invalid_amount => 'Invalid amount';

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
  String get location_hint => 'e.g. Maadi, Cairo';

  @override
  String get location_failed => 'Could not detect location';

  @override
  String get error_amount_zero => 'Amount must be greater than zero';

  @override
  String get error_category_required => 'Please select a category';

  @override
  String get error_wallet_required => 'Please select an account';

  @override
  String get error_name_required => 'Name is required';

  @override
  String get voice_tap_to_start => 'Tap the mic to start';

  @override
  String get voice_listening => 'Recording...';

  @override
  String get voice_confirm_title => 'Review Transactions';

  @override
  String get voice_confirm_accept_all => 'Save All';

  @override
  String get voice_error_no_service =>
      'Voice input is not available. Please check your internet connection.';

  @override
  String get voice_no_results => 'Nothing detected. Please try again.';

  @override
  String get voice_ai_error => 'AI parsing failed. Please try again.';

  @override
  String get voice_retry => 'Try Again';

  @override
  String get voice_ai_parsing => 'Analyzing with AI...';

  @override
  String get voice_cancel_recording => 'Cancel recording';

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
  String get parser_enrich => 'Enrich';

  @override
  String get parser_enrich_all => 'Enrich All';

  @override
  String get parser_possible_duplicate => 'Possible duplicate';

  @override
  String get parser_wallet_label => 'Account';

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
  String goal_link_prompt(String goalName) {
    return 'This looks like it relates to your \'$goalName\'. Link it?';
  }

  @override
  String get goal_link_action => 'Link';

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
  String get pro_upgrade => 'Upgrade to Pro';

  @override
  String get subscription_title => 'Pro Subscription';

  @override
  String get paywall_title => 'Masarify Pro';

  @override
  String get paywall_headline => 'Unlock Full Power';

  @override
  String get paywall_subheadline =>
      'Get unlimited budgets, AI insights, and more.';

  @override
  String get paywall_includes => 'Pro includes:';

  @override
  String get paywall_feature_budgets => 'Unlimited budgets';

  @override
  String get paywall_feature_goals => 'Unlimited savings goals';

  @override
  String get paywall_feature_insights => 'AI spending insights';

  @override
  String get paywall_feature_analytics => 'Advanced analytics & trends';

  @override
  String get paywall_feature_backup => 'Cloud backup (Google Drive)';

  @override
  String get paywall_feature_export => 'CSV & PDF export';

  @override
  String get paywall_feature_chat => 'AI financial assistant';

  @override
  String paywall_monthly(String price) {
    return '$price/month';
  }

  @override
  String paywall_yearly(String price) {
    return '$price/year — Save 30%';
  }

  @override
  String get paywall_restore => 'Restore Purchases';

  @override
  String get subscription_active => 'Pro Active';

  @override
  String get subscription_inactive => 'Free Plan';

  @override
  String get subscription_upgrade_prompt =>
      'Upgrade to Pro for unlimited features.';

  @override
  String get paywall_restored => 'Purchase restored successfully!';

  @override
  String get paywall_no_purchases => 'No previous purchases found.';

  @override
  String get paywall_store_unavailable =>
      'Store not available. Please try again later.';

  @override
  String paywall_trial_banner(int days) {
    return '$days days left in your free trial';
  }

  @override
  String get paywall_pro_feature => 'Pro Feature';

  @override
  String get paywall_unlock_cta => 'Tap to unlock';

  @override
  String get paywall_pricing_terms => '7-day free trial • Cancel anytime';

  @override
  String get subscription_manage => 'Manage Subscription';

  @override
  String get settings_pro_status => 'Masarify Pro';

  @override
  String settings_pro_trial_days(int days) {
    return 'Trial: $days days left';
  }

  @override
  String get settings_pro_free => 'Free Plan';

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
  String get wallet_add_short => 'Add';

  @override
  String get wallet_add_title => 'New Account';

  @override
  String get wallet_edit_title => 'Edit Account';

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
  String get wallet_cannot_archive_system =>
      'The Cash wallet cannot be archived';

  @override
  String get goal_contribution_from_wallet => 'From account';

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
  String goal_contribution_max(String amount) {
    return 'Maximum: $amount';
  }

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
  String get settings_categories_label => 'Categories';

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
  String get onboarding_page1_body =>
      'Track every pound, plan your future,\nand live worry-free about money.';

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
  String get recurring_active => 'Active Subscriptions';

  @override
  String get recurring_paused => 'Paused';

  @override
  String get recurring_pause => 'Pause';

  @override
  String get recurring_error_title => 'Please enter a title';

  @override
  String get recurring_error_amount => 'Please enter a valid amount';

  @override
  String get recurring_error_category => 'Please select a category';

  @override
  String get recurring_error_wallet => 'Please select an account';

  @override
  String get recurring_error_end_date =>
      'End date is required for custom frequency';

  @override
  String get recurring_error_date_order => 'End date must be after start date';

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
      'Set up subscriptions & bills to track regular payments';

  @override
  String get recurring_delete_title => 'Delete Subscription';

  @override
  String get recurring_delete_confirm =>
      'Are you sure you want to delete this subscription?';

  @override
  String get recurring_confirm_activate =>
      'Activate this subscription? It will start creating transactions automatically.';

  @override
  String get recurring_confirm_pause =>
      'Pause this subscription? No new transactions will be created until reactivated.';

  @override
  String get recurring_title_label => 'Title';

  @override
  String get recurring_title_hint => 'e.g. Rent, Internet, Salary';

  @override
  String get recurring_type_label => 'Transaction Type';

  @override
  String get recurring_view_all => 'View All';

  @override
  String get recurring_monthly_total => 'Monthly Total';

  @override
  String recurring_due_this_week(int count) {
    return '$count due this week';
  }

  @override
  String get recurring_upcoming => 'Upcoming';

  @override
  String get recurring_paid_section => 'Paid';

  @override
  String get recurring_auto_pay_label => 'Automatically mark as paid';

  @override
  String get recurring_auto_pay_wallet => 'Deduct from account';

  @override
  String get calendar_no_transactions_day => 'No transactions on this day';

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
  String get reports_vs_last_month => 'vs last month';

  @override
  String get reports_no_data => 'No transactions in this period';

  @override
  String get reports_total_expense => 'Total Expense';

  @override
  String get reports_net => 'Net';

  @override
  String get reports_daily_average => 'Daily Average';

  @override
  String get reports_total_spending => 'Total Spending';

  @override
  String get reports_highest_day => 'Highest Day';

  @override
  String get reports_vs_previous => 'vs previous period';

  @override
  String reports_savings_rate(int rate) {
    return 'Savings rate: $rate% of income';
  }

  @override
  String reportsCategoryCount(int count) {
    return '$count categories';
  }

  @override
  String reportsBudgetLabel(String amount) {
    return 'Budget: $amount';
  }

  @override
  String get balance_show => 'Show';

  @override
  String get balance_hide => 'Hide';

  @override
  String get budget_exceeded => 'Exceeded!';

  @override
  String get common_clear => 'Clear';

  @override
  String get common_date => 'Date';

  @override
  String get common_amount => 'Amount';

  @override
  String get settings_delete_confirm_word => 'DELETE';

  @override
  String get recurring_amount_label => 'Amount';

  @override
  String get budget_edit_title => 'Edit Budget';

  @override
  String get budget_period_label => 'Budget Period';

  @override
  String get budget_period_daily => 'Daily';

  @override
  String get budget_period_weekly => 'Weekly';

  @override
  String get budget_period_monthly => 'Monthly';

  @override
  String get budget_period_yearly => 'Yearly';

  @override
  String get budget_rollover_label => 'Roll over unused budget';

  @override
  String get goal_contribution_note => 'Note (Optional)';

  @override
  String get goal_icon_label => 'Icon';

  @override
  String get goal_color_label => 'Color';

  @override
  String get fab_voice => 'Voice';

  @override
  String get fab_manual => 'Manual';

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
  String get notif_section_bills => 'Subscriptions & Bills';

  @override
  String get notif_bill_reminder => 'Bill Reminders';

  @override
  String get notif_bill_reminder_sub =>
      'Remind about upcoming bills before due date';

  @override
  String get notif_recurring_reminder => 'Subscriptions';

  @override
  String get notif_recurring_reminder_sub =>
      'Notify when subscriptions are due';

  @override
  String get notif_section_goals => 'Goals';

  @override
  String get notif_goal_milestone => 'Goal Milestones';

  @override
  String get notif_goal_milestone_sub =>
      'Celebrate when you reach 25%, 50%, 75%, and 100% of a goal';

  @override
  String get notif_daily_reminder => 'Log Your Expenses';

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
  String get dashboard_offline_banner =>
      'Offline — AI features unavailable. Add transactions manually.';

  @override
  String get budget_over_by => 'Over by';

  @override
  String get hub_planning_title => 'Planning';

  @override
  String get hub_section_accounts => 'Accounts';

  @override
  String get hub_section_goals_budgets => 'Budgets & Goals';

  @override
  String get nav_planning => 'Planning';

  @override
  String get common_undo => 'Undo';

  @override
  String get auto_detected_transactions => 'Auto-detected Transactions';

  @override
  String get dashboard_chat_tooltip => 'AI Assistant';

  @override
  String get chat_action_budget_title => 'Create Budget';

  @override
  String get chat_action_recurring_title => 'Create Subscription';

  @override
  String get chat_action_wallet_title => 'Create Account';

  @override
  String get chat_action_delete_title => 'Delete Transaction';

  @override
  String get chat_action_transfer_title => 'Transfer';

  @override
  String get voice_transfer_from => 'From';

  @override
  String get voice_transfer_to => 'To';

  @override
  String get backup_cloud_title => 'Cloud Backup';

  @override
  String get backup_sign_in_google => 'Sign in with Google';

  @override
  String get backup_sign_out => 'Sign Out';

  @override
  String backup_last_date(String date) {
    return 'Last backup: $date';
  }

  @override
  String get backup_now => 'Backup Now';

  @override
  String get backup_restore_drive => 'Restore from Drive';

  @override
  String get backup_uploading => 'Uploading to Drive...';

  @override
  String get backup_downloading => 'Downloading from Drive...';

  @override
  String get backup_no_backups => 'No backups found on Google Drive';

  @override
  String get backup_offline_error => 'Connect to internet to use cloud backup';

  @override
  String get backup_drive_success => 'Backup saved to Google Drive';

  @override
  String get backup_drive_failed => 'Cloud backup failed. Please try again.';

  @override
  String get backup_sign_in_failed =>
      'Google sign-in failed. Check your internet connection and try again.';

  @override
  String get backup_session_expired =>
      'Your Google session has expired. Please sign in again.';

  @override
  String get backup_key_missing =>
      'Encryption key not found. This backup cannot be restored on this device.';

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
  String get voice_select_wallet => 'Select account';

  @override
  String voice_confirm_count(int count) {
    return 'Confirm ($count)';
  }

  @override
  String voice_saved_partial(int saved, int total) {
    return 'Saved $saved of $total transactions';
  }

  @override
  String get voice_select_all => 'Select All';

  @override
  String get voice_deselect_all => 'Deselect All';

  @override
  String voice_selected_count(int selected, int total) {
    return '$selected of $total selected';
  }

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
    return 'Subscription \"$title\" ($frequency) of $amount created!';
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
  String chat_action_wallet_not_found(String name) {
    return 'Could not find account \"$name\"';
  }

  @override
  String get chat_action_transfer_same_wallet =>
      'Source and destination accounts must be different';

  @override
  String chat_action_transfer_created(String amount, String from, String to) {
    return 'Transfer of $amount from \"$from\" to \"$to\" created!';
  }

  @override
  String get chat_action_update_tx_title => 'Update Transaction';

  @override
  String get chat_action_update_budget_title => 'Update Budget';

  @override
  String get chat_action_delete_budget_title => 'Delete Budget';

  @override
  String get chat_action_delete_goal_title => 'Delete Goal';

  @override
  String get chat_action_delete_recurring_title => 'Delete Subscription';

  @override
  String chat_action_tx_updated(String title, String amount) {
    return 'Transaction \"$title\" updated to $amount!';
  }

  @override
  String chat_action_budget_updated(String category, String amount) {
    return 'Budget for \"$category\" updated to $amount!';
  }

  @override
  String chat_action_budget_deleted(String category) {
    return 'Budget for \"$category\" deleted!';
  }

  @override
  String chat_action_budget_not_found(String category) {
    return 'No budget found for \"$category\" this month';
  }

  @override
  String chat_action_goal_deleted(String name) {
    return 'Goal \"$name\" deleted!';
  }

  @override
  String chat_action_goal_not_found(String name) {
    return 'No goal found matching \"$name\"';
  }

  @override
  String chat_action_recurring_deleted(String title) {
    return 'Subscription \"$title\" deleted!';
  }

  @override
  String chat_action_recurring_not_found(String title) {
    return 'No subscription found matching \"$title\"';
  }

  @override
  String get chat_action_update_wallet_title => 'Update Account';

  @override
  String get chat_action_update_goal_title => 'Update Goal';

  @override
  String get chat_action_update_recurring_title => 'Update Subscription';

  @override
  String get chat_action_update_category_title => 'Update Category';

  @override
  String get chat_action_create_category_title => 'Create Category';

  @override
  String get chat_action_delete_wallet_title => 'Archive Account';

  @override
  String chat_action_wallet_updated(String name) {
    return 'Account \"$name\" updated!';
  }

  @override
  String chat_action_goal_updated(String name) {
    return 'Goal \"$name\" updated!';
  }

  @override
  String chat_action_recurring_updated(String title) {
    return 'Subscription \"$title\" updated!';
  }

  @override
  String chat_action_category_updated(String name) {
    return 'Category \"$name\" updated!';
  }

  @override
  String chat_action_category_created(String name) {
    return 'Category \"$name\" created!';
  }

  @override
  String chat_action_wallet_archived(String name) {
    return 'Account \"$name\" archived!';
  }

  @override
  String get chat_action_category_not_updatable =>
      'Default categories cannot be renamed';

  @override
  String chat_action_category_exists(String name) {
    return 'A category named \"$name\" already exists';
  }

  @override
  String chat_action_wallet_has_references(String name) {
    return 'Account \"$name\" has transactions — it will be archived instead of deleted';
  }

  @override
  String get chat_copy_message => 'Copy message';

  @override
  String get chat_share_message => 'Share message';

  @override
  String get chat_copied => 'Message copied!';

  @override
  String chat_subscription_suggest(String title) {
    return '💡 \"$title\" looks like a recurring payment. Add to Subscriptions & Bills?';
  }

  @override
  String get onboarding_ready_title => 'You\'re All Set!';

  @override
  String get onboarding_ready_body => 'Start tracking your money today.';

  @override
  String get onboarding_slide1_title => 'Track in 2 Taps';

  @override
  String get onboarding_slide1_body =>
      'Tap the button, type the amount, done.\nThe fastest expense logging you\'ll find.';

  @override
  String get onboarding_slide2_title => 'Just Say It';

  @override
  String get onboarding_slide2_body =>
      'Speak naturally. AI understands\nyour expenses in any language.';

  @override
  String get onboarding_slide3_title => 'Your AI Financial Advisor';

  @override
  String get onboarding_slide3_body =>
      'Get smart spending insights, budget advice, and financial guidance — powered by AI.';

  @override
  String get onboarding_demo_amount => 'EGP 150.00';

  @override
  String get onboarding_demo_food => 'Food';

  @override
  String get onboarding_demo_transport => 'Transport';

  @override
  String get onboarding_demo_voice_text => '\"Lunch 150 pounds\"';

  @override
  String get onboarding_demo_chat_user =>
      'How much did I spend on food this week?';

  @override
  String get onboarding_demo_chat_ai =>
      'You spent EGP 450 on food — 15% more than last week.';

  @override
  String get onboarding_default_bank_name => 'My Bank';

  @override
  String get disclaimer_financial =>
      'Masarify provides budgeting guidance only, not regulated financial, investment, or tax advice.';

  @override
  String get common_dismiss => 'Dismiss';

  @override
  String insight_budget_risk_title(String category) {
    return '$category budget at risk';
  }

  @override
  String insight_budget_risk_body(int percent) {
    return 'You\'ve spent $percent% of your budget this month';
  }

  @override
  String insight_prediction_title(String category) {
    return '$category may overspend';
  }

  @override
  String insight_prediction_body(String amount) {
    return 'At this pace, you\'ll exceed your budget by $amount';
  }

  @override
  String insight_recurring_title(String title) {
    return 'Subscription: $title';
  }

  @override
  String insight_recurring_body(String amount, String frequency) {
    return '$amount $frequency — want to track it?';
  }

  @override
  String insight_suggest_title(String category) {
    return 'Set a budget for $category?';
  }

  @override
  String insight_suggest_body(String amount) {
    return 'You spend avg $amount/month on this category';
  }

  @override
  String get transaction_type_cash_withdrawal => 'Cash Withdrawal';

  @override
  String get transaction_type_cash_withdrawal_short => 'Withdraw';

  @override
  String get transaction_type_cash_deposit => 'Cash Deposit';

  @override
  String get transaction_type_cash_deposit_short => 'Deposit';

  @override
  String get voice_edit_title_hint => 'Refine title...';

  @override
  String voice_create_wallet_instead(String name) {
    return 'Create \'\'$name\'\' instead?';
  }

  @override
  String get home_filter_all => 'All';

  @override
  String get home_filter_expenses => 'Expenses';

  @override
  String get home_filter_income => 'Income';

  @override
  String get home_filter_transfers => 'Transfers';

  @override
  String get home_sort_date_newest => 'Newest first';

  @override
  String get home_sort_date_oldest => 'Oldest first';

  @override
  String get home_sort_amount_high => 'Highest amount';

  @override
  String get home_sort_amount_low => 'Lowest amount';

  @override
  String get home_search_hint => 'Search transactions...';

  @override
  String home_search_results(int count) {
    return '$count results';
  }

  @override
  String get home_net_label => 'Net';

  @override
  String get home_net_tooltip =>
      'Income minus expenses this month (transfers excluded)';

  @override
  String get home_sort_title => 'Sort by';

  @override
  String get home_no_matching_transactions =>
      'No transactions match your filters';

  @override
  String get home_clear_filters => 'Clear filters';

  @override
  String get transaction_delete_confirm_title => 'Delete transaction?';

  @override
  String get transaction_delete_confirm_body => 'This cannot be undone.';

  @override
  String get transfer_delete_confirm_title => 'Delete transfer?';

  @override
  String get transfer_delete_confirm_body =>
      'This will delete both legs of the transfer.';

  @override
  String get transfer_cannot_edit => 'Transfers cannot be edited from here';

  @override
  String get voice_confirm_select_category => 'Select category';

  @override
  String get voice_confirm_add_notes => 'Add notes...';

  @override
  String get voice_confirm_subscription_suggest =>
      'Add to Subscriptions & Bills?';

  @override
  String get voice_include => 'Include';

  @override
  String get insight_upcoming_bills_title => 'Upcoming Bills';

  @override
  String insight_upcoming_bills_body(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills due this week',
      one: '1 bill due this week',
    );
    return '$_temp0';
  }

  @override
  String get insight_budget_savings_title => 'Budget Savings';

  @override
  String insight_budget_savings_body(String amount, String category) {
    return 'Saved $amount on $category';
  }

  @override
  String get trial_started_message => 'Your 7-day Pro trial has started!';

  @override
  String get wallet_archive_title => 'Archive Account';

  @override
  String get wallet_archive_info =>
      'Archived accounts are hidden from your balance, transactions, and analytics.';

  @override
  String get wallet_archive_action => 'Archive';

  @override
  String wallet_archive_confirm(String name) {
    return 'Are you sure you want to archive $name?';
  }

  @override
  String get wallet_unarchive_action => 'Unarchive';

  @override
  String wallet_unarchive_confirm(String name) {
    return 'Restore $name to your active accounts?';
  }

  @override
  String get wallet_cannot_archive_default =>
      'The default account cannot be archived.';

  @override
  String get wallet_set_default_title => 'Set as Default';

  @override
  String wallet_set_default_confirm(String name) {
    return 'Make $name your default account?';
  }

  @override
  String wallet_set_default_success(String name) {
    return '$name is now your default account.';
  }

  @override
  String get wallet_manage_title => 'Manage Accounts';

  @override
  String get wallet_archived_section => 'Archived';

  @override
  String get wallet_starting_balance => 'Starting Balance';

  @override
  String get wallet_starting_balance_hint => '0';

  @override
  String get common_continue_label => 'Continue';

  @override
  String get common_transfer => 'Transfer';

  @override
  String get category_search_hint => 'Search categories...';

  @override
  String get settings_pin_hint => 'Enter 4-digit PIN';

  @override
  String get settings_daily_recap => 'Daily Spending Recap';

  @override
  String get settings_daily_recap_subtitle =>
      'Get a daily notification to review your spending';

  @override
  String get settings_recap_time => 'Recap Time';

  @override
  String get recap_notification_title => 'How was your spending today?';

  @override
  String get recap_notification_body => 'Tap to tell me — I\'ll log it for you';

  @override
  String notif_bill_due_title(String title) {
    return '$title is due';
  }

  @override
  String notif_bill_due_body(String amount) {
    return '$amount — tap to mark as paid';
  }

  @override
  String notif_budget_warning_title(String category, int percent) {
    return '$category budget at $percent%';
  }

  @override
  String notif_budget_warning_body(String spent, String limit) {
    return '$spent of $limit spent';
  }

  @override
  String notif_budget_exceeded_title(String category) {
    return '$category budget exceeded';
  }

  @override
  String notif_budget_exceeded_body(String spent, String limit) {
    return '$spent spent — $limit limit';
  }

  @override
  String notif_goal_milestone_title(String name, int percent) {
    return '$name — $percent% reached!';
  }

  @override
  String notif_goal_milestone_body(String current, String target) {
    return '$current of $target saved';
  }

  @override
  String get onboarding_starting_balance_title => 'Starting Balance';

  @override
  String get onboarding_starting_balance_body =>
      'Set your current account balance to start tracking accurately.';

  @override
  String get onboarding_starting_balance_set => 'Set Balance';

  @override
  String get onboarding_google_title => 'Protect Your Data';

  @override
  String get onboarding_google_body =>
      'Sign in with Google to automatically back up your finances to Google Drive.\nYour backups are encrypted — only you can access them.';

  @override
  String get onboarding_google_sign_in => 'Sign in with Google';

  @override
  String get onboarding_google_skip => 'I\'ll do this later';

  @override
  String onboarding_google_success(String email) {
    return 'Signed in as $email';
  }

  @override
  String get transfer_detail_title => 'Transfer Details';

  @override
  String get transfer_fee_label => 'Fee';

  @override
  String get transfer_not_found => 'Transfer not found';

  @override
  String get transfer_delete_title => 'Delete Transfer';

  @override
  String get transfer_delete_confirm =>
      'This will delete both legs of the transfer. Continue?';

  @override
  String get transfer_deleted_message => 'Transfer deleted';

  @override
  String budget_saved_last_month(String amount) {
    return 'Saved $amount last month';
  }

  @override
  String get notif_permission_denied =>
      'Notification permission denied. Enable it in Settings to receive alerts.';

  @override
  String get notif_permission_banner =>
      'Notifications are disabled. Tap to grant permission so alerts can reach you.';

  @override
  String get notif_permission_grant => 'Grant Permission';

  @override
  String get hint_fab => 'Tap + to quickly add transactions — Voice or Manual';

  @override
  String get hint_swipe_right => 'Swipe right to approve';

  @override
  String get hint_swipe_left => 'Swipe left to skip';

  @override
  String get action_card_arabic_name => '→ Arabic Name';

  @override
  String get home_due_soon_title => 'Due Soon';

  @override
  String get home_due_soon_today => 'Today';

  @override
  String get home_due_soon_tomorrow => 'Tomorrow';

  @override
  String home_due_soon_in_days(int count) {
    return 'In $count days';
  }

  @override
  String home_due_soon_more(int count) {
    return '+$count more';
  }

  @override
  String dashboard_account_selector(String name) {
    return 'Select account: $name';
  }

  @override
  String get voice_ai_thinking_messages =>
      'Hmmm...big day huh!;Let me get my calculator...;Empty pocket or empty bank account?;Crunching those numbers...;Your wallet just flinched;Math is hard, give me a sec...;One moment, counting zeros...;Decoding your financial choices...;Was that a need or a want?;Hmm, interesting spending pattern...;Running the numbers, please hold...;Processing... unlike your budget';

  @override
  String get voice_ai_cancel => 'Cancel';

  @override
  String get reports_net_cash_flow => 'Net Cash Flow';

  @override
  String reports_vs_last_month_pct(String arrow, int pct) {
    return '$arrow $pct% vs last month';
  }

  @override
  String get reports_this_month => 'This Month';

  @override
  String get reports_last_month => 'Last Month';

  @override
  String get reports_3_months => '3 Months';

  @override
  String get reports_6_months => '6 Months';

  @override
  String get reports_custom => 'Custom...';

  @override
  String get reports_all_types => 'All';

  @override
  String get reports_clear_filters => 'Clear';

  @override
  String get reports_income_by_category => 'Income by Category';

  @override
  String get reports_spending_by_category => 'Spending by Category';

  @override
  String reports_category_count(int count) {
    return '$count categories';
  }

  @override
  String reports_budget_label(String amount) {
    return 'Budget: $amount';
  }

  @override
  String reports_insight_savings(int rate) {
    return 'You saved $rate% of your income this month!';
  }

  @override
  String get reports_total_expenses_period => 'Total Expenses';

  @override
  String get reports_total_income_period => 'Total Income';

  @override
  String reports_vs_previous_pct(String arrow, String pct) {
    return '$arrow $pct% vs previous period';
  }

  @override
  String get reports_spending_pace => 'Spending Pace';

  @override
  String reports_pace_label(String amount) {
    return 'Avg $amount/day';
  }

  @override
  String get reports_daily_activity => 'Daily Activity';

  @override
  String get reports_weekly_breakdown => 'Weekly Breakdown';

  @override
  String reports_week_n(int n) {
    return 'Week $n';
  }

  @override
  String get reports_current_period => 'Current Period';

  @override
  String get reports_previous_period => 'Previous Period';

  @override
  String get reports_lowest_day => 'Lowest Day';

  @override
  String get reports_transactions_count => 'Transactions';

  @override
  String get reports_net_label => 'Net';

  @override
  String get reports_last_6_months => 'Last 6 Months';

  @override
  String reports_date_range(String start, String end) {
    return '$start - $end';
  }

  @override
  String get reports_select_range => 'Select Date Range';

  @override
  String get reports_last_7_days => 'Last 7 Days';

  @override
  String get reports_last_30_days => 'Last 30 Days';

  @override
  String get reports_this_quarter => 'This Quarter';

  @override
  String get reports_last_quarter => 'Last Quarter';

  @override
  String get reports_apply => 'Apply';

  @override
  String reports_category_top(String name) {
    return '$name is your #1 category';
  }

  @override
  String get hint_accounts => 'Tap to switch between accounts';

  @override
  String get home_filter_title => 'Filter';

  @override
  String get home_filter_date_range => 'Date Range';

  @override
  String get home_filter_today => 'Today';

  @override
  String get home_filter_this_week => 'This Week';

  @override
  String get home_filter_this_month => 'This Month';

  @override
  String get home_filter_last_month => 'Last Month';

  @override
  String get home_filter_custom_range => 'Custom Range...';

  @override
  String get home_filter_category => 'Category';

  @override
  String get home_filter_apply => 'Apply Filters';

  @override
  String get home_filter_clear => 'Clear All';

  @override
  String semantics_insight_label(String text) {
    return 'Insight: $text';
  }

  @override
  String get semantics_daily_trend_sparkline => 'Daily trend sparkline';

  @override
  String semantics_spending_trend_chart(int days) {
    return 'Spending trend chart for the last $days days with previous period comparison';
  }

  @override
  String semantics_spending_heatmap(int count) {
    return 'Daily spending activity heatmap for the last $count days. Darker colors indicate higher spending.';
  }

  @override
  String get semantics_spending_velocity_chart =>
      'Cumulative spending pace chart with month-end projection';
}
