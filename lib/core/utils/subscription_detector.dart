/// Detects whether a transaction appears to be a recurring subscription or bill.
///
/// Pure Dart — zero Flutter imports.
abstract final class SubscriptionDetector {
  /// Category names (English, lowercase) that are inherently subscription-like.
  static const _subscriptionCategories = {
    'subscriptions',
    'insurance',
    'phone & internet',
    'utilities',
    'housing & rent',
    'installments',
  };

  /// Keywords in transaction title/text suggesting a subscription.
  static const _subscriptionKeywords = [
    // English
    'netflix', 'spotify', 'youtube', 'shahid', 'anghami',
    'gym', 'membership', 'monthly', 'subscription', 'premium',
    'internet', 'fiber', 'dsl', 'rent', 'insurance', 'installment',
    // Arabic
    'اشتراك', 'باقة', 'باقه', 'جيم', 'عضوية', 'شهري',
    'نتفلكس', 'سبوتيفاي', 'يوتيوب', 'شاهد', 'أنغامي',
    'ايجار', 'إيجار', 'تأمين', 'قسط', 'أقساط',
    'انترنت', 'فايبر',
  ];

  /// Returns true if the given transaction looks like a subscription.
  static bool isSubscriptionLike({
    required String? categoryName,
    required String transactionText,
  }) {
    // Check 1: Category name match.
    if (categoryName != null &&
        _subscriptionCategories.contains(categoryName.toLowerCase())) {
      return true;
    }
    // Check 2: Keyword match in transaction text.
    final lower = transactionText.toLowerCase();
    return _subscriptionKeywords.any((kw) => lower.contains(kw));
  }
}
