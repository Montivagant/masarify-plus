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
  Color(0xFF080E0C), // 100% near-black (kept above pure black to preserve foreground contrast)
];

/// Radial bloom colors painted on top of the linear gradient.
/// Positions: see [GradientBackground._kBloomPositions].
static const Color bloomAquaLight  = Color(0xE6C8F2EE);
static const Color bloomMintLight  = Color(0xDDB7E8D2);
static const Color bloomWhiteLight = Color(0xD9FFFFFF);

static const Color bloomMintDark   = Color(0x335BC197);
static const Color bloomTealDark   = Color(0x2614C4A0);
```

**Note on dark token names** (`primaryDark`, `secondaryDark`, `tertiaryDark`, etc.): names are kept, values change. They describe Material 3 *slot meaning* (primary / secondary / tertiary roles), not hue. A doc comment in `app_colors.dart` will explain the rebrand from purple to mint to prevent future confusion when reading values like `primaryDark = #5BC197`.

### 4.2 `app_sizes.dart`

| Token | Before | After |
|---|---|---|
| `glassBlurCard` (tier 2) | `12.0` | `28.0` |
| `glassBlurInset` (tier 3) | `8.0` | unchanged (insets stay light) |
| `glassBorderWidth` | `1.0` | unchanged |
| `glassBorderWidthSubtle` | `0.5` | unchanged |
| `cardShadowBlur` | `12.0` | `32.0` |
| `cardShadowOffsetY` | `4.0` | `6.0` (subtle float — refined glass should not announce itself) |

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
| `displayLarge` | `fontSize: 32, letterSpacing: -0.5` | `fontSize: 38, letterSpacing: -0.9` (matches v7 mockup) |

**Tabular figures.** The mockup specifies tabular numerals on amounts so columns of money align cleanly. Plus Jakarta Sans (loaded via `google_fonts`) **must be verified to expose the `tnum` OpenType feature** before we ship — Google Fonts can serve subset variants without it. Verification step (in implementation):

```dart
final ts = GoogleFonts.plusJakartaSans(
  fontFeatures: const [FontFeature.tabularFigures()],
);
// Render '8888' twice — once tabular, once proportional — and visually confirm advance widths match.
```

If Plus Jakarta Sans on Google Fonts does **not** ship `tnum`, fall back to applying `FontFeature.proportionalFigures()` is a no-op and we either:
- (a) Self-host Plus Jakarta Sans with the full feature table, **or**
- (b) Accept proportional figures and pad amounts in `MoneyFormatter` to a fixed character grid.

Implementation should choose (a) if file size is acceptable; the spec doesn't pre-decide.

**Where the feature is applied.** Once verified, add `fontFeatures: [FontFeature.tabularFigures()]` to `displayLarge`, `headlineLarge`, `titleLarge`, `bodyLarge` in `AppTextStyles.sizeOverrides` so any number renders tabular without per-callsite changes.

---

## 5. Component changes

### 5.1 `lib/shared/widgets/cards/glass_card.dart`

**Goal:** match the visual recipe without breaking the existing tier API or performance fallback, and **without exceeding the documented 8-`BackdropFilter` GPU ceiling on Android**.

