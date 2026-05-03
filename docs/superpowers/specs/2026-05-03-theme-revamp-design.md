# Theme Revamp — Design Spec

**Date:** 2026-05-03
**Owner:** Omar Ghazal
**Status:** Awaiting review
**Validated by:** Visual companion iterations v1 → v7 (saved under `.superpowers/brainstorm/`)
**Reference aesthetic:** Paperpillar — *Smart Calendar App* (Dribbble shot 13842720) — pastel gradient + frosted glass on cool surfaces

---

## 1. Summary

Refresh the entire visual system — light + dark — around three changes:

1. **Page background:** static surface → cool pastel gradient that falls into white at the bottom (light) and into deep noir at the bottom (dark).
2. **Frosted-glass surfaces:** today's mint-tinted glass → refined low-fill, high-blur, hairline-bordered glass; gradient bleeds through cleanly.
3. **Brand cohesion:** keep mint primary across both themes — drop the dark-mode purple personality so light and dark are one identity that flexes.

**Layout, structure, widgets, and information architecture do not change.** This is a surface, palette, and atmosphere revamp — not a redesign. Existing widgets (`BalanceHeader`, `_GlassPill`, `TransactionCard`, `FilterBar`, `AppNavBar`, etc.) keep their structure; their tokens are re-skinned.

**Phase 1 (this spec) ships:** new tokens, refactored `GlassCard`, new `GradientBackground` shell widget, and applies the result to the **Home / Dashboard** screen + global theme. Other screens inherit automatically through the token + scaffold changes.

---

## 2. Why

The current app has two issues that compound:

- **Dual-personality split** — Minty Fresh (light) and Gothic Noir purple (dark) read as two different products. Users moving between OS themes lose brand continuity.
- **Glass tier 2 reads opaque** — `glassCardSurface` at 87 % alpha with a green tint covers the surface beneath. Cards feel like solid panels, not glass. The surface beneath them (a flat mint white) is also uninteresting, so even a transparent card has nothing worth showing through.

The revamp fixes both with one move: a soft pastel gradient surface gives the page real visual interest, and a refined low-fill glass treatment lets that interest show through. Cohesion comes from keeping mint primary in both modes.

---

## 3. Visual direction (validated)

The full visual was validated in browser mockups v1 → v7. Final direction = **v7**:

- Page background: vertical gradient `#DFF6E5 → #C8F2EE → #C9EBD3 → #E0F2E5 → #EFF8F1 → #F8FCF9 → #FFFFFF` plus three radial blooms (cool aqua upper-left, mint upper-right, cool white lower-center)
- Glass cards: `rgba(255,255,255,0.24)` fill, `BackdropFilter` σ=32 with `saturate(1.6)`, hairline border `rgba(255,255,255,0.36)`, single soft shadow `0 12px 32px rgba(15,30,50,0.05)`, single 0.5 px top inset highlight `rgba(255,255,255,0.7)`
- Pills/buttons follow the same recipe at smaller σ (20–24)
- Active filter chip = solid mint primary `#3DA37A` with a soft mint shadow (the only non-glass surface)
- All numerals: `tabular-nums`
- Balance display: `letter-spacing: -0.9px`
- Drop shadow color: cool slate `rgba(15,30,50, 0.04–0.06)` — not mint-tinted

**Semantic colors stay** — income green, expense red, transfer blue, cash amber. Only the brand surface palette and glass tokens move.

---

## 4. Token changes

### 4.1 `app_colors.dart`

