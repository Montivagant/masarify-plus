---
phase: 2
plan: 4
title: "App-Wide UX Fixes — SnackBar Revamp"
wave: 2
depends_on: [02-1-PLAN, 02-2-PLAN, 02-3-PLAN]
requirements: []
bugs: [D-10]
files_modified:
  - lib/shared/widgets/feedback/snack_helper.dart
  - lib/core/constants/app_sizes.dart
  - lib/core/constants/app_durations.dart
  - lib/features/ai_chat/presentation/screens/chat_screen.dart
  - lib/features/wallets/presentation/screens/add_wallet_screen.dart
  - lib/features/wallets/presentation/screens/transfer_screen.dart
  - lib/features/transactions/presentation/screens/add_transaction_screen.dart
  - lib/features/dashboard/presentation/widgets/quick_add_zone.dart
  - lib/features/budgets/presentation/screens/set_budget_screen.dart
  - lib/features/categories/presentation/screens/add_category_screen.dart
  - lib/features/goals/presentation/screens/goal_detail_screen.dart
  - lib/features/goals/presentation/screens/add_goal_screen.dart
autonomous: true
---

# Plan 2-4: App-Wide UX Fixes — SnackBar Revamp

**Goal:** Revamp all SnackBar/toast notifications to be modern, compact, bottom-aligned, auto-dismiss after 3 seconds (D-10). Create a unified styling approach and replace all raw `ScaffoldMessenger.showSnackBar()` callsites with `SnackHelper`.

---

## Task 1: Revamp SnackHelper Styling — Modern Compact Toast (D-10)

**Problem:** Current SnackBars are bulky, remain visible too long, appear centered, and require manual dismissal. They should be modern, compact, bottom-aligned, auto-dismiss after 3 seconds, with rounded corners and subtle background.

<read_first>
- lib/shared/widgets/feedback/snack_helper.dart (full file — current implementation)
- lib/core/constants/app_sizes.dart (design tokens for sizing)
- lib/core/constants/app_durations.dart (duration tokens)
</read_first>

<action>
1. In `lib/shared/widgets/feedback/snack_helper.dart`, update the `_show` method to produce a modern, compact toast:

   Replace the entire `_show` method with:
   ```dart
   static void _show(
     BuildContext context, {
     required String message,
     required IconData icon,
     required Color color,
     required Color onColor,
     SnackBarAction? action,
     required Duration duration,
   }) {
     ScaffoldMessenger.of(context)
       ..hideCurrentSnackBar()
       ..showSnackBar(
         SnackBar(
           content: Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               Icon(icon, color: onColor, size: AppSizes.iconSm),
               const SizedBox(width: AppSizes.sm),
               Flexible(
                 child: Text(
                   message,
                   style: TextStyle(
                     color: onColor,
                     fontSize: AppSizes.snackTextSize,
                     fontWeight: FontWeight.w500,
                   ),
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
             ],
           ),
           backgroundColor: color,
           behavior: SnackBarBehavior.floating,
           shape: RoundedRectangleBorder(
             borderRadius: BorderRadius.circular(AppSizes.snackBorderRadius),
           ),
           padding: const EdgeInsets.symmetric(
             horizontal: AppSizes.md,
             vertical: AppSizes.snackVerticalPadding,
           ),
           margin: const EdgeInsets.only(
             left: AppSizes.snackHorizontalMargin,
             right: AppSizes.snackHorizontalMargin,
             bottom: AppSizes.snackBottomMargin,
           ),
           elevation: AppSizes.snackElevation,
           duration: duration,
           dismissDirection: DismissDirection.horizontal,
           action: action,
         ),
       );
   }
   ```

2. In `lib/core/constants/app_sizes.dart`, add the SnackBar design tokens:
   ```dart
   // ── SnackBar / Toast ──────────────────────────────────────────────────
   static const double snackTextSize = 13.0;
   static const double snackBorderRadius = 12.0;
   static const double snackVerticalPadding = 10.0;
   static const double snackHorizontalMargin = 24.0;
   static const double snackBottomMargin = 16.0;
   static const double snackElevation = 4.0;
   ```

