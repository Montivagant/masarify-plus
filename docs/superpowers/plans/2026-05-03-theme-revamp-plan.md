# Theme Revamp Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the v7 visual revamp — pastel mint gradient background, refined frosted-glass surfaces, single mint brand identity across light + dark — without changing any layout or widget structure.

**Architecture:** Token-first refactor. New gradient + bloom widget owned by the navigation shell. `GlassCard` extended with a `useOwnBackdrop` flag so parent surfaces can own a single `BackdropFilter` region for many children, keeping the per-screen filter count under the documented 8-filter Android ceiling.

**Tech Stack:** Flutter 3.x, Riverpod 2.x, Material 3 via FlexColorScheme, Plus Jakarta Sans (`google_fonts`), Phosphor icons.

**Spec:** `docs/superpowers/specs/2026-05-03-theme-revamp-design.md`

**Visual reference:** `.superpowers/brainstorm/414-1777805942/content/home-mint-bubbly-v7.html`

---

## File Structure

**Modified (10 files):**

| File | Responsibility after change |
|---|---|
| `lib/app/theme/app_colors.dart` | Brand palette + gradient stops + bloom colors + reduce-transparency fallback values + dark rebrand from purple to mint |
| `lib/app/theme/app_text_styles.dart` | Typography scale; `displayLarge` 38sp; tabular figures applied (post-verification) |
| `lib/app/theme/app_theme.dart` | Light/dark themes; transparent scaffold; chip theme override; dropped `surfaceMode`/`blendLevel` |
| `lib/app/theme/app_theme_extension.dart` | Custom semantic tokens (income/expense/transfer/glass surfaces); shadow recolored to slate |
| `lib/core/constants/app_sizes.dart` | New blur, shadow, saturation, top-highlight constants |
| `lib/shared/widgets/cards/glass_card.dart` | New `useOwnBackdrop` param; corrected backdrop API; top inset highlight |
| `lib/shared/widgets/navigation/app_nav_bar.dart` | Shell wraps body in `GradientBackground`; nav bar owns a single tier-1 backdrop region |
| `lib/features/dashboard/presentation/widgets/balance_header.dart` | Hero region wraps in single backdrop; soft divider replaces hard bottom border |
| `lib/features/dashboard/presentation/widgets/filter_bar.dart` | Solid-tinted chips (no per-chip backdrop) |
| `lib/features/dashboard/presentation/widgets/transaction_sliver_list.dart` | List wraps in single tier-2 backdrop region |

**Added (3 files):**

| File | Responsibility |
|---|---|
| `lib/shared/widgets/backgrounds/gradient_background.dart` | Public `GradientBackground` widget — vertical gradient + RepaintBoundary + bloom layer |
| `lib/shared/widgets/backgrounds/_bloom_painter.dart` | Private `CustomPainter` that draws 2–3 radial blooms |
| `test/unit/theme_tokens_test.dart` | Sanity tests for new token shapes (lengths, ranges) |

**Phase 1 audit:** 9 screens override `Scaffold(backgroundColor: ...)` — Task 24 audits and fixes them.

---

## Task 1: Verify Plus Jakarta Sans tabular figures

**Files:**
- Create: `tool/verify_tnum.dart`

This is the §4.3 verification step. We need to confirm `google_fonts` ships Plus Jakarta Sans with the `tnum` OpenType feature before we apply `FontFeature.tabularFigures()` globally.

- [ ] **Step 1: Create the verification harness**

Create `tool/verify_tnum.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Run with: flutter run -t tool/verify_tnum.dart -d <device>
///
/// Renders two strings of digits — once with tabular figures, once without.
/// If the rendered widths differ between same-digit columns (e.g., '1' vs '8'
/// take different space when proportional but identical when tabular),
/// the font ships `tnum` and we are clear to use it.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const _Probe());
}

class _Probe extends StatelessWidget {
  const _Probe({super.key});
  @override
  Widget build(BuildContext context) {
    final base = TextStyle(fontSize: 32);
    final tabular = base.merge(GoogleFonts.plusJakartaSans(
      fontFeatures: const [FontFeature.tabularFigures()],
    ));
    final proportional = base.merge(GoogleFonts.plusJakartaSans());
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('11111', style: tabular),
              Text('11111', style: proportional),
              Text('88888', style: tabular),
              Text('88888', style: proportional),
              const SizedBox(height: 24),
              const Text('If 1- and 8-rows look the same width within each pair → tabular works.'),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Run the harness**

Run: `flutter run -t tool/verify_tnum.dart -d <device-id>`

Expected: app launches; visually compare the four strings.

- [ ] **Step 3: Decide based on result**

- If tabular and proportional rows look **identical** within each digit pair → Plus Jakarta Sans ships `tnum`. Continue with the plan as written.
- If they differ → the font does NOT ship `tnum`. Add this dependency to `pubspec.yaml` to self-host Plus Jakarta Sans with the full feature table:

```yaml
flutter:
  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Regular.ttf
        - asset: assets/fonts/PlusJakartaSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
        - asset: assets/fonts/PlusJakartaSans-ExtraBold.ttf
          weight: 800
```

Download fonts from <https://fonts.google.com/specimen/Plus+Jakarta+Sans>, place in `assets/fonts/`. Then in `app_theme.dart` swap `GoogleFonts.plusJakartaSans()` for `'PlusJakartaSans'` family. **Record the decision in this checkbox** before proceeding.

- [ ] **Step 4: Commit the harness (regardless of outcome)**

```bash
git add tool/verify_tnum.dart
git -c commit.gpgsign=false commit -m "chore: add tnum verification harness for Plus Jakarta Sans"
```

---

## Task 2: Add gradient color constants to AppColors

**Files:**
- Modify: `lib/app/theme/app_colors.dart`
- Test: `test/unit/theme_tokens_test.dart` (created in this task)

- [ ] **Step 1: Write the failing test**

Create `test/unit/theme_tokens_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarify_plus/app/theme/app_colors.dart';

