# Transaction Detail Screen — Pixel-Perfect Requirements

**Reference:** Stitch screen `fdbb66cf00184f948967a7b266e92db3`
**Files:**
- `lib/features/transactions/presentation/screens/transaction_detail_screen.dart`
- `lib/features/wallets/presentation/screens/transfer_detail_screen.dart` (unify styling)

---

## What's Wrong (Stitch Design vs Current App)

| Element | Stitch Design | Current App | Fix Required |
|---------|--------------|-------------|--------------|
| Hero card background | DARK gradient (dark green-to-black), premium look | Light glass with subtle type color tint | **Change to dark gradient background with white text** |
| Hero text color | ALL WHITE on dark bg (amount, title, badges) | Dark text on light bg | **Change all hero text to white/onPrimary** |
| Icon badge in hero | Category letter/icon in CORAL circle on dark bg | Icon in GlassCard inset circle on light bg | **Change to colored circle on dark bg** |
| "DETAILED INFORMATION" label | Small caps section label between hero and detail rows | Missing | **Add section label** |
| Detail row icons | ALL in GREEN circles (uniform primary color) | Each icon has its own color (category color, wallet color, outline) | **Change ALL detail icons to use primary/green circles** |
| Detail rows container | Individual rows on the surface background, NO wrapping card | Rows inside a single GlassCard with padding zero | **Remove wrapping GlassCard, render rows directly on surface** |
| Account row value | "Premium Visa • 4291" (shows card last 4 digits) | Just wallet name | **Append account hint if available** |
| "TRANSFER DETAILS" section | Section label + two side-by-side FROM/TO cards | Not present in transaction screen (only in transfer_detail_screen) | **Add transfer section when tx.type == 'transfer'** |
| FROM/TO cards | Two glassmorphic cards side by side with labels "FROM" / "TO" + wallet names + arrow between | Only in transfer_detail_screen, different layout | **Add unified FROM/TO card row** |
| Map position | Embedded map BELOW location row, inside a card, with green pin marker | Map exists but inside the details GlassCard | **Move map outside the detail rows, standalone** |
| Map size | Tall, roughly 200px, with rounded corners | Current `chartHeightMd` (200px) — correct size | OK |

---

## Exact Layout Specification (Top to Bottom)

### 1. App Bar
- **Current:** `AppAppBar(title: ..., actions: [edit, delete])`
- **Stitch shows:** Back arrow + "Transaction Details" + pencil icon (green) + trash icon (red)
- **Changes:**
  - Edit icon color: `cs.primary` (green) — currently default. Verify.
  - Delete icon color: `theme.expenseColor` (red) — currently default. Verify.
  - **These are likely already correct** — just verify on device.

### 2. Hero Card (MAJOR CHANGE — dark gradient background)
- **Current:** Light `GlassCard` with `tintColor: typeColor.withValues(alpha: opacitySubtle)` + dark text
- **Stitch:** Dark gradient card with white text — premium, high-contrast look

**New hero card implementation:**
```dart
Container(
  margin: const EdgeInsets.all(AppSizes.screenHPadding),
  padding: const EdgeInsets.symmetric(
    horizontal: AppSizes.lg,     // 24px horizontal
    vertical: AppSizes.xl,       // 32px vertical — generous
  ),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        cs.inverseSurface,                          // dark (~#2B3230)
        cs.inverseSurface.withValues(alpha: 0.85),  // slightly lighter
      ],
    ),
    borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),  // 24px — LARGER than default cards, matching Stitch
    boxShadow: [
      BoxShadow(
        color: cs.onSurface.withValues(alpha: AppSizes.opacityLight3),  // 20% opacity — STRONGER shadow for dark card
        blurRadius: AppSizes.heroShadowBlur,    // 16px
        offset: const Offset(0, AppSizes.heroShadowOffsetY),  // 6px Y
      ),
    ],
  ),
  child: SizedBox(
    width: double.infinity,
    child: Column(children: [...]),  // icon, amount, title, badges — see below
  ),
)
```
**Key differences from current:**
- `borderRadiusLg` (24) not `borderRadiusMd` (16) — Stitch shows larger rounded corners on the hero
- `heroShadowBlur` (16) not `cardShadowBlur` (12) — stronger shadow for the dark card to create depth
- Shadow opacity `opacityLight3` (0.2) not `opacitySubtle` (0.08) — visibly stronger

**Hero card contents (all WHITE text on dark bg):**

#### 2a. Category Icon Badge
- Size: `iconContainerXl` (56px) — circle
- Background: `typeColor` at 30% opacity (e.g., coral at 30% for expense)
- Icon: `catIcon`, size `iconLg` (32px), color: `typeColor` (coral/green/blue)
- Shape: `BoxShape.circle`
- **NOT** a GlassCard tier — just a Container circle on dark bg