#### 5.1.1 Decoration

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
            blurRadius: AppSizes.cardShadowBlur,   // 32
            offset: const Offset(0, AppSizes.cardShadowOffsetY), // 6
          ),
          // Top inset highlight — single hairline, gives glass its specular.
          BoxShadow(
            color: AppColors.white.withValues(alpha: 0.7),
            blurRadius: 0,
            offset: const Offset(0, AppSizes.glassTopHighlightInset),
            blurStyle: BlurStyle.inner,
          ),
        ]
      : null,
);
```

#### 5.1.2 BackdropFilter — corrected API

The composed `ImageFilter.compose(outer: blur, inner: ColorFilter)` pattern in earlier drafts **does not compile** — `ColorFilter` is not an `ImageFilter` in Flutter's public API and cannot be passed as `inner`. The correct way to apply a saturation tint over a blurred backdrop is to layer two filters via nested widgets:

```dart
content = RepaintBoundary(
  child: ClipRRect(
    borderRadius: radius,
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: ColorFiltered(
        // Saturation matrix applied AFTER blur — affects the
        // already-blurred backdrop bleed-through, not the child UI.
        colorFilter: const ColorFilter.matrix(_kSaturate160Matrix),
        child: content,
      ),
    ),
  ),
);
```

`_kSaturate160Matrix` = a standard 4×5 saturation matrix at 1.6×, defined as a private const at the top of the file. **However:** if the `ColorFiltered` saturation step turns out to also tint the foreground content (it's a known caveat of layering this way), drop it — the blur alone delivers the dominant glass effect and the saturation is a polish nicety, not load-bearing. Decision is empirical, taken during implementation; spec does not commit to keeping saturation.

#### 5.1.3 BackdropFilter scope — the GPU ceiling

The current code skips blur for `card` and `inset` tiers because stacking 8+ filters caused Android GPU overload. The new design requires more glass than v0, so we **cannot** simply switch tier 2 on globally. Strategy:

| Surface | Blur strategy | Rationale |
|---|---|---|
| Sheets, dialogs, full-screen overlays (tier 1) | Blur ON (existing) | One filter per overlay, isolated |
| Hero region of Home (`BalanceHeader`) | Blur ON — single region wraps balance + pills + Cash card + selector | Use **one** `BackdropFilter` for the whole hero, not one per child. Children are translucent fills only. |
| Insight card (tier 2) | Blur ON | Single filter, ≤2 visible at once |
| Transaction list | **Blur OFF on individual tiles**. List sits in a single tier-2 backdrop region painted at the SliverList level. Tiles use translucent fill + hairline border only. | Eliminates 8+ filters on a scrolled list — biggest win. |
| Filter chips | **Blur OFF**. Chips become solid tinted surfaces (Material 3 `ChoiceChip` defaults with theme overlay). The active chip is solid mint primary. | 4 type chips + up to 3 category chips = 7 filters dropped. |
| Bottom nav strip | Blur ON — single region | One filter, always present |
| Quick-action pills (Income/Expense) | **Blur OFF**. Use the parent hero region's blur. Pills paint translucent fills. | 2 filters dropped |

**Net visible-filter count on Home:** hero (1) + insight (1) + tx-list region (1) + nav (1) = **4**, well under the 8-filter ceiling. Tier 1 sheets when open add 1 transient filter — still safe.

`GlassCard`'s public API does not change; the **default behavior** for tier 2 changes from "always skip blur" to "honor `GlassConfig.shouldBlur`". A new bool param `useOwnBackdrop` (default `true` for tier 1, `false` for tier 2/3) lets call-sites opt out when sitting inside a parent backdrop region. The hero, transaction list, and nav each set `useOwnBackdrop: true` on their wrapping `GlassCard`; their children pass `useOwnBackdrop: false`.

#### 5.1.4 Performance fallback

`GlassConfig.shouldBlur(context)` keeps its existing role. When it returns `false` (low-end Android, OS reduce-transparency on iOS), **all** tiers skip `BackdropFilter` and fall back to higher fill-alpha values (already implemented). Adds zero new fallback paths.

### 5.2 New: `lib/shared/widgets/backgrounds/gradient_background.dart`

```dart
class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});
  final Widget child;

  // Bloom positions, sizes, and colors are static — wrap in RepaintBoundary
  // so dashboard rebuilds (filter changes, scroll, refresh) do not repaint
  // the gradient layer.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
              child: CustomPaint(painter: _BloomPainter(isDark: isDark)),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
```

#### 5.2.1 Bloom positions (concrete)

Three radial gradients painted by `_BloomPainter`, alignments measured against the screen rect:

| Bloom | Alignment (light) | Radius (× shortest side) | Color |
|---|---|---|---|
| Aqua mist (upper-left) | `Alignment(-0.65, -0.85)` | 0.85 | `AppColors.bloomAquaLight` |
| Mint pastel (upper-right) | `Alignment(0.75, -0.65)` | 0.75 | `AppColors.bloomMintLight` |
| Cool white (lower-center) | `Alignment(0.0, 0.85)` | 0.95 | `AppColors.bloomWhiteLight` |

Dark mode uses two blooms only (cool white bloom replaced by gradient floor):

| Bloom | Alignment (dark) | Radius | Color |
|---|---|---|---|
| Mint glow (upper-left) | `Alignment(-0.65, -0.85)` | 0.85 | `AppColors.bloomMintDark` |
| Teal glow (upper-right) | `Alignment(0.75, -0.65)` | 0.75 | `AppColors.bloomTealDark` |

Positions are RTL-safe (`Alignment` is unaffected by reading direction by design — the bloom layout intentionally does not mirror).

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

Per the GPU strategy in §5.1.3, **chips do not blur**. Adding 7+ `BackdropFilter` regions on a single horizontal scrollable strip is the exact pattern that triggers the documented overload bug.

Each chip becomes a solid tinted surface:
- **Unselected chips:** Material `ChoiceChip` with `backgroundColor: theme.glassCardSurface` (the new white-at-24% token) and a thin border at `glassCardBorder`. Reads as "glass-tinted" against the gradient page even without true backdrop blur because the fill alpha is low.
- **Active chip ("All", or whichever is selected):** solid mint primary `#3DA37A` with white foreground and a soft mint shadow. Stands out as the only solid surface in the strip.
- **Top-category chips:** keep the existing per-category color tint at low alpha; same hairline border treatment.