| Token | Before | After |
|---|---|---|
| `surface` (kept as a Color constant) | `#F5FBF8` mint white | `#EFF8F1` near-white mint — used only as the **reduce-transparency fallback** scaffold color |
| `surfaceDark` (same role) | `#1A1A1A` | `#0E2820` deep mint container — reduce-transparency fallback |
| `glassCardSurfaceLight` | `#DEF5FBF8` (mint, 87%) | `#3DFFFFFF` (white, ~24%) |
| `glassCardBorderLight` | `#14FFFFFF` (white, 8%) | `#5CFFFFFF` (white, 36%) |
| `glassSheetSurfaceLight` | `#B3F5FBF8` (mint, 70%) | `#A6FFFFFF` (white, 65%) — sheets need legibility on busy backdrops |
| `glassSheetBorderLight` | `#0DFFFFFF` (5%) | `#5CFFFFFF` (36%) |
| `glassShadowLight` | `#1A3DA37A` (mint at 10%) | `#0F0F1E32` (slate at ~6%) |
| `gradientStartLight` / `gradientEndLight` | mint pair | **removed** — superseded by `gradientLightStops` |
| `backgroundDark` | `#0E0E0E` true noir | `#06140F` deep mint forest (dark gradient top stop) |
| `primaryDark` | `#6B5B95` muted purple | `#5BC197` mint glow (matches light primary) |
| `primaryContainerDark` | `#2D2344` dark violet | `#143A2B` deep mint container |
| `secondaryDark` / `tertiaryDark` etc. | mauve / rose-gold pair | derive from same mint family — drop purple identity |
| `glassCardSurfaceDark` | `#DE1E1E2A` | `#14FFFFFF` (white at 8% on dark — frosted) |
| `glassCardBorderDark` | `#1AFFFFFF` | `#33FFFFFF` (white at 20%) |
| `glassShadowDark` | `#1A7B68AE` (purple) | `#33000000` (black at 20%, deeper for depth on dark) |

The actual scaffold-background swap happens in `AppTheme` (§5.4): `scaffoldBackgroundColor: AppColors.surface` → `Colors.transparent`. The `AppColors.surface` constant survives as a fallback for users with reduce-transparency enabled.

**New constants:**

```dart
/// Top-to-bottom gradient stops for the global page background.
static const List<Color> gradientLightStops = [
  Color(0xFFDFF6E5), // 0%   mint cream
  Color(0xFFC8F2EE), // 18%  aqua mist
  Color(0xFFC9EBD3), // 38%  mint pastel
  Color(0xFFE0F2E5), // 58%  soft mint
  Color(0xFFEFF8F1), // 76%  near-white mint
  Color(0xFFF8FCF9), // 90%  almost white
  Color(0xFFFFFFFF), // 100% white
];
static const List<double> gradientStops = [0.0, 0.18, 0.38, 0.58, 0.76, 0.90, 1.0];

static const List<Color> gradientDarkStops = [
  Color(0xFF06140F), // 0%   deep mint forest (top)
  Color(0xFF0A1F18), // 18%
  Color(0xFF0E2820), // 38%
  Color(0xFF0B1F19), // 58%
  Color(0xFF080E0C), // 76%
  Color(0xFF050807), // 90%
  Color(0xFF000000), // 100% true black (bottom)
];

/// Radial bloom colors painted on top of the linear gradient.
static const Color bloomAquaLight  = Color(0xE6C8F2EE);
static const Color bloomMintLight  = Color(0xDDB7E8D2);
static const Color bloomWhiteLight = Color(0xD9FFFFFF);

static const Color bloomMintDark   = Color(0x335BC197);
static const Color bloomTealDark   = Color(0x2614C4A0);
```

### 4.2 `app_sizes.dart`

| Token | Before | After |
|---|---|---|
| `glassBlurCard` (tier 2) | `12.0` | `32.0` |
| `glassBlurInset` (tier 3) | `8.0` | `20.0` |
| `glassBorderWidth` | `1.0` | unchanged |
| `glassBorderWidthSubtle` | `0.5` | unchanged |
| `cardShadowBlur` | `12.0` | `32.0` |
| `cardShadowOffsetY` | `4.0` | `12.0` |

**New:**

```dart
/// Backdrop saturation multiplier used with the glass blur for chromatic
/// frosting (Paperpillar reference).
static const double glassBackdropSaturation = 1.6;

/// Single inset highlight thickness on the top edge of a glass card.
static const double glassTopHighlightInset = 0.5;
```

### 4.3 `app_text_styles.dart`

