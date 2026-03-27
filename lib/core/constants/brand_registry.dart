import 'package:flutter/material.dart';

/// Known brand metadata for merchant icon display on transaction cards.
///
/// Each brand has a display name, primary color, and matching keywords.
/// The resolver matches transaction titles against keywords (case-insensitive).
class BrandInfo {
  const BrandInfo({
    required this.name,
    required this.color,
    required this.keywords,
    this.initial,
  });

  /// Display name (e.g. "Vodafone").
  final String name;

  /// Brand primary color for the icon background.
  final Color color;

  /// Keywords to match against transaction titles (lowercase).
  final List<String> keywords;

  /// Custom initial override (defaults to first letter of [name]).
  final String? initial;

  /// Returns the display initial for the brand icon.
  String get displayInitial => initial ?? name[0];
}

/// Registry of known brands for transaction icon matching.
///
/// Brands are matched by checking if the transaction title contains
/// any of the brand's keywords (case-insensitive substring match).
///
/// To add a new brand, append to [brands] with matching keywords.
abstract final class BrandRegistry {
  /// All registered brands, ordered by specificity (more specific first).
  static const List<BrandInfo> brands = [
    // ── Egyptian Telecom ──────────────────────────────────────────────
    // Vodafone Cash MUST be before Vodafone (more specific match first).
    BrandInfo(
      name: 'Vodafone Cash',
      color: Color(0xFFE60000),
      keywords: ['vodafone cash', 'فودافون كاش'],
      initial: 'VC',
    ),
    BrandInfo(
      name: 'Vodafone',
      color: Color(0xFFE60000),
      keywords: ['vodafone', 'فودافون', 'ڤودافون'],
    ),
    BrandInfo(
      name: 'Orange',
      color: Color(0xFFFF6600),
      keywords: ['orange', 'اورانج'],
    ),
    BrandInfo(
      name: 'Etisalat',
      color: Color(0xFF00965E),
      keywords: ['etisalat', 'اتصالات'],
      initial: 'e&',
    ),
    BrandInfo(
      name: 'WE',
      color: Color(0xFF6C2D82),
      keywords: ['telecom egypt', 'we telecom', 'we mobile', 'we bill', 'وي'],
      initial: 'WE',
    ),

    // ── Egyptian Banks ──────────────────────────────────────────────
    BrandInfo(
      name: 'CIB',
      color: Color(0xFF003DA5),
      keywords: ['cib', 'سي اي بي', 'السي اي بي', 'تجاري الدولي'],
      initial: 'CIB',
    ),
    BrandInfo(
      name: 'NBE',
      color: Color(0xFF004B87),
      keywords: [
        'nbe',
        'الأهلي',
        'الاهلي',
        'ahly',
        'national bank',
        'ان بي اي',
        'البنك الاهلي',
      ],
      initial: 'NBE',
    ),
    BrandInfo(
      name: 'Banque Misr',
      color: Color(0xFF1B3A5C),
      keywords: ['banque misr', 'بنك مصر', 'misr bank'],
      initial: 'BM',
    ),
    BrandInfo(
      name: 'QNB',
      color: Color(0xFF8B0029),
      keywords: ['qnb', 'قطر الوطني', 'كيو ان بي'],
      initial: 'QNB',
    ),
    BrandInfo(
      name: 'HSBC',
      color: Color(0xFFDB0011),
      keywords: ['hsbc', 'اتش اس بي سي'],
      initial: 'HSBC',
    ),

    // ── Egyptian Fintech & Payments ──────────────────────────────────
    BrandInfo(
      name: 'Fawry',
      color: Color(0xFFE8A317),
      keywords: ['fawry', 'فوري'],
    ),
    BrandInfo(
      name: 'InstaPay',
      color: Color(0xFF1E3A5F),
      keywords: ['instapay', 'انستاباي'],
    ),
    BrandInfo(
      name: 'ValU',
      color: Color(0xFF6C63FF),
      keywords: ['valu', 'ڤاليو', 'فاليو'],
    ),
    BrandInfo(
      name: 'Telda',
      color: Color(0xFF00C853),
      keywords: ['telda', 'تلدا', 'تيلدا'],
    ),
    BrandInfo(
      name: 'MNT-Halan',
      color: Color(0xFF1E3A5F),
      keywords: ['mnt', 'halan', 'هالان'],
      initial: 'MH',
    ),
    BrandInfo(
      name: 'Shahry',
      color: Color(0xFF6C63FF),
      keywords: ['shahry', 'شهري'],
      initial: 'Sh',
    ),
    BrandInfo(
      name: 'Sympl',
      color: Color(0xFFFF6B35),
      keywords: ['sympl', 'سيمبل'],
      initial: 'Sy',
    ),

    // ── Ride-hailing & Delivery ─────────────────────────────────────
    // Uber Eats MUST be before Uber (more specific keyword match first).
    BrandInfo(
      name: 'Uber Eats',
      color: Color(0xFF06C167),
      keywords: ['uber eats', 'اوبر ايتس'],
      initial: 'UE',
    ),
    BrandInfo(
      name: 'Uber',
      color: Color(0xFF000000),
      keywords: ['uber', 'اوبر'],
    ),
    BrandInfo(
      name: 'Careem',
      color: Color(0xFF4CB848),
      keywords: ['careem', 'كريم'],
    ),
    BrandInfo(
      name: 'InDriver',
      color: Color(0xFF3EB549),
      keywords: ['indriver', 'ان درايفر'],
    ),
    BrandInfo(
      name: 'Swvl',
      color: Color(0xFF34D399),
      keywords: ['swvl', 'سويفل'],
      initial: 'Sw',
    ),
    BrandInfo(
      name: 'Talabat',
      color: Color(0xFFFF5A00),
      keywords: ['talabat', 'طلبات'],
    ),
    BrandInfo(
      name: 'Elmenus',
      color: Color(0xFFE91E63),
      keywords: ['elmenus', 'المنيوز'],
    ),

    // ── Retail & Groceries ──────────────────────────────────────────
    BrandInfo(
      name: 'Carrefour',
      color: Color(0xFF004F9F),
      keywords: ['carrefour', 'كارفور'],
    ),
    BrandInfo(
      name: 'Spinneys',
      color: Color(0xFF1B5E20),
      keywords: ['spinneys', 'سبينيز'],
    ),
    BrandInfo(
      name: 'Kazyon',
      color: Color(0xFFE53935),
      keywords: ['kazyon', 'كازيون'],
    ),
    BrandInfo(
      name: 'Breadfast',
      color: Color(0xFF2196F3),
      keywords: ['breadfast', 'بريدفاست'],
    ),
    BrandInfo(
      name: 'Instashop',
      color: Color(0xFF00BFA5),
      keywords: ['instashop'],
    ),
    BrandInfo(
      name: 'B.Tech',
      color: Color(0xFF004B93),
      keywords: ['b.tech', 'btech', 'بي تك'],
      initial: 'BT',
    ),

    // ── Streaming & Entertainment ───────────────────────────────────
    BrandInfo(
      name: 'Netflix',
      color: Color(0xFFE50914),
      keywords: ['netflix', 'نتفلكس', 'نتفليكس'],
    ),
    BrandInfo(
      name: 'Spotify',
      color: Color(0xFF1DB954),
      keywords: ['spotify', 'سبوتيفاي'],
    ),
    BrandInfo(
      name: 'YouTube',
      color: Color(0xFFFF0000),
      keywords: ['youtube', 'يوتيوب'],
      initial: 'YT',
    ),
    BrandInfo(
      name: 'Shahid',
      color: Color(0xFF00BCD4),
      keywords: ['shahid', 'شاهد'],
    ),
    BrandInfo(
      name: 'Apple',
      color: Color(0xFF555555),
      keywords: ['apple', 'itunes', 'app store', 'icloud'],
    ),
    BrandInfo(
      name: 'Google',
      color: Color(0xFF4285F4),
      keywords: ['google', 'play store', 'google one'],
    ),

    // ── Dining & Coffee ─────────────────────────────────────────────
    BrandInfo(
      name: 'Starbucks',
      color: Color(0xFF00704A),
      keywords: ['starbucks', 'ستاربكس'],
    ),
    BrandInfo(
      name: "McDonald's",
      color: Color(0xFFFFC72C),
      keywords: ['mcdonald', 'ماكدونالدز', 'ماك'],
      initial: 'M',
    ),
    BrandInfo(
      name: 'KFC',
      color: Color(0xFFF40027),
      keywords: ['kfc', 'كنتاكي', 'كي اف سي'],
      initial: 'KFC',
    ),
    BrandInfo(
      name: 'Costa Coffee',
      color: Color(0xFF6F263D),
      keywords: ['costa', 'كوستا'],
      initial: 'CC',
    ),
    BrandInfo(
      name: 'Hardees',
      color: Color(0xFFE1251B),
      keywords: ['hardees', 'هارديز'],
    ),
    BrandInfo(
      name: "Mo'men",
      color: Color(0xFFD4AF37),
      keywords: ["mo'men", 'momen', 'مؤمن'],
      initial: 'Mo',
    ),
    BrandInfo(
      name: 'Gad',
      color: Color(0xFF8B0000),
      keywords: ['gad', 'جاد'],
    ),

    // ── Shopping ────────────────────────────────────────────────────
    BrandInfo(
      name: 'Amazon',
      color: Color(0xFFFF9900),
      keywords: ['amazon', 'امازون'],
    ),
    BrandInfo(
      name: 'Noon',
      color: Color(0xFFF5D100),
      keywords: ['noon', 'نون'],
    ),
    BrandInfo(
      name: 'Jumia',
      color: Color(0xFFFF6900),
      keywords: ['jumia', 'جوميا'],
    ),
    BrandInfo(
      name: 'IKEA',
      color: Color(0xFF0051BA),
      keywords: ['ikea', 'ايكيا'],
      initial: 'IKEA',
    ),
    BrandInfo(
      name: 'Zara',
      color: Color(0xFF000000),
      keywords: ['zara', 'زارا'],
    ),

    // ── Travel & Airlines ──────────────────────────────────────────
    BrandInfo(
      name: 'EgyptAir',
      color: Color(0xFF00205B),
      keywords: ['egyptair', 'مصر للطيران'],
      initial: 'EA',
    ),

    // ── Utilities & Services ─────────────────────────────────────────
    BrandInfo(
      name: 'Gym',
      color: Color(0xFFFF5722),
      keywords: ['gym', 'جيم', 'fitness', 'gold gym'],
    ),
  ];

  /// Finds the first matching brand for the given transaction title.
  /// Returns `null` if no brand matches.
  static BrandInfo? match(String title) {
    if (title.isEmpty) return null;
    final lower = title.toLowerCase();
    for (final brand in brands) {
      for (final keyword in brand.keywords) {
        if (lower.contains(keyword)) return brand;
      }
    }
    return null;
  }
}