#### 2b. Amount
- `SizedBox(height: AppSizes.md)` (16px) below icon — generous gap
- Text: `'$signPrefix${MoneyFormatter.format(tx.amount)}'`
- Style: `displaySmall` (32sp), `fontWeight: w700`, color: **`cs.inverseOnSurface`** (white)
- This is the biggest visual change — white amount on dark card
- Uses tabular figures: `fontFeatures: [FontFeature.tabularFigures()]`

#### 2c. Title
- `SizedBox(height: AppSizes.xs)` (4px) below amount — TIGHT gap (amount and title are close together in Stitch)
- Text: `tx.title`
- Style: `titleMedium`, `fontWeight: w500`, color: `cs.inverseOnSurface.withValues(alpha: AppSizes.opacityStrong)` (off-white, ~70% opacity)
- `textAlign: TextAlign.center`, maxLines 2, overflow ellipsis

#### 2d. Type + Date Badge Pills
- `SizedBox(height: AppSizes.sm)` (8px) below title — moderate gap before badges
- Row(mainAxisAlignment: center, mainAxisSize: min):
  - Type badge: `_TypeBadge(label: typeLabel, color: typeColor)` — keep current pill styling but text needs to be legible on dark bg. The pill bg is `typeColor.withValues(alpha: 0.2)` which is semi-transparent on dark, and text is `typeColor` — this should work.
  - SizedBox(width: sm)
  - Date badge: `_TypeBadge(label: formattedDate, color: cs.inverseOnSurface)` — use white/light color for the date pill on dark bg. Pill bg = white at 15% opacity, text = white.

**Update `_TypeBadge` to work on dark bg:** The current `_TypeBadge` uses `color.withValues(alpha: opacityLight2)` for bg and `color` for text. On dark bg:
- Type pill: `typeColor` at 20% on dark bg → visible. Text `typeColor` → visible. ✅ OK
- Date pill: Need `cs.inverseOnSurface` (white) for both bg tint and text. bg = white at 15% on dark → subtle light pill. Text = white → visible. ✅ OK

### 3. "DETAILED INFORMATION" Section Label (NEW)
- **Stitch shows:** "DETAILED INFORMATION" in small caps above the detail rows
- **Implementation:**
  ```dart
  Padding(
    padding: EdgeInsetsDirectional.fromSTEB(screenHPadding + xs, lg, screenHPadding, sm),
    child: Text(
      context.l10n.transaction_detailed_info.toUpperCase(),
      style: context.textStyles.labelSmall?.copyWith(
        color: cs.outline,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    ),
  )
  ```
- **L10n key:** `transaction_detailed_info` — "Detailed Information" / "معلومات تفصيلية"

### 4. Detail Rows (RESTYLE — remove wrapping card, unify icon colors)

**Current:** All detail rows wrapped in a single `GlassCard(padding: EdgeInsets.zero)`.
**Stitch:** Detail rows rendered DIRECTLY on the surface background, no wrapping card. Each row is standalone.

**Remove** the wrapping `GlassCard` around the detail rows. Render them as direct children of the Column.

**Change ALL detail row icons to GREEN circles:**
```dart
// CURRENT: per-icon colors (catColor, wallet color, cs.outline)
_DetailRow(icon: catIcon, iconColor: catColor, ...)
_DetailRow(icon: walletIcon, iconColor: walletColor, ...)
_DetailRow(icon: AppIcons.calendar, iconColor: cs.outline, ...)

// NEW: ALL icons use primary green
_DetailRow(icon: catIcon, iconColor: cs.primary, ...)
_DetailRow(icon: walletIcon, iconColor: cs.primary, ...)
_DetailRow(icon: AppIcons.calendar, iconColor: cs.primary, ...)
_DetailRow(icon: AppIcons.edit, iconColor: cs.primary, ...)
_DetailRow(icon: AppIcons.location, iconColor: cs.primary, ...)
_DetailRow(icon: sourceIcon, iconColor: cs.primary, ...)
```

**Stitch confirms:** Every detail row icon uses the SAME green circle — uniform, not per-category colored.

**_DetailRow icon container — change from GlassCard inset to simple Container circle:**
```dart
// CURRENT:
GlassCard(
  tier: GlassTier.inset,
  tintColor: iconColor.withValues(alpha: opacitySubtle),
  borderRadius: borderRadiusSm,  // rounded square, 40px
  ...
)

// NEW:
Container(
  width: AppSizes.colorSwatchSize,    // 36px — slightly SMALLER than current 40px, matching Stitch proportions
  height: AppSizes.colorSwatchSize,
  decoration: BoxDecoration(
    color: iconColor.withValues(alpha: AppSizes.opacityLight2),
    shape: BoxShape.circle,           // ← CIRCLE, matching Stitch
  ),
  child: Icon(icon, size: AppSizes.iconSm, color: iconColor),  // 20px icon
)
```
**Why 36px not 40px:** The Stitch detail row icons appear smaller relative to the text than the current 40px circles. `colorSwatchSize` (36) gives better proportion.