| Style | Before | After |
|---|---|---|
| `displayLarge` | `letterSpacing: -0.5` | `letterSpacing: -0.9` (tighter, more confident) |
| All numeric-displaying styles | n/a | apply `fontFeatures: [FontFeature.tabularFigures()]` via the `MoneyFormatter` rendering path or the textTheme |

The cleanest route is to add `fontFeatures` to `displayLarge`, `headlineLarge`, `titleLarge`, `bodyLarge` so any number renders tabular without per-callsite changes.

---

## 5. Component changes

### 5.1 `lib/shared/widgets/cards/glass_card.dart`

**Goal:** make the visual recipe match the spec without breaking the existing tier API or performance fallback.

Inside `build()`, after computing `surface` / `border` per tier:

```dart
final decoration = BoxDecoration(
  color: gradient == null ? effectiveSurface : null,
  gradient: gradient,
  borderRadius: radius,
  border: showBorder
      ? Border.all(color: border, width: borderWidth)
      : null,
  boxShadow: showShadow
      ? [
          BoxShadow(
            color: theme.glassShadow,
            blurRadius: AppSizes.cardShadowBlur,
            offset: const Offset(0, AppSizes.cardShadowOffsetY),
          ),
          // NEW — top inset highlight (gives glass its specular)
          BoxShadow(
            color: AppColors.white.withValues(alpha: 0.7),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, AppSizes.glassTopHighlightInset),
            blurStyle: BlurStyle.inner,
          ),
        ]
      : null,
);
```

The `BackdropFilter` call already exists for the `background` tier. **Extend it to tier 2 (`card`)** as well — the existing skip on Android was added because stacked filters caused GPU overload. The new tokens still allow several simultaneous filters per screen (Home displays roughly 6–9 glass surfaces at once: hero region, Cash card, two pills, account selector, insight, transaction tiles, nav bar). Keep the `GlassConfig.shouldBlur` opt-out path: when it returns false, all tiers fall back to the higher fill-alpha path that's already in place — cards remain readable without `BackdropFilter`.

Update `BackdropFilter` to include saturation:

```dart
filter: ImageFilter.compose(
  outer: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
  inner: const ColorFilter.matrix(_kSaturate1_6Matrix),
),
```

(`_kSaturate1_6Matrix` is a small 4×5 matrix constant defined at the top of the file.)

### 5.2 New: `lib/shared/widgets/backgrounds/gradient_background.dart`

```dart
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Linear vertical gradient (mint → white in light, mint forest → black in dark)
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: const Alignment(0, -1.0),
              end: const Alignment(0, 1.0),
              colors: isDark ? AppColors.gradientDarkStops : AppColors.gradientLightStops,
              stops: AppColors.gradientStops,
            ),
          ),
        ),
        // Three radial blooms — softened depth
        Positioned.fill(
          child: CustomPaint(painter: _BloomPainter(isDark: isDark)),
        ),
        child,
      ],
    );
  }
}
```

`_BloomPainter` paints three radial gradients at fixed alignments matching v7. RTL-safe (positions are alignment fractions, not pixel offsets).

### 5.3 `lib/shared/widgets/navigation/app_nav_bar.dart` — `AppScaffoldShell`

Wrap `widget.navigationShell` in `GradientBackground`:

```dart
final scaffold = Scaffold(
  extendBody: true,
  backgroundColor: Colors.transparent, // gradient shows through
  body: GradientBackground(child: widget.navigationShell),
  ...
);
```

Set `extendBody: true` so the gradient flows under the bottom nav.

The bottom nav surface itself becomes a frosted-glass strip — replace its current solid fill with a glass treatment matching tier 1 (sheets). Top edge gets the same hairline border as cards.

### 5.4 `lib/app/theme/app_theme.dart`

- Set `scaffoldBackgroundColor: Colors.transparent` for both light and dark themes.
- Drop the existing `surfaceMode`/`blendLevel` — they generate tinted neutrals we no longer want.
- The dark theme drops the purple `primaryDark`/`primaryContainerDark`/`secondaryDark` tokens and uses the new mint-forest variants.

### 5.5 Per-screen Scaffolds