3. Verify `lib/core/constants/app_durations.dart` already has appropriate durations:
   - `snackbarDefault = Duration(seconds: 3)` -- already exists, correct
   - `snackbarShort = Duration(seconds: 2)` -- already exists
   - `snackbarError = Duration(seconds: 4)` -- already exists
   - `snackbarLong = Duration(seconds: 5)` -- already exists

4. Verify the existing `snackbarBottomMargin` in `app_sizes.dart` is either replaced by the new `snackBottomMargin` or updated to the correct value. Check if `snackbarBottomMargin` exists; if it does, update it rather than creating a duplicate. If not, create the new tokens.

5. The key improvements over the current implementation:
   - Smaller icon: `AppSizes.iconSm` (20) instead of `AppSizes.iconMd` (24)
   - Smaller text: 13pt instead of bodyMedium (14-16pt)
   - Tighter padding: `10.0` vertical instead of default SnackBar padding
   - Swipe to dismiss: `dismissDirection: DismissDirection.horizontal`
   - Bottom margin: positioned just above the bottom nav bar area

   **Note:** `SnackHelper` is a static utility class and cannot access `Theme.of(context)` for text styles. Using a raw `TextStyle` with the `AppSizes.snackTextSize` design token is the accepted exception for static utility classes that construct widgets without a live `BuildContext` for theme resolution.
</action>

<acceptance_criteria>
- grep "snackTextSize" lib/core/constants/app_sizes.dart confirms design token
- grep "snackBorderRadius" lib/core/constants/app_sizes.dart confirms design token
- grep "snackVerticalPadding" lib/core/constants/app_sizes.dart confirms design token
- grep "DismissDirection.horizontal" lib/shared/widgets/feedback/snack_helper.dart confirms swipe dismiss
- grep "AppSizes.iconSm" lib/shared/widgets/feedback/snack_helper.dart confirms smaller icon
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 2: Replace Raw ScaffoldMessenger.showSnackBar Calls with SnackHelper

**Problem:** Several screens use raw `ScaffoldMessenger.of(context).showSnackBar(SnackBar(...))` instead of the centralized `SnackHelper`. These bypass the unified styling.

<read_first>
- lib/features/ai_chat/presentation/screens/chat_screen.dart (raw SnackBar usage)
- lib/features/wallets/presentation/screens/add_wallet_screen.dart (raw SnackBar usage)
- lib/features/wallets/presentation/screens/transfer_screen.dart (raw SnackBar usage)
- lib/features/transactions/presentation/screens/add_transaction_screen.dart (raw SnackBar usage)
- lib/features/dashboard/presentation/widgets/quick_add_zone.dart (raw SnackBar usage)
- lib/features/budgets/presentation/screens/set_budget_screen.dart (raw SnackBar usage)
- lib/features/categories/presentation/screens/add_category_screen.dart (raw SnackBar usage)
- lib/features/goals/presentation/screens/goal_detail_screen.dart (raw SnackBar usage)
- lib/features/goals/presentation/screens/add_goal_screen.dart (raw SnackBar usage)
</read_first>

<action>
1. Search for all raw `ScaffoldMessenger` / `showSnackBar` / `SnackBar(` calls across `lib/`:
   ```bash
   grep -rn "showSnackBar\|SnackBar(" lib/ --include="*.dart" | grep -v snack_helper.dart | grep -v ".g.dart"
   ```

2. For each file found, replace the raw SnackBar call with the appropriate SnackHelper method:

   **Pattern to replace:**
   ```dart
   ScaffoldMessenger.of(context).showSnackBar(
     SnackBar(
       content: Text(message),
       duration: AppDurations.snackbarShort,
     ),
   );
   ```

   **Replace with:**
   ```dart
   SnackHelper.showError(context, message);
   // or SnackHelper.showSuccess(context, message);
   // or SnackHelper.showInfo(context, message);
   ```

   Choose the appropriate method based on context:
   - Error messages (validation failures, exceptions) → `SnackHelper.showError()`
   - Success messages (saved, created, deleted) → `SnackHelper.showSuccess()`
   - Info messages (hints, neutral notifications) → `SnackHelper.showInfo()`