**Detail row padding — rows are now standalone (no wrapping card):**
```dart
padding: EdgeInsets.symmetric(
  horizontal: AppSizes.screenHPadding,  // 16px — align with screen edge
  vertical: AppSizes.sm,               // 8px — TIGHT vertical spacing between rows (Stitch shows compact rows)
),
```

**Detail row label style — verify against Stitch:**
- Label (e.g., "Category"): `labelSmall` (11sp), `cs.outline` — Stitch shows very small muted labels, smaller than `bodySmall`
- Value (e.g., "Dining & Drinks"): `bodyMedium` (14sp), `cs.onSurface`, `fontWeight: w500` — NOT `bodyLarge` (16sp), Stitch values appear moderate-sized
- `SizedBox(height: AppSizes.xxs)` (2px) between label and value — very tight

**Updated `_DetailRow.build()` template:**
```dart
Padding(
  padding: const EdgeInsets.symmetric(
    horizontal: AppSizes.screenHPadding,
    vertical: AppSizes.sm,
  ),
  child: Row(
    children: [
      Container(
        width: AppSizes.colorSwatchSize,
        height: AppSizes.colorSwatchSize,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: AppSizes.opacityLight2),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: AppSizes.iconSm, color: iconColor),
      ),
      const SizedBox(width: AppSizes.md),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.textStyles.labelSmall?.copyWith(color: context.colors.outline),
            ),
            const SizedBox(height: AppSizes.xxs),
            Text(
              value,
              style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  ),
)
```

### 5. OpenStreetMap (MOVE — standalone, outside detail rows)
- **Current:** Map is inside the detail rows area, directly after the location `_DetailRow`
- **Stitch:** Map appears as a standalone element below ALL detail rows, with its own padding, rounded corners, and clear separation
- **Move** the `FlutterMap` block AFTER all detail rows (after source row), as its own standalone section:
  ```dart
  // After all detail rows, before tags section:
  if (tx.latitude != null && tx.longitude != null)
    Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.screenHPadding,
        vertical: AppSizes.sm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),  // 16px rounded corners
        child: SizedBox(
          height: AppSizes.chartHeightMd,  // 200px tall
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(tx.latitude!, tx.longitude!),
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,  // non-interactive, display only
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.masarify.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(tx.latitude!, tx.longitude!),
                    child: Icon(AppIcons.location, color: cs.primary, size: AppSizes.iconLg),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  ```
- **Stitch shows:** The map has a green pin marker in the center, rounded corners, and sits flush with the screen horizontal padding
- **DO NOT** render the map inside any GlassCard — it's a direct ClipRRect on the surface

### 6. "TRANSFER DETAILS" Section (NEW — for transfer-type transactions)
- **Stitch shows:** When a transaction has transfer data, a "TRANSFER DETAILS" section label + FROM/TO cards appear
- **Note:** This only applies to the `transfer_detail_screen.dart`, not the regular transaction screen. Normal transactions don't have FROM/TO data. However, for design UNIFICATION, both screens should share the same hero card style and detail row pattern.

**For transfer_detail_screen.dart specifically:**
- `SizedBox(height: AppSizes.lg)` (24px) gap above "TRANSFER DETAILS" label — generous separation from detail rows
- Add "TRANSFER DETAILS" section label (same style as "DETAILED INFORMATION" — `labelSmall`, uppercase, letterSpacing 1.5, `cs.outline`)
- `SizedBox(height: AppSizes.sm)` below label
- Below label: Row with two GlassCard side-by-side, wrapped in `Padding(horizontal: screenHPadding)`:
  ```dart
  Row(
    children: [
      // FROM card
      Expanded(
        child: GlassCard(
          tintColor: cs.primaryContainer.withValues(alpha: opacitySubtle),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('FROM', style: labelSmall, cs.outline, uppercase, letterSpacing 1.0),
              SizedBox(height: xs),
              Row(children: [
                Icon(AppIcons.walletType(fromWallet.type), size: iconSm, color: cs.primary),
                SizedBox(width: xs),
                Text(fromName, bodyMedium, fontWeight w600),
              ]),
            ],
          ),
        ),
      ),
      // Arrow
      Padding(
        padding: EdgeInsets.symmetric(horizontal: sm),
        child: Icon(
          context.isRtl ? AppIcons.arrowBack : AppIcons.arrowForward,
          color: cs.primary,
          size: iconMd,
        ),
      ),
      // TO card
      Expanded(
        child: GlassCard(
          tintColor: cs.primaryContainer.withValues(alpha: opacitySubtle),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TO', style: labelSmall, cs.outline, uppercase, letterSpacing 1.0),
              SizedBox(height: xs),
              Row(children: [
                Icon(AppIcons.walletType(toWallet.type), size: iconSm, color: cs.primary),
                SizedBox(width: xs),
                Text(toName, bodyMedium, fontWeight w600),
              ]),
            ],
          ),
        ),
      ),
    ],
  )
  ```
