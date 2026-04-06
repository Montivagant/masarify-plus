# Onboarding Google Sign-In Screen Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Sign in with Google" screen to onboarding (Page 4, before Starting Balance) for Drive backup enrollment, strongly encouraged but skippable.

**Architecture:** Insert a new page into the existing 5-page `PageView` in `onboarding_screen.dart`, making it a 6-page flow. The new page uses the existing `GoogleDriveBackupService.signIn()` (which now rethrows errors) and follows the same visual pattern as existing onboarding pages (parallax icon, title, body, action buttons). No subscription/trial logic changes.

**Tech Stack:** Flutter, Riverpod, google_sign_in, existing MasarifyDS components (AppButton, AppIcons, AppSizes)

---

### Task 1: Add l10n strings for the Google Sign-In onboarding page

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ar.arb`

- [ ] **Step 1: Add English strings**

Add after the `onboarding_starting_balance_set` key in `lib/l10n/app_en.arb`:

```json
  "onboarding_google_title": "Protect Your Data",
  "onboarding_google_body": "Sign in with Google to automatically back up your finances to Google Drive.\nYour backups are encrypted — only you can access them.",
  "onboarding_google_sign_in": "Sign in with Google",
  "onboarding_google_skip": "I'll do this later",
  "onboarding_google_success": "Signed in as {email}",
  "@onboarding_google_success": {"placeholders": {"email": {"type": "String"}}},
```

- [ ] **Step 2: Add Arabic strings**

Add after the `onboarding_starting_balance_set` key in `lib/l10n/app_ar.arb`:

```json
  "onboarding_google_title": "احمِ بياناتك",
  "onboarding_google_body": "سجّل الدخول بحساب Google لحفظ بياناتك المالية تلقائيًا على Google Drive.\nالنسخ الاحتياطية مشفرة — أنت وحدك من يمكنه الوصول إليها.",
  "onboarding_google_sign_in": "تسجيل الدخول بحساب Google",
  "onboarding_google_skip": "سأفعل ذلك لاحقًا",
  "onboarding_google_success": "تم تسجيل الدخول كـ {email}",
  "@onboarding_google_success": {"placeholders": {"email": {"type": "String"}}},
```

- [ ] **Step 3: Regenerate l10n**

Run: `flutter gen-l10n`
Expected: No errors, new keys available in `AppLocalizations`.

- [ ] **Step 4: Verify no analysis errors**

Run: `flutter analyze lib/l10n/`
Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ar.arb
git commit -m "feat: add l10n strings for onboarding Google Sign-In page"
```

---

### Task 2: Build the Google Sign-In onboarding page widget

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/onboarding_screen.dart` (add new private widget at bottom)

- [ ] **Step 1: Add import for google_drive_provider**

Add this import to the top of `onboarding_screen.dart`, after the existing imports:

```dart
import '../../../../shared/providers/google_drive_provider.dart';
```

Also add `dart:developer`:

```dart
import 'dart:developer' as dev;
```

- [ ] **Step 2: Add the `_GoogleSignInPage` widget**

Add this widget at the bottom of `onboarding_screen.dart`, before the closing of the file (after `_StartingBalancePage`):

```dart
// ── Page 4: Google Sign-In ──────────────────────────────────────────────────

class _GoogleSignInPage extends ConsumerStatefulWidget {
  const _GoogleSignInPage({
    required this.pageOffset,
    required this.onNext,
    required this.onSkip,
  });