void main() {
  group('Gradient stops', () {
    test('light gradient has 7 stops, anchored mint at top, white at bottom', () {
      expect(AppColors.gradientLightStops, hasLength(7));
      expect(AppColors.gradientLightStops.first, const Color(0xFFDFF6E5));
      expect(AppColors.gradientLightStops.last, const Color(0xFFFFFFFF));
    });

    test('dark gradient has 7 stops, mint forest at top, near-black floor at bottom', () {
      expect(AppColors.gradientDarkStops, hasLength(7));
      expect(AppColors.gradientDarkStops.first, const Color(0xFF06140F));
      expect(AppColors.gradientDarkStops.last, const Color(0xFF080E0C));
      // Floor is above pure black to preserve foreground contrast.
      expect(AppColors.gradientDarkStops.last, isNot(const Color(0xFF000000)));
    });

    test('stops list is monotonic and matches color count', () {
      expect(AppColors.gradientStops, hasLength(7));
      expect(AppColors.gradientStops, equals([0.0, 0.18, 0.38, 0.58, 0.76, 0.90, 1.0]));
    });
  });

  group('Bloom colors', () {
    test('light blooms defined', () {
      expect(AppColors.bloomAquaLight,  isNotNull);
      expect(AppColors.bloomMintLight,  isNotNull);
      expect(AppColors.bloomWhiteLight, isNotNull);
    });

    test('dark blooms defined', () {
      expect(AppColors.bloomMintDark, isNotNull);
      expect(AppColors.bloomTealDark, isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/theme_tokens_test.dart`
Expected: FAIL — "The getter 'gradientLightStops' isn't defined".

- [ ] **Step 3: Add the gradient constants**

Insert into `lib/app/theme/app_colors.dart` immediately before the `// ── Utility ──` section (around line 75):

```dart
  // ── Gradient stops (theme revamp v7) ─────────────────────────────────
  /// Top-to-bottom gradient stops for the global page background (light).
  /// Cool mint/aqua at top → clean white at bottom.
  static const List<Color> gradientLightStops = [
    Color(0xFFDFF6E5), // 0%   mint cream
    Color(0xFFC8F2EE), // 18%  aqua mist
    Color(0xFFC9EBD3), // 38%  mint pastel
    Color(0xFFE0F2E5), // 58%  soft mint
    Color(0xFFEFF8F1), // 76%  near-white mint
    Color(0xFFF8FCF9), // 90%  almost white
    Color(0xFFFFFFFF), // 100% white
  ];

  /// Stop positions for [gradientLightStops] and [gradientDarkStops].
  static const List<double> gradientStops = [0.0, 0.18, 0.38, 0.58, 0.76, 0.90, 1.0];

  /// Top-to-bottom gradient stops for the dark page background.
  /// Mint forest at top → near-black floor (NOT pure black — preserves
  /// foreground contrast for nav labels and screen-bottom content).
  static const List<Color> gradientDarkStops = [
    Color(0xFF06140F), // 0%   deep mint forest
    Color(0xFF0A1F18), // 18%
    Color(0xFF0E2820), // 38%
    Color(0xFF0B1F19), // 58%
    Color(0xFF080E0C), // 76%
    Color(0xFF050807), // 90%
    Color(0xFF080E0C), // 100% near-black floor
  ];

  // ── Radial blooms (painted on top of the linear gradient) ────────────
  static const Color bloomAquaLight  = Color(0xE6C8F2EE); // ~90%
  static const Color bloomMintLight  = Color(0xDDB7E8D2); // ~87%
  static const Color bloomWhiteLight = Color(0xD9FFFFFF); // ~85%
  static const Color bloomMintDark   = Color(0x335BC197); // ~20% mint glow
  static const Color bloomTealDark   = Color(0x2614C4A0); // ~15% teal glow
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/theme_tokens_test.dart`
Expected: PASS, all 5 tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/app/theme/app_colors.dart test/unit/theme_tokens_test.dart
git -c commit.gpgsign=false commit -m "feat: add gradient stops and bloom colors to AppColors"
```

---

## Task 3: Update glass + reduce-transparency fallback tokens in AppColors

**Files:**
- Modify: `lib/app/theme/app_colors.dart`
- Test: `test/unit/theme_tokens_test.dart`

- [ ] **Step 1: Append failing tests**

Add to `test/unit/theme_tokens_test.dart` inside `void main() { ... }`:

```dart
  group('Glass surface tokens (light) — refined recipe', () {
    test('glassCardSurfaceLight is white at ~24% (was mint at 87%)', () {
      expect(AppColors.glassCardSurfaceLight, const Color(0x3DFFFFFF));
    });
    test('glassCardBorderLight is white at ~36%', () {
      expect(AppColors.glassCardBorderLight, const Color(0x5CFFFFFF));
    });
    test('glassSheetSurfaceLight retains higher alpha for sheet legibility', () {
      expect(AppColors.glassSheetSurfaceLight, const Color(0xA6FFFFFF));
    });
    test('glassShadowLight is slate-tinted (was mint-tinted)', () {
      expect(AppColors.glassShadowLight, const Color(0x0F0F1E32));
    });
  });

  group('Reduce-transparency fallback', () {
    test('AppColors.surface used as the light fallback solid', () {
      // Should match brightest gradient stop for visual continuity.
      expect(AppColors.surface, const Color(0xFFEFF8F1));
    });
    test('AppColors.surfaceDark used as the dark fallback solid', () {
      expect(AppColors.surfaceDark, const Color(0xFF0E2820));
    });
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/theme_tokens_test.dart`
Expected: FAIL — values don't match (existing tokens still hold old values).

- [ ] **Step 3: Update token values in `app_colors.dart`**

Replace these lines:

```dart
// Before
static const Color surface = Color(0xFFF5FBF8); // Mint White
```

With:

```dart
// Reduce-transparency fallback solid (matches brightest gradient stop).
// Used when GlassConfig.shouldBlur returns false.
static const Color surface = Color(0xFFEFF8F1);
```

Update `surfaceDark`:

```dart
// Before
static const Color surfaceDark = Color(0xFF1A1A1A); // Dark Charcoal

// After
// Reduce-transparency fallback solid for dark mode.
static const Color surfaceDark = Color(0xFF0E2820);
```

Update glass tokens:

```dart
// Tier 2: Card — was mint-tinted at 87%; now refined milky white at ~24%.
static const Color glassCardSurfaceLight = Color(0x3DFFFFFF); // white at 24%
static const Color glassCardSurfaceDark  = Color(0x14FFFFFF); // white at 8% on dark
static const Color glassCardBorderLight  = Color(0x5CFFFFFF); // white at 36%
static const Color glassCardBorderDark   = Color(0x33FFFFFF); // white at 20%

// Tier 1: Sheet — keep higher alpha for legibility on busy backdrops.
static const Color glassSheetSurfaceLight = Color(0xA6FFFFFF); // white at 65%
static const Color glassSheetSurfaceDark  = Color(0xCC0E2820); // deep mint at ~80%
static const Color glassSheetBorderLight  = Color(0x5CFFFFFF); // white at 36%
static const Color glassSheetBorderDark   = Color(0x33FFFFFF); // white at 20%

// Tier 3: Inset — unchanged.
// (existing values stay)

// Brand-tinted shadows — recolored to slate-neutral for cleaner read on white.
static const Color glassShadowLight = Color(0x0F0F1E32); // slate at ~6%
static const Color glassShadowDark  = Color(0x33000000); // black at 20% (depth on dark)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/unit/theme_tokens_test.dart`
Expected: PASS, all tests green.

- [ ] **Step 5: Commit**

```bash
git add lib/app/theme/app_colors.dart test/unit/theme_tokens_test.dart
git -c commit.gpgsign=false commit -m "refactor: refine glass tokens to white-tinted recipe + slate shadow"
```

---

## Task 4: Rebrand dark palette from purple to mint-forest

**Files:**
- Modify: `lib/app/theme/app_colors.dart`

- [ ] **Step 1: Replace dark palette section**

Find the `// ── Dark Mode (Gothic Noir) ──` block (lines 19–29 in original). Replace **only the values** for `backgroundDark`, `primaryDark`, `primaryContainerDark`, `secondaryDark`, `secondaryContainerDark`, `tertiaryDark`, `tertiaryContainerDark`, `errorDark`. Keep the names.

Replace block with:

```dart
  // ── Dark Mode (Mint Forest — theme revamp v7) ────────────────────────
  // Names describe Material 3 slot meaning (primary / secondary / tertiary
  // role), NOT hue. Values rebranded from the previous "Gothic Noir"
  // purple identity to the unified mint family.
  static const Color backgroundDark         = Color(0xFF06140F); // deep mint forest (gradient top)
  static const Color primaryDark            = Color(0xFF5BC197); // mint glow (matches light primary)
  static const Color primaryContainerDark   = Color(0xFF143A2B); // deep mint container
  static const Color secondaryDark          = Color(0xFF7DD9B8); // pastel mint
  static const Color secondaryContainerDark = Color(0xFF1A3A2D); // dark mint container
  static const Color tertiaryDark           = Color(0xFF89E0C5); // brighter mint
  static const Color tertiaryContainerDark  = Color(0xFF0F2A20); // deep tertiary
  static const Color errorDark              = Color(0xFFB85450); // warm terracotta (kept)
```

- [ ] **Step 2: Run analyzer to confirm no broken references**

Run: `flutter analyze lib/`
Expected: zero errors. Warnings about unused colors are acceptable; we're not removing names, only rebranding values.

- [ ] **Step 3: Commit**

```bash
git add lib/app/theme/app_colors.dart
git -c commit.gpgsign=false commit -m "refactor: rebrand dark palette purple → mint-forest (single brand identity)"
```

---

## Task 5: Update AppSizes — blur, shadow, saturation, top-highlight tokens

**Files:**
- Modify: `lib/core/constants/app_sizes.dart`
- Test: `test/unit/theme_tokens_test.dart`

- [ ] **Step 1: Append failing tests**

Add to `test/unit/theme_tokens_test.dart`:

```dart
  group('Glass size tokens', () {
    test('glassBlurCard bumped to 28', () {
      expect(AppSizes.glassBlurCard, 28.0);
    });
    test('cardShadowOffsetY softened to 6 (refined glass float)', () {
      expect(AppSizes.cardShadowOffsetY, 6.0);
    });
    test('cardShadowBlur is 32 for the airy spread', () {
      expect(AppSizes.cardShadowBlur, 32.0);
    });
    test('glassBackdropSaturation = 1.6 for chromatic frost', () {
      expect(AppSizes.glassBackdropSaturation, 1.6);
    });
    test('glassTopHighlightInset = 0.5 hairline specular', () {
      expect(AppSizes.glassTopHighlightInset, 0.5);
    });
  });
```

Also import at top:

```dart
import 'package:masarify_plus/core/constants/app_sizes.dart';
```

- [ ] **Step 2: Run tests to verify failure**

Run: `flutter test test/unit/theme_tokens_test.dart`
Expected: FAIL on `glassBlurCard` value (currently 12), and on missing constants `glassBackdropSaturation`, `glassTopHighlightInset`.

- [ ] **Step 3: Update existing values in `app_sizes.dart`**

Find `glassBlurCard = 12.0` → change to `28.0`.
Find `cardShadowBlur = 12.0` → change to `32.0`.
Find `cardShadowOffsetY = 4.0` → change to `6.0`.

Add new constants in the "Glass / Gradient" section:

```dart
  /// Backdrop saturation multiplier paired with the glass blur for
  /// chromatic frosting (Paperpillar reference, theme revamp v7).
  static const double glassBackdropSaturation = 1.6;

  /// Single hairline inset highlight on the top edge of a glass card —
  /// the "light catches the rim" specular detail.
  static const double glassTopHighlightInset = 0.5;
```

- [ ] **Step 4: Run tests to verify pass**

Run: `flutter test test/unit/theme_tokens_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/constants/app_sizes.dart test/unit/theme_tokens_test.dart
git -c commit.gpgsign=false commit -m "feat: add glass blur saturation + top-highlight size tokens"
```

---

## Task 6: Bump displayLarge to 38sp and prepare tabular-figures application

**Files:**
- Modify: `lib/app/theme/app_text_styles.dart`

> **Decision input from Task 1:** the verification harness already told you whether Plus Jakarta Sans on Google Fonts ships `tnum`. If yes, apply `FontFeature.tabularFigures()` here. If no, leave the `fontFeatures` lines commented out with a TODO referencing self-hosting (Task 1 step 3) — and finish self-hosting before re-enabling.

- [ ] **Step 1: Replace `displayLarge` block**

Find `displayLarge` at top of `sizeOverrides`. Replace:

```dart
    // Before
    displayLarge: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
    ),
```

With:

```dart
    // 38sp Bold — Wallet balance hero (theme revamp v7).
    displayLarge: TextStyle(
      fontSize: 38,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.9,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
```

Add the import at the top of the file (only if missing):

```dart
import 'dart:ui' show FontFeature;
```

- [ ] **Step 2: Apply tabular figures to other numeric-displaying styles**

Add `fontFeatures: [FontFeature.tabularFigures()],` to:
- `headlineLarge` (26sp Bold) — used in some money totals
- `titleLarge` (18sp Medium) — list primary text
- `bodyLarge` (16sp Regular) — amounts, body copy

Leave `bodyMedium`, `bodySmall`, `labelLarge`, `labelSmall` unchanged (rarely render numerals; consistency cost not worth it).

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze lib/`
Expected: zero errors.

- [ ] **Step 4: Quick visual sanity check on Home**

Run: `flutter run -d <device>`
Open the dashboard, confirm:
- Balance number is visibly larger than before (38 vs 32 sp).
- Income/expense pill amounts have aligned digit columns when zeros change to non-zeros.

- [ ] **Step 5: Commit**

```bash
git add lib/app/theme/app_text_styles.dart
git -c commit.gpgsign=false commit -m "feat: balance hero 38sp + tabular figures across numeric styles"
```

---

## Task 7: Define bloom alignment data class

**Files:**
- Create: `lib/shared/widgets/backgrounds/_bloom_painter.dart`

- [ ] **Step 1: Create the file with the data class only**

```dart
import 'package:flutter/material.dart';

/// One radial bloom painted on the global page gradient.
///
/// Positions are alignment fractions (`Alignment(-1..1, -1..1)`) so they
/// scale with screen size. The X axis is intentionally NOT mirrored for
/// RTL — bloom layout stays the same in Arabic.
@immutable
class BloomSpec {
  const BloomSpec({
    required this.alignment,
    required this.radiusFraction,
    required this.color,
  });

  /// Where the bloom's centre sits, as alignment fractions.
  final Alignment alignment;

  /// Bloom radius as a fraction of the shortest screen side.
  final double radiusFraction;

  /// Colour at the centre. Falls off to transparent at the radius edge.
  final Color color;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/shared/widgets/backgrounds/_bloom_painter.dart
git -c commit.gpgsign=false commit -m "feat: BloomSpec data class for gradient blooms"
```

---

## Task 8: Implement _BloomPainter

**Files:**
- Modify: `lib/shared/widgets/backgrounds/_bloom_painter.dart`

- [ ] **Step 1: Append the painter class**

Add to `_bloom_painter.dart`:

```dart
/// Paints a list of [BloomSpec]s on the canvas as soft radial gradients.
///
/// Wrapped in a `RepaintBoundary` by [GradientBackground] — does not
/// repaint on dashboard rebuilds.
class BloomPainter extends CustomPainter {
  const BloomPainter(this.blooms);

  final List<BloomSpec> blooms;

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;
    for (final bloom in blooms) {
      final centre = Offset(
        size.width  * (bloom.alignment.x + 1) / 2,
        size.height * (bloom.alignment.y + 1) / 2,
      );
      final radius = shortest * bloom.radiusFraction;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [bloom.color, bloom.color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: centre, radius: radius));
      canvas.drawCircle(centre, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BloomPainter old) =>
      !listEquals(old.blooms, blooms);
}
```

Add the missing import at the top:

```dart
import 'package:flutter/foundation.dart' show listEquals;
```

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze lib/shared/widgets/backgrounds/`
Expected: zero errors.

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/backgrounds/_bloom_painter.dart
git -c commit.gpgsign=false commit -m "feat: BloomPainter draws radial bloom highlights"
```

---

## Task 9: Implement GradientBackground widget

**Files:**
- Create: `lib/shared/widgets/backgrounds/gradient_background.dart`

- [ ] **Step 1: Create the widget**

```dart
import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '_bloom_painter.dart';

/// Cool pastel gradient page background with two or three radial blooms.
///
/// Wraps [child] in a `Stack` that paints the gradient + blooms first,
/// then layers `child` on top. Wrapped in `RepaintBoundary` so dashboard
/// rebuilds (filter changes, scroll, refresh) do not repaint the
/// gradient layer.
///
/// Pairs with `Scaffold(backgroundColor: Colors.transparent)` so the
/// gradient is visible through scaffolds.
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  static const _lightBlooms = <BloomSpec>[
    BloomSpec(
      alignment: Alignment(-0.65, -0.85),
      radiusFraction: 0.85,
      color: AppColors.bloomAquaLight,
    ),
    BloomSpec(
      alignment: Alignment(0.75, -0.65),
      radiusFraction: 0.75,
      color: AppColors.bloomMintLight,
    ),
    BloomSpec(
      alignment: Alignment(0.0, 0.85),
      radiusFraction: 0.95,
      color: AppColors.bloomWhiteLight,
    ),
  ];

  static const _darkBlooms = <BloomSpec>[
    BloomSpec(
      alignment: Alignment(-0.65, -0.85),
      radiusFraction: 0.85,
      color: AppColors.bloomMintDark,
    ),
    BloomSpec(
      alignment: Alignment(0.75, -0.65),
      radiusFraction: 0.75,
      color: AppColors.bloomTealDark,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blooms = isDark ? _darkBlooms : _lightBlooms;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? AppColors.gradientDarkStops
                    : AppColors.gradientLightStops,
                stops: AppColors.gradientStops,
              ),
            ),
            child: Positioned.fill(
              child: CustomPaint(painter: BloomPainter(blooms)),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
```

- [ ] **Step 2: Smoke-test that it builds in both brightnesses**

Add to `test/widget_test.dart` (replacing the placeholder):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:masarify_plus/shared/widgets/backgrounds/gradient_background.dart';

void main() {
  testWidgets('GradientBackground builds in light mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const GradientBackground(child: SizedBox.expand()),
      ),
    );
    expect(find.byType(GradientBackground), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('GradientBackground builds in dark mode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const GradientBackground(child: SizedBox.expand()),
      ),
    );
    expect(find.byType(GradientBackground), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
```

- [ ] **Step 3: Run tests**

Run: `flutter test test/widget_test.dart`
Expected: PASS, both tests green.

- [ ] **Step 4: Commit**

```bash
git add lib/shared/widgets/backgrounds/gradient_background.dart test/widget_test.dart
git -c commit.gpgsign=false commit -m "feat: GradientBackground widget with bloom layer"
```

---

## Task 10: Update AppTheme — transparent scaffold, drop surfaceMode/blendLevel, glassShadow re-route

**Files:**
- Modify: `lib/app/theme/app_theme.dart`
- Modify: `lib/app/theme/app_theme_extension.dart`

- [ ] **Step 1: Update `app_theme.dart`**

In `AppTheme.light`:
- Remove the `surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,` line.
- Remove the `blendLevel: 7,` line.
- Change the `.copyWith` block's `scaffoldBackgroundColor: AppColors.surface,` to `scaffoldBackgroundColor: Colors.transparent,`.
- Set the navigation bar background to `Colors.transparent` (the bottom nav will paint its own glass surface in Task 18):
```dart
navigationBarTheme: base.navigationBarTheme.copyWith(
  backgroundColor: Colors.transparent,
  // ... rest unchanged
),
```

In `AppTheme.dark`:
- Same three changes: remove `surfaceMode`, remove `blendLevel`, change `scaffoldBackgroundColor: AppColors.backgroundDark` → `Colors.transparent`.
- Navigation bar `backgroundColor: Colors.transparent`.

Add a `chipTheme` override applied to **both** themes' `subThemesData` (the chip's own override won't be enough because we need control over the unselected-chip background). Inside both `FlexSubThemesData(...)` blocks, append:

```dart
chipRadius: AppSizes.borderRadiusSm,
chipSchemeColor: SchemeColor.primary,            // selected chip background
chipSelectedSchemeColor: SchemeColor.onPrimary,  // selected chip foreground
chipBlendColors: false,                          // do not tint unselected chip
```

- [ ] **Step 2: Update `app_theme_extension.dart`**

Already routes `glassShadowLight`/`glassShadowDark` from `AppColors` — no change needed in this file. The new shadow values flow through automatically because Task 3 changed the source constants.

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze lib/`
Expected: zero errors.

- [ ] **Step 4: Commit**

```bash
git add lib/app/theme/app_theme.dart
git -c commit.gpgsign=false commit -m "refactor: transparent scaffold, drop FlexSurfaceMode, chip theme override"
```

---

## Task 11: Wire GradientBackground into AppScaffoldShell

**Files:**
- Modify: `lib/shared/widgets/navigation/app_nav_bar.dart`

- [ ] **Step 1: Wrap shell body**

Locate `AppScaffoldShell.build()` (around line 223). Find:

```dart
final scaffold = Scaffold(
  extendBody: true,
  body: widget.navigationShell,
  ...
);
```

Replace `body:` with:

```dart
body: GradientBackground(child: widget.navigationShell),
```

Add `extendBody: true` is already present — verify it stays.

Add the import at the top of the file:

```dart
import '../backgrounds/gradient_background.dart';
```

- [ ] **Step 2: Run the app and visually confirm**

Run: `flutter run -d <device>`
Open the Dashboard. Expected:
- Cool mint gradient visible at top of screen
- Warm-free gradient (no orange/cream) — falls to white at bottom
- Glass cards still render but now show the gradient through them (existing tier-2 still skips blur per current GlassCard, so this is a sneak preview only)
- Nav bar still in old style (Task 18 fixes that)

- [ ] **Step 3: Commit**

```bash
git add lib/shared/widgets/navigation/app_nav_bar.dart
git -c commit.gpgsign=false commit -m "feat: shell wraps screens in GradientBackground"
```

---

## Task 12: GlassCard — add useOwnBackdrop param and saturation matrix constant

**Files:**
- Modify: `lib/shared/widgets/cards/glass_card.dart`

- [ ] **Step 1: Add the saturation matrix constant**

At the very top of `glass_card.dart` (after imports, before the `enum GlassTier`):

```dart
/// 4×5 colour matrix that boosts saturation by 1.6× while leaving
/// luminance unchanged. Applied via `ColorFiltered` *after* the
/// backdrop blur so the bleed-through reads as chromatic frost.
///
/// Reference: standard saturation matrix with s = 1.6, lr = 0.213,
/// lg = 0.715, lb = 0.072 (sRGB luminance weights).
const List<double> _kSaturate160Matrix = <double>[
  // R out
  0.213 + 0.787 * 1.6, 0.715 - 0.715 * 1.6, 0.072 - 0.072 * 1.6, 0, 0,
  // G out
  0.213 - 0.213 * 1.6, 0.715 + 0.285 * 1.6, 0.072 - 0.072 * 1.6, 0, 0,
  // B out
  0.213 - 0.213 * 1.6, 0.715 - 0.715 * 1.6, 0.072 + 0.928 * 1.6, 0, 0,
  // A out
  0, 0, 0, 1, 0,
];
```

- [ ] **Step 2: Add `useOwnBackdrop` param to `GlassCard`**

Find the `GlassCard` constructor. Add a new optional named param:

```dart
const GlassCard({
  super.key,
  required this.child,
  this.tier = GlassTier.card,
  this.padding = const EdgeInsets.all(AppSizes.md),
  this.borderRadius,
  this.tintColor,
  this.showBorder = true,
  this.showShadow = false,
  this.gradient,
  this.onTap,
  this.margin,
  this.useOwnBackdrop,   // NEW
});
```

Add the field:

```dart
/// Whether this card paints its own `BackdropFilter` region.
///
/// `null` (default) → derived from tier: tier-1 sheets blur (true),
/// tier-2 cards and tier-3 insets do NOT blur on their own (false). A
/// parent surface owns the backdrop instead — see
/// `BalanceHeader`, `TransactionSliverList`, `AppNavBar`.
///
/// Override to `true` for an isolated tier-2 card whose parent does
/// not own a backdrop (e.g., the dashboard insight card).
final bool? useOwnBackdrop;
```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze lib/shared/widgets/cards/`
Expected: zero errors. The unused field will warn — that's fine, Task 13 wires it up.

- [ ] **Step 4: Commit**

```bash
git add lib/shared/widgets/cards/glass_card.dart
git -c commit.gpgsign=false commit -m "feat: add useOwnBackdrop param + saturation matrix to GlassCard"
```

---

## Task 13: GlassCard — refactor build() with corrected backdrop API + top inset highlight

**Files:**
- Modify: `lib/shared/widgets/cards/glass_card.dart`

- [ ] **Step 1: Refactor `build()` body**

Replace the entire `build()` method with:

```dart
@override
Widget build(BuildContext context) {
  final theme = context.appTheme;
  final radius =
      borderRadius ?? BorderRadius.circular(AppSizes.borderRadiusMd);
  final canBlur = GlassConfig.shouldBlur(context);

  // Resolve tier-based properties.
  final double sigma;
  final Color surface;
  final Color border;
  final double borderWidth;
  switch (tier) {
    case GlassTier.background:
      sigma = AppSizes.glassBlurBackground;
      surface = theme.glassSheetSurface;
      border = theme.glassSheetBorder;
      borderWidth = AppSizes.glassBorderWidthSubtle;
    case GlassTier.card:
      sigma = AppSizes.glassBlurCard;
      surface = theme.glassCardSurface;
      border = theme.glassCardBorder;
      borderWidth = AppSizes.glassBorderWidth;
    case GlassTier.inset:
      sigma = AppSizes.glassBlurInset;
      surface = theme.glassInsetSurface;
      border = theme.glassInsetBorder;
      borderWidth = AppSizes.glassBorderWidth;
  }

  // Derive blur policy.
  // Default per tier:
  //   background → own backdrop (sheet/dialog isolated)
  //   card / inset → DO NOT own backdrop (parent owns it)
  final defaultOwnsBackdrop = tier == GlassTier.background;
  final ownsBackdrop = useOwnBackdrop ?? defaultOwnsBackdrop;

  // Merge tint colour with base surface if provided.
  final effectiveSurface =
      tintColor != null ? Color.alphaBlend(tintColor!, surface) : surface;

  final decoration = BoxDecoration(
    color: gradient == null ? effectiveSurface : null,
    gradient: gradient,
    borderRadius: radius,
    border: showBorder ? Border.all(color: border, width: borderWidth) : null,
    boxShadow: showShadow
        ? <BoxShadow>[
            BoxShadow(
              color: theme.glassShadow,
              blurRadius: AppSizes.cardShadowBlur,
              offset: const Offset(0, AppSizes.cardShadowOffsetY),
            ),
            // Single hairline top inset — the "light catches the rim" specular.
            BoxShadow(
              color: AppColors.white.withValues(alpha: 0.7),
              blurRadius: 0,
              offset: const Offset(0, AppSizes.glassTopHighlightInset),
              blurStyle: BlurStyle.inner,
            ),
          ]
        : null,
  );

  Widget content = Container(
    padding: padding,
    decoration: decoration,
    child: child,
  );

  // Wrap in BackdropFilter only when this card OWNS its backdrop and the
  // device supports blur. Otherwise: clip for rounded corners only.
  if (ownsBackdrop && canBlur) {
    content = RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: ColorFiltered(
            // Saturation applied to the blurred backdrop bleed-through.
            // NOTE: this also tints the foreground content slightly. If
            // that proves visually wrong on real device, drop this
            // ColorFiltered wrapper and accept blur-only frost.
            colorFilter: const ColorFilter.matrix(_kSaturate160Matrix),
            child: content,
          ),
        ),
      ),
    );
  } else {
    content = ClipRRect(
      borderRadius: radius,
      child: content,
    );
  }

  if (margin != null) {
    content = Padding(padding: margin!, child: content);
  }

  if (onTap != null) {
    content = Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      ),
    );
  }

  return content;
}
```

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze lib/shared/widgets/cards/`
Expected: zero errors.

- [ ] **Step 3: Run app and visually verify**

Run: `flutter run -d <device>`
Open Dashboard. Expected:
- Insight card and any other tier-2 GlassCards still render but **without** their own backdrop blur. They show low-fill white tint on the gradient (the per-card backdrops will be claimed by parents in subsequent tasks).
- Bottom sheets (tier 1) still blur correctly.
- No regression in low-end fallback (`GlassConfig.shouldBlur`).

- [ ] **Step 4: Empirical saturation check**

Watch for unwanted tint on text/icons inside cards. If text colours look noticeably saturated, **revisit step 1**: remove the `ColorFiltered` wrapper, replace with just `BackdropFilter` directly. Document the decision in the file's header docstring.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/cards/glass_card.dart
git -c commit.gpgsign=false commit -m "refactor: GlassCard backdrop policy + top-inset specular"
```

---

## Task 14: BalanceHeader — single hero backdrop + soft divider

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/balance_header.dart`

- [ ] **Step 1: Wrap the whole hero in one BackdropFilter region**

Find the outer `Container` in `BalanceHeader.build()` (line ~61). Replace the existing `Container(decoration: BoxDecoration(...), padding: ..., child: Column(...))` with:

```dart
return RepaintBoundary(
  child: ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: AppSizes.glassBlurCard,
        sigmaY: AppSizes.glassBlurCard,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.glassCardSurface,
          // Soft fade replaces the hard 1px bottom border.
          // Gradient bottom-side decoration: solid border colour at top edge,
          // transparent at bottom — creates a gentle visual separator.
        ),
        padding: const EdgeInsetsDirectional.only(
          start: AppSizes.screenHPadding,
          end: AppSizes.screenHPadding,
          top: AppSizes.xl,
          bottom: AppSizes.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... existing children unchanged ...
          ],
        ),
      ),
    ),
  ),
);
```

Add the import at the top:

```dart
import 'dart:ui' show ImageFilter;
```

- [ ] **Step 2: Add a soft divider below the hero**

Right after the closing `)` of the `Container` (still inside the `BackdropFilter`'s child position), wrap the hero in a `Stack` and overlay a 12px gradient strip:

Actually simpler: inside the hero `Container`'s `Column`, append after the last child:

```dart
const SizedBox(height: AppSizes.md),
// Soft fade divider — replaces hard bottom border.
Container(
  height: AppSizes.glassBorderWidth,
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        theme.glassCardBorder.withValues(alpha: 0),
        theme.glassCardBorder,
        theme.glassCardBorder.withValues(alpha: 0),
      ],
      stops: const [0.0, 0.5, 1.0],
    ),
  ),
),
```

- [ ] **Step 3: Tell GlassCard children inside the hero to skip their own backdrop**

The Cash card uses `GlassCard(tier: GlassTier.inset, ...)` — tier-3 default already does NOT own a backdrop, so no change needed.

The Income/Expense pills are not GlassCards (they're DecoratedBox in `_GlassPill`). No change needed.

The account selector pill uses a Container with surfaceContainerLow — it's not a GlassCard, no per-element blur to disable.

**No further child changes required for this task.**

- [ ] **Step 4: Run analyzer + visual check**

Run: `flutter analyze lib/features/dashboard/`
Expected: zero errors.

Run: `flutter run -d <device>`
Open Dashboard. Expected:
- Hero region is now glassy — the gradient blurs visibly behind the balance number.
- Income/Expense pills still tint with their semantic colour but no double-blur effect.
- Cash card glass is subtle.
- Bottom of hero blends into the body via the gradient strip — no hard line.

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/widgets/balance_header.dart
git -c commit.gpgsign=false commit -m "feat: BalanceHeader claims single backdrop region + soft divider"
```

---

## Task 15: FilterBar — solid-tinted chips (no per-chip blur)

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/filter_bar.dart`

The chips use `ChoiceChip`. Material's `ChoiceChip` already paints a solid background — the chip theme override in Task 10 (`chipBlendColors: false`, `chipRadius: borderRadiusSm`) covers most of this. Confirm the chip styling matches the v7 mockup.

- [ ] **Step 1: Verify chip styling**

For each `ChoiceChip(...)` instance in `filter_bar.dart`:
- `selectedColor` should be `cs.primary` (already true for type chips).
- For unselected: ensure `backgroundColor` is **not** explicitly set (so it falls back to the theme override).

If any chip has an inline `backgroundColor:` override, remove it and let theme take over. If any has `side: BorderSide(color: cs.outline.withValues(alpha: ...))` — keep it; that's the hairline border per mockup.

- [ ] **Step 2: Run analyzer + visual check**

Run: `flutter analyze lib/features/dashboard/`

Open Dashboard, observe the filter bar:
- "All" chip: solid mint primary fill, white text.
- Other type chips: low-alpha white tint (theme default), hairline outline.
- Top category chips: existing per-category colour at low alpha.
- No backdrop blur per-chip (the gradient still shows through softly via the low-alpha fill).

- [ ] **Step 3: Commit (only if changes were needed)**

```bash
git add lib/features/dashboard/presentation/widgets/filter_bar.dart
git -c commit.gpgsign=false commit -m "refactor: FilterBar chips rely on theme override, no inline overrides"
```

If no changes were needed, skip the commit and proceed.

---

## Task 16: AppNavBar — single tier-1 backdrop region

**Files:**
- Modify: `lib/shared/widgets/navigation/app_nav_bar.dart`

- [ ] **Step 1: Find the AppNavBar build method**

Locate the `AppNavBar` widget's `build()`. The existing nav bar paints a solid surface from the `navigationBarTheme` (now transparent per Task 10).

- [ ] **Step 2: Wrap nav contents in a BackdropFilter**

Replace the outer return with:

```dart
return RepaintBoundary(
  child: ClipRect(
    child: BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: AppSizes.glassBlurBackground,
        sigmaY: AppSizes.glassBlurBackground,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.appTheme.glassSheetSurface,
          border: Border(
            top: BorderSide(
              color: context.appTheme.glassSheetBorder,
              width: AppSizes.glassBorderWidthSubtle,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: AppSizes.bottomNavHeight,
            child: NavigationBar(
              // ... existing NavigationBar config unchanged ...
            ),
          ),
        ),
      ),
    ),
  ),
);
```

Add imports if missing:

```dart
import 'dart:ui' show ImageFilter;
import '../../../core/extensions/build_context_extensions.dart';
```

- [ ] **Step 3: Run analyzer + visual check**

Run: `flutter analyze lib/shared/widgets/navigation/`

Open the app. Expected:
- Nav bar reads as a frosted glass strip pinned to bottom.
- Hairline top border separates it from the body.
- Active destination still highlights via theme defaults.

- [ ] **Step 4: Commit**

```bash
git add lib/shared/widgets/navigation/app_nav_bar.dart
git -c commit.gpgsign=false commit -m "feat: AppNavBar claims single tier-1 backdrop region"
```

---

## Task 17: TransactionSliverList — single tier-2 backdrop region

**Files:**
- Modify: `lib/features/dashboard/presentation/widgets/transaction_sliver_list.dart`

The transaction list renders many `TransactionCard` rows. Each row is a tier-2 surface. With the GlassCard refactor (Task 13), tier-2 default does NOT own a backdrop. So per-row blur is already off. Now we need ONE backdrop region wrapping the whole list.

- [ ] **Step 1: Wrap the SliverList in a SliverToBoxAdapter** ❌ — wrong approach, would lose lazy rendering.

Use `SliverFillRemaining`? Also wrong — list is paginated.

**Correct approach:** the list itself is built lazily and CANNOT be wrapped in a single BackdropFilter without forcing a layout/paint that evaluates all rows. Instead, paint the backdrop as a **viewport-sized fixed layer** behind the sliver list using `Stack` + `Positioned.fill` at the parent screen level (`DashboardScreen`).

Pivot the task:

- [ ] **Step 2: Add a backdrop layer at the dashboard screen scroll viewport**

In `lib/features/dashboard/presentation/screens/dashboard_screen.dart`, find the `Expanded` containing `RefreshIndicator → SlidableAutoCloseBehavior → CustomScrollView` (around line 180). Wrap the `CustomScrollView` in a `Stack`:

```dart
child: Stack(
  fit: StackFit.expand,
  children: [
    // Single tier-2 backdrop covering the scrollable region — the
    // transaction list and other list-region content show the
    // gradient through this one BackdropFilter instead of per row.
    Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: AppSizes.glassBlurCard,
            sigmaY: AppSizes.glassBlurCard,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ),
    // The actual scroll viewport.
    SlidableAutoCloseBehavior(
      child: CustomScrollView(
        // ... existing config ...
      ),
    ),
  ],
),
```

Add the import:

```dart
import 'dart:ui' show ImageFilter;
```

- [ ] **Step 3: Confirm transaction tiles do not double-blur**

In `lib/shared/widgets/cards/transaction_card.dart` (read it), find any `BackdropFilter` calls. There should be none — `TransactionCard` uses `GlassCard` or simple `Container`s. If it uses `GlassCard(tier: GlassTier.card)`, that now defaults to `useOwnBackdrop: false` (Task 13) and is correct. No change needed unless a transaction card explicitly sets `useOwnBackdrop: true`.

- [ ] **Step 4: Run analyzer + visual check**

Run: `flutter analyze lib/features/dashboard/`

Open Dashboard. Expected:
- Transaction list region is glassy — the gradient blurs softly behind the rows.
- Individual rows don't double-blur (no flicker / GPU stalls on scroll).

- [ ] **Step 5: Commit**

```bash
git add lib/features/dashboard/presentation/screens/dashboard_screen.dart
git -c commit.gpgsign=false commit -m "feat: dashboard scroll region claims single backdrop layer"
```

---

## Task 18: Audit `Scaffold(backgroundColor: ...)` overrides

**Files:**
- Modify (potentially): the 9 files listed below

Files with explicit `backgroundColor:` overrides on `Scaffold` (from §6 audit):

- `lib/features/transactions/presentation/screens/transaction_detail_screen.dart`
- `lib/features/hub/presentation/screens/hub_screen.dart`
- `lib/features/goals/presentation/screens/goal_detail_screen.dart`
- `lib/features/recurring/presentation/screens/recurring_screen.dart`
- `lib/features/wallets/presentation/screens/wallets_screen.dart`
- `lib/features/goals/presentation/screens/goals_screen.dart`
- `lib/features/ai_chat/presentation/screens/chat_screen.dart`
- `lib/features/onboarding/presentation/screens/splash_screen.dart`
- `lib/features/budgets/presentation/screens/budgets_screen.dart`

- [ ] **Step 1: For each file, evaluate the override**

For each file, run: `grep -n "backgroundColor" <file>` to locate the override.

For each match:
- **If `backgroundColor: AppColors.surface` or similar opaque → change to `Colors.transparent`** so the gradient flows through.
- **If `backgroundColor: cs.primary` or a vivid colour (likely a splash/onboarding intent) → keep**, but verify the screen looks right by running the app.
- **If `backgroundColor: cs.surfaceContainer` or another role-based colour → change to `Colors.transparent`**; the gradient is the new surface.

- [ ] **Step 2: Stage all changes and run analyzer**

Run: `flutter analyze lib/`
Expected: zero errors.

- [ ] **Step 3: Visual sanity-check each touched screen**

For each touched screen, navigate to it in the running app. Confirm gradient shows through the screen body and content remains legible.

- [ ] **Step 4: Commit**

```bash
git add lib/features/
git -c commit.gpgsign=false commit -m "refactor: scaffold overrides → transparent for gradient flow"
```

---

## Task 19: Same-day visual triage of primary tabs

**Files:** none — this is a verification + bug-log task

- [ ] **Step 1: Run app on a real device (or emulator with a recent OS image)**

Run: `flutter run -d <device>` then navigate every primary tab:
- **Dashboard** — already verified in Tasks 14, 17.
- **Reports**
- **Calendar**
- **Hub**

For each tab, confirm:
- Gradient flows through the screen
- Glass surfaces (cards, sheets) look right against the gradient
- Text remains AA-readable
- No raw `Card(...)` widgets stand out as opaque white blocks

- [ ] **Step 2: Run primary bottom-sheet flows**

- Add Transaction sheet
- Account picker sheet
- Filter sheet
- Sort sheet
- Voice overlay

Confirm sheets render with tier-1 glass (more opaque than cards, but still glassy).

- [ ] **Step 3: Triage**

Categorise issues found into:
1. **Blocks merge** — broken layouts, illegible text, GPU stalls. Add as Task 20+ in this plan and fix before continuing.
2. **Phase 2** — minor cosmetic polish on a screen that still functions correctly. Log under `docs/superpowers/specs/2026-05-03-theme-revamp-design.md` Phase 2 list as a follow-up.

If anything blocks merge, write the new tasks here with code, then proceed.

- [ ] **Step 4: Commit triage notes (only if Phase 2 list grew)**

```bash
git add docs/superpowers/specs/2026-05-03-theme-revamp-design.md
git -c commit.gpgsign=false commit -m "docs: theme revamp Phase 2 triage notes"
```

---

## Task 20: Final verification — Home matches v7 mockup

**Files:** none — this is a verification task

- [ ] **Step 1: Open both at once**

In the visual companion: open `.superpowers/brainstorm/414-1777805942/content/home-mint-bubbly-v7.html` in a browser via http://localhost:52698 (or restart the brainstorm server with `bash skills/brainstorming/scripts/start-server.sh --project-dir D:/Masarify-Plus`).

Run the app on a device alongside.

- [ ] **Step 2: Compare element by element**

| Element | Mockup expectation | Live verify |
|---|---|---|
| Page background | Cool mint top → white bottom | ✅/❌ |
| App bar | Dashboard title + AI ✦ + ⚙ | ✅/❌ |
| Balance number | 38sp, tabular figures, `-0.9px` tracking | ✅/❌ |
| Income / Expense pills | Tinted glass, semantic icons, semantic amounts | ✅/❌ |
| Cash card | Amber-bordered glass, filled icon, balance | ✅/❌ |
| Account selector pill | Translucent fill, hairline border | ✅/❌ |
| Insight card | Glass with low fill, accent icon container, dismiss × | ✅/❌ |
| Filter chips | Active = solid mint; rest = tinted glass with outline | ✅/❌ |
| Date headers | "Today · May 3", net subtotal in semantic colour | ✅/❌ |
| Transaction tiles | Accent bar left, icon container 14px, semantic amount | ✅/❌ |
| Bottom nav | Frosted strip with hairline top border, central FAB | ✅/❌ |
| FAB | Mint gradient circle, ~52dp, raised | ✅/❌ |

- [ ] **Step 3: Run analyzer one final time**

Run: `flutter analyze lib/`
Expected: zero errors.

- [ ] **Step 4: Run all tests**

Run: `flutter test`
Expected: all green.

- [ ] **Step 5: Commit if any final tweaks were made**

If any element didn't match and you tweaked tokens to bring it in line:

```bash
git add <touched-files>
git -c commit.gpgsign=false commit -m "polish: align Home to v7 mockup"
```

- [ ] **Step 6: Mark Phase 1 done**

Update the spec's Phase 1 checklist (`docs/superpowers/specs/2026-05-03-theme-revamp-design.md`) — tick all the boxes:

```bash
# Edit the spec file, replace [ ] with [x] for completed Phase 1 items
git add docs/superpowers/specs/2026-05-03-theme-revamp-design.md
git -c commit.gpgsign=false commit -m "docs: theme revamp Phase 1 complete"
```

---

## Self-review summary

**Spec coverage check (each spec section → task):**
- §3 Visual direction (v7) → Tasks 2–6 (tokens) + 14, 17 (parents)
- §4.1 Color tokens → Tasks 2, 3, 4
- §4.2 Size tokens → Task 5
- §4.3 Typography + tabular figures → Tasks 1, 6
- §5.1 GlassCard refactor → Tasks 12, 13
- §5.2 GradientBackground → Tasks 7, 8, 9
- §5.3 AppScaffoldShell → Task 11
- §5.4 AppTheme → Task 10
- §5.5 Per-screen scaffold audit → Task 18
- §5.6 BalanceHeader divider + hero backdrop → Task 14
- §5.7 Filter chips → Tasks 10 (theme override) + 15
- AppNavBar (in §11 file list, not its own §) → Task 16
- TransactionSliverList (in §11 file list) → Task 17
- §6 Same-day triage → Task 19
- §6 Home verification → Task 20
- §7 Dark mode → covered by Tasks 2, 3, 4, 9 (all light/dark parallel)
- §9 GPU performance benchmark → Phase 2 deliberately, noted in Task 19
- §11 File touch list → Tasks 1–17 collectively

All spec sections have at least one task. No gaps.

**Placeholder scan:** No "TODO", "TBD", "implement later" remain. The phrase "Phase 2" is used intentionally as deferred scope, not as a placeholder.

**Type / API consistency:**
- `useOwnBackdrop` named consistently across Tasks 12, 13, 14, 17.
- `GradientBackground` import path consistent across Tasks 9, 11.
- `BloomSpec`, `BloomPainter` names consistent across Tasks 7, 8, 9.
- `_kSaturate160Matrix` consistent within `glass_card.dart`.

---

## Out of scope for this plan
- Performance benchmark on Pixel 4a — Phase 2 (see spec §6).
- Onboarding splash treatment — Phase 2.
- Per-screen polish for tabs flagged in Task 19 triage — those become individual follow-up specs/plans if surfacing.