Audit every `Scaffold(...)` callsite to confirm `backgroundColor: Colors.transparent` (the theme default does this; only inline overrides need fixing). The Home dashboard, AppAppBar, and existing widget tree need no structural changes.

### 5.6 `BalanceHeader` — single small fix

Replace the hard `border: Border(bottom: BorderSide(color: theme.glassCardBorder))` with a soft fade — either drop the bottom border entirely (rely on the gradient transition) or use a `LinearGradient`-painted divider via `BoxDecoration`. Bottom border is the only thing that visually fences the hero off; everything else carries.

### 5.7 Filter chips (`FilterBar`)

Material's `ChoiceChip` doesn't support backdrop blur natively. Two options:
- **A (preferred):** wrap each `ChoiceChip` with `GlassChipDecorator` — a small `ClipRRect` + `BackdropFilter` that paints the glass surface behind the unselected chip. The selected chip stays solid mint primary.
- **B:** rebuild as a custom `GlassChip` widget. Heavier change, fully controllable.

Phase 1 takes A — minimal blast radius.

---

## 6. Scope

### Phase 1 (this spec)
- [ ] All token changes in §4 (light + dark palette + sizes + text)
- [ ] `GlassCard` refactor (§5.1)
- [ ] `GradientBackground` widget + `_BloomPainter` (§5.2)
- [ ] `AppScaffoldShell` wraps with `GradientBackground` and goes transparent (§5.3)
- [ ] `AppTheme` drops `surfaceMode`/`blendLevel`, scaffold becomes transparent (§5.4)
- [ ] `BalanceHeader` divider softened (§5.6)
- [ ] `FilterBar` chips get `GlassChipDecorator` (§5.7)
- [ ] `AppNavBar` goes glassy at tier 1
- [ ] Audit & fix any `Scaffold(backgroundColor: ...)` overrides
- [ ] Verify Home / Dashboard screen visually matches v7

### Phase 2 (future spec)
- Per-screen visual audit: Reports, Hub, Calendar, Wallets, Goals, Subscriptions, Settings, AI Chat — confirm they read correctly on the new gradient. Most should "just work" because they already use `GlassCard`.
- Bottom-sheet treatments review
- Onboarding splash treatment with the new palette
- Performance pass on low-end Android (verify `GlassConfig.shouldBlur` fallback is still acceptable)

### Out of scope
- Layout / structural changes to any screen
- Information architecture
- Iconography (Phosphor stays)
- Typography family change (Plus Jakarta Sans stays)
- New features
- Dark-mode toggle UX

---

## 7. Dark mode

The dark mode mirrors the structure of light:

- Page gradient: deep mint forest (`#06140F`) at the top → true black (`#000`) at the bottom, with two soft mint glows as radial blooms (low alpha so dark stays moody)
- Glass cards: `rgba(255,255,255,0.08)` fill, blur σ=32, hairline `rgba(255,255,255,0.20)`, single black shadow
- Mint primary stays as the brand color — the FAB and active states glow against the deep forest
- Income/expense semantic colors lighten for AA contrast on dark (existing `incomeGreenDark`/`expenseRedDark` tokens already do this — keep them)
- The previous "Gothic Noir" purple identity is retired

**Why:** the user's primary direction was *cohesion* (Question 1, Option A). One brand identity that flexes between modes is the cleanest answer.

---

## 8. RTL

The gradient is vertical and the radial blooms are placed at alignment fractions (e.g., `Alignment(-0.65, -0.85)` for the upper-left bloom). RTL is automatically handled — Flutter mirrors `EdgeInsetsDirectional` and friends, and our gradient/blooms use `Alignment` (which is *not* mirrored, by design).

Per-widget RTL audit on the Home screen during implementation: `BalanceHeader` already uses `EdgeInsetsDirectional`, the Cash card icon stays on the start side, the Income/Expense pills stack horizontally and mirror correctly. Confirm in Arabic locale before claiming done.

---

## 9. Accessibility & performance

### Contrast
- Body text on glass: today `cs.onSurface` ≈ `#0F3D2C` on a tinted-glass-over-pastel composition. Worst-case contrast (text over a pure mint pastel patch) measures ~9:1 — passes AAA.
- Income/expense semantic colors keep their existing AA-rated values.
- Active filter chip uses solid mint primary on white text — verify AA ≥ 4.5:1 (existing primary already passes).

