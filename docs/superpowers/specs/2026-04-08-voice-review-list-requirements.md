# Voice Review List View — Pixel-Perfect Requirements

**Reference:** Stitch screen `a80bf43bbf4d445a8c27df3d33181a46`
**Files:**
- `lib/features/voice_input/presentation/widgets/draft_list_item.dart`
- `lib/features/voice_input/presentation/screens/voice_confirm_screen.dart` (list view section + bottom bar)

---

## What's Wrong (Stitch Design vs Current App)

| Element | Stitch Design | Current App | Fix Required |
|---------|--------------|-------------|--------------|
| Screen header | "CONFIRM TRANSACTIONS" label (small caps) + "Freshly Minted" large headline below app bar | Only app bar title "Review (3)", no in-body header | **Add editorial header section below app bar** |
| Card icon circle | Category icon in colored circle, LEFT of category name | Same layout — already correct | OK |
| Category name + subtitle | "Food & Dining" bold + "Zuma Restaurant" subtitle below it | Category name as `titleSmall` + title as `bodyMedium` below | Already close — verify sizes match |
| Amount format | "-EGP 450.00" with currency prefix, RED color for expense | "+/-" prefix + formatAmount (no "EGP") | **Change to `MoneyFormatter.format()` which includes "EGP" prefix** |
| Amount position | Right-aligned, same row as category name + icon | Already correct | OK |
| Raw transcript | Shown in quotes, italic, muted, below the title | Shown italic muted below title — already correct | OK, but Stitch shows it in quotes: `"lunch at zuma for four-hundred and fifty"` — add quotes |
| Detail pills | Wallet name pill + Date pill + Type pill in a row | Already have Wrap with pills | OK — verify pill styling matches |
| Suggestion chip | Green tinted banner "Create Savings Goal" | Already have suggestion chip system | OK |
| Include toggle | Toggle switch (not checkbox) + "Include" label | Uses `Checkbox` + "Include" label | **Change from Checkbox to a custom Toggle/Switch** |
| Edit button | "Edit" text button, right-aligned | TextButton "Edit" — already correct | OK |
| Transfer card | Shows "CIB Bank → Savings Goal" with arrow in the card body, NOT in pills | Transfer details shown in pills only | **Add FROM → TO flow row for transfer type cards** |
| Bottom bar | Large green gradient "Submit All" button with rounded corners + "Discard" and "Save Draft" text buttons flanking bottom | Plain `FilledButton` "Submit All (3)" | **Redesign bottom bar with gradient button + flanking text buttons** |
| Card vertical spacing | Cards spaced ~12-16px apart with clear visual separation | Currently `AppSizes.sm` (8px) margin — may be too tight | **Increase to `AppSizes.md` (16px) vertical margin** |
| Batch controls | Not visible in Stitch (Select All / count) | Shows above list | **Move inside app bar actions or hide — Stitch doesn't show them** |

---

## Exact Layout Specification (Top to Bottom)

### 1. App Bar
- **Current:** `AppAppBar(title: context.l10n.voice_confirm_title)` with toggle icon
- **Keep:** Back arrow, toggle icon (swap between list/swipe view)
- **Change title:** From full "Review Transactions" to just "Review ({count})" — Stitch shows "Review (3)"

### 2. Editorial Header (NEW — below app bar, inside body)
- **Stitch shows:** "CONFIRM TRANSACTIONS" small caps label + "Freshly Minted" large bold headline
- **Implementation:** Add at top of `_buildListView`, before batch controls:
  ```
  Padding(screenHPadding horizontal, md vertical):
    Column(crossAxisAlignment: start):
      - "CONFIRM TRANSACTIONS" — labelSmall, uppercase, letterSpacing 1.5, cs.outline, fontWeight w600
      - SizedBox(height: AppSizes.xs)
      - "Freshly Minted" — headlineMedium (or headlineSmall), fontWeight w700, cs.onSurface
  ```
- **L10n keys needed:**
  - `voice_confirm_subtitle` — "CONFIRM TRANSACTIONS" / "تأكيد المعاملات"
  - `voice_confirm_headline` — "Freshly Minted" / "معاملات جديدة" (or a suitable Arabic equivalent)

### 3. Batch Controls
- **Stitch:** Not visible as a separate row
- **Action:** Keep the select all / deselect all logic but **move it into the app bar as a text action button** or **place it below the headline as a subtle row**
- **Recommended:** Keep as-is but reduce visual weight — make it `labelSmall` in `cs.outline`, not a prominent TextButton

### 4. Transaction Cards (DraftListItem)

