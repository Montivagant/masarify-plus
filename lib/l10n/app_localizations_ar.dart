// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'مصاريفي';

  @override
  String get appTagline => 'سيطر على فلوسك';

  @override
  String get nav_home => 'الرئيسية';

  @override
  String get nav_transactions => 'المعاملات';

  @override
  String get nav_budgets => 'الميزانية';

  @override
  String get nav_analytics => 'التحليلات';

  @override
  String get nav_more => 'المزيد';

  @override
  String get dashboard_title => 'مصاريفي';

  @override
  String get dashboard_net_balance => 'الرصيد الكلي';

  @override
  String get dashboard_income => 'دخل';

  @override
  String get dashboard_expense => 'مصروف';

  @override
  String get dashboard_recent_transactions => 'الأخيرة';

  @override
  String get dashboard_see_all => 'الكل';

  @override
  String get dashboard_quick_add_expense => '+ مصروف';

  @override
  String get dashboard_quick_add_income => '+ دخل';

  @override
  String get dashboard_spending_overview => 'نظرة عامة على الإنفاق';

  @override
  String get dashboard_budget_alerts => 'تنبيهات الميزانية';

  @override
  String get dashboard_manage_budgets => 'إدارة الميزانيات';

  @override
  String get dashboard_welcome_empty => 'أهلاً بك في مصاريفي!';

  @override
  String get dashboard_welcome_empty_sub => 'اضغط + لإضافة أول معاملة';

  @override
  String get transactions_title => 'المعاملات';

  @override
  String get transactions_search_hint => 'ابحث في المعاملات...';

  @override
  String get transactions_filter => 'تصفية';

  @override
  String get transactions_empty_title => 'لا توجد معاملات بعد';

  @override
  String get transactions_empty_sub => 'اضغط + لإضافة أول معاملة';

  @override
  String get transactions_add => 'إضافة معاملة';

  @override
  String get transaction_type_expense => 'مصروف';

  @override
  String get transaction_type_income => 'دخل';

  @override
  String get transaction_type_transfer => 'تحويل';

  @override
  String get transaction_title_label => 'العنوان';

  @override
  String get transaction_title_hint => 'مثال: قهوة، مشتريات...';

  @override
  String get transaction_note => 'ملاحظة';

  @override
  String get transaction_date => 'التاريخ';

  @override
  String get transaction_wallet => 'الحساب';

  @override
  String get transaction_category => 'التصنيف';

  @override
  String get transaction_tags => 'الوسوم';

  @override
  String get transaction_location => 'الموقع';

  @override
  String get transaction_all_categories => 'كل التصنيفات';

  @override
  String get transaction_amount_hint => '٠٫٠٠';

  @override
  String get transaction_save => 'حفظ';

  @override
  String get transaction_saved => 'تم حفظ المعاملة';

  @override
  String get transaction_deleted => 'تم حذف المعاملة';

  @override
  String get transaction_undo => 'تراجع';

  @override
  String get transaction_source_voice => 'صوت';

  @override
  String get transaction_source_sms => 'رسالة';

  @override
  String get transaction_source_notification => 'إشعار';

  @override
  String get transaction_source_import => 'استيراد';

  @override
  String get wallets_title => 'الحسابات';

  @override
  String get wallets_add => 'إضافة حساب';

  @override
  String get wallets_transfer => 'تحويل';

  @override
  String get wallet_type_cash => 'نقدي';

  @override
  String get wallet_type_bank => 'حساب بنكي';

  @override
  String get wallet_type_mobile_wallet => 'حساب إلكتروني';

  @override
  String get wallet_type_credit_card => 'بطاقة ائتمانية';

  @override
  String get wallet_type_savings => 'ادخار';

  @override
  String get wallet_name_hint => 'اسم الحساب';

  @override
  String get wallet_initial_balance => 'الرصيد الابتدائي';

  @override
  String get wallet_delete_warning => 'لا يمكن حذف حساب به معاملات';

  @override
  String get wallet_balance => 'الرصيد';

  @override
  String get categories_title => 'التصنيفات';

  @override
  String get categories_expense => 'مصروفات';

  @override
  String get categories_income => 'دخل';

  @override
  String get category_add => 'إضافة تصنيف';

  @override
  String get category_name_en => 'الاسم (إنجليزي)';

  @override
  String get category_name_ar => 'الاسم (عربي)';

  @override
  String get category_name_label => 'اسم الفئة';

  @override
  String get category_name_hint => 'مثال: قهوة، بقالة';

  @override
  String get category_icon => 'الأيقونة';

  @override
  String get category_color => 'اللون';

  @override
  String get category_type => 'النوع';

  @override
  String get category_delete_default_warning =>
      'لا يمكن حذف التصنيفات الافتراضية';

  @override
  String get budgets_title => 'الميزانيات';

  @override
  String get budgets_empty_title => 'لا توجد ميزانيات';

  @override
  String get budgets_empty_sub => 'حدد حدوداً شهرية للتحكم في الإنفاق';

  @override
  String get budget_set => 'تحديد ميزانية';

  @override
  String get budget_limit => 'الحد الشهري';

  @override
  String get budget_rollover => 'ترحيل المبلغ المتبقي';

  @override
  String get budget_spent => 'المُنفَق';

  @override
  String get budget_remaining => 'المتبقي';

  @override
  String budget_alert_80(String category) {
    return 'ميزانية $category وصلت ٨٠٪';
  }

  @override
  String budget_alert_100(String category) {
    return 'تجاوزت ميزانية $category!';
  }

  @override
  String get goals_title => 'الأهداف';

  @override
  String get goals_empty_title => 'لا توجد أهداف ادخارية';

  @override
  String get goals_empty_sub => 'حدد هدفاً وابدأ الادخار';

  @override
  String get goal_add => 'إنشاء هدف';

  @override
  String get goal_target => 'المبلغ المستهدف';

  @override
  String get goal_deadline => 'تاريخ الهدف (اختياري)';

  @override
  String get goal_keywords => 'كلمات المطابقة التلقائية';

  @override
  String get goal_contribute => 'إضافة مبلغ';

  @override
  String get goal_completed => 'تم تحقيق الهدف! 🎉';

  @override
  String get goal_overdue => 'متأخر';

  @override
  String goal_progress(int percent) {
    return 'تم $percent٪';
  }

  @override
  String get recurring_add => 'إضافة متكرر';

  @override
  String get recurring_edit => 'تعديل التكرار';

  @override
  String get recurring_frequency_daily => 'يومي';

  @override
  String get recurring_frequency_weekly => 'أسبوعي';

  @override
  String get recurring_frequency_monthly => 'شهري';

  @override
  String get recurring_frequency_yearly => 'سنوي';

  @override
  String get recurring_frequency_custom => 'مخصص';

  @override
  String get recurring_next_due => 'الموعد القادم';

  @override
  String get recurring_and_bills_title => 'المتكررة والفواتير';

  @override
  String get recurring_overdue => 'متأخرة';

  @override
  String get recurring_upcoming_bills => 'فواتير قادمة';

  @override
  String get recurring_paid => 'مدفوعة';

  @override
  String get recurring_mark_paid => 'تم الدفع';

  @override
  String get recurring_mark_paid_confirm =>
      'هل تريد تسجيل هذا الدفع؟ سيتم إنشاء معاملة.';

  @override
  String get recurring_bill_paid_success => 'تم تسجيل دفع الفاتورة';

  @override
  String get recurring_due_date_label => 'الاستحقاق';

  @override
  String get recurring_frequency_once => 'مرة واحدة';

  @override
  String get reports_title => 'التقارير';

  @override
  String get reports_overview => 'نظرة عامة';

  @override
  String get reports_categories => 'التصنيفات';

  @override
  String get reports_trends => 'الاتجاهات';

  @override
  String get reports_comparison => 'المقارنة';

  @override
  String get reports_empty_title => 'بيانات غير كافية';

  @override
  String get reports_empty_sub => 'أضف معاملات لترى الإحصائيات';

  @override
  String get calendar_title => 'التقويم';

  @override
  String get calendar_empty_title => 'لا نشاط هذا الشهر';

  @override
  String get chat_title => 'مصاريفي AI';

  @override
  String get chat_input_hint => 'اسأل عن مصاريفك...';

  @override
  String get chat_clear => 'مسح المحادثة';

  @override
  String get chat_clear_confirm => 'حذف كل الرسائل؟';

  @override
  String get chat_offline => 'أنت غير متصل — المحادثة تحتاج إنترنت';

  @override
  String get chat_error_rate_limit => 'طلبات كثيرة، حاول بعد قليل';

  @override
  String get chat_error_unauthorized => 'مشكلة في مفتاح API، تحقق من الإعدادات';

  @override
  String get chat_error_timeout => 'انتهت المهلة، حاول مرة أخرى';

  @override
  String get chat_error_generic => 'حدث خطأ، حاول مرة أخرى';

  @override
  String get chat_action_confirm => 'تأكيد';

  @override
  String get chat_action_cancel => 'إلغاء';

  @override
  String get chat_action_retry => 'إعادة المحاولة';

  @override
  String get chat_action_confirmed => 'تم الإنشاء بنجاح!';

  @override
  String get chat_action_cancelled => 'تم الإلغاء';

  @override
  String get chat_action_failed => 'فشل — حاول مرة أخرى؟';

  @override
  String get chat_action_goal_title => 'إنشاء هدف ادخاري';

  @override
  String get chat_action_tx_title => 'إنشاء معاملة';

  @override
  String get hub_title => 'المزيد';

  @override
  String get hub_section_money => 'المال';

  @override
  String get hub_section_reports => 'التقارير';

  @override
  String get hub_section_planning => 'التخطيط';

  @override
  String get hub_section_ai => 'مساعد ذكي';

  @override
  String get hub_section_app => 'التطبيق';

  @override
  String get hub_wallets => 'الحسابات';

  @override
  String get hub_analytics => 'التحليلات';

  @override
  String get hub_calendar => 'التقويم';

  @override
  String get hub_recurring => 'المعاملات المتكررة';

  @override
  String get hub_settings => 'الإعدادات';

  @override
  String get hub_backup => 'النسخ الاحتياطي والتصدير';

  @override
  String get hub_about => 'عن التطبيق';

  @override
  String get hub_help => 'المساعدة والأسئلة الشائعة';

  @override
  String get hub_active => 'نشط';

  @override
  String get hub_in_progress => 'قيد التنفيذ';

  @override
  String get hub_new_label => 'جديد';

  @override
  String get settings_title => 'الإعدادات';

  @override
  String get settings_general => 'عام';

  @override
  String get settings_security => 'الأمان';

  @override
  String get settings_data => 'البيانات';

  @override
  String get settings_about => 'عن التطبيق';

  @override
  String get settings_language => 'اللغة';

  @override
  String get settings_currency => 'العملة';

  @override
  String get settings_theme => 'المظهر';

  @override
  String get settings_theme_light => 'فاتح';

  @override
  String get settings_theme_dark => 'داكن';

  @override
  String get settings_theme_system => 'النظام';

  @override
  String get settings_first_day_of_week => 'أول يوم في الأسبوع';

  @override
  String get settings_first_day_of_month => 'أول يوم في الشهر';

  @override
  String get settings_pin_setup => 'تعيين رمز PIN';

  @override
  String get settings_pin_change => 'تغيير رمز PIN';

  @override
  String get settings_biometric => 'تسجيل الدخول ببصمة الإصبع';

  @override
  String get settings_auto_lock => 'القفل التلقائي';

  @override
  String get settings_auto_lock_subtitle => 'قفل التطبيق بعد فترة عدم نشاط';

  @override
  String get settings_auto_lock_immediate => 'فوري';

  @override
  String get settings_auto_lock_1_min => 'بعد دقيقة واحدة';

  @override
  String get settings_auto_lock_5_min => 'بعد ٥ دقائق';

  @override
  String get settings_pin_enabled => 'تم تفعيل رمز PIN';

  @override
  String get settings_pin_disabled => 'تم إزالة رمز PIN';

  @override
  String get settings_biometric_enabled => 'تم تفعيل تسجيل الدخول ببصمة الإصبع';

  @override
  String get settings_biometric_disabled =>
      'تم إلغاء تسجيل الدخول ببصمة الإصبع';

  @override
  String get settings_biometric_unavailable =>
      'المصادقة البيومترية غير متوفرة على هذا الجهاز';

  @override
  String get settings_verify_pin_first => 'تحقق من رمز PIN الحالي';

  @override
  String settings_pin_lockout(String duration) {
    return 'محاولات كثيرة. حاول مرة أخرى بعد $duration.';
  }

  @override
  String get settings_clear_data => 'مسح جميع البيانات';

  @override
  String get settings_clear_data_confirm => 'اكتب حذف للتأكيد';

  @override
  String get settings_smart_input => 'الإدخال الذكي';

  @override
  String get settings_voice_input => 'الإدخال الصوتي';

  @override
  String get settings_notification_parser => 'تحليل الإشعارات';

  @override
  String get settings_sms_parser => 'تحليل الرسائل';

  @override
  String get settings_language_changed => 'تم تغيير اللغة';

  @override
  String get backup_title => 'النسخ الاحتياطي والتصدير';

  @override
  String get backup_export_json => 'تصدير نسخة احتياطية (JSON)';

  @override
  String get backup_restore => 'استعادة النسخة الاحتياطية';

  @override
  String get backup_export_csv => 'تصدير كـ CSV';

  @override
  String get backup_export_pdf => 'تصدير تقرير PDF';

  @override
  String get backup_success => 'تم إنشاء النسخة الاحتياطية';

  @override
  String get backup_restore_success => 'تم استعادة البيانات بنجاح';

  @override
  String get backup_error_invalid => 'ملف النسخة الاحتياطية غير صالح';

  @override
  String get backup_error_version => 'هذه النسخة الاحتياطية تتطلب إصداراً أحدث';

  @override
  String get backup_confirm_restore_title => 'استعادة النسخة الاحتياطية؟';

  @override
  String get backup_confirm_restore_body =>
      'سيتم استبدال جميع البيانات الحالية بالنسخة الاحتياطية. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get backup_select_month => 'اختر الشهر';

  @override
  String get backup_exporting => 'جارٍ التصدير...';

  @override
  String get backup_restoring => 'جارٍ الاستعادة...';

  @override
  String get backup_export_json_subtitle =>
      'نسخة احتياطية كاملة لقاعدة البيانات للنقل أو الحفظ';

  @override
  String get backup_restore_subtitle =>
      'استبدال جميع البيانات من ملف نسخة احتياطية';

  @override
  String get backup_export_csv_subtitle => 'معاملات شهرية بتنسيق جدول بيانات';

  @override
  String get backup_export_pdf_subtitle => 'تقرير ملخص مالي شهري';

  @override
  String get auth_pin_setup_title => 'تعيين رمز PIN';

  @override
  String get auth_pin_setup_subtitle =>
      'أنشئ رمز PIN من ٦ أرقام لحماية بياناتك';

  @override
  String get auth_pin_confirm => 'تأكيد رمز PIN';

  @override
  String get auth_pin_mismatch => 'رموز PIN غير متطابقة. حاول مجدداً.';

  @override
  String get auth_pin_entry_title => 'أدخل رمز PIN';

  @override
  String get auth_pin_wrong => 'رمز PIN غير صحيح';

  @override
  String get auth_biometric_prompt => 'تحقق من هويتك لفتح مصاريفي';

  @override
  String get auth_use_pin => 'استخدم رمز PIN';

  @override
  String get onboarding_page1_title => 'سيطر على فلوسك';

  @override
  String get onboarding_page1_subtitle => 'تتبع كل جنيه. امتلك أموالك.';

  @override
  String get onboarding_page1_cta => 'ابدأ الآن';

  @override
  String get onboarding_page2_title => 'ما هو رصيدك الحالي؟';

  @override
  String get onboarding_page2_subtitle =>
      'سننشئ لك حساباً نقدياً. يمكنك تغيير هذا لاحقاً.';

  @override
  String get onboarding_page2_cta => 'ابدأ التتبع';

  @override
  String get onboarding_page2_skip => 'تخطي';

  @override
  String get splash_loading => 'جار التحميل...';

  @override
  String get common_save => 'حفظ';

  @override
  String get common_cancel => 'إلغاء';

  @override
  String get common_delete => 'حذف';

  @override
  String get common_edit => 'تعديل';

  @override
  String get common_close => 'إغلاق';

  @override
  String get common_confirm => 'تأكيد';

  @override
  String get common_retry => 'إعادة المحاولة';

  @override
  String get common_back => 'رجوع';

  @override
  String get common_done => 'تم';

  @override
  String get common_next => 'التالي';

  @override
  String get common_skip => 'تخطي';

  @override
  String get common_error_generic => 'حدث خطأ ما. يرجى المحاولة مجدداً.';

  @override
  String get common_invalid_amount => 'مبلغ غير صالح';

  @override
  String get common_error_db =>
      'خطأ في قاعدة البيانات. يرجى إعادة تشغيل التطبيق.';

  @override
  String get common_empty_list => 'لا يوجد شيء هنا بعد';

  @override
  String get common_loading => 'جار التحميل...';

  @override
  String get common_grant_permission => 'منح الإذن';

  @override
  String get common_maybe_later => 'ربما لاحقاً';

  @override
  String get permission_mic_title => 'الوصول للميكروفون';

  @override
  String get permission_mic_body =>
      'يستخدم مصاريفي الميكروفون لتسجيل الأوامر الصوتية. يتم إرسال الصوت إلى Google AI للتفريغ عند توفر الإنترنت. لا يتم تخزين أي شيء بشكل دائم.';

  @override
  String get permission_location_title => 'الوصول للموقع';

  @override
  String get permission_location_body =>
      'يمكن لمصاريفي إضافة اسم الموقع للمعاملة. هذا اختياري تماماً.';

  @override
  String get location_detect => 'تحديد الموقع';

  @override
  String get location_detecting => 'جاري التحديد…';

  @override
  String get location_hint => 'مثلاً: المعادي، القاهرة';

  @override
  String get location_failed => 'لم نتمكن من تحديد الموقع';

  @override
  String get permission_notification_title => 'الوصول للإشعارات';

  @override
  String get permission_notification_body =>
      'يمكن لمصاريفي قراءة إشعارات البنك لاكتشاف المعاملات تلقائياً. لا يُرسل شيء لأي خادم.';

  @override
  String get error_amount_zero => 'يجب أن يكون المبلغ أكبر من صفر';

  @override
  String get error_category_required => 'يرجى اختيار تصنيف';

  @override
  String get error_wallet_required => 'يرجى اختيار حساب';

  @override
  String get error_name_required => 'الاسم مطلوب';

  @override
  String get error_pin_too_short => 'رمز PIN يجب أن يكون ٦ أرقام';

  @override
  String get voice_tap_to_start => 'اضغط على المايك للبدء';

  @override
  String get voice_listening => 'جار التسجيل...';

  @override
  String get voice_processing => 'جار المعالجة...';

  @override
  String get voice_confirm_title => 'مراجعة المعاملات';

  @override
  String get voice_confirm_all => 'تأكيد الكل';

  @override
  String get voice_remove => 'إزالة';

  @override
  String get voice_unavailable => 'الإدخال الصوتي غير متوفر على هذا الجهاز';

  @override
  String get voice_error_no_service =>
      'الإدخال الصوتي غير متاح. يرجى التحقق من اتصالك بالإنترنت.';

  @override
  String get voice_error_no_locale =>
      'لا توجد حزم لغات للتعرف على الكلام. يرجى تثبيت واحدة من إعدادات الجهاز.';

  @override
  String get voice_error_speech =>
      'خطأ في التعرف على الكلام. يرجى المحاولة مرة أخرى.';

  @override
  String get voice_no_results => 'لم يتم اكتشاف شيء. حاول مرة أخرى.';

  @override
  String get voice_ai_error => 'فشل التحليل الذكي. حاول مرة أخرى.';

  @override
  String get voice_permission_denied => 'إذن الميكروفون مطلوب للإدخال الصوتي';

  @override
  String get voice_retry => 'حاول مرة أخرى';

  @override
  String get voice_ai_parsing => 'جار التحليل بالذكاء الاصطناعي...';

  @override
  String get permission_allow => 'السماح';

  @override
  String get permission_deny => 'رفض';

  @override
  String get sms_review_title => 'معاملات مكتشفة';

  @override
  String get parsed_transactions_title => 'المعاملات المستخرجة';

  @override
  String get sms_review_approve => 'موافقة';

  @override
  String get sms_review_skip => 'تخطي';

  @override
  String get sms_review_edit => 'تعديل';

  @override
  String sms_new_found(int count) {
    return 'تم اكتشاف $count معاملة — اضغط للمراجعة';
  }

  @override
  String get parser_no_pending => 'لا توجد معاملات معلقة للمراجعة';

  @override
  String get parser_approved_msg => 'تم اعتماد المعاملة';

  @override
  String get parser_skipped_msg => 'تم تخطي المعاملة';

  @override
  String get parser_approve_all => 'اعتماد الكل';

  @override
  String get parser_ai_category => 'الفئة المقترحة';

  @override
  String get parser_ai_merchant => 'التاجر';

  @override
  String get parser_ai_note => 'ملاحظة';

  @override
  String get parser_enrich => 'تحسين';

  @override
  String get parser_enrich_all => 'تحسين الكل';

  @override
  String get parser_enriching => 'جاري التحسين…';

  @override
  String goal_link_prompt(String goalName) {
    return 'يبدو أن هذا مرتبط بهدفك \'$goalName\'. هل تريد ربطه؟';
  }

  @override
  String get goal_link_action => 'ربط';

  @override
  String get goal_dismiss => 'تجاهل';

  @override
  String get transfer_from => 'من';

  @override
  String get transfer_to => 'إلى';

  @override
  String get transfer_fee => 'رسوم التحويل (اختياري)';

  @override
  String get language_en => 'English';

  @override
  String get language_ar => 'العربية';

  @override
  String get language_system => 'حسب النظام';

  @override
  String get pro_badge => 'PRO';

  @override
  String get pro_feature_title => 'ميزة PRO';

  @override
  String pro_feature_body(String featureName) {
    return '$featureName متاحة لمشتركي PRO فقط.\nقريباً جداً!';
  }

  @override
  String get pro_upgrade => 'الترقية إلى برو';

  @override
  String get subscription_title => 'اشتراك Pro';

  @override
  String get paywall_title => 'Masarify Pro';

  @override
  String get common_ok => 'حسناً';

  @override
  String get common_error_title => 'حدث خطأ';

  @override
  String get common_all => 'الكل';

  @override
  String get common_save_changes => 'حفظ التعديلات';

  @override
  String get date_today => 'اليوم';

  @override
  String get date_yesterday => 'أمس';

  @override
  String get transaction_edit_title => 'تعديل المعاملة';

  @override
  String get transaction_detail_title => 'تفاصيل المعاملة';

  @override
  String get transaction_not_found => 'المعاملة غير موجودة';

  @override
  String get transaction_delete_title => 'حذف المعاملة';

  @override
  String get transaction_delete_confirm => 'هل أنت متأكد من حذف هذه المعاملة؟';

  @override
  String transaction_deleted_message(String title) {
    return 'تم حذف \"$title\"';
  }

  @override
  String get transaction_source_label => 'المصدر';

  @override
  String get transaction_source_manual => 'يدوي';

  @override
  String get transaction_no_results => 'لا توجد نتائج';

  @override
  String get transaction_try_different => 'جرّب كلمة بحث مختلفة';

  @override
  String get transaction_filter_type_title => 'تصفية حسب النوع';

  @override
  String get transaction_filter_all => 'الكل';

  @override
  String get transaction_filter_expenses => 'المصروفات';

  @override
  String get transaction_filter_income => 'الدخل';

  @override
  String get transaction_filter_expenses_chip => 'مصروفات';

  @override
  String get transaction_filter_income_chip => 'دخل';

  @override
  String get transaction_optional_details => 'تفاصيل إضافية';

  @override
  String get transaction_note_hint => 'أضف ملاحظة اختيارية...';

  @override
  String get transaction_category_picker => 'اختر الفئة';

  @override
  String get transaction_wallet_picker => 'اختر الحساب';

  @override
  String get wallet_detail_title => 'تفاصيل الحساب';

  @override
  String get wallet_not_found => 'الحساب غير موجود';

  @override
  String get wallet_add_title => 'حساب جديد';

  @override
  String get wallet_edit_title => 'تعديل الحساب';

  @override
  String get wallet_delete_title => 'حذف الحساب';

  @override
  String get wallet_delete_confirm => 'هل أنت متأكد من حذف هذا الحساب؟';

  @override
  String get wallet_cannot_delete_title => 'لا يمكن حذف الحساب';

  @override
  String get wallet_name_label => 'اسم الحساب';

  @override
  String get wallet_name_hint_example => 'مثال: الحساب الرئيسي';

  @override
  String get wallet_name_duplicate => 'يوجد حساب بنفس الاسم بالفعل';

  @override
  String get wallet_total_balance => 'إجمالي الرصيد';

  @override
  String get wallet_current_balance => 'الرصيد الحالي';

  @override
  String get wallet_transactions_header => 'معاملات هذا الحساب';

  @override
  String get wallet_no_transactions_sub => 'لم تُسجَّل معاملات لهذا الحساب بعد';

  @override
  String get wallet_cannot_delete_body =>
      'هذا الحساب يحتوي على معاملات.\nاحذف أو انقل المعاملات أولاً قبل حذف الحساب.';

  @override
  String get wallet_type_label => 'نوع الحساب';

  @override
  String get wallet_color_label => 'لون الحساب';

  @override
  String get wallet_add_button => 'إضافة الحساب';

  @override
  String get wallet_type_cash_short => 'نقدي';

  @override
  String get wallet_type_bank_short => 'بنك';

  @override
  String get wallet_type_mobile_wallet_short => 'رقمي';

  @override
  String get wallet_type_credit_card_short => 'ائتمان';

  @override
  String get wallet_type_savings_short => 'توفير';

  @override
  String get wallets_empty_title => 'لا توجد حسابات';

  @override
  String get wallets_empty_sub => 'أضف حسابك الأول لتبدأ تتبع فلوسك';

  @override
  String get wallets_transfer_button => 'تحويل بين الحسابات';

  @override
  String get category_add_title => 'فئة جديدة';

  @override
  String get category_edit_title => 'تعديل الفئة';

  @override
  String get category_delete_title => 'حذف الفئة';

  @override
  String category_delete_confirm(String name) {
    return 'هل أنت متأكد من حذف \"$name\"؟';
  }

  @override
  String get category_default_title => 'فئة افتراضية';

  @override
  String get category_default_chip => 'افتراضي';

  @override
  String get category_name_ar_label => 'اسم الفئة (عربي)';

  @override
  String get category_name_ar_hint => 'مثال: قهوة، نقل، اشتراك';

  @override
  String get category_name_en_label => 'اسم الفئة (إنجليزي)';

  @override
  String get category_group_needs => 'أساسيات';

  @override
  String get category_group_wants => 'رغبات';

  @override
  String get category_group_savings => 'توفير';

  @override
  String get categories_empty_title => 'لا توجد فئات';

  @override
  String get categories_empty_sub => 'أضف فئة لتصنيف معاملاتك';

  @override
  String get budget_total_label => 'الإجمالي';

  @override
  String get budget_spent_label => 'المصروف';

  @override
  String get budget_rollover_title => 'ترحيل الميزانية';

  @override
  String get budgets_empty_sub_long => 'حدد ميزانية لكل فئة لتتحكم في مصاريفك';

  @override
  String get goal_detail_title => 'تفاصيل الهدف';

  @override
  String get goal_not_found => 'الهدف غير موجود';

  @override
  String get goal_add_title => 'هدف ادخاري جديد';

  @override
  String get goal_edit_title => 'تعديل الهدف';

  @override
  String get goal_name_label => 'اسم الهدف';

  @override
  String get goal_name_hint => 'مثال: سفر اليابان، سيارة جديدة';

  @override
  String get goal_detail_add_savings => 'إضافة مدخرات';

  @override
  String get goal_already_funded => 'تم تمويل هذا الهدف بالكامل.';

  @override
  String get goal_detail_no_savings => 'لا توجد مدخرات بعد';

  @override
  String get goal_detail_no_savings_sub => 'أضف أول مبلغ لهذا الهدف';

  @override
  String get goal_saved_label => 'المدخر';

  @override
  String get goal_target_label => 'الهدف';

  @override
  String get goal_remaining_label => 'المتبقي';

  @override
  String get goal_completed_chip => 'مكتمل';

  @override
  String get goal_target_required => 'أدخل مبلغ الهدف';

  @override
  String get goal_delete_title => 'حذف الهدف';

  @override
  String get goal_delete_confirm =>
      'هل أنت متأكد من حذف هذا الهدف وجميع المساهمات؟';

  @override
  String get goal_delete_contribution_confirm =>
      'هل أنت متأكد من حذف هذه المساهمة؟';

  @override
  String get budget_delete_title => 'حذف الميزانية';

  @override
  String get budget_delete_confirm => 'هل أنت متأكد من حذف هذه الميزانية؟';

  @override
  String get goals_empty_sub_long => 'ضع لنفسك هدفاً ادخارياً وابدأ تحقيقه';

  @override
  String get transfer_title => 'تحويل بين الحسابات';

  @override
  String get transfer_amount_label => 'المبلغ';

  @override
  String get transfer_note_label => 'ملاحظة (اختياري)';

  @override
  String get transfer_confirm_button => 'تأكيد التحويل';

  @override
  String get transfer_different_wallets => 'اختر حسابين مختلفين';

  @override
  String get transfer_from_wallet => 'من حساب';

  @override
  String get transfer_to_wallet => 'إلى حساب';

  @override
  String get transfer_select_wallet => 'اختر الحساب';

  @override
  String get transfer_swap => 'تبديل';

  @override
  String get transfer_insufficient_title => 'رصيد غير كافٍ';

  @override
  String get transfer_insufficient_body =>
      'رصيد الحساب المصدر أقل من مبلغ التحويل. هل تريد المتابعة؟';

  @override
  String get transfer_success => 'تم التحويل بنجاح';

  @override
  String get settings_appearance => 'المظهر';

  @override
  String get settings_theme_auto => 'تلقائي';

  @override
  String get settings_data_management => 'إدارة البيانات';

  @override
  String get settings_wallets_label => 'الحسابات';

  @override
  String get settings_wallets_subtitle => 'إدارة حساباتك';

  @override
  String get settings_categories_label => 'الفئات';

  @override
  String get settings_categories_subtitle => 'تخصيص فئات المصروفات والدخل';

  @override
  String get settings_pin_subtitle => 'حماية التطبيق برمز PIN';

  @override
  String get settings_biometric_subtitle => 'المصادقة البيومترية';

  @override
  String get settings_backup_section => 'النسخ الاحتياطي';

  @override
  String get settings_backup_label => 'نسخ احتياطي وتصدير';

  @override
  String get settings_backup_subtitle => 'تصدير بياناتك أو استيرادها';

  @override
  String get settings_danger_zone => 'منطقة الخطر';

  @override
  String get settings_clear_data_label => 'حذف جميع البيانات';

  @override
  String get settings_clear_data_subtitle => 'مسح كل شيء والبدء من جديد';

  @override
  String get settings_clear_data_title => 'حذف جميع البيانات';

  @override
  String get settings_clear_data_warning =>
      'هذا الإجراء لا يمكن التراجع عنه.\nسيتم حذف جميع الحسابات والمعاملات والميزانيات والأهداف.';

  @override
  String get settings_clear_data_permanent => 'حذف نهائي';

  @override
  String get settings_about_section => 'حول التطبيق';

  @override
  String get settings_version => 'الإصدار';

  @override
  String get settings_help_label => 'المساعدة والدعم';

  @override
  String get settings_help_subtitle => 'الأسئلة الشائعة والتواصل';

  @override
  String get settings_first_day_budget_cycle =>
      'أول يوم في الشهر (دورة الميزانية)';

  @override
  String get settings_currency_egp => 'ج.م — جنيه مصري';

  @override
  String get settings_currency_usd => '\$ — دولار أمريكي';

  @override
  String get settings_currency_eur => '€ — يورو';

  @override
  String get settings_currency_sar => 'ر.س — ريال سعودي';

  @override
  String get settings_currency_aed => 'د.إ — درهم إماراتي';

  @override
  String get settings_currency_kwd => 'د.ك — دينار كويتي';

  @override
  String get settings_day_saturday => 'السبت';

  @override
  String get settings_day_sunday => 'الأحد';

  @override
  String get settings_day_monday => 'الاثنين';

  @override
  String get settings_pin_lock_label => 'قفل بالرمز السري';

  @override
  String get settings_budget_cycle_subtitle =>
      'يحدد بداية دورة الميزانية الشهرية';

  @override
  String get common_coming_soon => 'قريباً';

  @override
  String get dashboard_income_label => 'الإيرادات';

  @override
  String get dashboard_expense_label => 'المصروفات';

  @override
  String get dashboard_no_transactions => 'لا توجد معاملات بعد';

  @override
  String get dashboard_start_tracking => 'ابدأ بتسجيل أول معاملة لتتبع فلوسك';

  @override
  String get dashboard_failed_balance => 'تعذر تحميل الرصيد';

  @override
  String get dashboard_failed_transactions => 'تعذر تحميل المعاملات';

  @override
  String get dashboard_failed_spending => 'تعذر تحميل نظرة المصروفات';

  @override
  String get dashboard_failed_budgets => 'تعذر تحميل تنبيهات الميزانية';

  @override
  String get dashboard_voice => 'صوت';

  @override
  String get balance_income_label => 'الإيرادات';

  @override
  String get balance_expense_label => 'المصروفات';

  @override
  String get onboarding_feature_wallets => 'حسابات متعددة';

  @override
  String get onboarding_feature_budgets => 'ميزانيات ذكية';

  @override
  String get onboarding_feature_goals => 'أهداف ادخار';

  @override
  String get onboarding_feature_reports => 'تقارير مفصّلة';

  @override
  String get onboarding_language_prompt => 'اختر لغة التطبيق';

  @override
  String get onboarding_page1_body =>
      'تتبّع كل جنيه، خطّط لمستقبلك،\nوعيش من غير قلق على الفلوس.';

  @override
  String get onboarding_page2_body =>
      'أدخل رصيدك الحالي لنبدأ الحسابات صح.\n(اختياري — ممكن تغيّره بعدين)';

  @override
  String get onboarding_saving => 'جاري الحفظ...';

  @override
  String get onboarding_default_wallet_name => 'كاش';

  @override
  String get onboarding_account_name_label => 'اسم الحساب';

  @override
  String get onboarding_account_name_hint => 'مثلاً: كاش، CIB، فودافون كاش';

  @override
  String get onboarding_account_type_label => 'نوع الحساب';

  @override
  String get goal_active_section => 'جارية';

  @override
  String get goal_completed_section => 'مكتملة';

  @override
  String goal_days_remaining(int daysLeft) {
    return 'متبقي $daysLeft يوم';
  }

  @override
  String get goal_pick_date => 'اختر تاريخاً';

  @override
  String get goal_remove_date => 'إزالة التاريخ';

  @override
  String get goal_keyword_hint => 'مثال: سفر، رحلة، طيران';

  @override
  String get month_1 => 'يناير';

  @override
  String get month_2 => 'فبراير';

  @override
  String get month_3 => 'مارس';

  @override
  String get month_4 => 'أبريل';

  @override
  String get month_5 => 'مايو';

  @override
  String get month_6 => 'يونيو';

  @override
  String get month_7 => 'يوليو';

  @override
  String get month_8 => 'أغسطس';

  @override
  String get month_9 => 'سبتمبر';

  @override
  String get month_10 => 'أكتوبر';

  @override
  String get month_11 => 'نوفمبر';

  @override
  String get month_12 => 'ديسمبر';

  @override
  String get month_previous => 'الشهر السابق';

  @override
  String get month_next => 'الشهر التالي';

  @override
  String get dashboard_other_category => 'أخرى';

  @override
  String get dashboard_total => 'إجمالي';

  @override
  String get recurring_active => 'المتكررة النشطة';

  @override
  String get recurring_paused => 'متوقفة';

  @override
  String get recurring_pause => 'إيقاف';

  @override
  String get recurring_resume => 'تفعيل';

  @override
  String get recurring_frequency_label => 'التكرار';

  @override
  String get recurring_start_date => 'تاريخ البدء';

  @override
  String get recurring_end_date => 'تاريخ الانتهاء (اختياري)';

  @override
  String get recurring_end_date_required => 'تاريخ الانتهاء';

  @override
  String get recurring_empty_title => 'لا توجد قواعد متكررة';

  @override
  String get recurring_empty_sub => 'أضف معاملاتك المتكررة لتوفير الوقت';

  @override
  String get recurring_delete_title => 'حذف المتكرر';

  @override
  String get recurring_delete_confirm =>
      'هل أنت متأكد من حذف هذه المعاملة المتكررة؟';

  @override
  String get recurring_confirm_activate =>
      'تفعيل هذه المعاملة المتكررة؟ سيتم إنشاء معاملات تلقائياً.';

  @override
  String get recurring_confirm_pause =>
      'إيقاف هذه المعاملة المتكررة؟ لن يتم إنشاء معاملات جديدة حتى إعادة التفعيل.';

  @override
  String get recurring_title_label => 'العنوان';

  @override
  String get recurring_title_hint => 'مثال: إيجار، إنترنت، راتب';

  @override
  String get recurring_type_label => 'نوع المعاملة';

  @override
  String get recurring_saved => 'تم حفظ المعاملة المتكررة';

  @override
  String get calendar_no_transactions_day => 'لا توجد معاملات في هذا اليوم';

  @override
  String get calendar_day_income => 'دخل';

  @override
  String get calendar_day_expense => 'مصروفات';

  @override
  String get reports_period_7d => '٧ أيام';

  @override
  String get reports_period_30d => '٣٠ يوم';

  @override
  String get reports_period_90d => '٩٠ يوم';

  @override
  String get reports_income_vs_expense => 'الدخل مقابل المصروف';

  @override
  String get reports_top_categories => 'أعلى التصنيفات';

  @override
  String get reports_this_month => 'هذا الشهر';

  @override
  String get reports_last_month => 'الشهر الماضي';

  @override
  String get reports_vs_last_month => 'مقارنة بالشهر الماضي';

  @override
  String get reports_no_data => 'لا توجد معاملات في هذه الفترة';

  @override
  String get reports_total_income => 'إجمالي الدخل';

  @override
  String get reports_total_expense => 'إجمالي المصروف';

  @override
  String get reports_net => 'الصافي';

  @override
  String get reports_daily_average => 'المتوسط اليومي';

  @override
  String reports_category_rank(int rank) {
    return '#$rank';
  }

  @override
  String get balance_show => 'إظهار';

  @override
  String get balance_hide => 'إخفاء';

  @override
  String get goal_status_completed => 'مكتمل';

  @override
  String get goal_status_overdue => 'فات الموعد';

  @override
  String get goal_status_last_day => 'اليوم آخر يوم';

  @override
  String get goal_status_one_day => 'يوم واحد متبقي';

  @override
  String goal_status_days_remaining(int days) {
    return '$days يوم متبقي';
  }

  @override
  String goal_status_months_remaining(int months) {
    return '$months شهر متبقي';
  }

  @override
  String get budget_exceeded => 'تجاوزت!';

  @override
  String get common_search => 'بحث';

  @override
  String get common_search_hint => 'بحث...';

  @override
  String get common_clear => 'مسح';

  @override
  String get common_date => 'التاريخ';

  @override
  String get common_amount => 'المبلغ';

  @override
  String get common_delete_action => 'حذف';

  @override
  String get settings_delete_confirm_word => 'حذف';

  @override
  String get recurring_amount_label => 'المبلغ';

  @override
  String get budget_edit_title => 'تعديل الميزانية';

  @override
  String get goal_contribution_note => 'ملاحظة (اختياري)';

  @override
  String get goal_icon_label => 'الأيقونة';

  @override
  String get goal_color_label => 'اللون';

  @override
  String get quick_add_title => 'إضافة سريعة';

  @override
  String get quick_add_voice => 'إدخال صوتي';

  @override
  String get settings_notification_parser_subtitle =>
      'اكتشاف المعاملات تلقائياً من إشعارات البنك';

  @override
  String get settings_sms_parser_subtitle =>
      'فحص الرسائل النصية لاكتشاف معاملات البنك';

  @override
  String get permission_sms_title => 'صلاحية الرسائل';

  @override
  String get permission_sms_body =>
      'يمكن لمصاريفي فحص رسائلك النصية لاكتشاف معاملات البنك. يتم تحليل الرسائل محلياً على جهازك. يمكنك اختيارياً الضغط على \'إثراء\' لأي معاملة مكتشفة لاستخدام الذكاء الاصطناعي لتحديد الفئة والتاجر.';

  @override
  String get settings_ai_model => 'نموذج الذكاء الاصطناعي';

  @override
  String get settings_ai_model_subtitle =>
      'اختر النموذج الذي يعالج الإدخال الصوتي';

  @override
  String get settings_ai_model_auto => 'تلقائي (موصى به)';

  @override
  String get settings_ai_model_gemma_27b => 'Gemma 3 27B';

  @override
  String get settings_ai_model_gemini_flash => 'Gemini 2.0 Flash';

  @override
  String get settings_ai_model_qwen3_4b => 'Qwen3 4B';

  @override
  String get fab_expense => 'مصروف';

  @override
  String get fab_income => 'دخل';

  @override
  String get fab_voice => 'صوت';

  @override
  String get wallet_archive_balance_warning =>
      'هذا الحساب لا يزال يحتوي على رصيد. سيتم استبعاد الرصيد من إجماليك بعد الأرشفة.';

  @override
  String get notif_prefs_title => 'إعدادات الإشعارات';

  @override
  String get notif_section_budget => 'تنبيهات الميزانية';

  @override
  String get notif_budget_warning => 'تحذير الميزانية (٨٠٪)';

  @override
  String get notif_budget_warning_sub =>
      'إشعار عند وصول الإنفاق إلى ٨٠٪ من الميزانية';

  @override
  String get notif_budget_exceeded => 'تجاوز الميزانية (١٠٠٪)';

  @override
  String get notif_budget_exceeded_sub => 'إشعار عند استنفاد الميزانية بالكامل';

  @override
  String get notif_section_bills => 'الفواتير والمتكررات';

  @override
  String get notif_bill_reminder => 'تذكير الفواتير';

  @override
  String get notif_bill_reminder_sub =>
      'تذكير بالفواتير القادمة قبل موعد الاستحقاق';

  @override
  String get notif_recurring_reminder => 'المعاملات المتكررة';

  @override
  String get notif_recurring_reminder_sub =>
      'إشعار عند استحقاق المعاملات المتكررة';

  @override
  String get notif_section_goals => 'الأهداف';

  @override
  String get notif_goal_milestone => 'إنجازات الأهداف';

  @override
  String get notif_goal_milestone_sub =>
      'احتفل عند الوصول إلى ٢٥٪ و٥٠٪ و٧٥٪ و١٠٠٪ من الهدف';

  @override
  String get notif_section_daily => 'التذكير اليومي';

  @override
  String get notif_daily_reminder => 'سجّل مصاريفك';

  @override
  String get notif_daily_reminder_sub => 'تذكير لطيف لتسجيل معاملات اليوم';

  @override
  String get notif_daily_reminder_time => 'وقت التذكير';

  @override
  String get notif_section_quiet => 'ساعات الهدوء';

  @override
  String get notif_quiet_hours => 'تفعيل ساعات الهدوء';

  @override
  String get notif_quiet_hours_sub => 'إيقاف جميع الإشعارات خلال ساعات محددة';

  @override
  String get notif_quiet_start => 'البداية';

  @override
  String get notif_quiet_end => 'النهاية';

  @override
  String get period_3_months => '3 أشهر';

  @override
  String get period_6_months => '6 أشهر';

  @override
  String get period_1_year => 'سنة';

  @override
  String get pdf_report_title => 'تقرير مصاريفي الشهري';

  @override
  String get pdf_top_categories => 'أعلى الفئات';

  @override
  String get pdf_transactions => 'المعاملات';

  @override
  String get pdf_income => 'الدخل';

  @override
  String get pdf_expense => 'المصروفات';

  @override
  String get pdf_net => 'الصافي';

  @override
  String get pdf_col_date => 'التاريخ';

  @override
  String get pdf_col_title => 'العنوان';

  @override
  String get pdf_col_amount => 'المبلغ';

  @override
  String get pdf_col_type => 'النوع';

  @override
  String get pdf_col_category => 'الفئة';

  @override
  String get pdf_col_wallet => 'الحساب';

  @override
  String get dashboard_all_accounts => 'جميع الحسابات';

  @override
  String get voice_offline_message =>
      'التحليل الذكي يحتاج إنترنت. يمكنك إضافة المعاملة يدوياً.';

  @override
  String get dashboard_offline_banner =>
      'غير متصل — ميزات الذكاء غير متاحة. أضف المعاملات يدوياً.';

  @override
  String get budget_over_by => 'تجاوز بـ';

  @override
  String get dashboard_month_summary => 'هذا الشهر';

  @override
  String get dashboard_month_net => 'الصافي';

  @override
  String get dashboard_vs_last_month => 'مقارنة بالشهر الماضي';

  @override
  String get dashboard_insights => 'نظرة سريعة';

  @override
  String dashboard_insight_spending_up(int percent) {
    return '+$percent% وتيرة إنفاق';
  }

  @override
  String dashboard_insight_spending_down(int percent) {
    return '$percent% إنفاق أقل';
  }

  @override
  String get dashboard_insight_parsed_transactions => 'المعاملات المحللة';

  @override
  String insight_recurring_detected(String title) {
    return 'شهري: $title — أضف كمتكرر؟';
  }

  @override
  String insight_weekly_detected(String title) {
    return 'أسبوعي: $title — أضف كمتكرر؟';
  }

  @override
  String insight_over_budget_prediction(String category, String amount) {
    return '$category قد يتجاوز الميزانية بـ $amount';
  }

  @override
  String insight_budget_suggestion(String amount, String category) {
    return 'حدد ميزانية $amount لـ $category؟';
  }

  @override
  String get hub_planning_title => 'التخطيط';

  @override
  String get hub_section_accounts => 'الحسابات';

  @override
  String get hub_section_goals_budgets => 'الميزانيات والأهداف';

  @override
  String get hub_section_recurring => 'المتكرر والفواتير';

  @override
  String get nav_planning => 'التخطيط';

  @override
  String get dashboard_quick_add => 'إضافة سريعة';

  @override
  String quick_add_saved(String title) {
    return 'تمت إضافة $title';
  }

  @override
  String get common_undo => 'تراجع';
}