  final double pageOffset;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  ConsumerState<_GoogleSignInPage> createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends ConsumerState<_GoogleSignInPage> {
  bool _busy = false;
  bool _signedIn = false;
  String? _email;

  Future<void> _signIn() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final driveService = ref.read(googleDriveBackupProvider);
      final account = await driveService.signIn();
      if (!mounted) return;
      if (account != null) {
        setState(() {
          _signedIn = true;
          _email = account.email;
        });
        // Brief pause to show success state, then auto-advance.
        await Future<void>.delayed(AppDurations.splashHold);
        if (mounted) widget.onNext();
      }
      // account == null means user cancelled — stay on page, no error.
    } catch (e) {
      dev.log('Onboarding sign-in error: $e', name: 'Onboarding');
      if (mounted) {
        SnackHelper.showError(context, context.l10n.backup_sign_in_failed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
      child: Column(
        children: [
          const Spacer(),
          // ── Icon ───────────────────────────────────────────────────────
          Transform.translate(
            offset: Offset(
              widget.pageOffset * AppSizes.onboardingParallaxOffset,
              0,
            ),
            child: Container(
              width: AppSizes.onboardingIcon,
              height: AppSizes.onboardingIcon,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: AppSizes.opacityLight),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _signedIn ? AppIcons.checkCircle : AppIcons.backup,
                size: AppSizes.iconXl2,
                color: cs.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          // ── Title ──────────────────────────────────────────────────────
          Text(
            _signedIn
                ? context.l10n.onboarding_google_success(_email ?? '')
                : context.l10n.onboarding_google_title,
            style: context.textStyles.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (!_signedIn) ...[
            const SizedBox(height: AppSizes.sm),
            Text(
              context.l10n.onboarding_google_body,
              style: context.textStyles.bodyMedium?.copyWith(
                color: cs.outline,
                height: AppSizes.lineHeightNormal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const Spacer(flex: 2),
          // ── Buttons ────────────────────────────────────────────────────
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(AppSizes.xl),
              child: CircularProgressIndicator.adaptive(),
            )
          else if (!_signedIn) ...[
            AppButton(
              label: context.l10n.onboarding_google_sign_in,
              onPressed: _signIn,
              icon: AppIcons.backup,
            ),
            const SizedBox(height: AppSizes.sm),
            TextButton(
              onPressed: widget.onSkip,
              child: Text(
                context.l10n.onboarding_google_skip,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: cs.outline,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSizes.xl),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verify no analysis errors**

Run: `flutter analyze lib/features/onboarding/`
Expected: `No issues found!` (widget is defined but not yet wired into the PageView)

- [ ] **Step 4: Commit**

```bash
git add lib/features/onboarding/presentation/screens/onboarding_screen.dart
git commit -m "feat: add _GoogleSignInPage widget for onboarding"
```

---

### Task 3: Wire the new page into the onboarding PageView

**Files:**
- Modify: `lib/features/onboarding/presentation/screens/onboarding_screen.dart`

- [ ] **Step 1: Update `_pageCount` from 5 to 6**

In `_OnboardingScreenState`, change:

```dart
  static const _pageCount = 5;
```

to:

```dart
  static const _pageCount = 6;
```

- [ ] **Step 2: Update `_skipToStartingBalance` to skip to new last page**

The `_skipToStartingBalance` method already uses `_pageCount - 1`, so it automatically targets the correct page. No change needed — but verify it still references `_pageCount - 1`.

- [ ] **Step 3: Update the `showSkip` condition**

The skip button currently shows on slides 1-3 (feature previews). Now the Google page is page 4, so skip should show on pages 1-3 still (skip jumps to starting balance = page 5 = `_pageCount - 1`). The condition `_currentIndex >= 1 && _currentIndex <= 3` is still correct. No change needed.

- [ ] **Step 4: Insert the Google Sign-In page into the PageView**

In the `build` method, in the `PageView.children` list, insert the new page **between** Page 3 (AI Financial Advisor) and the current Page 4 (Starting Balance). Replace the `PageView` children section:

Change the comment `// Page 4: Starting balance (optional)` block and add the new page before it:

```dart
                    // Page 4: Google Sign-In (strongly encouraged)
                    _GoogleSignInPage(
                      pageOffset: _offsetForPage(4),
                      onNext: _nextPage,
                      onSkip: _nextPage,
                    ),
                    // Page 5: Starting balance (optional)
                    _StartingBalancePage(
                      pageOffset: _offsetForPage(5),
                      loading: _loading,
                      onAmountChanged: (piastres) =>
                          _startingBalancePiastres = piastres,
                      onFinish: _finish,
                      onSkip: () {
                        _startingBalancePiastres = 0;
                        _finish();
                      },
                    ),
```

Note: Both `onNext` and `onSkip` call `_nextPage` — skip just advances to Starting Balance without signing in.

- [ ] **Step 5: Update the class doc comment**

Change the class doc comment at the top from:

```dart
/// 5-page onboarding flow:
///   Page 0 — Welcome hero (app value prop + language toggle)
///   Pages 1-3 — Value preview slides (animated feature demos)
///   Page 4 — Starting balance (optional, skip → 0)
```

to:

```dart
/// 6-page onboarding flow:
///   Page 0 — Welcome hero (app value prop + language toggle)
///   Pages 1-3 — Value preview slides (animated feature demos)
///   Page 4 — Google Sign-In (Drive backup enrollment, skippable)
///   Page 5 — Starting balance (optional, skip → 0)
```

- [ ] **Step 6: Verify no analysis errors**

Run: `flutter analyze lib/features/onboarding/`
Expected: `No issues found!`

- [ ] **Step 7: Manual test checklist**

Test the following on a debug build:

1. Onboarding starts at Welcome page (Page 0)
2. "Next" advances through pages 1-3 normally
3. Skip button on pages 1-3 jumps to Starting Balance (Page 5, last page)
4. Page 4 shows Google Sign-In screen with shield/backup icon, title, body, two buttons
5. Tapping "Sign in with Google" shows Google account picker
6. After successful sign-in: checkmark icon + email shown, auto-advances to Starting Balance
7. Tapping "I'll do this later" advances to Starting Balance
8. If sign-in fails (e.g. cancel network): error snackbar shown, stays on page
9. User cancelling account picker: no error, stays on page
10. Page indicator shows 6 dots
11. RTL (Arabic) layout is correct
12. Starting Balance page still works correctly (set balance / skip)
13. Onboarding completes normally after Starting Balance

- [ ] **Step 8: Commit**

```bash
git add lib/features/onboarding/presentation/screens/onboarding_screen.dart
git commit -m "feat: wire Google Sign-In page into onboarding flow as Page 4"
```