#### 4a. Card Container
- **Current:** `GlassCard(showShadow: true, margin: horizontal screenHPadding, vertical sm)`
- **Change:** Increase vertical margin from `AppSizes.sm` (8) to `AppSizes.md` (16) — Stitch shows more breathing room between cards
- **Keep:** `showShadow: true`, `Opacity` wrapper for excluded items

#### 4b. Row 1: Icon + Category + Amount
- **Icon circle:**
  - Size: `AppSizes.minTapTarget` (48px) — current is correct, matches Stitch
  - Background: `categoryColor.withValues(alpha: AppSizes.opacityLight)` — keep
  - Icon: `categoryIcon`, `iconSm`, `categoryColor` — keep
- **Category name:**
  - Current: `titleSmall`, `fontWeight: w700` — keep
- **Subtitle below category name (NEW):**
  - Stitch shows the merchant/title as a subtitle DIRECTLY below the category name, in the same Expanded column
  - Current code has title as a separate Row 2 below. Move it into the category column:
    ```
    Expanded > Column(crossAxisStart):
      Text(categoryName, titleSmall, w700)
      SizedBox(height: xxs)
      Text(title, bodySmall, cs.outline)  // merchant name as subtitle
    ```
  - This matches Stitch where "Food & Dining" is bold and "Zuma Restaurant" is directly below it in muted text
  - **Salary card note:** Stitch shows "Monthly" as a subtitle line between category name and title — this appears to be the transaction frequency/type hint. For regular transactions this is just the title/merchant. Don't add frequency data — it's not available in voice drafts. The subtitle is simply the `title` field.
- **Amount:**
  - **Stitch shows:** "-EGP 450.00" for expenses, "+EGP 25,000.00" for income, "EGP 1,200.00" for transfers (no sign)
  - **Change format:** From `'$prefix${MoneyFormatter.formatAmount(amount)}'` (shows "-450") to `'$prefix${MoneyFormatter.format(amount)}'` (shows "-EGP 450")
  - The `MoneyFormatter.format()` already includes the "EGP" prefix. Just prepend the sign:
    ```dart
    final formattedAmount = '$prefix${MoneyFormatter.format(amount)}';
    ```
  - Style: `titleMedium`, `fontWeight: w700`, `color: typeColor`, tabular figures — keep current
  - **Right-aligned** in the Row via no Expanded wrapping (amount is last child, Row handles alignment)

#### 4c. Row 2: Raw Transcript (moved — was Row 2, now part of card body)
- Since the title moved into Row 1 as a subtitle, the raw transcript becomes the main Row 2
- **Wrap in quotes:** `'"$rawTranscript"'` — Stitch shows quoted italic text
- Style: `bodySmall`, `cs.outline`, `fontStyle: FontStyle.italic`, maxLines 2
- Only show if `rawTranscript != null && rawTranscript != title`

#### 4d. Row 3: Detail Pills
- **Current:** Wrap with wallet, date, type pills — keep
- **Pill styling:** `labelSmall` text, `borderRadiusFull`, horizontal `sm` + vertical `xxs` padding
- **Pill colors:**
  - Wallet: `cs.surfaceContainerHigh` (subtle grey — Stitch shows light grey pills)
  - Date: `cs.surfaceContainerHigh` (same subtle grey)
  - Type: `typeColor.withValues(alpha: AppSizes.opacityLight2)` (colored for emphasis)
- **Change pill background** from `colors.secondaryContainer` / `colors.tertiaryContainer` to `cs.surfaceContainerHigh` for wallet and date — Stitch shows neutral grey pills, not colored

#### 4e. Transfer-Specific Row (NEW — for type == 'transfer')
- **Stitch shows:** Two transfer-specific elements:
  1. The subtitle in Row 1 (under "Transfer" category name) shows "To {destination wallet name}" — e.g. "To Savings Account"
  2. Below the detail pills: "CIB Bank → Savings Goal" as a dedicated row with arrow icon
- **Row 1 subtitle for transfers:** When `type == 'transfer'`, the subtitle text should be `'To ${toWalletName ?? "?"}'` instead of the transaction title
- **Arrow row — add after detail pills, only for transfers:**
  ```
  if (type == 'transfer' && fromWalletName != null) ...[
    SizedBox(height: sm),
    Row(children: [
      Text(fromWalletName!, bodySmall, fontWeight: w500, cs.onSurface),
      SizedBox(width: xs),
      Icon(context.isRtl ? AppIcons.arrowBack : AppIcons.arrowForward, size: iconXxs, cs.outline),
      SizedBox(width: xs),
      Text(toWalletName ?? '?', bodySmall, fontWeight: w500, cs.onSurface),
    ]),
  ]
  ```
- **RTL note:** Arrow direction must flip for Arabic (use `context.isRtl` check)
- **Requires:** Add `fromWalletName` and `toWalletName` parameters to DraftListItem (for transfer type cards)