### Reduce-motion / Reduce-transparency
The existing `GlassConfig.shouldBlur` already disables `BackdropFilter` on low-end devices and respects MediaQuery `disableAnimations`. We extend the same opt-out to honor a (new) "Reduce transparency" setting if the OS exposes one (iOS does via `accessibilityReduceTransparency`; Android exposes a `removeAnimations` flag we already check). When opted out:
- Glass surfaces fall back to a more opaque mint-white (`#FFFFFF` at 88%) on light, deep mint at 88% on dark
- Gradient page is replaced with the brightest stop solid (`#EFF8F1` light, `#0E2820` dark)

### GPU
The gradient + blooms paint once per frame (not animated). `_BloomPainter` is a single `CustomPaint` with three radial gradient draws — well within budget. The blur sigma jump (12 → 32) is the real cost: it scales roughly with sigma². On the Home screen this means roughly 6–9 simultaneous `BackdropFilter` regions, which is within budget on a Pixel 6 / iPhone 13-class device but warrants a benchmark on Pixel 4a / Samsung A-series before merging. If we see regressions, the `GlassConfig.shouldBlur` opt-out already exists and is the right fallback lever.

---

## 10. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Stacked `BackdropFilter` regression on Android low-end | Med | Keep `GlassConfig.shouldBlur` fallback — already in `GlassCard`. Extend the legibility fallback to use higher fill alpha. Test on a Pixel 4a / Samsung A-series before ship. |
| Existing screens look wrong on the new gradient (e.g., `Card` widgets without `GlassCard` treatment) | Med | Phase 2 visual audit. Most card surfaces use `GlassCard`; the few `Card` widgets become a Phase 2 mop-up. |
| Tabular numerals applied via `fontFeatures` change line metrics | Low | Plus Jakarta Sans tabular figures match the proportional figures in advance width. Quick eyeball pass during Phase 1. |
| Purple → mint identity in dark mode will surprise existing users | Low (single user) | Single dev/owner, no public users yet. |
| `LinearGradient` with 7 stops + 3 radial blooms looks heavy | Low | Validated visually in v7. If it feels noisy on real device, reduce to a 3-stop linear + 1 bloom. |

---

## 11. File touch list (Phase 1)

**Modified:**
- `lib/app/theme/app_colors.dart`
- `lib/app/theme/app_text_styles.dart`
- `lib/app/theme/app_theme.dart`
- `lib/app/theme/app_theme_extension.dart`
- `lib/core/constants/app_sizes.dart`
- `lib/shared/widgets/cards/glass_card.dart`
- `lib/shared/widgets/navigation/app_nav_bar.dart`
- `lib/features/dashboard/presentation/widgets/balance_header.dart`
- `lib/features/dashboard/presentation/widgets/filter_bar.dart`

**Added:**
- `lib/shared/widgets/backgrounds/gradient_background.dart`
- `lib/shared/widgets/backgrounds/_bloom_painter.dart` (private companion)
- `lib/shared/widgets/cards/glass_chip_decorator.dart`

---

## 12. Open questions

These don't block writing the implementation plan, but worth surfacing:

1. **Bloom positioning under different aspect ratios** — tablets and foldables. Mockup is phone-portrait. Likely fine via alignment fractions, but verify on a tablet emulator early.
2. **Should the gradient animate subtly?** A 30-second slow drift through the bloom positions is feasible at zero perceptual cost but adds an `AnimationController` to the shell. **Recommendation: no**, ship it static, revisit if it feels too still.
3. **Glass-chip decorator behavior when chip is selected** — confirm we want zero blur behind the active mint chip, or a faint blur to keep it consistent. **Recommendation: zero blur, solid mint.**
4. **Do we keep the existing dark-mode entry point names** (`AppColors.primaryDark` etc.) or rename them now that purple is gone? **Recommendation: keep names, just change values** — minimizes diff size and downstream breakage.
