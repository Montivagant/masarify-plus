---
active: true
iteration: 1
max_iterations: 6
completion_promise: "AUDIT COMPLETE"
started_at: "2026-02-28T12:54:42Z"
---


## Masarify Plus — Full Surgical Audit & Fix Loop

You are auditing the Masarify Plus Flutter project at d:\Masarify-Plus.
Read MEMORY.md at C:\Users\omarw\.claude\projects\d--Masarify-Plus\memory\MEMORY.md for project rules before doing ANYTHING.

### Phase Detection
Check git status. If your previous iteration left uncommitted fixes, continue from where you stopped.
- If this is iteration 1-3: run FULL DETAILED AUDIT (all 9 categories below, deep scan).
- If this is iteration 4-5: run QUICK SWEEP (flutter analyze, grep for hardcoded values, dead code check only).
- If iteration 6+: output <promise>AUDIT COMPLETE</promise> if zero issues remain across all categories, otherwise keep fixing.

### Audit Categories (use parallel agents for independent categories)

**1. Dead Code & Unused Files**
- Find .dart files in lib/ that are never imported anywhere
- Find public classes, functions, methods that have zero references
- Find unused imports in every file
- Find files that are stubs with placeholder text still in them (e.g. 'Phase 3', 'TODO', 'STUB')

**2. Unused Dependencies**
- Cross-reference every package in pubspec.yaml dependencies against actual imports in lib/
- Flag any package that is never imported
- Do NOT remove dev_dependencies or transitive dependencies

**3. Hardcoded Styles & Non-Tokenized Values (CRITICAL)**
- Grep for Color(0x, Colors., const Color( — must use AppColors.* or context.colors or context.appTheme
- Grep for EdgeInsets hardcoded numbers — must use AppSizes.*
- Grep for TextStyle( with hardcoded fontSize/fontWeight — must use Theme.of(context).textTheme.* or context.textStyles.*
- Grep for BorderRadius.circular( with raw numbers — must use AppSizes.borderRadius*
- Grep for SizedBox( with raw width/height numbers — must use AppSizes.*
- Grep for Icon( with raw size: numbers — must use AppSizes.icon*
- Grep for Duration( with raw milliseconds — must use AppDurations.*
- Grep for Padding/margin with raw doubles — must use AppSizes.*
- Grep for withOpacity( or withValues(alpha: with raw doubles — must use AppSizes.opacity* tokens
- EXCEPTION: values inside app_colors.dart, app_sizes.dart, app_durations.dart, app_theme.dart, app_theme_extension.dart are definitions, not violations
- EXCEPTION: generated files (.g.dart, .freezed.dart), test files, and l10n files are exempt

**4. Hardcoded Arabic & English Text (CRITICAL)**
- Grep ALL .dart files in lib/ (excluding l10n/, .g.dart, .freezed.dart) for:
  - Arabic text literals: any string containing Arabic Unicode chars (U+0600-U+06FF) that is NOT inside app_en.arb, app_ar.arb, or l10n generated files
  - English UI-facing text literals: any Text('...' or title: '...' or label: '...' or hint: '...' or subtitle: '...' or hintText: '...' with hardcoded English strings
  - Hardcoded snackbar messages, dialog titles, button labels, tooltip strings
- ALL user-visible strings MUST use context.l10n.* keys
- If a key does not exist in app_en.arb / app_ar.arb, ADD it to both files with proper Arabic translation
- After adding keys, run: flutter gen-l10n
- EXCEPTION: log messages, debug prints, route paths, enum values, JSON keys, asset paths, regex patterns are NOT violations
- EXCEPTION: strings inside egyptian_arabic_finance.json dictionary, egyptian_sms_patterns.dart, and test files are exempt

**5. Architecture Violations**
- Any Navigator.push() or Navigator.pop() — must be context.push()/context.go()/context.pop()
- Any setState() in ConsumerWidget (only allowed in ConsumerStatefulWidget for AnimationController/form state)
- Any direct Drift/Flutter import in domain/ layer files
- Any provider not following the StreamProvider/FutureProvider pattern

**6. File & Folder Structure**
- Verify feature-first structure: lib/features/<name>/presentation/screens|widgets/, data/, domain/
- Find files in wrong directories (e.g., a widget file in screens/, a service in utils/)
- Check import ordering: ../../ paths must sort BEFORE ../ paths

**7. Code Quality**
- BuildContext used after async gap without mounted check
- Missing const constructors where possible
- Unused parameters in constructors or methods
- Empty catch blocks without at least a comment

**8. Run flutter analyze lib/**
- Must produce 'No issues found!'
- Fix every warning, info, and error

**9. Run flutter test (if test/ exists)**
- Run existing tests, fix any failures

### Rules for Fixing
- Fix issues IN PLACE — do not create new wrapper files
- Use existing design tokens: AppSizes.*, AppColors.*, AppIcons.*, AppDurations.*, context.appTheme.*, context.l10n.*
- For new l10n keys: add to BOTH app_en.arb AND app_ar.arb, then run flutter gen-l10n
- Run 'flutter analyze lib/' after each batch of fixes to verify zero warnings
- Run 'dart run build_runner build --delete-conflicting-outputs' if you modify any .dart file that has a .g.dart counterpart
- Commit each logical batch with a descriptive message
- If you find 0 issues in a full sweep, output <promise>AUDIT COMPLETE</promise>