No new widget needed — this is a `ChoiceChip` theme override in `AppTheme.subThemesData.chipRadius` plus per-instance color overrides in `FilterBar`.

---

## 6. Scope

**Honest framing:** the token changes are global. The moment Phase 1 lands, every screen renders against the new gradient with the new glass tokens. There is no isolation flag. The framing is **"foundation + Home verification + same-day triage of all primary tabs"**, not "Home only."

This is acceptable here because:
- Single dev/owner, no public production users
- Most existing screens already render through `GlassCard`, which inherits the new tokens automatically
- A feature flag would add infrastructure cost (toggle UX, two parallel theme paths) for no real benefit on a one-person codebase

### Phase 1 (this spec)
- [ ] All token changes in §4 (light + dark palette + sizes + text)
- [ ] `GlassCard` refactor — decoration, corrected `BackdropFilter` API, `useOwnBackdrop` param (§5.1)
- [ ] `GradientBackground` widget with `RepaintBoundary` + `_BloomPainter` with concrete positions (§5.2)
- [ ] `AppScaffoldShell` wraps with `GradientBackground` and goes transparent (§5.3)
- [ ] `AppTheme` drops `surfaceMode`/`blendLevel`, scaffold becomes transparent, chip theme override (§5.4)
- [ ] `BalanceHeader` divider softened, hero region becomes the single backdrop wrapper (§5.6)
- [ ] `FilterBar` chips become solid tinted (no per-chip blur) (§5.7)
- [ ] `AppNavBar` goes glassy at tier 1 (single backdrop region)
- [ ] `TransactionSliverList` wraps in a single tier-2 backdrop region; tiles drop their per-row blur
- [ ] Audit & fix any `Scaffold(backgroundColor: ...)` overrides app-wide
- [ ] Verify Plus Jakarta Sans tabular figures (§4.3) before applying `fontFeatures` globally
- [ ] **Same-day visual triage** of every primary tab (Home, Reports, Calendar, Hub) and the bottom-sheet inventory — log issues, decide what blocks merge vs what becomes Phase 2
- [ ] Verify Home / Dashboard visually matches v7

