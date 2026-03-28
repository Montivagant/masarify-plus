/// Egyptian Arabic lexicon for voice transaction parsing.
///
/// This is the SINGLE SOURCE OF TRUTH for all voice-related keyword maps.
/// [VoiceTransactionParser] and [ArabicNumberParser] reference this class.
///
/// All amount values are in **piastres** (Rule #1: 100 EGP = 10000 piastres).
abstract final class VoiceDictionary {
  /// Fractional amounts in **piastres**.
  ///
  /// "نص جنيه" = half pound = 50 piastres.
  /// "ربع جنيه" = quarter pound = 25 piastres.
  static const Map<String, int> fractions = {
    'نص': 50,
    'ربع': 25,
  };

  /// Expense trigger keywords (Egyptian Arabic + English).
  static const List<String> expenseTriggers = [
    'صرفت',
    'دفعت',
    'اشتريت',
    'شريت',
    'كليت',
    'ركبت',
    'عملت',
    'اديت',
    'دفعتلهم',
    'بعتلهم',
    'جبت',
    'حسبت',
    'مصروف',
    'فاتورة',
    'ايجار',
    'اشتراك',
    'اكلت',
    'spent',
    'paid',
    'bought',
    'ordered',
  ];

  /// Income trigger keywords (Egyptian Arabic + English).
  static const List<String> incomeTriggers = [
    'اتودت',
    'استلمت',
    'اتقبضت',
    'بعت',
    'اخدت',
    'قبضت',
    'اتحولتلي',
    'ودوني',
    'اتقاضيت',
    'راتب',
    'مرتب',
    'دخل',
    'كسبت',
    'ربحت',
    'حولولي',
    'received',
    'got paid',
    'salary',
  ];

  /// Cash withdrawal trigger keywords (Egyptian Arabic + English).
  static const List<String> cashWithdrawalTriggers = [
    'سحبت',
    'سحب',
    'صراف',
    'سحبت من الصراف',
    'سحبت من البنك',
    'withdrew',
    'withdrawal',
    'cash out',
  ];

  /// Cash deposit trigger keywords (Egyptian Arabic + English).
  static const List<String> cashDepositTriggers = [
    'أودعت',
    'اودعت',
    'إيداع',
    'ايداع',
    'حطيت فلوس',
    'حطيت في البنك',
    'deposited',
    'deposit',
    'cash deposit',
    'put money',
  ];

  /// Keywords that refer to the physical cash (system) wallet.
  /// Used by [WalletMatcher.isCashWalletHint], [ChatActionExecutor], and
  /// [VoiceConfirmScreen] for explicit cash detection.
  static const List<String> cashWalletKeywords = [
    'كاش',
    'كاش فلوس',
    'نقدي',
    'نقدية',
    'نقود',
    'نقد',
    'كاش في اليد',
    'كاش في ايدي',
    'cash',
    'cash in hand',
  ];

  /// Fast lookup set for [cashWalletKeywords].
  static final Set<String> cashWalletKeywordSet = {
    for (final k in cashWalletKeywords) k,
  };

  /// Time keyword → day offset from today.
  static const Map<String, int> timeKeywords = {
    'امبارح': -1,
    'أمس': -1,
    'أول امبارح': -2,
    'اول امبارح': -2,
    'اول امس': -2,
    'النهارده': 0,
    'النهاردة': 0,
    'اليوم': 0,
    'دلوقتي': 0,
    'من يومين': -2,
    'من تلات تيام': -3,
    'من اسبوع': -7,
  };