3. Add the `SnackHelper` import to each file that gains the new dependency:
   ```dart
   import '../../../../shared/widgets/feedback/snack_helper.dart';
   ```
   (Adjust relative path depth based on file location.)

4. Specific files to check and fix:

   **chat_screen.dart** — Has raw `ScaffoldMessenger.of(context).showSnackBar` around line 203-208. Replace with:
   ```dart
   SnackHelper.showError(context, errorGeneric);
   ```

   **add_wallet_screen.dart** — Check for raw SnackBar on save success/error.

   **transfer_screen.dart** — Check for raw SnackBar on transfer success/error.

   **add_transaction_screen.dart** — Check for raw SnackBar on save.

   **quick_add_zone.dart** — Check for raw SnackBar on quick-add actions.

   **set_budget_screen.dart** — Check for raw SnackBar on budget save.

   **add_category_screen.dart** — Check for raw SnackBar on category creation.

   **goal_detail_screen.dart** — Check for raw SnackBar on contribution/delete.

   **add_goal_screen.dart** — Check for raw SnackBar on goal creation.

5. After replacing all callsites, verify no raw `SnackBar(` constructors remain outside of `snack_helper.dart`:
   ```bash
   grep -rn "SnackBar(" lib/ --include="*.dart" | grep -v snack_helper.dart | grep -v ".g.dart"
   ```
   The only remaining `SnackBar(` should be inside `snack_helper.dart` itself.
</action>

<acceptance_criteria>
- grep -rc "ScaffoldMessenger.*showSnackBar\|SnackBar(" lib/ --include="*.dart" minus snack_helper.dart returns 0 for each file (no raw SnackBar usage outside SnackHelper)
- grep "SnackHelper" lib/features/ai_chat/presentation/screens/chat_screen.dart confirms replacement
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 3: Verify SnackBar Behavior and Edge Cases

<read_first>
- lib/shared/widgets/feedback/snack_helper.dart (updated implementation)
</read_first>

<action>
1. Verify `hideCurrentSnackBar()` is called before showing a new one (line 86-87) — prevents stacking.

2. Verify the `behavior: SnackBarBehavior.floating` ensures the toast floats above the bottom nav bar.

3. Verify the `dismissDirection: DismissDirection.horizontal` allows swipe-to-dismiss.

4. Verify the auto-dismiss duration defaults:
   - Success: 3 seconds (`snackbarDefault`)
   - Error: 4 seconds (`snackbarError`)
   - Info: 3 seconds (`snackbarDefault`)

5. Verify RTL behavior: SnackBar content with `Row` and `Flexible` should naturally adapt to RTL layout direction. No explicit RTL handling needed since Flutter handles this automatically for `Row`.

6. Run `flutter analyze lib/` — must report zero issues.
</action>

<acceptance_criteria>
- grep "hideCurrentSnackBar" lib/shared/widgets/feedback/snack_helper.dart confirms no stacking
- grep "SnackBarBehavior.floating" lib/shared/widgets/feedback/snack_helper.dart confirms floating
- grep "DismissDirection.horizontal" lib/shared/widgets/feedback/snack_helper.dart confirms swipe dismiss
- flutter analyze lib/ reports zero issues
</acceptance_criteria>

---

## Task 4: Run Full Analysis and Verify

<read_first>
- (none — verification-only task)
</read_first>

<action>
1. Run `flutter analyze lib/` — must report zero issues.
2. Run `flutter test test/unit/` — ensure no regressions.
3. Verify D-10 is fully addressed:
   - SnackBars are compact (smaller icon, smaller text, tighter padding)
   - SnackBars are bottom-aligned (floating behavior)
   - SnackBars auto-dismiss (3s default, 4s error)
   - SnackBars can be swiped to dismiss
   - All callsites use SnackHelper (no raw SnackBar constructors outside snack_helper.dart)
4. Verify no unused imports or dead code from the replacements.
</action>

<acceptance_criteria>
- flutter analyze lib/ reports "No issues found!"
- flutter test completes with zero failures
- grep -rn "SnackBar(" lib/ --include="*.dart" returns results ONLY in snack_helper.dart
</acceptance_criteria>