#### 4f. Suggestion Chip
- **Keep current implementation** — matches Stitch ("Create Savings Goal" tinted banner)

#### 4g. Row 4: Include + Edit
- **Include toggle:**
  - **Stitch shows** a toggle switch (custom circular toggle), NOT a material Checkbox
  - **Change:** Replace `Checkbox` with `Switch.adaptive` or a custom toggle:
    ```
    SizedBox(
      height: AppSizes.iconMd,
      child: Switch.adaptive(
        value: isIncluded,
        onChanged: (_) => onToggle(),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    ```
  - "Include" label: `bodySmall`, keep same
- **Edit button:** `TextButton` with "Edit" text — keep same, right-aligned via `Spacer`

### 5. Bottom Bar (REDESIGN to match Stitch)

**Current:** Simple `SafeArea` > `Padding` > `FilledButton("Submit All (3)")`

**Stitch shows:** Three elements in a row at the bottom:
- LEFT: "Discard" text button (grey)
- CENTER: Large green gradient "Submit All" pill button (prominent, filled, rounded)
- RIGHT: "Save Draft" text button (grey)

**New implementation:**
```
SafeArea > Padding(screenHPadding) > Row:
  - TextButton("Discard", onPressed: _discardAll, style: grey text)
  - Expanded > Center > FilledButton(
      "Submit All",
      onPressed: _confirmAll,
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        shape: StadiumBorder(),
        padding: EdgeInsets.symmetric(horizontal: xl, vertical: md),
      ),
    )
  - TextButton("Save Draft", onPressed: _saveDraft, style: grey text)
```

**L10n keys needed:**
- `voice_discard_all` — "Discard" / "تجاهل"
- `voice_save_draft` — "Save Draft" / "حفظ كمسودة"

**Business logic for new buttons:**
- **Discard:** Pop the screen without saving (confirm dialog first)
- **Save Draft:** Save drafts to local storage for later review (if not implemented, show "Coming soon" snack for now)

### 6. Slidable Actions (Keep Current)
- Swipe right: Edit (primary color)
- Swipe left: Decline (expense color)
- extentRatio 0.2, BehindMotion
- No changes needed

### 7. Stagger Animation (Keep Current)
- fadeIn + slideY with stagger delay
- Skip if reduceMotion
- No changes needed

---

## Design Tokens

| Property | Token |
|----------|-------|
| Card vertical margin | `AppSizes.md` (16) — increased from sm (8) |
| Icon circle size | `AppSizes.minTapTarget` (48) |
| Detail pill radius | `borderRadiusFull` |
| Detail pill bg (neutral) | `cs.surfaceContainerHigh` |
| Detail pill bg (type) | `typeColor.withValues(alpha: opacityLight2)` |
| Submit button shape | `StadiumBorder()` (full pill) |
| Headline text | `headlineMedium` or `headlineSmall` |
| Section label | `labelSmall`, uppercase, letterSpacing 1.5 |

---

## L10n Keys Needed

- `voice_confirm_subtitle` — "CONFIRM TRANSACTIONS" / "تأكيد المعاملات"
- `voice_confirm_headline` — "Freshly Minted" / "معاملات جديدة"
- `voice_discard_all` — "Discard" / "تجاهل"
- `voice_save_draft` — "Save Draft" / "حفظ كمسودة"

---

## New Parameters for DraftListItem

For transfer-type cards, add optional parameters:
```dart
this.fromWalletName,
this.toWalletName,
```
Fields:
```dart
final String? fromWalletName;
final String? toWalletName;
```
Pass from `voice_confirm_screen.dart` by resolving the `draft.walletId` and `draft.toWalletId` to wallet names.

---

## Existing Code to Reuse

| What | Where |
|------|-------|
| `MoneyFormatter.format()` | `lib/core/utils/money_formatter.dart` |
| `MoneyFormatter.formatAmount()` | same file |
| `CategoryIconMapper.fromName()` | `lib/core/utils/category_icon_mapper.dart` |
| `ColorUtils.fromHex()` | `lib/core/utils/color_utils.dart` |
| `GlassCard` | `lib/shared/widgets/cards/glass_card.dart` |
| `AppAppBar` | `lib/shared/widgets/navigation/app_app_bar.dart` |
| `_buildSuggestionChip` / `_chip` | already in draft_list_item.dart — keep |

---

## What NOT to Change
- Suggestion chip system (wallet create, subscription, goal match) — keep all logic
- Slidable edit/decline gestures
- Stagger animation
- The `_openEditSheet` flow for editing individual drafts
- The `_confirmAll` submit logic
- The swipe view (this doc only covers list view mode)
- The toggle between swipe/list view in app bar