  /// Category keyword → seeded category iconName mapping.
  ///
  /// Values MUST match `iconName` in [CategorySeed] so that auto-match works.
  static const Map<String, String> categoryKeywords = {
    // Food & Dining → iconName: 'restaurant'
    'أكل': 'restaurant', 'اكل': 'restaurant', 'فطار': 'restaurant',
    'غدا': 'restaurant', 'عشا': 'restaurant', 'كافيه': 'restaurant',
    'قهوه': 'restaurant', 'قهوة': 'restaurant',
    'مطعم': 'restaurant', 'طعام': 'restaurant', 'كوفي': 'restaurant',
    'ماكدونالدز': 'restaurant', 'ماك': 'restaurant', 'كنتاكي': 'restaurant',
    'بيتزا': 'restaurant', 'دليفري': 'restaurant', 'طلبات': 'restaurant',
    'talabat': 'restaurant', 'elmenus': 'restaurant',
    // Transport → iconName: 'directions_car'
    'عربيه': 'directions_car', 'أوبر': 'directions_car',
    'اوبر': 'directions_car', 'كريم': 'directions_car',
    'باص': 'directions_car', 'مترو': 'directions_car',
    'تاكسي': 'directions_car', 'بنزين': 'directions_car',
    'نقل': 'directions_car', 'مواصلات': 'directions_car',
    'uber': 'directions_car', 'careem': 'directions_car',
    'swvl': 'directions_car',
    // Shopping → iconName: 'shopping_bag'
    'نون': 'shopping_bag', 'امازون': 'shopping_bag',
    'جوميا': 'shopping_bag', 'مول': 'shopping_bag',
    'كارفور': 'shopping_bag', 'سبينيس': 'shopping_bag',
    'هدوم': 'shopping_bag', 'ملابس': 'shopping_bag',
    'شوبينج': 'shopping_bag',
    'noon': 'shopping_bag', 'amazon': 'shopping_bag',
    // Healthcare → iconName: 'local_hospital'
    'دكتور': 'local_hospital', 'دواء': 'local_hospital',
    'دوا': 'local_hospital', 'صيدليه': 'local_hospital',
    'صيدلية': 'local_hospital', 'صحة': 'local_hospital',
    'مستشفى': 'local_hospital', 'pharmacy': 'local_hospital',
    // Utilities → iconName: 'bolt'
    'فاتوره': 'bolt', 'كهرباء': 'bolt', 'ميه': 'bolt',
    'مياه': 'bolt', 'غاز': 'bolt', 'انترنت': 'bolt',
    'نت': 'bolt', 'موبايل': 'bolt', 'تليفون': 'bolt',
    // Housing & Rent → iconName: 'home'
    'ايجار': 'home', 'إيجار': 'home', 'rent': 'home',
    // Entertainment → iconName: 'movie'
    'ترفيه': 'movie', 'سينما': 'movie', 'فيلم': 'movie',
    'العاب': 'movie', 'خروجة': 'movie', 'خروجه': 'movie',
    'netflix': 'movie', 'يوتيوب': 'movie', 'بلايستيشن': 'movie',
    // Education → iconName: 'school'
    'تعليم': 'school', 'كورس': 'school', 'كتاب': 'school',
    'كتب': 'school', 'دروس': 'school', 'مدرسة': 'school',
    'جامعة': 'school', 'مصاريف الدراسة': 'school',
    'udemy': 'school', 'coursera': 'school',
    // Groceries → iconName: 'shopping_cart'
    'سوبر': 'shopping_cart', 'خضار': 'shopping_cart',
    'بقالة': 'shopping_cart', 'فاكهة': 'shopping_cart',
    'سوبرماركت': 'shopping_cart', 'بقاله': 'shopping_cart',
    'grocery': 'shopping_cart', 'supermarket': 'shopping_cart',
    // Clothing → iconName: 'checkroom'
    'لبس': 'checkroom', 'هدوم جديدة': 'checkroom',
    'جزمة': 'checkroom', 'حذاء': 'checkroom', 'جاكيت': 'checkroom',
    'clothing': 'checkroom', 'shoes': 'checkroom',
    // Travel → iconName: 'flight'
    'سفر': 'flight', 'طيران': 'flight', 'فندق': 'flight',
    'تذكرة': 'flight', 'رحلة': 'flight', 'رحله': 'flight',
    'travel': 'flight', 'flight': 'flight', 'hotel': 'flight',
    // Subscriptions → iconName: 'subscriptions'
    'اشتراك': 'subscriptions', 'باقة': 'subscriptions',
    'باقه': 'subscriptions', 'سبوتيفاي': 'subscriptions',
    'subscription': 'subscriptions', 'spotify': 'subscriptions',
    // Phone & Internet → iconName: 'phone_android'
    'شحن': 'phone_android', 'رصيد': 'phone_android',
    'فودافون': 'phone_android', 'اتصالات': 'phone_android',
    'اورنج': 'phone_android', 'وي': 'phone_android',
    // Gifts → iconName: 'card_giftcard'
    'هدية': 'card_giftcard', 'هديه': 'card_giftcard',
    'gift': 'card_giftcard', 'عيدية': 'card_giftcard',
    // Personal Care → iconName: 'spa'
    'حلاق': 'spa', 'كوافير': 'spa', 'صالون': 'spa',
    'عناية': 'spa', 'haircut': 'spa', 'salon': 'spa',
    // Salary → iconName: 'account_balance_wallet'
    'مرتب': 'account_balance_wallet', 'راتب': 'account_balance_wallet',
    'salary': 'account_balance_wallet', 'قبضت': 'account_balance_wallet',
    'اتقبضت': 'account_balance_wallet',
    // Freelance → iconName: 'work'
    'فريلانس': 'work', 'مشروع': 'work', 'شغل': 'work',
    'freelance': 'work', 'project': 'work',
  };

  /// Transfer trigger keywords (Egyptian Arabic + English).
  static const List<String> transferTriggers = [
    'حولت',
    'حولتلهم',
    'سديت',
    'سددت',
    'نقلت',
    'حطيت في',
    'من حسابي',
    'تحويل',
    'transferred',
    'moved',
    'sent to',
    'transfer',
  ];

  /// Multi-transaction split conjunctions.
  static const List<String> splitKeywords = [
    'وكمان',
    'وبعدين',
    'وبرضو',
    'كمان',
    'وبعد كده',
    'بعدين',
    'and also',
    'then',
  ];
}
