import '../../domain/entities/wallet_entity.dart';
import '../constants/voice_dictionary.dart';

/// Fuzzy-matches a spoken wallet hint against a list of wallets.
///
/// Pure Dart utility — no Flutter imports.
abstract final class WalletMatcher {
  /// Returns the best matching wallet, or null if no match/ambiguous.
  ///
  /// Priority: exact > contains > abbreviation > fuzzy overlap (>=50%).
  static WalletEntity? match(String hint, List<WalletEntity> wallets) {
    if (hint.trim().isEmpty || wallets.isEmpty) return null;
    final normalized = _normalize(hint);

    // 1. Exact match (case-insensitive).
    for (final w in wallets) {
      if (_normalize(w.name) == normalized) return w;
    }

    // 2. Contains match (either direction) — only if exactly 1 match.
    final containsMatches = wallets.where((w) {
      final wn = _normalize(w.name);
      return wn.contains(normalized) || normalized.contains(wn);
    }).toList();
    if (containsMatches.length == 1) return containsMatches.first;

    // 3. Known abbreviation lookup.
    final resolvedName = _resolveAbbreviation(normalized);
    if (resolvedName != null) {
      for (final w in wallets) {
        final wn = _normalize(w.name);
        if (wn == resolvedName.toLowerCase() ||
            wn.contains(resolvedName.toLowerCase()) ||
            resolvedName.toLowerCase().contains(wn)) {
          return w;
        }
      }
    }

    // 4. Character overlap >= 50% (only for hints with 3+ chars to avoid
    //    false positives from single-character set overlap).
    if (normalized.length >= 3) {
      WalletEntity? best;
      double bestScore = 0;
      for (final w in wallets) {
        final wn = _normalize(w.name);
        if (wn.length < 3) continue;
        final score = _similarity(normalized, wn);
        if (score >= 0.5 && score > bestScore) {
          bestScore = score;
          best = w;
        }
      }
      return best;
    }
    return null;
  }

  static String _normalize(String s) {
    var result = s.trim().toLowerCase();
    // Strip Arabic definite article "ال".
    if (result.startsWith('ال')) {
      result = result.substring(2);
    }
    return result;
  }

  /// Resolves known Egyptian bank abbreviations (Arabic spoken forms → English name).
  static String? _resolveAbbreviation(String normalized) {
    for (final entry in _knownAbbreviations.entries) {
      if (normalized == _normalize(entry.key)) return entry.value;
    }
    return null;
  }

  /// Returns true if [hint] refers to the physical cash (system) wallet.
  static bool isCashWalletHint(String hint) {
    final normalized = _normalize(hint);
    return VoiceDictionary.cashWalletKeywords
        .any((kw) => _normalize(kw) == normalized);
  }

  /// Known Egyptian bank abbreviation map (Arabic spoken -> English name).
  static const Map<String, String> _knownAbbreviations = {
    'سي اي بي': 'CIB',
    'ان بي اي': 'NBE',
    'البنك الاهلي': 'NBE',
    'الاهلي': 'NBE',
    'بنك مصر': 'Banque Misr',
    'كيو ان بي': 'QNB',
    'اتش اس بي سي': 'HSBC',
    'فودافون كاش': 'Vodafone Cash',
    'كاش': 'Cash',
    'نقدي': 'Cash',
    'نقود': 'Cash',
    'cash': 'Cash',
  };

  /// Character-level overlap coefficient similarity score (0.0–1.0).
  static double _similarity(String a, String b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final setA = a.split('').toSet();
    final setB = b.split('').toSet();
    final intersection = setA.intersection(setB).length;
    final smaller = setA.length < setB.length ? setA.length : setB.length;
    if (smaller == 0) return 0.0;
    return intersection / smaller;
  }
}
