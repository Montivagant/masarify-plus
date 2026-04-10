import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Masarify'**
  String get appName;

  /// No description provided for @appBrandEnglish.
  ///
  /// In en, this message translates to:
  /// **'Masarify'**
  String get appBrandEnglish;

  /// No description provided for @appBrandArabic.
  ///
  /// In en, this message translates to:
  /// **'مصاريفي'**
  String get appBrandArabic;

  /// No description provided for @nav_home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get nav_analytics;

  /// No description provided for @nav_subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get nav_subscriptions;

  /// No description provided for @dashboard_title.
  ///
  /// In en, this message translates to:
  /// **'Masarify'**
  String get dashboard_title;

  /// No description provided for @dashboard_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get dashboard_income;

  /// No description provided for @dashboard_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get dashboard_expense;

  /// No description provided for @dashboard_welcome_empty.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Masarify!'**
  String get dashboard_welcome_empty;

  /// No description provided for @dashboard_welcome_empty_sub.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first transaction'**
  String get dashboard_welcome_empty_sub;

  /// No description provided for @transactions_title.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions_title;

  /// No description provided for @transactions_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get transactions_empty_title;

  /// No description provided for @transactions_add.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get transactions_add;

  /// No description provided for @transaction_type_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transaction_type_expense;

  /// No description provided for @transaction_type_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transaction_type_income;

  /// No description provided for @transaction_type_transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transaction_type_transfer;

  /// No description provided for @transaction_title_label.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get transaction_title_label;

  /// No description provided for @transaction_title_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Coffee, Grocery run...'**
  String get transaction_title_hint;

  /// No description provided for @transaction_note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get transaction_note;

  /// No description provided for @transaction_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transaction_date;

  /// No description provided for @transaction_wallet.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get transaction_wallet;

  /// No description provided for @transaction_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transaction_category;

  /// No description provided for @transaction_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get transaction_location;

  /// No description provided for @transaction_amount_hint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get transaction_amount_hint;

  /// No description provided for @transaction_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get transaction_save;

  /// No description provided for @transaction_saved.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved'**
  String get transaction_saved;

  /// No description provided for @transaction_deleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get transaction_deleted;

  /// No description provided for @transaction_source_voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get transaction_source_voice;

  /// No description provided for @transaction_source_sms.
  ///
  /// In en, this message translates to:
  /// **'SMS'**
  String get transaction_source_sms;

  /// No description provided for @transaction_source_notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get transaction_source_notification;

  /// No description provided for @transaction_source_import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get transaction_source_import;

  /// No description provided for @transaction_source_ai_chat.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get transaction_source_ai_chat;

  /// No description provided for @transaction_source_recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring Rule'**
  String get transaction_source_recurring;

  /// No description provided for @transaction_detailed_info.
  ///
  /// In en, this message translates to:
  /// **'Detailed Information'**
  String get transaction_detailed_info;

  /// No description provided for @transaction_transfer_details.
  ///
  /// In en, this message translates to:
  /// **'Transfer Details'**
  String get transaction_transfer_details;

  /// No description provided for @transfer_from_label.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get transfer_from_label;

  /// No description provided for @transfer_to_label.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get transfer_to_label;

  /// No description provided for @wallets_title.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get wallets_title;

  /// No description provided for @wallets_add.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get wallets_add;

  /// No description provided for @wallets_transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get wallets_transfer;

  /// No description provided for @wallet_type_physical_cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get wallet_type_physical_cash;

  /// No description provided for @wallet_type_bank.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get wallet_type_bank;

  /// No description provided for @wallet_type_mobile_wallet.
  ///
  /// In en, this message translates to:
  /// **'Mobile Wallet'**
  String get wallet_type_mobile_wallet;

  /// No description provided for @wallet_type_credit_card.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get wallet_type_credit_card;

  /// No description provided for @wallet_type_prepaid_card.
  ///
  /// In en, this message translates to:
  /// **'Prepaid Card'**
  String get wallet_type_prepaid_card;

  /// No description provided for @wallet_type_investment.
  ///
  /// In en, this message translates to:
  /// **'Investment Account'**
  String get wallet_type_investment;

  /// No description provided for @wallet_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get wallet_name_hint;

  /// No description provided for @wallet_initial_balance.
  ///
  /// In en, this message translates to:
  /// **'Initial Balance'**
  String get wallet_initial_balance;

  /// No description provided for @categories_title.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories_title;

  /// No description provided for @categories_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get categories_expense;

  /// No description provided for @categories_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get categories_income;

  /// No description provided for @category_add.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get category_add;

  /// No description provided for @category_name_label.
  ///
  /// In en, this message translates to:
  /// **'Category Name'**
  String get category_name_label;

  /// No description provided for @category_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Coffee, Groceries'**
  String get category_name_hint;

  /// No description provided for @category_name_duplicate.
  ///
  /// In en, this message translates to:
  /// **'A category with this name already exists'**
  String get category_name_duplicate;

  /// No description provided for @category_icon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get category_icon;

  /// No description provided for @category_color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get category_color;

  /// No description provided for @category_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get category_type;

  /// No description provided for @category_delete_default_warning.
  ///
  /// In en, this message translates to:
  /// **'Default categories cannot be deleted'**
  String get category_delete_default_warning;

  /// No description provided for @budgets_title.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets_title;

  /// No description provided for @budgets_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No budgets set'**
  String get budgets_empty_title;

  /// No description provided for @budgets_empty_sub.
  ///
  /// In en, this message translates to:
  /// **'Set monthly limits to control spending'**
  String get budgets_empty_sub;

  /// No description provided for @budget_set.
  ///
  /// In en, this message translates to:
  /// **'Set Budget'**
  String get budget_set;

  /// No description provided for @budget_limit.
  ///
  /// In en, this message translates to:
  /// **'Monthly Limit'**
  String get budget_limit;

  /// No description provided for @budget_progress_a11y.
  ///
  /// In en, this message translates to:
  /// **'{category}: {percent}'**
  String budget_progress_a11y(String category, String percent);

  /// No description provided for @budget_spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budget_spent;

  /// No description provided for @budget_remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get budget_remaining;

  /// No description provided for @goals_title.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals_title;

  /// No description provided for @goals_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No savings goals'**
  String get goals_empty_title;

  /// No description provided for @goals_empty_sub.
  ///
  /// In en, this message translates to:
  /// **'Set a goal and start saving'**
  String get goals_empty_sub;

  /// No description provided for @goal_add.
  ///
  /// In en, this message translates to:
  /// **'Create Goal'**
  String get goal_add;

  /// No description provided for @goal_target.
  ///
  /// In en, this message translates to:
  /// **'Target Amount'**
  String get goal_target;

  /// No description provided for @goal_deadline.
  ///
  /// In en, this message translates to:
  /// **'Target Date (optional)'**
  String get goal_deadline;

  /// No description provided for @goal_keywords.
  ///
  /// In en, this message translates to:
  /// **'Auto-match keywords'**
  String get goal_keywords;

  /// No description provided for @goal_completed.
  ///
  /// In en, this message translates to:
  /// **'Goal Completed! 🎉'**
  String get goal_completed;

  /// No description provided for @goal_overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get goal_overdue;

  /// No description provided for @recurring_add.
  ///
  /// In en, this message translates to:
  /// **'Add Subscription'**
  String get recurring_add;

  /// No description provided for @recurring_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Subscription'**
  String get recurring_edit;

  /// No description provided for @recurring_frequency_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurring_frequency_daily;

  /// No description provided for @recurring_frequency_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurring_frequency_weekly;

  /// No description provided for @recurring_frequency_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurring_frequency_monthly;

  /// No description provided for @recurring_frequency_yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurring_frequency_yearly;

  /// No description provided for @recurring_frequency_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get recurring_frequency_custom;

  /// No description provided for @recurring_next_due.
  ///
  /// In en, this message translates to:
  /// **'Next due'**
  String get recurring_next_due;

  /// No description provided for @recurring_and_bills_title.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions & Bills'**
  String get recurring_and_bills_title;

  /// No description provided for @recurring_overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get recurring_overdue;

  /// No description provided for @recurring_upcoming_bills.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bills'**
  String get recurring_upcoming_bills;

  /// No description provided for @recurring_paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get recurring_paid;

  /// No description provided for @recurring_mark_paid.
  ///
  /// In en, this message translates to:
  /// **'Mark Paid'**
  String get recurring_mark_paid;

  /// No description provided for @recurring_mark_paid_confirm.
  ///
  /// In en, this message translates to:
  /// **'Mark this bill as paid? A transaction will be recorded.'**
  String get recurring_mark_paid_confirm;

  /// No description provided for @recurring_bill_paid_success.
  ///
  /// In en, this message translates to:
  /// **'Bill marked as paid'**
  String get recurring_bill_paid_success;

  /// No description provided for @recurring_due_date_label.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get recurring_due_date_label;

  /// No description provided for @recurring_frequency_once.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get recurring_frequency_once;

  /// No description provided for @reports_title.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get reports_title;

  /// No description provided for @reports_overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get reports_overview;

  /// No description provided for @reports_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get reports_categories;

  /// No description provided for @reports_trends.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get reports_trends;

  /// No description provided for @reports_all_accounts.
  ///
  /// In en, this message translates to:
  /// **'All Accounts'**
  String get reports_all_accounts;

  /// No description provided for @reports_empty_title.
  ///
  /// In en, this message translates to:
  /// **'Not enough data'**
  String get reports_empty_title;

  /// No description provided for @reports_empty_sub.
  ///
  /// In en, this message translates to:
  /// **'Add some transactions to see insights'**
  String get reports_empty_sub;

  /// No description provided for @calendar_title.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar_title;

  /// No description provided for @calendar_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No activity this month'**
  String get calendar_empty_title;

  /// No description provided for @chat_title.
  ///
  /// In en, this message translates to:
  /// **'Masarify AI'**
  String get chat_title;

  /// No description provided for @chat_input_hint.
  ///
  /// In en, this message translates to:
  /// **'Ask about your finances...'**
  String get chat_input_hint;

  /// No description provided for @chat_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear chat'**
  String get chat_clear;

  /// No description provided for @chat_clear_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete all messages?'**
  String get chat_clear_confirm;

  /// No description provided for @chat_offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline — chat requires internet'**
  String get chat_offline;

  /// No description provided for @chat_error_rate_limit.
  ///
  /// In en, this message translates to:
  /// **'Too many requests, try again shortly'**
  String get chat_error_rate_limit;

  /// No description provided for @chat_error_unauthorized.
  ///
  /// In en, this message translates to:
  /// **'API key issue, check settings'**
  String get chat_error_unauthorized;

  /// No description provided for @chat_error_timeout.
  ///
  /// In en, this message translates to:
  /// **'Response timed out, try again'**
  String get chat_error_timeout;

  /// No description provided for @chat_error_generic.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong, try again'**
  String get chat_error_generic;

  /// No description provided for @chat_action_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get chat_action_confirm;

  /// No description provided for @chat_action_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get chat_action_cancel;

  /// No description provided for @chat_action_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get chat_action_retry;

  /// No description provided for @chat_action_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Created successfully!'**
  String get chat_action_confirmed;

  /// No description provided for @chat_action_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get chat_action_cancelled;

  /// No description provided for @chat_action_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed — try again?'**
  String get chat_action_failed;

  /// No description provided for @chat_action_goal_title.
  ///
  /// In en, this message translates to:
  /// **'Create Savings Goal'**
  String get chat_action_goal_title;

  /// No description provided for @chat_action_tx_title.
  ///
  /// In en, this message translates to:
  /// **'Create Transaction'**
  String get chat_action_tx_title;

  /// No description provided for @hub_section_ai.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get hub_section_ai;

  /// No description provided for @hub_section_app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get hub_section_app;

  /// No description provided for @hub_wallets.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get hub_wallets;

  /// No description provided for @hub_active.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get hub_active;

  /// No description provided for @hub_in_progress.
  ///
  /// In en, this message translates to:
  /// **'in progress'**
  String get hub_in_progress;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @settings_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settings_general;

  /// No description provided for @settings_security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settings_security;

  /// No description provided for @settings_about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @settings_currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settings_currency;

  /// No description provided for @settings_theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settings_theme;

  /// No description provided for @settings_theme_light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settings_theme_light;

  /// No description provided for @settings_theme_dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settings_theme_dark;

  /// No description provided for @settings_theme_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settings_theme_system;

  /// No description provided for @settings_first_day_of_week.
  ///
  /// In en, this message translates to:
  /// **'First Day of Week'**
  String get settings_first_day_of_week;

  /// No description provided for @settings_first_day_of_month.
  ///
  /// In en, this message translates to:
  /// **'First Day of Month'**
  String get settings_first_day_of_month;

  /// No description provided for @settings_pin_change.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get settings_pin_change;

  /// No description provided for @settings_biometric.
  ///
  /// In en, this message translates to:
  /// **'Biometric Login'**
  String get settings_biometric;

  /// No description provided for @settings_auto_lock.
  ///
  /// In en, this message translates to:
  /// **'Auto-lock'**
  String get settings_auto_lock;

  /// No description provided for @settings_auto_lock_immediate.
  ///
  /// In en, this message translates to:
  /// **'Immediate'**
  String get settings_auto_lock_immediate;

  /// No description provided for @settings_auto_lock_1_min.
  ///
  /// In en, this message translates to:
  /// **'After 1 minute'**
  String get settings_auto_lock_1_min;

  /// No description provided for @settings_auto_lock_5_min.
  ///
  /// In en, this message translates to:
  /// **'After 5 minutes'**
  String get settings_auto_lock_5_min;

  /// No description provided for @settings_pin_enabled.
  ///
  /// In en, this message translates to:
  /// **'PIN enabled'**
  String get settings_pin_enabled;

  /// No description provided for @settings_pin_disabled.
  ///
  /// In en, this message translates to:
  /// **'PIN removed'**
  String get settings_pin_disabled;

  /// No description provided for @settings_biometric_enabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric login enabled'**
  String get settings_biometric_enabled;

  /// No description provided for @settings_biometric_disabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric login disabled'**
  String get settings_biometric_disabled;

  /// No description provided for @settings_biometric_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication not available on this device'**
  String get settings_biometric_unavailable;

  /// No description provided for @settings_verify_pin_first.
  ///
  /// In en, this message translates to:
  /// **'Verify your current PIN'**
  String get settings_verify_pin_first;

  /// No description provided for @settings_pin_lockout.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {duration}.'**
  String settings_pin_lockout(String duration);

  /// No description provided for @settings_clear_data.
  ///
  /// In en, this message translates to:
  /// **'Clear All Data'**
  String get settings_clear_data;

  /// No description provided for @settings_clear_data_confirm.
  ///
  /// In en, this message translates to:
  /// **'Type DELETE to confirm'**
  String get settings_clear_data_confirm;

  /// No description provided for @settings_voice_input.
  ///
  /// In en, this message translates to:
  /// **'Voice Input'**
  String get settings_voice_input;

  /// No description provided for @settings_language_changed.
  ///
  /// In en, this message translates to:
  /// **'Language changed'**
  String get settings_language_changed;

  /// No description provided for @backup_title.
  ///
  /// In en, this message translates to:
  /// **'Backup & Export'**
  String get backup_title;

  /// No description provided for @backup_export_json.
  ///
  /// In en, this message translates to:
  /// **'Export Backup (JSON)'**
  String get backup_export_json;

  /// No description provided for @backup_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup'**
  String get backup_restore;

  /// No description provided for @backup_export_csv.
  ///
  /// In en, this message translates to:
  /// **'Export as CSV'**
  String get backup_export_csv;

  /// No description provided for @backup_export_pdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF Report'**
  String get backup_export_pdf;

  /// No description provided for @backup_success.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully'**
  String get backup_success;

  /// No description provided for @backup_restore_success.
  ///
  /// In en, this message translates to:
  /// **'Data restored successfully'**
  String get backup_restore_success;

  /// No description provided for @backup_error_invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid backup file'**
  String get backup_error_invalid;

  /// No description provided for @backup_confirm_restore_title.
  ///
  /// In en, this message translates to:
  /// **'Restore Backup?'**
  String get backup_confirm_restore_title;

  /// No description provided for @backup_confirm_restore_body.
  ///
  /// In en, this message translates to:
  /// **'This will replace all current data with the backup. This action cannot be undone.'**
  String get backup_confirm_restore_body;

  /// No description provided for @backup_select_month.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get backup_select_month;

  /// No description provided for @backup_export_json_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Full database backup for transfer or safekeeping'**
  String get backup_export_json_subtitle;

  /// No description provided for @backup_restore_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all data from a backup file'**
  String get backup_restore_subtitle;

  /// No description provided for @backup_export_csv_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly transactions in spreadsheet format'**
  String get backup_export_csv_subtitle;

  /// No description provided for @backup_export_pdf_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly financial summary report'**
  String get backup_export_pdf_subtitle;

  /// No description provided for @csv_header_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get csv_header_date;

  /// No description provided for @csv_header_title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get csv_header_title;

  /// No description provided for @csv_header_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get csv_header_amount;

  /// No description provided for @csv_header_currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get csv_header_currency;

  /// No description provided for @csv_header_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get csv_header_type;

  /// No description provided for @csv_header_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get csv_header_category;

  /// No description provided for @csv_header_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get csv_header_account;

  /// No description provided for @csv_header_tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get csv_header_tags;

  /// No description provided for @csv_header_source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get csv_header_source;

  /// No description provided for @csv_header_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get csv_header_location;

  /// No description provided for @csv_header_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get csv_header_notes;

  /// No description provided for @auth_pin_setup_title.
  ///
  /// In en, this message translates to:
  /// **'Set PIN'**
  String get auth_pin_setup_title;

  /// No description provided for @auth_pin_setup_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a 6-digit PIN to protect your data'**
  String get auth_pin_setup_subtitle;

  /// No description provided for @auth_pin_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get auth_pin_confirm;

  /// No description provided for @auth_pin_mismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs don\'t match. Try again.'**
  String get auth_pin_mismatch;

  /// No description provided for @auth_pin_entry_title.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get auth_pin_entry_title;

  /// No description provided for @auth_pin_wrong.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get auth_pin_wrong;

  /// No description provided for @auth_biometric_prompt.
  ///
  /// In en, this message translates to:
  /// **'Authenticate to open Masarify'**
  String get auth_biometric_prompt;

  /// No description provided for @auth_use_pin.
  ///
  /// In en, this message translates to:
  /// **'Use PIN instead'**
  String get auth_use_pin;

  /// No description provided for @onboarding_page1_title.
  ///
  /// In en, this message translates to:
  /// **'Take Control of Your Money'**
  String get onboarding_page1_title;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get common_close;

  /// No description provided for @common_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get common_confirm;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get common_none;

  /// No description provided for @common_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get common_next;

  /// No description provided for @common_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get common_skip;

  /// No description provided for @common_error_generic.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get common_error_generic;

  /// No description provided for @common_invalid_amount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get common_invalid_amount;

  /// No description provided for @permission_mic_title.
  ///
  /// In en, this message translates to:
  /// **'Microphone Access'**
  String get permission_mic_title;

  /// No description provided for @permission_mic_body.
  ///
  /// In en, this message translates to:
  /// **'Masarify uses your microphone to record voice commands. Audio is sent to Google AI for transcription when you have internet access. Nothing is stored permanently.'**
  String get permission_mic_body;

  /// No description provided for @permission_location_title.
  ///
  /// In en, this message translates to:
  /// **'Location Access'**
  String get permission_location_title;

  /// No description provided for @permission_location_body.
  ///
  /// In en, this message translates to:
  /// **'Masarify can tag your transaction with the location name. This is completely optional.'**
  String get permission_location_body;

  /// No description provided for @location_detect.
  ///
  /// In en, this message translates to:
  /// **'Detect Location'**
  String get location_detect;

  /// No description provided for @location_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Maadi, Cairo'**
  String get location_hint;

  /// No description provided for @location_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not detect location'**
  String get location_failed;

  /// No description provided for @error_amount_zero.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get error_amount_zero;

  /// No description provided for @error_category_required.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get error_category_required;

  /// No description provided for @error_wallet_required.
  ///
  /// In en, this message translates to:
  /// **'Please select an account'**
  String get error_wallet_required;

  /// No description provided for @error_name_required.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get error_name_required;

  /// No description provided for @voice_tap_to_start.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic to start'**
  String get voice_tap_to_start;

  /// No description provided for @voice_listening.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get voice_listening;

  /// No description provided for @voice_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Review Transactions'**
  String get voice_confirm_title;

  /// No description provided for @voice_confirm_accept_all.
  ///
  /// In en, this message translates to:
  /// **'Save All'**
  String get voice_confirm_accept_all;

  /// No description provided for @voice_error_no_service.
  ///
  /// In en, this message translates to:
  /// **'Voice input is not available. Please check your internet connection.'**
  String get voice_error_no_service;

  /// No description provided for @voice_no_results.
  ///
  /// In en, this message translates to:
  /// **'Nothing detected. Please try again.'**
  String get voice_no_results;

  /// No description provided for @voice_ai_error.
  ///
  /// In en, this message translates to:
  /// **'AI parsing failed. Please try again.'**
  String get voice_ai_error;

  /// No description provided for @voice_retry.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get voice_retry;

  /// No description provided for @voice_ai_parsing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing with AI...'**
  String get voice_ai_parsing;

  /// No description provided for @voice_cancel_recording.
  ///
  /// In en, this message translates to:
  /// **'Cancel recording'**
  String get voice_cancel_recording;

  /// No description provided for @permission_allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get permission_allow;

  /// No description provided for @permission_deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get permission_deny;

  /// No description provided for @sms_review_title.
  ///
  /// In en, this message translates to:
  /// **'Transactions Found'**
  String get sms_review_title;

  /// No description provided for @parsed_transactions_title.
  ///
  /// In en, this message translates to:
  /// **'Auto-detected Transactions'**
  String get parsed_transactions_title;

  /// No description provided for @sms_review_approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get sms_review_approve;

  /// No description provided for @sms_review_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get sms_review_skip;

  /// No description provided for @sms_new_found.
  ///
  /// In en, this message translates to:
  /// **'{count} transaction(s) found — tap to review'**
  String sms_new_found(int count);

  /// No description provided for @parser_no_pending.
  ///
  /// In en, this message translates to:
  /// **'No pending transactions to review'**
  String get parser_no_pending;

  /// No description provided for @parser_approved_msg.
  ///
  /// In en, this message translates to:
  /// **'Transaction approved'**
  String get parser_approved_msg;

  /// No description provided for @parser_skipped_msg.
  ///
  /// In en, this message translates to:
  /// **'Transaction skipped'**
  String get parser_skipped_msg;

  /// No description provided for @parser_enrich.
  ///
  /// In en, this message translates to:
  /// **'Enrich'**
  String get parser_enrich;

  /// No description provided for @parser_enrich_all.
  ///
  /// In en, this message translates to:
  /// **'Enrich All'**
  String get parser_enrich_all;

  /// No description provided for @parser_possible_duplicate.
  ///
  /// In en, this message translates to:
  /// **'Possible duplicate'**
  String get parser_possible_duplicate;

  /// No description provided for @parser_wallet_label.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get parser_wallet_label;

  /// No description provided for @parser_approve_as_transfer.
  ///
  /// In en, this message translates to:
  /// **'Approve as Transfer'**
  String get parser_approve_as_transfer;

  /// No description provided for @parser_atm_detected.
  ///
  /// In en, this message translates to:
  /// **'ATM Withdrawal'**
  String get parser_atm_detected;

  /// No description provided for @parser_select_cash_wallet.
  ///
  /// In en, this message translates to:
  /// **'Select cash wallet'**
  String get parser_select_cash_wallet;

  /// No description provided for @parser_duplicate_exists.
  ///
  /// In en, this message translates to:
  /// **'Similar transaction already exists. Create anyway?'**
  String get parser_duplicate_exists;

  /// No description provided for @goal_link_prompt.
  ///
  /// In en, this message translates to:
  /// **'This looks like it relates to your \'{goalName}\'. Link it?'**
  String goal_link_prompt(String goalName);

  /// No description provided for @goal_link_action.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get goal_link_action;

  /// No description provided for @transfer_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get transfer_from;

  /// No description provided for @transfer_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get transfer_to;

  /// No description provided for @transfer_fee.
  ///
  /// In en, this message translates to:
  /// **'Transfer Fee (optional)'**
  String get transfer_fee;

  /// No description provided for @language_en.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_en;

  /// No description provided for @language_ar.
  ///
  /// In en, this message translates to:
  /// **'Arabic (العربية)'**
  String get language_ar;

  /// No description provided for @language_system.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get language_system;

  /// No description provided for @pro_badge.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get pro_badge;

  /// No description provided for @pro_upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get pro_upgrade;

  /// No description provided for @subscription_title.
  ///
  /// In en, this message translates to:
  /// **'Pro Subscription'**
  String get subscription_title;

  /// No description provided for @paywall_title.
  ///
  /// In en, this message translates to:
  /// **'Masarify Pro'**
  String get paywall_title;

  /// No description provided for @paywall_headline.
  ///
  /// In en, this message translates to:
  /// **'Unlock Full Power'**
  String get paywall_headline;

  /// No description provided for @paywall_subheadline.
  ///
  /// In en, this message translates to:
  /// **'Get unlimited budgets, AI insights, and more.'**
  String get paywall_subheadline;

  /// No description provided for @paywall_includes.
  ///
  /// In en, this message translates to:
  /// **'Pro includes:'**
  String get paywall_includes;

  /// No description provided for @paywall_feature_budgets.
  ///
  /// In en, this message translates to:
  /// **'Unlimited budgets'**
  String get paywall_feature_budgets;

  /// No description provided for @paywall_feature_goals.
  ///
  /// In en, this message translates to:
  /// **'Unlimited savings goals'**
  String get paywall_feature_goals;

  /// No description provided for @paywall_feature_insights.
  ///
  /// In en, this message translates to:
  /// **'AI spending insights'**
  String get paywall_feature_insights;

  /// No description provided for @paywall_feature_analytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced analytics & trends'**
  String get paywall_feature_analytics;

  /// No description provided for @paywall_feature_backup.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup (Google Drive)'**
  String get paywall_feature_backup;

  /// No description provided for @paywall_feature_export.
  ///
  /// In en, this message translates to:
  /// **'CSV & PDF export'**
  String get paywall_feature_export;

  /// No description provided for @paywall_feature_chat.
  ///
  /// In en, this message translates to:
  /// **'AI financial assistant'**
  String get paywall_feature_chat;

  /// No description provided for @paywall_monthly.
  ///
  /// In en, this message translates to:
  /// **'{price}/month'**
  String paywall_monthly(String price);

  /// No description provided for @paywall_yearly.
  ///
  /// In en, this message translates to:
  /// **'{price}/year — Save 30%'**
  String paywall_yearly(String price);

  /// No description provided for @paywall_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get paywall_restore;

  /// No description provided for @subscription_active.
  ///
  /// In en, this message translates to:
  /// **'Pro Active'**
  String get subscription_active;

  /// No description provided for @subscription_inactive.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get subscription_inactive;

  /// No description provided for @subscription_upgrade_prompt.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro for unlimited features.'**
  String get subscription_upgrade_prompt;

  /// No description provided for @paywall_restored.
  ///
  /// In en, this message translates to:
  /// **'Purchase restored successfully!'**
  String get paywall_restored;

  /// No description provided for @paywall_no_purchases.
  ///
  /// In en, this message translates to:
  /// **'No previous purchases found.'**
  String get paywall_no_purchases;

  /// No description provided for @paywall_store_unavailable.
  ///
  /// In en, this message translates to:
  /// **'Store not available. Please try again later.'**
  String get paywall_store_unavailable;

  /// No description provided for @paywall_trial_banner.
  ///
  /// In en, this message translates to:
  /// **'{days} days left in your free trial'**
  String paywall_trial_banner(int days);

  /// No description provided for @paywall_pro_feature.
  ///
  /// In en, this message translates to:
  /// **'Pro Feature'**
  String get paywall_pro_feature;

  /// No description provided for @paywall_unlock_cta.
  ///
  /// In en, this message translates to:
  /// **'Tap to unlock'**
  String get paywall_unlock_cta;

  /// No description provided for @paywall_pricing_terms.
  ///
  /// In en, this message translates to:
  /// **'7-day free trial • Cancel anytime'**
  String get paywall_pricing_terms;

  /// No description provided for @subscription_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get subscription_manage;

  /// No description provided for @settings_pro_status.
  ///
  /// In en, this message translates to:
  /// **'Masarify Pro'**
  String get settings_pro_status;

  /// No description provided for @settings_pro_trial_days.
  ///
  /// In en, this message translates to:
  /// **'Trial: {days} days left'**
  String settings_pro_trial_days(int days);

  /// No description provided for @settings_pro_free.
  ///
  /// In en, this message translates to:
  /// **'Free Plan'**
  String get settings_pro_free;

  /// No description provided for @common_ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get common_ok;

  /// No description provided for @common_error_title.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get common_error_title;

  /// No description provided for @common_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get common_all;

  /// No description provided for @common_save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get common_save_changes;

  /// No description provided for @date_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get date_today;

  /// No description provided for @date_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get date_yesterday;

  /// No description provided for @transaction_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Transaction'**
  String get transaction_edit_title;

  /// No description provided for @transaction_detail_title.
  ///
  /// In en, this message translates to:
  /// **'Transaction Details'**
  String get transaction_detail_title;

  /// No description provided for @transaction_not_found.
  ///
  /// In en, this message translates to:
  /// **'Transaction not found'**
  String get transaction_not_found;

  /// No description provided for @transaction_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get transaction_delete_title;

  /// No description provided for @transaction_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this transaction?'**
  String get transaction_delete_confirm;

  /// No description provided for @transaction_deleted_message.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{title}\"'**
  String transaction_deleted_message(String title);

  /// No description provided for @transaction_source_label.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get transaction_source_label;

  /// No description provided for @transaction_source_manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get transaction_source_manual;

  /// No description provided for @transaction_optional_details.
  ///
  /// In en, this message translates to:
  /// **'Additional details'**
  String get transaction_optional_details;

  /// No description provided for @transaction_note_hint.
  ///
  /// In en, this message translates to:
  /// **'Add an optional note...'**
  String get transaction_note_hint;

  /// No description provided for @transaction_category_picker.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get transaction_category_picker;

  /// No description provided for @transaction_wallet_picker.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get transaction_wallet_picker;

  /// No description provided for @wallet_detail_title.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get wallet_detail_title;

  /// No description provided for @wallet_not_found.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get wallet_not_found;

  /// No description provided for @wallet_add_short.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get wallet_add_short;

  /// No description provided for @wallet_physical_wallet.
  ///
  /// In en, this message translates to:
  /// **'Physical Wallet'**
  String get wallet_physical_wallet;

  /// No description provided for @wallet_add_title.
  ///
  /// In en, this message translates to:
  /// **'New Account'**
  String get wallet_add_title;

  /// No description provided for @wallet_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Account'**
  String get wallet_edit_title;

  /// No description provided for @wallet_name_label.
  ///
  /// In en, this message translates to:
  /// **'Account Name'**
  String get wallet_name_label;

  /// No description provided for @wallet_name_hint_example.
  ///
  /// In en, this message translates to:
  /// **'e.g. Main Account'**
  String get wallet_name_hint_example;

  /// No description provided for @wallet_name_duplicate.
  ///
  /// In en, this message translates to:
  /// **'An account with this name already exists'**
  String get wallet_name_duplicate;

  /// No description provided for @wallet_total_balance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get wallet_total_balance;

  /// No description provided for @wallet_current_balance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get wallet_current_balance;

  /// No description provided for @wallet_transactions_header.
  ///
  /// In en, this message translates to:
  /// **'Account Transactions'**
  String get wallet_transactions_header;

  /// No description provided for @wallet_no_transactions_sub.
  ///
  /// In en, this message translates to:
  /// **'No transactions recorded for this account yet'**
  String get wallet_no_transactions_sub;

  /// No description provided for @wallet_type_label.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get wallet_type_label;

  /// No description provided for @wallet_color_label.
  ///
  /// In en, this message translates to:
  /// **'Account Color'**
  String get wallet_color_label;

  /// No description provided for @wallet_add_button.
  ///
  /// In en, this message translates to:
  /// **'Add Account'**
  String get wallet_add_button;

  /// No description provided for @wallet_type_physical_cash_short.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get wallet_type_physical_cash_short;

  /// No description provided for @wallet_type_bank_short.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get wallet_type_bank_short;

  /// No description provided for @wallet_type_mobile_wallet_short.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet_type_mobile_wallet_short;

  /// No description provided for @wallet_type_credit_card_short.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get wallet_type_credit_card_short;

  /// No description provided for @wallet_type_prepaid_card_short.
  ///
  /// In en, this message translates to:
  /// **'Prepaid'**
  String get wallet_type_prepaid_card_short;

  /// No description provided for @wallet_type_investment_short.
  ///
  /// In en, this message translates to:
  /// **'Invest'**
  String get wallet_type_investment_short;

  /// No description provided for @wallet_cannot_archive_system.
  ///
  /// In en, this message translates to:
  /// **'The Cash wallet cannot be archived'**
  String get wallet_cannot_archive_system;

  /// No description provided for @goal_contribution_from_wallet.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get goal_contribution_from_wallet;

  /// No description provided for @wallet_linked_senders_label.
  ///
  /// In en, this message translates to:
  /// **'Linked SMS Senders'**
  String get wallet_linked_senders_label;

  /// No description provided for @wallet_linked_senders_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. CIB, NBE, BankMisr'**
  String get wallet_linked_senders_hint;

  /// No description provided for @wallet_linked_senders_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Match auto-detected transactions to this account'**
  String get wallet_linked_senders_subtitle;

  /// No description provided for @wallets_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get wallets_empty_title;

  /// No description provided for @wallets_empty_sub.
  ///
  /// In en, this message translates to:
  /// **'Add your first account to start tracking'**
  String get wallets_empty_sub;

  /// No description provided for @wallets_transfer_button.
  ///
  /// In en, this message translates to:
  /// **'Transfer Between Accounts'**
  String get wallets_transfer_button;

  /// No description provided for @category_add_title.
  ///
  /// In en, this message translates to:
  /// **'New Category'**
  String get category_add_title;

  /// No description provided for @category_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Category'**
  String get category_edit_title;

  /// No description provided for @category_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Category'**
  String get category_delete_title;

  /// No description provided for @category_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String category_delete_confirm(String name);

  /// No description provided for @category_default_title.
  ///
  /// In en, this message translates to:
  /// **'Default Category'**
  String get category_default_title;

  /// No description provided for @category_default_chip.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get category_default_chip;

  /// No description provided for @category_group_needs.
  ///
  /// In en, this message translates to:
  /// **'Needs'**
  String get category_group_needs;

  /// No description provided for @category_group_wants.
  ///
  /// In en, this message translates to:
  /// **'Wants'**
  String get category_group_wants;

  /// No description provided for @category_group_savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get category_group_savings;

  /// No description provided for @categories_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No categories'**
  String get categories_empty_title;

  /// No description provided for @categories_empty_sub.
  ///
  /// In en, this message translates to:
  /// **'Add a category to classify your transactions'**
  String get categories_empty_sub;

  /// No description provided for @budget_total_label.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get budget_total_label;

  /// No description provided for @budget_spent_label.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get budget_spent_label;

  /// No description provided for @budgets_empty_sub_long.
  ///
  /// In en, this message translates to:
  /// **'Set a budget for each category to control your spending'**
  String get budgets_empty_sub_long;

  /// No description provided for @goal_detail_title.
  ///
  /// In en, this message translates to:
  /// **'Goal Details'**
  String get goal_detail_title;

  /// No description provided for @goal_not_found.
  ///
  /// In en, this message translates to:
  /// **'Goal not found'**
  String get goal_not_found;

  /// No description provided for @goal_add_title.
  ///
  /// In en, this message translates to:
  /// **'New Savings Goal'**
  String get goal_add_title;

  /// No description provided for @goal_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Goal'**
  String get goal_edit_title;

  /// No description provided for @goal_name_label.
  ///
  /// In en, this message translates to:
  /// **'Goal Name'**
  String get goal_name_label;

  /// No description provided for @goal_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Japan Trip, New Car'**
  String get goal_name_hint;

  /// No description provided for @goal_detail_add_savings.
  ///
  /// In en, this message translates to:
  /// **'Add Savings'**
  String get goal_detail_add_savings;

  /// No description provided for @goal_already_funded.
  ///
  /// In en, this message translates to:
  /// **'This goal is already fully funded.'**
  String get goal_already_funded;

  /// No description provided for @goal_contribution_max.
  ///
  /// In en, this message translates to:
  /// **'Maximum: {amount}'**
  String goal_contribution_max(String amount);

  /// No description provided for @goal_detail_no_savings.
  ///
  /// In en, this message translates to:
  /// **'No savings yet'**
  String get goal_detail_no_savings;

  /// No description provided for @goal_detail_no_savings_sub.
  ///
  /// In en, this message translates to:
  /// **'Add your first amount to this goal'**
  String get goal_detail_no_savings_sub;

  /// No description provided for @goal_saved_label.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get goal_saved_label;

  /// No description provided for @goal_target_label.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get goal_target_label;

  /// No description provided for @goal_remaining_label.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get goal_remaining_label;

  /// No description provided for @goal_completed_chip.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goal_completed_chip;

  /// No description provided for @goal_target_required.
  ///
  /// In en, this message translates to:
  /// **'Enter a target amount'**
  String get goal_target_required;

  /// No description provided for @goal_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Goal'**
  String get goal_delete_title;

  /// No description provided for @goal_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this goal and all contributions?'**
  String get goal_delete_confirm;

  /// No description provided for @goal_delete_contribution_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this contribution?'**
  String get goal_delete_contribution_confirm;

  /// No description provided for @budget_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Budget'**
  String get budget_delete_title;

  /// No description provided for @budget_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this budget?'**
  String get budget_delete_confirm;

  /// No description provided for @goals_empty_sub_long.
  ///
  /// In en, this message translates to:
  /// **'Set a savings goal and start achieving it'**
  String get goals_empty_sub_long;

  /// No description provided for @transfer_title.
  ///
  /// In en, this message translates to:
  /// **'Transfer Between Accounts'**
  String get transfer_title;

  /// No description provided for @transfer_amount_label.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transfer_amount_label;

  /// No description provided for @transfer_note_label.
  ///
  /// In en, this message translates to:
  /// **'Note (Optional)'**
  String get transfer_note_label;

  /// No description provided for @transfer_confirm_button.
  ///
  /// In en, this message translates to:
  /// **'Confirm Transfer'**
  String get transfer_confirm_button;

  /// No description provided for @transfer_different_wallets.
  ///
  /// In en, this message translates to:
  /// **'Select two different accounts'**
  String get transfer_different_wallets;

  /// No description provided for @transfer_from_wallet.
  ///
  /// In en, this message translates to:
  /// **'From Account'**
  String get transfer_from_wallet;

  /// No description provided for @transfer_to_wallet.
  ///
  /// In en, this message translates to:
  /// **'To Account'**
  String get transfer_to_wallet;

  /// No description provided for @transfer_select_wallet.
  ///
  /// In en, this message translates to:
  /// **'Select Account'**
  String get transfer_select_wallet;

  /// No description provided for @transfer_swap.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get transfer_swap;

  /// No description provided for @transfer_insufficient_title.
  ///
  /// In en, this message translates to:
  /// **'Insufficient Balance'**
  String get transfer_insufficient_title;

  /// No description provided for @transfer_insufficient_body.
  ///
  /// In en, this message translates to:
  /// **'Source account balance is less than the transfer amount. Continue anyway?'**
  String get transfer_insufficient_body;

  /// No description provided for @transfer_success.
  ///
  /// In en, this message translates to:
  /// **'Transfer completed successfully'**
  String get transfer_success;

  /// No description provided for @settings_appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settings_appearance;

  /// No description provided for @settings_categories_label.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get settings_categories_label;

  /// No description provided for @settings_pin_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Protect the app with a PIN code'**
  String get settings_pin_subtitle;

  /// No description provided for @settings_biometric_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric authentication'**
  String get settings_biometric_subtitle;

  /// No description provided for @settings_backup_section.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get settings_backup_section;

  /// No description provided for @settings_backup_label.
  ///
  /// In en, this message translates to:
  /// **'Backup & Export'**
  String get settings_backup_label;

  /// No description provided for @settings_backup_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Export your data or import a backup'**
  String get settings_backup_subtitle;

  /// No description provided for @settings_danger_zone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get settings_danger_zone;

  /// No description provided for @settings_clear_data_label.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get settings_clear_data_label;

  /// No description provided for @settings_clear_data_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear everything and start fresh'**
  String get settings_clear_data_subtitle;

  /// No description provided for @settings_clear_data_title.
  ///
  /// In en, this message translates to:
  /// **'Delete All Data'**
  String get settings_clear_data_title;

  /// No description provided for @settings_clear_data_warning.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.\nAll accounts, transactions, budgets, and goals will be deleted.'**
  String get settings_clear_data_warning;

  /// No description provided for @settings_clear_data_permanent.
  ///
  /// In en, this message translates to:
  /// **'Permanent Delete'**
  String get settings_clear_data_permanent;

  /// No description provided for @settings_about_section.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settings_about_section;

  /// No description provided for @settings_version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settings_version;

  /// No description provided for @settings_help_label.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get settings_help_label;

  /// No description provided for @settings_help_subtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQs and contact'**
  String get settings_help_subtitle;

  /// No description provided for @settings_first_day_budget_cycle.
  ///
  /// In en, this message translates to:
  /// **'First Day of Month (Budget Cycle)'**
  String get settings_first_day_budget_cycle;

  /// No description provided for @settings_currency_egp.
  ///
  /// In en, this message translates to:
  /// **'EGP — Egyptian Pound'**
  String get settings_currency_egp;

  /// No description provided for @settings_currency_usd.
  ///
  /// In en, this message translates to:
  /// **'\$ — US Dollar'**
  String get settings_currency_usd;

  /// No description provided for @settings_currency_eur.
  ///
  /// In en, this message translates to:
  /// **'€ — Euro'**
  String get settings_currency_eur;

  /// No description provided for @settings_currency_sar.
  ///
  /// In en, this message translates to:
  /// **'SAR — Saudi Riyal'**
  String get settings_currency_sar;

  /// No description provided for @settings_currency_aed.
  ///
  /// In en, this message translates to:
  /// **'AED — UAE Dirham'**
  String get settings_currency_aed;

  /// No description provided for @settings_currency_kwd.
  ///
  /// In en, this message translates to:
  /// **'KWD — Kuwaiti Dinar'**
  String get settings_currency_kwd;

  /// No description provided for @settings_day_saturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get settings_day_saturday;

  /// No description provided for @settings_day_sunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get settings_day_sunday;

  /// No description provided for @settings_day_monday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get settings_day_monday;

  /// No description provided for @settings_pin_lock_label.
  ///
  /// In en, this message translates to:
  /// **'Lock with PIN'**
  String get settings_pin_lock_label;

  /// No description provided for @settings_budget_cycle_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Determines the start of the monthly budget cycle'**
  String get settings_budget_cycle_subtitle;

  /// No description provided for @common_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get common_coming_soon;

  /// No description provided for @onboarding_page1_body.
  ///
  /// In en, this message translates to:
  /// **'Track every pound, plan your future,\nand live worry-free about money.'**
  String get onboarding_page1_body;

  /// No description provided for @goal_active_section.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get goal_active_section;

  /// No description provided for @goal_completed_section.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get goal_completed_section;

  /// No description provided for @goal_days_remaining.
  ///
  /// In en, this message translates to:
  /// **'{daysLeft} days remaining'**
  String goal_days_remaining(int daysLeft);

  /// No description provided for @goal_pick_date.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get goal_pick_date;

  /// No description provided for @goal_remove_date.
  ///
  /// In en, this message translates to:
  /// **'Remove date'**
  String get goal_remove_date;

  /// No description provided for @goal_keyword_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. travel, trip, flight'**
  String get goal_keyword_hint;

  /// No description provided for @month_1.
  ///
  /// In en, this message translates to:
  /// **'January'**
  String get month_1;

  /// No description provided for @month_2.
  ///
  /// In en, this message translates to:
  /// **'February'**
  String get month_2;

  /// No description provided for @month_3.
  ///
  /// In en, this message translates to:
  /// **'March'**
  String get month_3;

  /// No description provided for @month_4.
  ///
  /// In en, this message translates to:
  /// **'April'**
  String get month_4;

  /// No description provided for @month_5.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get month_5;

  /// No description provided for @month_6.
  ///
  /// In en, this message translates to:
  /// **'June'**
  String get month_6;

  /// No description provided for @month_7.
  ///
  /// In en, this message translates to:
  /// **'July'**
  String get month_7;

  /// No description provided for @month_8.
  ///
  /// In en, this message translates to:
  /// **'August'**
  String get month_8;

  /// No description provided for @month_9.
  ///
  /// In en, this message translates to:
  /// **'September'**
  String get month_9;

  /// No description provided for @month_10.
  ///
  /// In en, this message translates to:
  /// **'October'**
  String get month_10;

  /// No description provided for @month_11.
  ///
  /// In en, this message translates to:
  /// **'November'**
  String get month_11;

  /// No description provided for @month_12.
  ///
  /// In en, this message translates to:
  /// **'December'**
  String get month_12;

  /// No description provided for @month_previous.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get month_previous;

  /// No description provided for @month_next.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get month_next;

  /// No description provided for @recurring_active.
  ///
  /// In en, this message translates to:
  /// **'Active Subscriptions'**
  String get recurring_active;

  /// No description provided for @recurring_paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurring_paused;

  /// No description provided for @recurring_pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get recurring_pause;

  /// No description provided for @recurring_error_title.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get recurring_error_title;

  /// No description provided for @recurring_error_amount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get recurring_error_amount;

  /// No description provided for @recurring_error_category.
  ///
  /// In en, this message translates to:
  /// **'Please select a category'**
  String get recurring_error_category;

  /// No description provided for @recurring_error_wallet.
  ///
  /// In en, this message translates to:
  /// **'Please select an account'**
  String get recurring_error_wallet;

  /// No description provided for @recurring_error_end_date.
  ///
  /// In en, this message translates to:
  /// **'End date is required for custom frequency'**
  String get recurring_error_end_date;

  /// No description provided for @recurring_error_date_order.
  ///
  /// In en, this message translates to:
  /// **'End date must be after start date'**
  String get recurring_error_date_order;

  /// No description provided for @recurring_frequency_label.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get recurring_frequency_label;

  /// No description provided for @recurring_start_date.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get recurring_start_date;

  /// No description provided for @recurring_end_date.
  ///
  /// In en, this message translates to:
  /// **'End Date (optional)'**
  String get recurring_end_date;

  /// No description provided for @recurring_end_date_required.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get recurring_end_date_required;

  /// No description provided for @recurring_empty_sub.
  ///
  /// In en, this message translates to:
  /// **'Set up subscriptions & bills to track regular payments'**
  String get recurring_empty_sub;

  /// No description provided for @recurring_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Subscription'**
  String get recurring_delete_title;

  /// No description provided for @recurring_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this subscription?'**
  String get recurring_delete_confirm;

  /// No description provided for @recurring_confirm_activate.
  ///
  /// In en, this message translates to:
  /// **'Activate this subscription? It will start creating transactions automatically.'**
  String get recurring_confirm_activate;

  /// No description provided for @recurring_confirm_pause.
  ///
  /// In en, this message translates to:
  /// **'Pause this subscription? No new transactions will be created until reactivated.'**
  String get recurring_confirm_pause;

  /// No description provided for @recurring_title_label.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get recurring_title_label;

  /// No description provided for @recurring_title_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Rent, Internet, Salary'**
  String get recurring_title_hint;

  /// No description provided for @recurring_type_label.
  ///
  /// In en, this message translates to:
  /// **'Transaction Type'**
  String get recurring_type_label;

  /// No description provided for @recurring_view_all.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get recurring_view_all;

  /// No description provided for @recurring_monthly_total.
  ///
  /// In en, this message translates to:
  /// **'Monthly Total'**
  String get recurring_monthly_total;

  /// No description provided for @recurring_due_this_week.
  ///
  /// In en, this message translates to:
  /// **'{count} due this week'**
  String recurring_due_this_week(int count);

  /// No description provided for @recurring_upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get recurring_upcoming;

  /// No description provided for @recurring_paid_section.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get recurring_paid_section;

  /// No description provided for @recurring_total_monthly_spend.
  ///
  /// In en, this message translates to:
  /// **'Total Monthly Spend'**
  String get recurring_total_monthly_spend;

  /// No description provided for @recurring_attention_required.
  ///
  /// In en, this message translates to:
  /// **'Attention Required'**
  String get recurring_attention_required;

  /// No description provided for @recurring_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get recurring_coming_soon;

  /// No description provided for @recurring_active_services.
  ///
  /// In en, this message translates to:
  /// **'Active Services'**
  String get recurring_active_services;

  /// No description provided for @recurring_recently_paid.
  ///
  /// In en, this message translates to:
  /// **'Recently Paid'**
  String get recurring_recently_paid;

  /// No description provided for @recurring_potential_savings.
  ///
  /// In en, this message translates to:
  /// **'Potential Savings'**
  String get recurring_potential_savings;

  /// No description provided for @recurring_spending_trend.
  ///
  /// In en, this message translates to:
  /// **'Spending Trend'**
  String get recurring_spending_trend;

  /// No description provided for @recurring_per_month.
  ///
  /// In en, this message translates to:
  /// **'{amount}/mo'**
  String recurring_per_month(String amount);

  /// No description provided for @recurring_auto_pay_label.
  ///
  /// In en, this message translates to:
  /// **'Automatically mark as paid'**
  String get recurring_auto_pay_label;

  /// No description provided for @recurring_auto_pay_wallet.
  ///
  /// In en, this message translates to:
  /// **'Deduct from account'**
  String get recurring_auto_pay_wallet;

  /// No description provided for @calendar_no_transactions_day.
  ///
  /// In en, this message translates to:
  /// **'No transactions on this day'**
  String get calendar_no_transactions_day;

  /// No description provided for @reports_period_7d.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get reports_period_7d;

  /// No description provided for @reports_period_30d.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get reports_period_30d;

  /// No description provided for @reports_period_90d.
  ///
  /// In en, this message translates to:
  /// **'90 Days'**
  String get reports_period_90d;

  /// No description provided for @reports_income_vs_expense.
  ///
  /// In en, this message translates to:
  /// **'Income vs Expense'**
  String get reports_income_vs_expense;

  /// No description provided for @reports_top_categories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get reports_top_categories;

  /// No description provided for @reports_vs_last_month.
  ///
  /// In en, this message translates to:
  /// **'vs last month'**
  String get reports_vs_last_month;

  /// No description provided for @reports_no_data.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this period'**
  String get reports_no_data;

  /// No description provided for @reports_total_expense.
  ///
  /// In en, this message translates to:
  /// **'Total Expense'**
  String get reports_total_expense;

  /// No description provided for @reports_net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get reports_net;

  /// No description provided for @reports_daily_average.
  ///
  /// In en, this message translates to:
  /// **'Daily Average'**
  String get reports_daily_average;

  /// No description provided for @reports_total_spending.
  ///
  /// In en, this message translates to:
  /// **'Total Spending'**
  String get reports_total_spending;

  /// No description provided for @reports_highest_day.
  ///
  /// In en, this message translates to:
  /// **'Highest Day'**
  String get reports_highest_day;

  /// No description provided for @reports_vs_previous.
  ///
  /// In en, this message translates to:
  /// **'vs previous period'**
  String get reports_vs_previous;

  /// No description provided for @reports_savings_rate.
  ///
  /// In en, this message translates to:
  /// **'Savings rate: {rate}% of income'**
  String reports_savings_rate(int rate);

  /// No description provided for @reportsCategoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String reportsCategoryCount(int count);

  /// No description provided for @reportsBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget: {amount}'**
  String reportsBudgetLabel(String amount);

  /// No description provided for @balance_show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get balance_show;

  /// No description provided for @balance_hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get balance_hide;

  /// No description provided for @budget_exceeded.
  ///
  /// In en, this message translates to:
  /// **'Exceeded!'**
  String get budget_exceeded;

  /// No description provided for @common_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get common_clear;

  /// No description provided for @common_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get common_date;

  /// No description provided for @common_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get common_amount;

  /// No description provided for @settings_delete_confirm_word.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get settings_delete_confirm_word;

  /// No description provided for @recurring_amount_label.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get recurring_amount_label;

  /// No description provided for @budget_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit Budget'**
  String get budget_edit_title;

  /// No description provided for @budget_period_label.
  ///
  /// In en, this message translates to:
  /// **'Budget Period'**
  String get budget_period_label;

  /// No description provided for @budget_period_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get budget_period_daily;

  /// No description provided for @budget_period_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get budget_period_weekly;

  /// No description provided for @budget_period_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budget_period_monthly;

  /// No description provided for @budget_period_yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get budget_period_yearly;

  /// No description provided for @budget_rollover_label.
  ///
  /// In en, this message translates to:
  /// **'Roll over unused budget'**
  String get budget_rollover_label;

  /// No description provided for @goal_contribution_note.
  ///
  /// In en, this message translates to:
  /// **'Note (Optional)'**
  String get goal_contribution_note;

  /// No description provided for @goal_icon_label.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get goal_icon_label;

  /// No description provided for @goal_color_label.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get goal_color_label;

  /// No description provided for @fab_voice.
  ///
  /// In en, this message translates to:
  /// **'Voice'**
  String get fab_voice;

  /// No description provided for @fab_manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get fab_manual;

  /// No description provided for @wallet_archive_balance_warning.
  ///
  /// In en, this message translates to:
  /// **'This account still has a remaining balance. The balance will be excluded from your totals after archiving.'**
  String get wallet_archive_balance_warning;

  /// No description provided for @notif_prefs_title.
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notif_prefs_title;

  /// No description provided for @notif_section_budget.
  ///
  /// In en, this message translates to:
  /// **'Budget Alerts'**
  String get notif_section_budget;

  /// No description provided for @notif_budget_warning.
  ///
  /// In en, this message translates to:
  /// **'Budget Warning (80%)'**
  String get notif_budget_warning;

  /// No description provided for @notif_budget_warning_sub.
  ///
  /// In en, this message translates to:
  /// **'Notify when spending reaches 80% of budget'**
  String get notif_budget_warning_sub;

  /// No description provided for @notif_budget_exceeded.
  ///
  /// In en, this message translates to:
  /// **'Budget Exceeded (100%)'**
  String get notif_budget_exceeded;

  /// No description provided for @notif_budget_exceeded_sub.
  ///
  /// In en, this message translates to:
  /// **'Notify when a budget is fully spent'**
  String get notif_budget_exceeded_sub;

  /// No description provided for @notif_section_bills.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions & Bills'**
  String get notif_section_bills;

  /// No description provided for @notif_bill_reminder.
  ///
  /// In en, this message translates to:
  /// **'Bill Reminders'**
  String get notif_bill_reminder;

  /// No description provided for @notif_bill_reminder_sub.
  ///
  /// In en, this message translates to:
  /// **'Remind about upcoming bills before due date'**
  String get notif_bill_reminder_sub;

  /// No description provided for @notif_recurring_reminder.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get notif_recurring_reminder;

  /// No description provided for @notif_recurring_reminder_sub.
  ///
  /// In en, this message translates to:
  /// **'Notify when subscriptions are due'**
  String get notif_recurring_reminder_sub;

  /// No description provided for @notif_section_goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get notif_section_goals;

  /// No description provided for @notif_goal_milestone.
  ///
  /// In en, this message translates to:
  /// **'Goal Milestones'**
  String get notif_goal_milestone;

  /// No description provided for @notif_goal_milestone_sub.
  ///
  /// In en, this message translates to:
  /// **'Celebrate when you reach 25%, 50%, 75%, and 100% of a goal'**
  String get notif_goal_milestone_sub;

  /// No description provided for @notif_daily_reminder.
  ///
  /// In en, this message translates to:
  /// **'Log Your Expenses'**
  String get notif_daily_reminder;

  /// No description provided for @notif_section_quiet.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get notif_section_quiet;

  /// No description provided for @notif_quiet_hours.
  ///
  /// In en, this message translates to:
  /// **'Enable Quiet Hours'**
  String get notif_quiet_hours;

  /// No description provided for @notif_quiet_hours_sub.
  ///
  /// In en, this message translates to:
  /// **'Pause all notifications during set hours'**
  String get notif_quiet_hours_sub;

  /// No description provided for @notif_quiet_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get notif_quiet_start;

  /// No description provided for @notif_quiet_end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get notif_quiet_end;

  /// No description provided for @period_3_months.
  ///
  /// In en, this message translates to:
  /// **'3M'**
  String get period_3_months;

  /// No description provided for @period_6_months.
  ///
  /// In en, this message translates to:
  /// **'6M'**
  String get period_6_months;

  /// No description provided for @period_1_year.
  ///
  /// In en, this message translates to:
  /// **'1Y'**
  String get period_1_year;

  /// No description provided for @pdf_report_title.
  ///
  /// In en, this message translates to:
  /// **'Masarify Monthly Report'**
  String get pdf_report_title;

  /// No description provided for @pdf_top_categories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get pdf_top_categories;

  /// No description provided for @pdf_transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get pdf_transactions;

  /// No description provided for @pdf_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get pdf_income;

  /// No description provided for @pdf_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get pdf_expense;

  /// No description provided for @pdf_net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get pdf_net;

  /// No description provided for @pdf_col_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get pdf_col_date;

  /// No description provided for @pdf_col_title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get pdf_col_title;

  /// No description provided for @pdf_col_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get pdf_col_amount;

  /// No description provided for @pdf_col_type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get pdf_col_type;

  /// No description provided for @pdf_col_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get pdf_col_category;

  /// No description provided for @pdf_col_wallet.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get pdf_col_wallet;

  /// No description provided for @pdf_page_label.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get pdf_page_label;

  /// No description provided for @pdf_of_label.
  ///
  /// In en, this message translates to:
  /// **'of'**
  String get pdf_of_label;

  /// No description provided for @pdf_unknown_category.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get pdf_unknown_category;

  /// No description provided for @dashboard_all_accounts.
  ///
  /// In en, this message translates to:
  /// **'All Accounts'**
  String get dashboard_all_accounts;

  /// No description provided for @dashboard_offline_banner.
  ///
  /// In en, this message translates to:
  /// **'Offline — AI features unavailable. Add transactions manually.'**
  String get dashboard_offline_banner;

  /// No description provided for @budget_over_by.
  ///
  /// In en, this message translates to:
  /// **'Over by'**
  String get budget_over_by;

  /// No description provided for @hub_planning_title.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get hub_planning_title;

  /// No description provided for @hub_section_accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get hub_section_accounts;

  /// No description provided for @hub_section_goals_budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets & Goals'**
  String get hub_section_goals_budgets;

  /// No description provided for @hub_headline.
  ///
  /// In en, this message translates to:
  /// **'Curate your capital.'**
  String get hub_headline;

  /// No description provided for @hub_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize your financial future with precision and clarity'**
  String get hub_subtitle;

  /// No description provided for @hub_optimization_label.
  ///
  /// In en, this message translates to:
  /// **'Optimization'**
  String get hub_optimization_label;

  /// No description provided for @hub_saving_insights_title.
  ///
  /// In en, this message translates to:
  /// **'Saving Insights'**
  String get hub_saving_insights_title;

  /// No description provided for @hub_saving_insights_body.
  ///
  /// In en, this message translates to:
  /// **'You could save an additional EGP 120/mo by consolidating your streaming subscriptions.'**
  String get hub_saving_insights_body;

  /// No description provided for @hub_view_details.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get hub_view_details;

  /// No description provided for @nav_planning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get nav_planning;

  /// No description provided for @common_undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get common_undo;

  /// No description provided for @auto_detected_transactions.
  ///
  /// In en, this message translates to:
  /// **'Auto-detected Transactions'**
  String get auto_detected_transactions;

  /// No description provided for @dashboard_chat_tooltip.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get dashboard_chat_tooltip;

  /// No description provided for @chat_action_budget_title.
  ///
  /// In en, this message translates to:
  /// **'Create Budget'**
  String get chat_action_budget_title;

  /// No description provided for @chat_action_recurring_title.
  ///
  /// In en, this message translates to:
  /// **'Create Subscription'**
  String get chat_action_recurring_title;

  /// No description provided for @chat_action_wallet_title.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get chat_action_wallet_title;

  /// No description provided for @chat_action_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Transaction'**
  String get chat_action_delete_title;

  /// No description provided for @chat_action_transfer_title.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get chat_action_transfer_title;

  /// No description provided for @voice_transfer_from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get voice_transfer_from;

  /// No description provided for @voice_transfer_to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get voice_transfer_to;

  /// No description provided for @backup_cloud_title.
  ///
  /// In en, this message translates to:
  /// **'Cloud Backup'**
  String get backup_cloud_title;

  /// No description provided for @backup_sign_in_google.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get backup_sign_in_google;

  /// No description provided for @backup_sign_out.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get backup_sign_out;

  /// No description provided for @backup_last_date.
  ///
  /// In en, this message translates to:
  /// **'Last backup: {date}'**
  String backup_last_date(String date);

  /// No description provided for @backup_now.
  ///
  /// In en, this message translates to:
  /// **'Backup Now'**
  String get backup_now;

  /// No description provided for @backup_restore_drive.
  ///
  /// In en, this message translates to:
  /// **'Restore from Drive'**
  String get backup_restore_drive;

  /// No description provided for @backup_uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading to Drive...'**
  String get backup_uploading;

  /// No description provided for @backup_downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading from Drive...'**
  String get backup_downloading;

  /// No description provided for @backup_no_backups.
  ///
  /// In en, this message translates to:
  /// **'No backups found on Google Drive'**
  String get backup_no_backups;

  /// No description provided for @backup_offline_error.
  ///
  /// In en, this message translates to:
  /// **'Connect to internet to use cloud backup'**
  String get backup_offline_error;

  /// No description provided for @backup_drive_success.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to Google Drive'**
  String get backup_drive_success;

  /// No description provided for @backup_drive_failed.
  ///
  /// In en, this message translates to:
  /// **'Cloud backup failed. Please try again.'**
  String get backup_drive_failed;

  /// No description provided for @backup_sign_in_failed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Check your internet connection and try again.'**
  String get backup_sign_in_failed;

  /// No description provided for @backup_session_expired.
  ///
  /// In en, this message translates to:
  /// **'Your Google session has expired. Please sign in again.'**
  String get backup_session_expired;

  /// No description provided for @backup_key_missing.
  ///
  /// In en, this message translates to:
  /// **'Encryption key not found. This backup cannot be restored on this device.'**
  String get backup_key_missing;

  /// No description provided for @backup_pre_reset_offer.
  ///
  /// In en, this message translates to:
  /// **'Save a backup before deleting?'**
  String get backup_pre_reset_offer;

  /// No description provided for @backup_pre_reset_drive.
  ///
  /// In en, this message translates to:
  /// **'Backup to Google Drive'**
  String get backup_pre_reset_drive;

  /// No description provided for @backup_pre_reset_file.
  ///
  /// In en, this message translates to:
  /// **'Export to file'**
  String get backup_pre_reset_file;

  /// No description provided for @backup_pre_reset_skip.
  ///
  /// In en, this message translates to:
  /// **'No, just delete'**
  String get backup_pre_reset_skip;

  /// No description provided for @backup_failed_continue.
  ///
  /// In en, this message translates to:
  /// **'Backup failed. Delete all data anyway?'**
  String get backup_failed_continue;

  /// No description provided for @voice_select_wallet.
  ///
  /// In en, this message translates to:
  /// **'Select account'**
  String get voice_select_wallet;

  /// No description provided for @voice_confirm_count.
  ///
  /// In en, this message translates to:
  /// **'Review ({count})'**
  String voice_confirm_count(int count);

  /// No description provided for @voice_saved_partial.
  ///
  /// In en, this message translates to:
  /// **'Saved {saved} of {total} transactions'**
  String voice_saved_partial(int saved, int total);

  /// No description provided for @voice_select_all.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get voice_select_all;

  /// No description provided for @voice_deselect_all.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get voice_deselect_all;

  /// No description provided for @voice_selected_count.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} selected'**
  String voice_selected_count(int selected, int total);

  /// No description provided for @backup_encryption_warning.
  ///
  /// In en, this message translates to:
  /// **'Cloud backups are encrypted and tied to this device. If you reinstall the app or switch devices, you will not be able to restore cloud backups. Use local file backup for device transfers.'**
  String get backup_encryption_warning;

  /// No description provided for @chat_action_invalid_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero'**
  String get chat_action_invalid_amount;

  /// No description provided for @chat_action_invalid_target.
  ///
  /// In en, this message translates to:
  /// **'Target amount must be greater than zero'**
  String get chat_action_invalid_target;

  /// No description provided for @chat_action_invalid_budget_limit.
  ///
  /// In en, this message translates to:
  /// **'Budget limit must be greater than zero'**
  String get chat_action_invalid_budget_limit;

  /// No description provided for @chat_action_category_not_found.
  ///
  /// In en, this message translates to:
  /// **'Could not match category \"{name}\". Available: {available}'**
  String chat_action_category_not_found(String name, String available);

  /// No description provided for @chat_action_no_active_wallet.
  ///
  /// In en, this message translates to:
  /// **'No active account available. Please create one first.'**
  String get chat_action_no_active_wallet;

  /// No description provided for @chat_action_budget_exists.
  ///
  /// In en, this message translates to:
  /// **'A budget already exists for \"{category}\" this month'**
  String chat_action_budget_exists(String category);

  /// No description provided for @chat_action_wallet_exists.
  ///
  /// In en, this message translates to:
  /// **'An account with this name already exists'**
  String get chat_action_wallet_exists;

  /// No description provided for @chat_action_tx_not_found.
  ///
  /// In en, this message translates to:
  /// **'No transaction found matching \"{title}\" with that amount'**
  String chat_action_tx_not_found(String title);

  /// No description provided for @chat_action_goal_created.
  ///
  /// In en, this message translates to:
  /// **'Goal \"{name}\" created with a target of {amount}!'**
  String chat_action_goal_created(String name, String amount);

  /// No description provided for @chat_action_tx_recorded.
  ///
  /// In en, this message translates to:
  /// **'Transaction \"{title}\" of {amount} recorded!'**
  String chat_action_tx_recorded(String title, String amount);

  /// No description provided for @chat_action_budget_created.
  ///
  /// In en, this message translates to:
  /// **'Budget of {amount} created for \"{category}\"!'**
  String chat_action_budget_created(String amount, String category);

  /// No description provided for @chat_action_recurring_created.
  ///
  /// In en, this message translates to:
  /// **'Subscription \"{title}\" ({frequency}) of {amount} created!'**
  String chat_action_recurring_created(
      String title, String frequency, String amount);

  /// No description provided for @chat_action_wallet_created.
  ///
  /// In en, this message translates to:
  /// **'Account \"{name}\" created with balance {amount}!'**
  String chat_action_wallet_created(String name, String amount);

  /// No description provided for @chat_action_tx_deleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction \"{title}\" of {amount} deleted!'**
  String chat_action_tx_deleted(String title, String amount);

  /// No description provided for @chat_action_wallet_not_found.
  ///
  /// In en, this message translates to:
  /// **'Could not find account \"{name}\"'**
  String chat_action_wallet_not_found(String name);

  /// No description provided for @chat_action_transfer_same_wallet.
  ///
  /// In en, this message translates to:
  /// **'Source and destination accounts must be different'**
  String get chat_action_transfer_same_wallet;

  /// No description provided for @chat_action_transfer_created.
  ///
  /// In en, this message translates to:
  /// **'Transfer of {amount} from \"{from}\" to \"{to}\" created!'**
  String chat_action_transfer_created(String amount, String from, String to);

  /// No description provided for @chat_action_update_tx_title.
  ///
  /// In en, this message translates to:
  /// **'Update Transaction'**
  String get chat_action_update_tx_title;

  /// No description provided for @chat_action_update_budget_title.
  ///
  /// In en, this message translates to:
  /// **'Update Budget'**
  String get chat_action_update_budget_title;

  /// No description provided for @chat_action_delete_budget_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Budget'**
  String get chat_action_delete_budget_title;

  /// No description provided for @chat_action_delete_goal_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Goal'**
  String get chat_action_delete_goal_title;

  /// No description provided for @chat_action_delete_recurring_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Subscription'**
  String get chat_action_delete_recurring_title;

  /// No description provided for @chat_action_tx_updated.
  ///
  /// In en, this message translates to:
  /// **'Transaction \"{title}\" updated to {amount}!'**
  String chat_action_tx_updated(String title, String amount);

  /// No description provided for @chat_action_budget_updated.
  ///
  /// In en, this message translates to:
  /// **'Budget for \"{category}\" updated to {amount}!'**
  String chat_action_budget_updated(String category, String amount);

  /// No description provided for @chat_action_budget_deleted.
  ///
  /// In en, this message translates to:
  /// **'Budget for \"{category}\" deleted!'**
  String chat_action_budget_deleted(String category);

  /// No description provided for @chat_action_budget_not_found.
  ///
  /// In en, this message translates to:
  /// **'No budget found for \"{category}\" this month'**
  String chat_action_budget_not_found(String category);

  /// No description provided for @chat_action_goal_deleted.
  ///
  /// In en, this message translates to:
  /// **'Goal \"{name}\" deleted!'**
  String chat_action_goal_deleted(String name);

  /// No description provided for @chat_action_goal_not_found.
  ///
  /// In en, this message translates to:
  /// **'No goal found matching \"{name}\"'**
  String chat_action_goal_not_found(String name);

  /// No description provided for @chat_action_recurring_deleted.
  ///
  /// In en, this message translates to:
  /// **'Subscription \"{title}\" deleted!'**
  String chat_action_recurring_deleted(String title);

  /// No description provided for @chat_action_recurring_not_found.
  ///
  /// In en, this message translates to:
  /// **'No subscription found matching \"{title}\"'**
  String chat_action_recurring_not_found(String title);

  /// No description provided for @chat_action_update_wallet_title.
  ///
  /// In en, this message translates to:
  /// **'Update Account'**
  String get chat_action_update_wallet_title;

  /// No description provided for @chat_action_update_goal_title.
  ///
  /// In en, this message translates to:
  /// **'Update Goal'**
  String get chat_action_update_goal_title;

  /// No description provided for @chat_action_update_recurring_title.
  ///
  /// In en, this message translates to:
  /// **'Update Subscription'**
  String get chat_action_update_recurring_title;

  /// No description provided for @chat_action_update_category_title.
  ///
  /// In en, this message translates to:
  /// **'Update Category'**
  String get chat_action_update_category_title;

  /// No description provided for @chat_action_create_category_title.
  ///
  /// In en, this message translates to:
  /// **'Create Category'**
  String get chat_action_create_category_title;

  /// No description provided for @chat_action_delete_wallet_title.
  ///
  /// In en, this message translates to:
  /// **'Archive Account'**
  String get chat_action_delete_wallet_title;

  /// No description provided for @chat_action_wallet_updated.
  ///
  /// In en, this message translates to:
  /// **'Account \"{name}\" updated!'**
  String chat_action_wallet_updated(String name);

  /// No description provided for @chat_action_goal_updated.
  ///
  /// In en, this message translates to:
  /// **'Goal \"{name}\" updated!'**
  String chat_action_goal_updated(String name);

  /// No description provided for @chat_action_recurring_updated.
  ///
  /// In en, this message translates to:
  /// **'Subscription \"{title}\" updated!'**
  String chat_action_recurring_updated(String title);

  /// No description provided for @chat_action_category_updated.
  ///
  /// In en, this message translates to:
  /// **'Category \"{name}\" updated!'**
  String chat_action_category_updated(String name);

  /// No description provided for @chat_action_category_created.
  ///
  /// In en, this message translates to:
  /// **'Category \"{name}\" created!'**
  String chat_action_category_created(String name);

  /// No description provided for @chat_action_wallet_archived.
  ///
  /// In en, this message translates to:
  /// **'Account \"{name}\" archived!'**
  String chat_action_wallet_archived(String name);

  /// No description provided for @chat_action_category_not_updatable.
  ///
  /// In en, this message translates to:
  /// **'Default categories cannot be renamed'**
  String get chat_action_category_not_updatable;

  /// No description provided for @chat_action_category_exists.
  ///
  /// In en, this message translates to:
  /// **'A category named \"{name}\" already exists'**
  String chat_action_category_exists(String name);

  /// No description provided for @chat_action_wallet_has_references.
  ///
  /// In en, this message translates to:
  /// **'Account \"{name}\" has transactions — it will be archived instead of deleted'**
  String chat_action_wallet_has_references(String name);

  /// No description provided for @chat_copy_message.
  ///
  /// In en, this message translates to:
  /// **'Copy message'**
  String get chat_copy_message;

  /// No description provided for @chat_share_message.
  ///
  /// In en, this message translates to:
  /// **'Share message'**
  String get chat_share_message;

  /// No description provided for @chat_copied.
  ///
  /// In en, this message translates to:
  /// **'Message copied!'**
  String get chat_copied;

  /// No description provided for @chat_subscription_suggest.
  ///
  /// In en, this message translates to:
  /// **'💡 \"{title}\" looks like a recurring payment. Add to Subscriptions & Bills?'**
  String chat_subscription_suggest(String title);

  /// No description provided for @onboarding_ready_title.
  ///
  /// In en, this message translates to:
  /// **'You\'re All Set!'**
  String get onboarding_ready_title;

  /// No description provided for @onboarding_ready_body.
  ///
  /// In en, this message translates to:
  /// **'Start tracking your money today.'**
  String get onboarding_ready_body;

  /// No description provided for @onboarding_slide1_title.
  ///
  /// In en, this message translates to:
  /// **'Track in 2 Taps'**
  String get onboarding_slide1_title;

  /// No description provided for @onboarding_slide1_body.
  ///
  /// In en, this message translates to:
  /// **'Tap the button, type the amount, done.\nThe fastest expense logging you\'ll find.'**
  String get onboarding_slide1_body;

  /// No description provided for @onboarding_slide2_title.
  ///
  /// In en, this message translates to:
  /// **'Just Say It'**
  String get onboarding_slide2_title;

  /// No description provided for @onboarding_slide2_body.
  ///
  /// In en, this message translates to:
  /// **'Speak naturally. AI understands\nyour expenses in any language.'**
  String get onboarding_slide2_body;

  /// No description provided for @onboarding_slide3_title.
  ///
  /// In en, this message translates to:
  /// **'Your AI Financial Advisor'**
  String get onboarding_slide3_title;

  /// No description provided for @onboarding_slide3_body.
  ///
  /// In en, this message translates to:
  /// **'Get smart spending insights, budget advice, and financial guidance — powered by AI.'**
  String get onboarding_slide3_body;

  /// No description provided for @onboarding_demo_amount.
  ///
  /// In en, this message translates to:
  /// **'EGP 150.00'**
  String get onboarding_demo_amount;

  /// No description provided for @onboarding_demo_food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get onboarding_demo_food;

  /// No description provided for @onboarding_demo_transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get onboarding_demo_transport;

  /// No description provided for @onboarding_demo_voice_text.
  ///
  /// In en, this message translates to:
  /// **'\"Lunch 150 pounds\"'**
  String get onboarding_demo_voice_text;

  /// No description provided for @onboarding_demo_chat_user.
  ///
  /// In en, this message translates to:
  /// **'How much did I spend on food this week?'**
  String get onboarding_demo_chat_user;

  /// No description provided for @onboarding_demo_chat_ai.
  ///
  /// In en, this message translates to:
  /// **'You spent EGP 450 on food — 15% more than last week.'**
  String get onboarding_demo_chat_ai;

  /// No description provided for @onboarding_default_bank_name.
  ///
  /// In en, this message translates to:
  /// **'My Bank'**
  String get onboarding_default_bank_name;

  /// No description provided for @disclaimer_financial.
  ///
  /// In en, this message translates to:
  /// **'Masarify provides budgeting guidance only, not regulated financial, investment, or tax advice.'**
  String get disclaimer_financial;

  /// No description provided for @common_dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get common_dismiss;

  /// No description provided for @insight_budget_risk_title.
  ///
  /// In en, this message translates to:
  /// **'{category} budget at risk'**
  String insight_budget_risk_title(String category);

  /// No description provided for @insight_budget_risk_body.
  ///
  /// In en, this message translates to:
  /// **'You\'ve spent {percent}% of your budget this month'**
  String insight_budget_risk_body(int percent);

  /// No description provided for @insight_prediction_title.
  ///
  /// In en, this message translates to:
  /// **'{category} may overspend'**
  String insight_prediction_title(String category);

  /// No description provided for @insight_prediction_body.
  ///
  /// In en, this message translates to:
  /// **'At this pace, you\'ll exceed your budget by {amount}'**
  String insight_prediction_body(String amount);

  /// No description provided for @insight_recurring_title.
  ///
  /// In en, this message translates to:
  /// **'Subscription: {title}'**
  String insight_recurring_title(String title);

  /// No description provided for @insight_recurring_body.
  ///
  /// In en, this message translates to:
  /// **'{amount} {frequency} — want to track it?'**
  String insight_recurring_body(String amount, String frequency);

  /// No description provided for @insight_suggest_title.
  ///
  /// In en, this message translates to:
  /// **'Set a budget for {category}?'**
  String insight_suggest_title(String category);

  /// No description provided for @insight_suggest_body.
  ///
  /// In en, this message translates to:
  /// **'You spend avg {amount}/month on this category'**
  String insight_suggest_body(String amount);

  /// No description provided for @transaction_type_cash_withdrawal.
  ///
  /// In en, this message translates to:
  /// **'Cash Withdrawal'**
  String get transaction_type_cash_withdrawal;

  /// No description provided for @transaction_type_cash_withdrawal_short.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get transaction_type_cash_withdrawal_short;

  /// No description provided for @transaction_type_cash_deposit.
  ///
  /// In en, this message translates to:
  /// **'Cash Deposit'**
  String get transaction_type_cash_deposit;

  /// No description provided for @transaction_type_cash_deposit_short.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get transaction_type_cash_deposit_short;

  /// No description provided for @voice_edit_title_hint.
  ///
  /// In en, this message translates to:
  /// **'Refine title...'**
  String get voice_edit_title_hint;

  /// No description provided for @voice_create_wallet_instead.
  ///
  /// In en, this message translates to:
  /// **'Create \'\'{name}\'\' instead?'**
  String voice_create_wallet_instead(String name);

  /// No description provided for @home_filter_all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get home_filter_all;

  /// No description provided for @home_filter_expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get home_filter_expenses;

  /// No description provided for @home_filter_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get home_filter_income;

  /// No description provided for @home_filter_transfers.
  ///
  /// In en, this message translates to:
  /// **'Transfers'**
  String get home_filter_transfers;

  /// No description provided for @home_sort_date_newest.
  ///
  /// In en, this message translates to:
  /// **'Newest first'**
  String get home_sort_date_newest;

  /// No description provided for @home_sort_date_oldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get home_sort_date_oldest;

  /// No description provided for @home_sort_amount_high.
  ///
  /// In en, this message translates to:
  /// **'Highest amount'**
  String get home_sort_amount_high;

  /// No description provided for @home_sort_amount_low.
  ///
  /// In en, this message translates to:
  /// **'Lowest amount'**
  String get home_sort_amount_low;

  /// No description provided for @home_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search transactions...'**
  String get home_search_hint;

  /// No description provided for @home_search_results.
  ///
  /// In en, this message translates to:
  /// **'{count} results'**
  String home_search_results(int count);

  /// No description provided for @home_net_label.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get home_net_label;

  /// No description provided for @home_net_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Income minus expenses this month (transfers excluded)'**
  String get home_net_tooltip;

  /// No description provided for @home_sort_title.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get home_sort_title;

  /// No description provided for @home_no_matching_transactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions match your filters'**
  String get home_no_matching_transactions;

  /// No description provided for @home_clear_filters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get home_clear_filters;

  /// No description provided for @transaction_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction?'**
  String get transaction_delete_confirm_title;

  /// No description provided for @transaction_delete_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get transaction_delete_confirm_body;

  /// No description provided for @transfer_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete transfer?'**
  String get transfer_delete_confirm_title;

  /// No description provided for @transfer_delete_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'This will delete both legs of the transfer.'**
  String get transfer_delete_confirm_body;

  /// No description provided for @transfer_cannot_edit.
  ///
  /// In en, this message translates to:
  /// **'Transfers cannot be edited from here'**
  String get transfer_cannot_edit;

  /// No description provided for @voice_confirm_select_category.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get voice_confirm_select_category;

  /// No description provided for @voice_confirm_add_notes.
  ///
  /// In en, this message translates to:
  /// **'Add notes...'**
  String get voice_confirm_add_notes;

  /// No description provided for @voice_confirm_subscription_suggest.
  ///
  /// In en, this message translates to:
  /// **'Add to Subscriptions & Bills?'**
  String get voice_confirm_subscription_suggest;

  /// No description provided for @voice_include.
  ///
  /// In en, this message translates to:
  /// **'Include'**
  String get voice_include;

  /// No description provided for @voice_confirm_subtitle.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM TRANSACTIONS'**
  String get voice_confirm_subtitle;

  /// No description provided for @voice_confirm_headline.
  ///
  /// In en, this message translates to:
  /// **'Freshly Minted'**
  String get voice_confirm_headline;

  /// No description provided for @voice_discard_all.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get voice_discard_all;

  /// No description provided for @voice_discard_confirm.
  ///
  /// In en, this message translates to:
  /// **'Discard all transactions? This cannot be undone.'**
  String get voice_discard_confirm;

  /// No description provided for @voice_discard_confirm_action.
  ///
  /// In en, this message translates to:
  /// **'Discard All'**
  String get voice_discard_confirm_action;

  /// No description provided for @voice_submit_all.
  ///
  /// In en, this message translates to:
  /// **'Submit All'**
  String get voice_submit_all;

  /// No description provided for @voice_save_draft.
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get voice_save_draft;

  /// No description provided for @insight_upcoming_bills_title.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Bills'**
  String get insight_upcoming_bills_title;

  /// No description provided for @insight_upcoming_bills_body.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bill due this week} other{{count} bills due this week}}'**
  String insight_upcoming_bills_body(int count);

  /// No description provided for @insight_budget_savings_title.
  ///
  /// In en, this message translates to:
  /// **'Budget Savings'**
  String get insight_budget_savings_title;

  /// No description provided for @insight_budget_savings_body.
  ///
  /// In en, this message translates to:
  /// **'Saved {amount} on {category}'**
  String insight_budget_savings_body(String amount, String category);

  /// No description provided for @trial_started_message.
  ///
  /// In en, this message translates to:
  /// **'Your 7-day Pro trial has started!'**
  String get trial_started_message;

  /// No description provided for @wallet_archive_title.
  ///
  /// In en, this message translates to:
  /// **'Archive Account'**
  String get wallet_archive_title;

  /// No description provided for @wallet_archive_info.
  ///
  /// In en, this message translates to:
  /// **'Archived accounts are hidden from your balance, transactions, and analytics.'**
  String get wallet_archive_info;

  /// No description provided for @wallet_archive_action.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get wallet_archive_action;

  /// No description provided for @wallet_archive_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to archive {name}?'**
  String wallet_archive_confirm(String name);

  /// No description provided for @wallet_unarchive_action.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get wallet_unarchive_action;

  /// No description provided for @wallet_unarchive_confirm.
  ///
  /// In en, this message translates to:
  /// **'Restore {name} to your active accounts?'**
  String wallet_unarchive_confirm(String name);

  /// No description provided for @wallet_cannot_archive_default.
  ///
  /// In en, this message translates to:
  /// **'The default account cannot be archived.'**
  String get wallet_cannot_archive_default;

  /// No description provided for @wallet_set_default_title.
  ///
  /// In en, this message translates to:
  /// **'Set as Default'**
  String get wallet_set_default_title;

  /// No description provided for @wallet_set_default_confirm.
  ///
  /// In en, this message translates to:
  /// **'Make {name} your default account?'**
  String wallet_set_default_confirm(String name);

  /// No description provided for @wallet_set_default_success.
  ///
  /// In en, this message translates to:
  /// **'{name} is now your default account.'**
  String wallet_set_default_success(String name);

  /// No description provided for @wallet_manage_title.
  ///
  /// In en, this message translates to:
  /// **'Manage Accounts'**
  String get wallet_manage_title;

  /// No description provided for @wallet_archived_section.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get wallet_archived_section;

  /// No description provided for @wallet_starting_balance.
  ///
  /// In en, this message translates to:
  /// **'Starting Balance'**
  String get wallet_starting_balance;

  /// No description provided for @wallet_starting_balance_hint.
  ///
  /// In en, this message translates to:
  /// **'0'**
  String get wallet_starting_balance_hint;

  /// No description provided for @common_continue_label.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get common_continue_label;

  /// No description provided for @common_transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get common_transfer;

  /// No description provided for @category_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search categories...'**
  String get category_search_hint;

  /// No description provided for @settings_pin_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter 4-digit PIN'**
  String get settings_pin_hint;

  /// No description provided for @settings_daily_recap.
  ///
  /// In en, this message translates to:
  /// **'Daily Spending Recap'**
  String get settings_daily_recap;

  /// No description provided for @settings_daily_recap_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Get a daily notification to review your spending'**
  String get settings_daily_recap_subtitle;

  /// No description provided for @settings_recap_time.
  ///
  /// In en, this message translates to:
  /// **'Recap Time'**
  String get settings_recap_time;

  /// No description provided for @recap_notification_title.
  ///
  /// In en, this message translates to:
  /// **'How was your spending today?'**
  String get recap_notification_title;

  /// No description provided for @recap_notification_body.
  ///
  /// In en, this message translates to:
  /// **'Tap to tell me — I\'ll log it for you'**
  String get recap_notification_body;

  /// No description provided for @notif_bill_due_title.
  ///
  /// In en, this message translates to:
  /// **'{title} is due'**
  String notif_bill_due_title(String title);

  /// No description provided for @notif_bill_due_body.
  ///
  /// In en, this message translates to:
  /// **'{amount} — tap to mark as paid'**
  String notif_bill_due_body(String amount);

  /// No description provided for @notif_budget_warning_title.
  ///
  /// In en, this message translates to:
  /// **'{category} budget at {percent}%'**
  String notif_budget_warning_title(String category, int percent);

  /// No description provided for @notif_budget_warning_body.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {limit} spent'**
  String notif_budget_warning_body(String spent, String limit);

  /// No description provided for @notif_budget_exceeded_title.
  ///
  /// In en, this message translates to:
  /// **'{category} budget exceeded'**
  String notif_budget_exceeded_title(String category);

  /// No description provided for @notif_budget_exceeded_body.
  ///
  /// In en, this message translates to:
  /// **'{spent} spent — {limit} limit'**
  String notif_budget_exceeded_body(String spent, String limit);

  /// No description provided for @notif_goal_milestone_title.
  ///
  /// In en, this message translates to:
  /// **'{name} — {percent}% reached!'**
  String notif_goal_milestone_title(String name, int percent);

  /// No description provided for @notif_goal_milestone_body.
  ///
  /// In en, this message translates to:
  /// **'{current} of {target} saved'**
  String notif_goal_milestone_body(String current, String target);

  /// No description provided for @onboarding_starting_balance_title.
  ///
  /// In en, this message translates to:
  /// **'Starting Balance'**
  String get onboarding_starting_balance_title;

  /// No description provided for @onboarding_starting_balance_body.
  ///
  /// In en, this message translates to:
  /// **'Set your current account balance to start tracking accurately.'**
  String get onboarding_starting_balance_body;

  /// No description provided for @onboarding_starting_balance_set.
  ///
  /// In en, this message translates to:
  /// **'Set Balance'**
  String get onboarding_starting_balance_set;

  /// No description provided for @onboarding_google_title.
  ///
  /// In en, this message translates to:
  /// **'Protect Your Data'**
  String get onboarding_google_title;

  /// No description provided for @onboarding_google_body.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to automatically back up your finances to Google Drive.\nYour backups are encrypted — only you can access them.'**
  String get onboarding_google_body;

  /// No description provided for @onboarding_google_sign_in.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get onboarding_google_sign_in;

  /// No description provided for @onboarding_google_skip.
  ///
  /// In en, this message translates to:
  /// **'I\'ll do this later'**
  String get onboarding_google_skip;

  /// No description provided for @onboarding_google_success.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String onboarding_google_success(String email);

  /// No description provided for @transfer_detail_title.
  ///
  /// In en, this message translates to:
  /// **'Transfer Details'**
  String get transfer_detail_title;

  /// No description provided for @transfer_fee_label.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get transfer_fee_label;

  /// No description provided for @transfer_not_found.
  ///
  /// In en, this message translates to:
  /// **'Transfer not found'**
  String get transfer_not_found;

  /// No description provided for @transfer_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Transfer'**
  String get transfer_delete_title;

  /// No description provided for @transfer_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'This will delete both legs of the transfer. Continue?'**
  String get transfer_delete_confirm;

  /// No description provided for @transfer_deleted_message.
  ///
  /// In en, this message translates to:
  /// **'Transfer deleted'**
  String get transfer_deleted_message;

  /// No description provided for @budget_saved_last_month.
  ///
  /// In en, this message translates to:
  /// **'Saved {amount} last month'**
  String budget_saved_last_month(String amount);

  /// No description provided for @notif_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Notification permission denied. Enable it in Settings to receive alerts.'**
  String get notif_permission_denied;

  /// No description provided for @notif_permission_banner.
  ///
  /// In en, this message translates to:
  /// **'Notifications are disabled. Tap to grant permission so alerts can reach you.'**
  String get notif_permission_banner;

  /// No description provided for @notif_permission_grant.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get notif_permission_grant;

  /// No description provided for @hint_fab.
  ///
  /// In en, this message translates to:
  /// **'Tap + to quickly add transactions — Voice or Manual'**
  String get hint_fab;

  /// No description provided for @hint_swipe_right.
  ///
  /// In en, this message translates to:
  /// **'Swipe right to approve'**
  String get hint_swipe_right;

  /// No description provided for @hint_swipe_left.
  ///
  /// In en, this message translates to:
  /// **'Swipe left to skip'**
  String get hint_swipe_left;

  /// No description provided for @action_card_arabic_name.
  ///
  /// In en, this message translates to:
  /// **'→ Arabic Name'**
  String get action_card_arabic_name;

  /// No description provided for @home_due_soon_title.
  ///
  /// In en, this message translates to:
  /// **'Due Soon'**
  String get home_due_soon_title;

  /// No description provided for @home_due_soon_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get home_due_soon_today;

  /// No description provided for @home_due_soon_tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get home_due_soon_tomorrow;

  /// No description provided for @home_due_soon_in_days.
  ///
  /// In en, this message translates to:
  /// **'In {count} days'**
  String home_due_soon_in_days(int count);

  /// No description provided for @home_due_soon_more.
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String home_due_soon_more(int count);

  /// No description provided for @dashboard_account_selector.
  ///
  /// In en, this message translates to:
  /// **'Select account: {name}'**
  String dashboard_account_selector(String name);

  /// No description provided for @voice_ai_thinking_messages.
  ///
  /// In en, this message translates to:
  /// **'Hmmm...big day huh!;Let me get my calculator...;Empty pocket or empty bank account?;Crunching those numbers...;Your wallet just flinched;Math is hard, give me a sec...;One moment, counting zeros...;Decoding your financial choices...;Was that a need or a want?;Hmm, interesting spending pattern...;Running the numbers, please hold...;Processing... unlike your budget'**
  String get voice_ai_thinking_messages;

  /// No description provided for @voice_ai_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get voice_ai_cancel;

  /// No description provided for @reports_net_cash_flow.
  ///
  /// In en, this message translates to:
  /// **'Net Cash Flow'**
  String get reports_net_cash_flow;

  /// No description provided for @reports_vs_last_month_pct.
  ///
  /// In en, this message translates to:
  /// **'{arrow} {pct}% vs last month'**
  String reports_vs_last_month_pct(String arrow, int pct);

  /// No description provided for @reports_this_month.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get reports_this_month;

  /// No description provided for @reports_last_month.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get reports_last_month;

  /// No description provided for @reports_3_months.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get reports_3_months;

  /// No description provided for @reports_6_months.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get reports_6_months;

  /// No description provided for @reports_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom...'**
  String get reports_custom;

  /// No description provided for @reports_all_types.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get reports_all_types;

  /// No description provided for @reports_clear_filters.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get reports_clear_filters;

  /// No description provided for @reports_income_by_category.
  ///
  /// In en, this message translates to:
  /// **'Income by Category'**
  String get reports_income_by_category;

  /// No description provided for @reports_spending_by_category.
  ///
  /// In en, this message translates to:
  /// **'Spending by Category'**
  String get reports_spending_by_category;

  /// No description provided for @reports_category_count.
  ///
  /// In en, this message translates to:
  /// **'{count} categories'**
  String reports_category_count(int count);

  /// No description provided for @reports_budget_label.
  ///
  /// In en, this message translates to:
  /// **'Budget: {amount}'**
  String reports_budget_label(String amount);

  /// No description provided for @reports_insight_savings.
  ///
  /// In en, this message translates to:
  /// **'You saved {rate}% of your income this month!'**
  String reports_insight_savings(int rate);

  /// No description provided for @reports_total_expenses_period.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get reports_total_expenses_period;

  /// No description provided for @reports_total_income_period.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get reports_total_income_period;

  /// No description provided for @reports_vs_previous_pct.
  ///
  /// In en, this message translates to:
  /// **'{arrow} {pct}% vs previous period'**
  String reports_vs_previous_pct(String arrow, String pct);

  /// No description provided for @reports_spending_pace.
  ///
  /// In en, this message translates to:
  /// **'Spending Pace'**
  String get reports_spending_pace;

  /// No description provided for @reports_pace_label.
  ///
  /// In en, this message translates to:
  /// **'Avg {amount}/day'**
  String reports_pace_label(String amount);

  /// No description provided for @reports_daily_activity.
  ///
  /// In en, this message translates to:
  /// **'Daily Activity'**
  String get reports_daily_activity;

  /// No description provided for @reports_weekly_breakdown.
  ///
  /// In en, this message translates to:
  /// **'Weekly Breakdown'**
  String get reports_weekly_breakdown;

  /// No description provided for @reports_week_n.
  ///
  /// In en, this message translates to:
  /// **'Week {n}'**
  String reports_week_n(int n);

  /// No description provided for @reports_current_period.
  ///
  /// In en, this message translates to:
  /// **'Current Period'**
  String get reports_current_period;

  /// No description provided for @reports_previous_period.
  ///
  /// In en, this message translates to:
  /// **'Previous Period'**
  String get reports_previous_period;

  /// No description provided for @reports_lowest_day.
  ///
  /// In en, this message translates to:
  /// **'Lowest Day'**
  String get reports_lowest_day;

  /// No description provided for @reports_transactions_count.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get reports_transactions_count;

  /// No description provided for @reports_net_label.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get reports_net_label;

  /// No description provided for @reports_last_6_months.
  ///
  /// In en, this message translates to:
  /// **'Last 6 Months'**
  String get reports_last_6_months;

  /// No description provided for @reports_date_range.
  ///
  /// In en, this message translates to:
  /// **'{start} - {end}'**
  String reports_date_range(String start, String end);

  /// No description provided for @reports_select_range.
  ///
  /// In en, this message translates to:
  /// **'Select Date Range'**
  String get reports_select_range;

  /// No description provided for @reports_last_7_days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get reports_last_7_days;

  /// No description provided for @reports_last_30_days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get reports_last_30_days;

  /// No description provided for @reports_this_quarter.
  ///
  /// In en, this message translates to:
  /// **'This Quarter'**
  String get reports_this_quarter;

  /// No description provided for @reports_last_quarter.
  ///
  /// In en, this message translates to:
  /// **'Last Quarter'**
  String get reports_last_quarter;

  /// No description provided for @reports_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get reports_apply;

  /// No description provided for @reports_category_top.
  ///
  /// In en, this message translates to:
  /// **'{name} is your #1 category'**
  String reports_category_top(String name);

  /// No description provided for @hint_accounts.
  ///
  /// In en, this message translates to:
  /// **'Tap to switch between accounts'**
  String get hint_accounts;

  /// No description provided for @home_filter_title.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get home_filter_title;

  /// No description provided for @home_filter_date_range.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get home_filter_date_range;

  /// No description provided for @home_filter_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get home_filter_today;

  /// No description provided for @home_filter_this_week.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get home_filter_this_week;

  /// No description provided for @home_filter_this_month.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get home_filter_this_month;

  /// No description provided for @home_filter_last_month.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get home_filter_last_month;

  /// No description provided for @home_filter_custom_range.
  ///
  /// In en, this message translates to:
  /// **'Custom Range...'**
  String get home_filter_custom_range;

  /// No description provided for @home_filter_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get home_filter_category;

  /// No description provided for @home_filter_apply.
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get home_filter_apply;

  /// No description provided for @home_filter_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get home_filter_clear;

  /// No description provided for @semantics_insight_label.
  ///
  /// In en, this message translates to:
  /// **'Insight: {text}'**
  String semantics_insight_label(String text);

  /// No description provided for @semantics_daily_trend_sparkline.
  ///
  /// In en, this message translates to:
  /// **'Daily trend sparkline'**
  String get semantics_daily_trend_sparkline;

  /// No description provided for @semantics_spending_trend_chart.
  ///
  /// In en, this message translates to:
  /// **'Spending trend chart for the last {days} days with previous period comparison'**
  String semantics_spending_trend_chart(int days);

  /// No description provided for @semantics_spending_heatmap.
  ///
  /// In en, this message translates to:
  /// **'Daily spending activity heatmap for the last {count} days. Darker colors indicate higher spending.'**
  String semantics_spending_heatmap(int count);

  /// No description provided for @semantics_spending_velocity_chart.
  ///
  /// In en, this message translates to:
  /// **'Cumulative spending pace chart with month-end projection'**
  String get semantics_spending_velocity_chart;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
