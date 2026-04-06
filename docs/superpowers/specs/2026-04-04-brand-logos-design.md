# Brand Logos — Design Spec

**Date:** 2026-04-04
**Scope:** 3-tier brand logo system for transactions, bills, goals, budgets
**Status:** Approved

---

## 1. Data Model

Extend `BrandInfo` in `lib/core/constants/brand_registry.dart`:

```dart
class BrandInfo {
  const BrandInfo({
    required this.name,
    required this.color,
    required this.keywords,
    this.initial,
    this.domain,    // e.g. 'netflix.com' for Brandfetch CDN
    this.assetPath, // e.g. 'assets/brands/netflix.svg' for bundled
  });

  final String name;
  final String color;
  final List<String> keywords;
  final String? initial;
  final String? domain;
  final String? assetPath;
}
```

## 2. Resolution Pipeline

Three-tier fallback, checked in order:

1. **Local SVG** — `SvgPicture.asset(brand.assetPath!)` if `assetPath != null` and file exists. Instant, offline, no network.
2. **Brandfetch CDN** — `CachedNetworkImage` from `https://cdn.brandfetch.io/{domain}/w/64/h/64/icon` if `domain != null`. Fetched once, cached to disk permanently. Shows colored initial circle while loading.
3. **Colored initial circle** — existing `_BrandIconCircle` (letter + brand color). Always available, zero dependencies.

## 3. New Widget: `BrandLogo`

Create `lib/shared/widgets/cards/brand_logo.dart`:

- Takes `BrandInfo? brand` and `double size` (default 40)
- If `brand == null`, returns `null` (caller shows category icon instead)
- Walks the 3-tier pipeline
- For tier 2: uses `CachedNetworkImage` with `placeholder` = tier 3 widget, `errorWidget` = tier 3 widget
- Circular clip with `ClipOval`

## 4. New Dependencies

- `flutter_svg: ^2.0.0` — render bundled SVG brand icons
- `cached_network_image: ^3.3.0` — fetch + disk-cache Brandfetch CDN logos

## 5. Brand Registry Expansion

Current: 55 brands. Add ~30 more:

**Pharmacies:** El-Ezaby, Seif Pharmacy
**Gas stations:** Wataniya, Total, Misr Petroleum
**Fast food:** Domino's, Pizza Hut, Burger King, Baskin Robbins, Cinnabon
**Banks:** Banque du Caire, Mashreq, FAB
**Education:** Coursera, Udemy
**Shopping:** H&M, Shein, AliExpress
**Gyms:** Gold's Gym
**Food delivery:** Rabbit (formerly Otlob)
**More streaming:** HBO Max, Apple TV+, DAZN
**Insurance:** AXA, Allianz
**Telecom:** Nile Online

Each entry includes: name, color hex, keywords (EN + AR), domain, assetPath.

## 6. Bundled SVGs

Directory: `assets/brands/`
Format: Monochrome SVG from SimpleIcons where available.
Egyptian brands: manually created simple SVGs (just the brand initial in a circle with brand color — similar to current circles but as vector assets for consistency).
Count: ~80 files
Size: ~150-200KB total

Register in `pubspec.yaml`:
```yaml
assets:
  - assets/brands/
```

## 7. Surfaces to Wire

| Surface | File | Current state | Change |
|---------|------|---------------|--------|
| Dashboard transaction list | `transaction_sliver_list.dart` | No brand info | Add `BrandRegistry.match(tx.title)` + pass to card |
| Transaction card | `transaction_card.dart` | Uses `_BrandIconCircle` | Replace with `BrandLogo` widget |
| Transaction list section | `transaction_list_section.dart` | Passes `brandInfo` | Update to use `BrandLogo` |
| Recurring bills list | `recurring_screen.dart` | Category icon only | Add brand matching + `BrandLogo` |
| Goal detail | `goal_detail_screen.dart` | Category icon only | Add brand matching for linked transactions |
| Budget detail | `set_budget_screen.dart` | Category icon only | No change (budgets are per-category, not per-brand) |

## 8. Brandfetch CDN

- Free tier: 500,000 requests/month (no API key needed for basic icon endpoint)
- Endpoint: `https://cdn.brandfetch.io/{domain}/w/64/h/64/icon`
- Returns WebP/PNG icon at requested size
- Disk-cached via `cached_network_image`'s built-in `CacheManager`
- No network = shows tier 3 fallback (colored circle)
- Respects offline-first rule: tier 1 (bundled) covers 80% of cases without any network

## 9. File Impact

### New files
| File | Purpose |
|------|---------|
| `lib/shared/widgets/cards/brand_logo.dart` | 3-tier brand logo widget |
| `assets/brands/*.svg` | ~80 bundled brand SVGs |

### Modified files
| File | Change |
|------|--------|
| `lib/core/constants/brand_registry.dart` | Add domain/assetPath fields, expand to ~85 brands |
| `lib/shared/widgets/cards/transaction_card.dart` | Replace `_BrandIconCircle` with `BrandLogo` |
| `lib/features/dashboard/presentation/widgets/transaction_sliver_list.dart` | Wire brand matching |
| `lib/features/recurring/presentation/screens/recurring_screen.dart` | Add brand matching |
| `pubspec.yaml` | Add flutter_svg, cached_network_image, assets/brands/ |

### APK impact
- flutter_svg: ~minimal (tree-shaken)
- cached_network_image: ~200KB
- SVG assets: ~150-200KB
- Total: ~400-500KB