- **L10n keys:**
  - `transfer_from_label` — "FROM" / "من" (may already exist)
  - `transfer_to_label` — "TO" / "إلى" (may already exist)
  - `transaction_transfer_details` — "Transfer Details" / "تفاصيل التحويل"

### 7. Transfer Detail Screen Unification
- **Apply the same dark gradient hero card** to `transfer_detail_screen.dart`
- **Apply the same "DETAILED INFORMATION" section label** pattern
- **Apply the same detail row styling** (green circle icons, no wrapping card)
- **Add the "TRANSFER DETAILS" FROM/TO section** as described above
- The transfer detail screen currently has a different hero card structure — it should match the transaction detail hero exactly (dark gradient, white text, icon badge, amount, title, type+date pills)

---

## Design Tokens

| Property | Token | Notes |
|----------|-------|-------|
| Hero card bg | `cs.inverseSurface` gradient (dark) | LinearGradient topLeft→bottomRight |
| Hero card radius | `AppSizes.borderRadiusLg` (24px) | LARGER than default cards |
| Hero card shadow | `heroShadowBlur` (16), `opacityLight3` (0.2) | Stronger than default card shadow |
| Hero card padding | horizontal `lg` (24), vertical `xl` (32) | Generous |
| Hero text color | `cs.inverseOnSurface` (white) | All hero text |
| Hero icon badge size | `iconContainerXl` (56px), `BoxShape.circle` | Category color at 30% on dark bg |
| Amount text | `displaySmall` (32sp), white, w700 | Tabular figures |
| Gap: icon → amount | `AppSizes.md` (16px) | |
| Gap: amount → title | `AppSizes.xs` (4px) | Tight |
| Gap: title → badges | `AppSizes.sm` (8px) | |
| Detail icon circles | `colorSwatchSize` (36px), `BoxShape.circle` | Smaller than previous 40px |
| Detail icon color | `cs.primary` (ALL green, uniform) | Not per-category |
| Detail label style | `labelSmall` (11sp), `cs.outline` | Smaller than previous bodySmall |
| Detail value style | `bodyMedium` (14sp), `w500` | Not bodyLarge |
| Detail row vertical pad | `AppSizes.sm` (8px) | Tight/compact rows |
| Section label | `labelSmall`, uppercase, letterSpacing 1.5, `cs.outline` | |
| Map height | `chartHeightMd` (200px) | |
| Map radius | `borderRadiusMd` (16px) | |
| FROM/TO card tint | `cs.primaryContainer.withValues(alpha: opacitySubtle)` | |
| FROM/TO gap above | `AppSizes.lg` (24px) | Generous separation |

---

## L10n Keys Needed

- `transaction_detailed_info` — "Detailed Information" / "معلومات تفصيلية"
- `transaction_transfer_details` — "Transfer Details" / "تفاصيل التحويل"
- `transfer_from_label` — "FROM" / "من" (check if exists)
- `transfer_to_label` — "TO" / "إلى" (check if exists)

---

## Existing Code to Reuse

| What | Where |
|------|-------|
| `FlutterMap` + `LatLng` | Already imported in transaction_detail_screen |
| `_TypeBadge` widget | Already in transaction_detail_screen — keep, works on dark bg |
| `_DetailRow` widget | Already exists — modify icon container shape + color |
| `_sourceIcon` / `_sourceLabel` | Already in transaction_detail_screen — keep |
| `_confirmDelete` | Already in transaction_detail_screen — keep |
| `MoneyFormatter.format()` | `lib/core/utils/money_formatter.dart` |
| `CategoryIconMapper.fromName()` | `lib/core/utils/category_icon_mapper.dart` |
| `ColorUtils.fromHex()` | `lib/core/utils/color_utils.dart` |

---

## What NOT to Change
- `_confirmDelete` dialog logic
- `_sourceIcon` / `_sourceLabel` switch helpers
- `transactionByIdProvider` data loading
- Loading/error/empty states
- Tags section (keep as-is)
- Raw source text section (keep as-is)
- FlutterMap configuration (tile URL, user agent, zoom, marker) — just move position
