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
    this.domain,
    this.assetPath,
  });

  /// Display name (e.g. "Vodafone").
  final String name;

  /// Brand primary color for the icon background.
  final Color color;

  /// Keywords to match against transaction titles (lowercase).
  final List<String> keywords;

  /// Custom initial override (defaults to first letter of [name]).
  final String? initial;

  /// Domain for Brandfetch CDN logo lookup (e.g. 'netflix.com').
  final String? domain;

  /// Path to a bundled SVG asset (e.g. 'assets/brands/netflix.svg').
  final String? assetPath;

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
      domain: 'vodafone.com.eg',
    ),
    BrandInfo(
      name: 'Vodafone',
      color: Color(0xFFE60000),
      keywords: ['vodafone', 'فودافون', 'ڤودافون'],
      domain: 'vodafone.com.eg',
    ),
    BrandInfo(
      name: 'Orange',
      color: Color(0xFFFF6600),
      keywords: ['orange', 'اورانج'],
      domain: 'orange.eg',
    ),
    BrandInfo(
      name: 'Etisalat',
      color: Color(0xFF00965E),
      keywords: ['etisalat', 'اتصالات'],
      initial: 'e&',
      domain: 'etisalat.eg',
    ),
    BrandInfo(
      name: 'WE',
      color: Color(0xFF6C2D82),
      keywords: ['telecom egypt', 'we telecom', 'we mobile', 'we bill', 'وي'],
      initial: 'WE',
      domain: 'te.eg',
    ),

    // ── Egyptian Banks ──────────────────────────────────────────────
    BrandInfo(
      name: 'CIB',
      color: Color(0xFF003DA5),
      keywords: ['cib', 'سي اي بي', 'السي اي بي', 'تجاري الدولي'],
      initial: 'CIB',
      domain: 'cib.com.eg',
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
      domain: 'nbe.com.eg',
    ),
    BrandInfo(
      name: 'Banque Misr',
      color: Color(0xFF1B3A5C),
      keywords: ['banque misr', 'بنك مصر', 'misr bank'],
      initial: 'BM',
      domain: 'banquemisr.com',
    ),
    BrandInfo(
      name: 'QNB',
      color: Color(0xFF8B0029),
      keywords: ['qnb', 'قطر الوطني', 'كيو ان بي'],
      initial: 'QNB',
      domain: 'qnb.com',
    ),
    BrandInfo(
      name: 'HSBC',
      color: Color(0xFFDB0011),
      keywords: ['hsbc', 'اتش اس بي سي'],
      initial: 'HSBC',
      domain: 'hsbc.com.eg',
    ),
    BrandInfo(
      name: 'Alex Bank',
      color: Color(0xFF003C71),
      keywords: ['alex bank', 'بنك الاسكندرية', 'الإسكندرية'],
      initial: 'AB',
      domain: 'alexbank.com',
    ),
    BrandInfo(
      name: 'AAIB',
      color: Color(0xFF005C5C),
      keywords: ['aaib', 'العربي الأفريقي', 'arab african'],
      initial: 'AAIB',
      domain: 'aaib.com',
    ),
    BrandInfo(
      name: 'Banque du Caire',
      color: Color(0xFF003DA5),
      keywords: ['banque du caire', 'بنك القاهرة'],
      initial: 'BC',
      domain: 'bdc.com.eg',
    ),

    // ── Egyptian Fintech & Payments ──────────────────────────────────
    BrandInfo(
      name: 'Fawry',
      color: Color(0xFFE8A317),
      keywords: ['fawry', 'فوري'],
      domain: 'fawry.com',
    ),
    BrandInfo(
      name: 'InstaPay',
      color: Color(0xFF1E3A5F),
      keywords: ['instapay', 'انستاباي'],
      domain: 'instapay.eg',
    ),
    BrandInfo(
      name: 'ValU',
      color: Color(0xFF6C63FF),
      keywords: ['valu', 'ڤاليو', 'فاليو'],
      domain: 'valu.com.eg',
    ),
    BrandInfo(
      name: 'Telda',
      color: Color(0xFF00C853),
      keywords: ['telda', 'تلدا', 'تيلدا'],
      domain: 'telda.app',
    ),
    BrandInfo(
      name: 'MNT-Halan',
      color: Color(0xFF1E3A5F),
      keywords: ['mnt', 'halan', 'هالان'],
      initial: 'MH',
      domain: 'hframetech.com',
    ),
    BrandInfo(
      name: 'Shahry',
      color: Color(0xFF6C63FF),
      keywords: ['shahry', 'شهري'],
      initial: 'Sh',
      domain: 'shahry.app',
    ),
    BrandInfo(
      name: 'Sympl',
      color: Color(0xFFFF6B35),
      keywords: ['sympl', 'سيمبل'],
      initial: 'Sy',
      domain: 'sympl.com',
    ),
    BrandInfo(
      name: 'Paymob',
      color: Color(0xFF0066FF),
      keywords: ['paymob', 'بايموب'],
      initial: 'PM',
      domain: 'paymob.com',
    ),
    BrandInfo(
      name: 'Khazna',
      color: Color(0xFF00B894),
      keywords: ['khazna', 'خزنة'],
      domain: 'khazna.app',
    ),
    BrandInfo(
      name: 'Lucky',
      color: Color(0xFF4CAF50),
      keywords: ['lucky', 'لاكي'],
    ),

    // ── Ride-hailing & Delivery ─────────────────────────────────────
    // Uber Eats MUST be before Uber (more specific keyword match first).
    BrandInfo(
      name: 'Uber Eats',
      color: Color(0xFF06C167),
      keywords: ['uber eats', 'اوبر ايتس'],
      initial: 'UE',
      domain: 'ubereats.com',
    ),
    BrandInfo(
      name: 'Uber',
      color: Color(0xFF000000),
      keywords: ['uber', 'اوبر'],
      domain: 'uber.com',
    ),
    BrandInfo(
      name: 'Careem',
      color: Color(0xFF4CB848),
      keywords: ['careem', 'كريم'],
      domain: 'careem.com',
    ),
    BrandInfo(
      name: 'InDriver',
      color: Color(0xFF3EB549),
      keywords: ['indriver', 'ان درايفر'],
      domain: 'indriver.com',
    ),
    BrandInfo(
      name: 'Swvl',
      color: Color(0xFF34D399),
      keywords: ['swvl', 'سويفل'],
      initial: 'Sw',
      domain: 'swvl.com',
    ),
    BrandInfo(
      name: 'Talabat',
      color: Color(0xFFFF5A00),
      keywords: ['talabat', 'طلبات'],
      domain: 'talabat.com',
    ),
    BrandInfo(
      name: 'Elmenus',
      color: Color(0xFFE91E63),
      keywords: ['elmenus', 'المنيوز'],
      domain: 'elmenus.com',
    ),
    BrandInfo(
      name: 'Rabbit',
      color: Color(0xFFFF6F00),
      keywords: ['rabbit', 'رابيت'],
      domain: 'rabbit.com.eg',
    ),

    // ── Retail & Groceries ──────────────────────────────────────────
    BrandInfo(
      name: 'Carrefour',
      color: Color(0xFF004F9F),
      keywords: ['carrefour', 'كارفور'],
      domain: 'carrefouregypt.com',
    ),
    BrandInfo(
      name: 'Spinneys',
      color: Color(0xFF1B5E20),
      keywords: ['spinneys', 'سبينيز'],
      domain: 'spinneys.com',
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
      domain: 'breadfast.com',
    ),
    BrandInfo(
      name: 'Instashop',
      color: Color(0xFF00BFA5),
      keywords: ['instashop'],
      domain: 'instashop.com',
    ),
    BrandInfo(
      name: 'Seoudi',
      color: Color(0xFFE53935),
      keywords: ['seoudi', 'سعودي', 'سعودى'],
    ),
    BrandInfo(
      name: 'Hyper One',
      color: Color(0xFF1565C0),
      keywords: ['hyper one', 'هايبر وان'],
      initial: 'H1',
      domain: 'hyperone.com.eg',
    ),
    BrandInfo(
      name: 'B.Tech',
      color: Color(0xFF004B93),
      keywords: ['b.tech', 'btech', 'بي تك'],
      initial: 'BT',
      domain: 'btech.com',
    ),

    // ── Streaming & Entertainment ───────────────────────────────────
    BrandInfo(
      name: 'Netflix',
      color: Color(0xFFE50914),
      keywords: ['netflix', 'نتفلكس', 'نتفليكس'],
      domain: 'netflix.com',
    ),
    BrandInfo(
      name: 'Spotify',
      color: Color(0xFF1DB954),
      keywords: ['spotify', 'سبوتيفاي'],
      domain: 'spotify.com',
    ),
    BrandInfo(
      name: 'YouTube',
      color: Color(0xFFFF0000),
      keywords: ['youtube', 'يوتيوب'],
      initial: 'YT',
      domain: 'youtube.com',
    ),
    BrandInfo(
      name: 'Shahid',
      color: Color(0xFF00BCD4),
      keywords: ['shahid', 'شاهد'],
      domain: 'shahid.mbc.net',
    ),
    BrandInfo(
      name: 'Anghami',
      color: Color(0xFF6C3EA6),
      keywords: ['anghami', 'أنغامي', 'انغامي'],
      domain: 'anghami.com',
    ),
    BrandInfo(
      name: 'Disney+',
      color: Color(0xFF113CCF),
      keywords: ['disney', 'ديزني'],
      initial: 'D+',
      domain: 'disneyplus.com',
    ),
    BrandInfo(
      name: 'Apple TV+',
      color: Color(0xFF000000),
      keywords: ['apple tv', 'ابل تي في'],
      initial: 'TV+',
      domain: 'tv.apple.com',
    ),
    BrandInfo(
      name: 'OSN',
      color: Color(0xFF1A1A2E),
      keywords: ['osn', 'أو إس إن'],
      initial: 'OSN',
      domain: 'osn.com',
    ),
    BrandInfo(
      name: 'Apple',
      color: Color(0xFF555555),
      keywords: ['apple', 'itunes', 'app store', 'icloud'],
      domain: 'apple.com',
    ),
    BrandInfo(
      name: 'Google',
      color: Color(0xFF4285F4),
      keywords: ['google', 'play store', 'google one'],
      domain: 'google.com',
    ),

    // ── Dining & Coffee ─────────────────────────────────────────────
    BrandInfo(
      name: 'Starbucks',
      color: Color(0xFF00704A),
      keywords: ['starbucks', 'ستاربكس'],
      domain: 'starbucks.com',
    ),
    BrandInfo(
      name: "McDonald's",
      color: Color(0xFFFFC72C),
      keywords: ['mcdonald', 'ماكدونالدز', 'ماك'],
      initial: 'M',
      domain: 'mcdonalds.com',
    ),
    BrandInfo(
      name: 'KFC',
      color: Color(0xFFF40027),
      keywords: ['kfc', 'كنتاكي', 'كي اف سي'],
      initial: 'KFC',
      domain: 'kfc.com',
    ),
    BrandInfo(
      name: 'Costa Coffee',
      color: Color(0xFF6F263D),
      keywords: ['costa', 'كوستا'],
      initial: 'CC',
      domain: 'costa.co.uk',
    ),
    BrandInfo(
      name: 'Hardees',
      color: Color(0xFFE1251B),
      keywords: ['hardees', 'هارديز'],
      domain: 'hardees.com',
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
    BrandInfo(
      name: "Domino's",
      color: Color(0xFF006491),
      keywords: ['domino', 'دومينوز'],
      domain: 'dominos.com',
    ),
    BrandInfo(
      name: 'Pizza Hut',
      color: Color(0xFFEE3A23),
      keywords: ['pizza hut', 'بيتزا هت'],
      domain: 'pizzahut.com',
    ),
    BrandInfo(
      name: 'Burger King',
      color: Color(0xFFFF8732),
      keywords: ['burger king', 'برجر كنج'],
      domain: 'burgerking.com',
    ),
    BrandInfo(
      name: 'Baskin Robbins',
      color: Color(0xFFFF1C6E),
      keywords: ['baskin', 'باسكن'],
      domain: 'baskinrobbins.com',
    ),
    BrandInfo(
      name: 'Cinnabon',
      color: Color(0xFF003E7E),
      keywords: ['cinnabon', 'سينابون'],
      domain: 'cinnabon.com',
    ),
    BrandInfo(
      name: 'Krispy Kreme',
      color: Color(0xFF00653A),
      keywords: ['krispy', 'كريسبي'],
      domain: 'krispykreme.com',
    ),

    // ── Shopping ────────────────────────────────────────────────────
    BrandInfo(
      name: 'Amazon',
      color: Color(0xFFFF9900),
      keywords: ['amazon', 'امازون'],
      domain: 'amazon.eg',
    ),
    BrandInfo(
      name: 'Noon',
      color: Color(0xFFF5D100),
      keywords: ['noon', 'نون'],
      domain: 'noon.com',
    ),
    BrandInfo(
      name: 'Jumia',
      color: Color(0xFFFF6900),
      keywords: ['jumia', 'جوميا'],
      domain: 'jumia.com.eg',
    ),
    BrandInfo(
      name: 'IKEA',
      color: Color(0xFF0051BA),
      keywords: ['ikea', 'ايكيا'],
      initial: 'IKEA',
      domain: 'ikea.com',
    ),
    BrandInfo(
      name: 'Zara',
      color: Color(0xFF000000),
      keywords: ['zara', 'زارا'],
      domain: 'zara.com',
    ),
    BrandInfo(
      name: 'H&M',
      color: Color(0xFFE50010),
      keywords: ['h&m', 'اتش اند ام'],
      initial: 'H&M',
      domain: 'hm.com',
    ),
    BrandInfo(
      name: 'Shein',
      color: Color(0xFF000000),
      keywords: ['shein', 'شي ان'],
      domain: 'shein.com',
    ),
    BrandInfo(
      name: 'AliExpress',
      color: Color(0xFFFF4747),
      keywords: ['aliexpress', 'علي اكسبريس'],
      domain: 'aliexpress.com',
    ),

    // ── Travel & Airlines ──────────────────────────────────────────
    BrandInfo(
      name: 'EgyptAir',
      color: Color(0xFF00205B),
      keywords: ['egyptair', 'مصر للطيران'],
      initial: 'EA',
      domain: 'egyptair.com',
    ),

    // ── Pharmacies ──────────────────────────────────────────────────
    BrandInfo(
      name: 'El-Ezaby Pharmacy',
      color: Color(0xFF00A651),
      keywords: ['elezaby', 'ezaby', 'العزبي'],
      domain: 'elezaby.com',
    ),
    BrandInfo(
      name: 'Seif Pharmacy',
      color: Color(0xFF1B75BB),
      keywords: ['seif', 'سيف'],
      domain: 'seifpharmacy.com',
    ),

    // ── Gas Stations ────────────────────────────────────────────────
    BrandInfo(
      name: 'Total Energies',
      color: Color(0xFFFF0000),
      keywords: ['total', 'توتال'],
      domain: 'totalenergies.com',
    ),
    BrandInfo(
      name: 'Wataniya',
      color: Color(0xFF007236),
      keywords: ['wataniya', 'وطنية'],
    ),
    BrandInfo(
      name: 'Misr Petroleum',
      color: Color(0xFF003DA5),
      keywords: ['misr petroleum', 'مصر للبترول'],
      initial: 'MP',
    ),

    // ── Education ───────────────────────────────────────────────────
    BrandInfo(
      name: 'Coursera',
      color: Color(0xFF0056D2),
      keywords: ['coursera', 'كورسيرا'],
      domain: 'coursera.org',
    ),
    BrandInfo(
      name: 'Udemy',
      color: Color(0xFFA435F0),
      keywords: ['udemy', 'يوديمي'],
      domain: 'udemy.com',
    ),

    // ── Gym & Fitness ───────────────────────────────────────────────
    BrandInfo(
      name: "Gold's Gym",
      color: Color(0xFFFFD700),
      keywords: ['gold gym', 'golds gym', 'جولد جيم'],
      domain: 'goldsgym.com',
    ),
    BrandInfo(
      name: 'Gym',
      color: Color(0xFFFF5722),
      keywords: ['gym', 'جيم', 'fitness'],
    ),

    // ── Insurance ───────────────────────────────────────────────────
    BrandInfo(
      name: 'AXA',
      color: Color(0xFF00008F),
      keywords: ['axa', 'اكسا'],
      domain: 'axa.com',
    ),
    BrandInfo(
      name: 'Allianz',
      color: Color(0xFF003781),
      keywords: ['allianz', 'اليانز'],
      domain: 'allianz.com',
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