### Phase 2 (future spec)
- Polish pass on screens flagged in the same-day triage
- Onboarding splash treatment with the new palette
- Performance benchmark on Pixel 4a / Samsung A-series — confirm `GlassConfig.shouldBlur` fallback path is acceptable
- Dark-mode visual review (Phase 1 ships dark, but a careful pass for contrast and mood is worth doing once light is in users' hands)

### Out of scope
- Layout / structural changes to any screen
- Information architecture
- Iconography (Phosphor stays)
- Typography family change (Plus Jakarta Sans stays — unless §4.3 verification fails, in which case self-hosting is in scope as a one-line dependency change)
- New features
- Dark-mode toggle UX

---

## 7. Dark mode

The dark mode mirrors the structure of light:

- Page gradient: deep mint forest (`#06140F`) at the top → near-black (`#080E0C`) at the bottom — **floored above pure black** to preserve foreground contrast for text/icons rendered near the screen bottom (nav labels, last transaction).
- Glass cards: `rgba(255,255,255,0.08)` fill, blur σ=28, hairline `rgba(255,255,255,0.20)`, single black shadow.
- Mint primary stays as the brand color — the FAB and active states glow against the deep forest.
- Income/expense semantic colors lighten for AA contrast on dark (existing `incomeGreenDark`/`expenseRedDark` tokens already do this — keep them).
- The previous "Gothic Noir" purple identity is retired.

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
The existing `GlassConfig.shouldBlur` disables `BackdropFilter` on low-end devices and respects `MediaQuery.of(context).disableAnimations` (the cross-platform reduce-motion signal).

For **reduce-transparency** specifically:
- **iOS** exposes `MediaQuery.of(context).accessibilityFeatures.reduceTransparency` (via `WidgetsBinding.instance.platformDispatcher.accessibilityFeatures`). Honor it: when true, all glass tiers fall back.
- **Android** does **not** have an OS-level reduce-transparency flag. The cross-platform `disableAnimations` check is the closest signal, but it conflates two different needs. For Android we can offer an in-app **Settings → Accessibility → "Reduce transparency"** toggle that flips the same flag `GlassConfig.shouldBlur` already reads — Phase 2 work, not Phase 1.

When opted out (via any signal), in addition to skipping `BackdropFilter`:
- Glass surfaces fall back to a more opaque solid (`AppColors.surface` `#EFF8F1` on light, `surfaceDark` `#0E2820` on dark) — these are precisely the reduce-transparency fallback values defined in §4.1
- Gradient page is replaced with the brightest stop solid (`#EFF8F1` light, `#0E2820` dark)

### GPU
The gradient + blooms paint once per frame and are wrapped in `RepaintBoundary` (§5.2) to isolate them from dashboard rebuilds. `_BloomPainter` is a single `CustomPaint` with two or three radial gradient draws — well within budget.

The blur sigma jump (12 → 28) is the real cost: blur scales roughly with sigma². The §5.1.3 strategy keeps Home at **~4 simultaneous `BackdropFilter` regions** (hero, insight, tx-list, nav), well under the documented 8-filter Android ceiling. Sheets add 1 transient filter when open — still safe.

Benchmark plan: profile Home on a Pixel 4a (representative low-end) before merging Phase 1. If we exceed 16ms frame budget under scroll, the `GlassConfig.shouldBlur` opt-out is the lever; no spec change required.

---

## 10. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| Stacked `BackdropFilter` regression on Android low-end | Low (was Med before §5.1.3 strategy) | Architecturally bounded: §5.1.3 keeps visible filters at ≤4 on Home (hero, insight, tx-list, nav). Chips and tx-list rows are explicitly solid-fill, no per-element blur. `GlassConfig.shouldBlur` fallback remains the safety net. Benchmark on Pixel 4a before merge. |
| `ColorFiltered`-after-`BackdropFilter` saturates the foreground content, not just the backdrop | Med | Acknowledged in §5.1.2. Implementation tries it; if it looks wrong, the saturation step is dropped — blur alone delivers the dominant glass effect. |
| Plus Jakarta Sans (Google Fonts variant) lacks `tnum` OpenType feature | Med | §4.3 mandates verification before applying `fontFeatures` globally. Fallbacks: self-host Plus Jakarta Sans, or pad money strings in `MoneyFormatter`. |
| Existing screens look wrong on the new gradient (e.g., raw `Card()` widgets) | Med | Same-day triage in §6. Most card surfaces already use `GlassCard`; raw `Card()` is rare. |
| Pure-`Scaffold` overrides set their own `backgroundColor` and break the gradient | Med | §6 audit step (`Scaffold(backgroundColor: ...)` overrides app-wide). One-time grep + fix. |
| Purple → mint identity in dark mode will surprise existing users | Low (single user) | Single dev/owner, no public users yet. |
| `LinearGradient` with 7 stops + 2–3 radial blooms looks heavy on real device | Low | Validated visually in v7. If it feels noisy in-app, reduce to a 3-stop linear + 1 bloom — pure token tweak. |

---

## 11. File touch list (Phase 1)

**Modified:**
- `lib/app/theme/app_colors.dart` — palette + new gradient/bloom constants + dark token rebrand
- `lib/app/theme/app_text_styles.dart` — `displayLarge` 38sp, tabular figures (post-verification)
- `lib/app/theme/app_theme.dart` — transparent scaffold, drop `surfaceMode`/`blendLevel`, chip theme override
- `lib/app/theme/app_theme_extension.dart` — glass shadow recolored to slate
- `lib/core/constants/app_sizes.dart` — `glassBlurCard`, `cardShadowBlur`, `cardShadowOffsetY`, `glassBackdropSaturation`, `glassTopHighlightInset`
- `lib/shared/widgets/cards/glass_card.dart` — corrected backdrop API, `useOwnBackdrop` param, top inset highlight
- `lib/shared/widgets/navigation/app_nav_bar.dart` — gradient wrap on shell, glass nav surface (single backdrop), transparent scaffold
- `lib/features/dashboard/presentation/widgets/balance_header.dart` — soft divider, single hero backdrop wrapping all children
- `lib/features/dashboard/presentation/widgets/filter_bar.dart` — solid-tinted chips (no blur)
- `lib/features/dashboard/presentation/widgets/transaction_sliver_list.dart` — wrap list in single tier-2 backdrop region

**Added:**
- `lib/shared/widgets/backgrounds/gradient_background.dart` — gradient + blooms with `RepaintBoundary`
- `lib/shared/widgets/backgrounds/_bloom_painter.dart` — private companion `CustomPainter`

---

## 12. Open questions

These don't block writing the implementation plan, but worth surfacing:

1. **Bloom positioning under different aspect ratios** — tablets and foldables. Mockup is phone-portrait. Alignment fractions should scale, but verify on a tablet emulator early.
2. **Animated gradient?** A 30-second slow drift through bloom positions is feasible at low cost. Decision: **no**, ship static, revisit if it feels too still.
3. **`ColorFiltered` saturation may bleed into foreground content** — empirical check during implementation. If it does, drop the saturation step entirely. Spec does not commit to keeping it.
4. **Per-screen `Scaffold` overrides** — full count is unknown until the audit step runs. If the count is large (>10), the audit becomes its own task before the rest of Phase 1 lands.
