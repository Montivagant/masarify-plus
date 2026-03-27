# Masarify — Play Store Launch Stack Research

_Date: 2026-03-27 | Scope: Performance, Billing, Store Submission, App Size_
_Context: Flutter/Dart app, Riverpod 2.x, Drift, go_router. Impeller disabled (BackdropFilter glassmorphism). Min SDK 24. Currently targeting API 34._

---

## 1. Flutter Performance Tools

### 1.1 Build Modes for Profiling

**Confidence: HIGH**

Always profile in `--profile` mode, never debug. Debug mode uses JIT compilation and disables most optimizations — numbers are meaningless.

| Mode | Use For | Command |
|------|---------|---------|
| `debug` | Development only — never benchmark | `flutter run` |
| `profile` | All performance measurement | `flutter run --profile` |
| `release` | Final size measurement | `flutter build apk --release` |

Profile mode: retains DevTools service ports and timeline events, compiles with AOT optimizations, gives realistic numbers.

### 1.2 Startup Trace

**Confidence: HIGH**

```bash
# Generates build/start_up_info.json with microsecond timestamps
flutter run --profile --trace-startup

# Key metrics in the JSON output:
# "timeToFirstFrameMicros" — cold start to first visible frame
# "timeToFrameworkInitMicros" — Dart VM + Flutter framework init
# "timeAfterFrameworkInitMicros" — first build pass
```

Target for PERF-01: `timeToFirstFrameMicros` under 2,000,000 (2 seconds) on mid-range device.

**Masarify-specific concern:** The app initializes Drift (SQLite), Riverpod providers, and loads 34 default categories at startup. Profile which providers are synchronously awaited in `main()` — defer any non-critical initialization.

Optimization strategies:
- Use `SplashScreen` / `flutter_native_splash` to cover native boot phase (already in pubspec)
- Lazy-initialize non-critical providers (AI services, backup service)
- Move `runApp()` earlier; defer heavy DB setup behind a `FutureProvider`
- Avoid `await` chains in `main()` beyond the absolute minimum (DB open + provider container)

### 1.3 Frame Rendering — DevTools Performance View

**Confidence: HIGH**

```bash
# Connect DevTools to a running profile build
flutter run --profile --dds-port=8181 --disable-service-auth-codes
# Then open: http://localhost:8181 or via `flutter pub global run devtools`
```

Frame budget: **16ms at 60fps**, **8ms at 120fps**. A bar in the flame chart colored red = jank frame.

The performance view shows two threads:
- **UI thread** — Dart/Flutter widget build + layout
- **Raster thread** — GPU painting (Skia, since Impeller is disabled)

**Masarify-specific concern:** Impeller is disabled (`android:value="false"` in AndroidManifest). The app runs on Skia. This means:
- Shader compilation jank is a real risk on first run
- `saveLayer()` calls (BackdropFilter glassmorphism) are expensive — already present throughout the design system
- Use `--cache-sksl` flag to pre-warm shaders during testing:
  ```bash
  flutter run --profile --cache-sksl --purge-persistent-cache
  # Then record SKSLs: flutter run --profile --cache-sksl
  # Bundle them: flutter build apk --bundle-sksl-path flutter_01.sksl.json
  ```

### 1.4 CPU Profiler

**Confidence: HIGH**

Open DevTools → CPU Profiler tab. Capture a trace during:
1. App startup (first 3 seconds)
2. Scrolling through a 500-item transaction list (PERF-02)
3. Opening the AI chat screen

Look for hot paths in:
- `TransactionListSection` / `TransactionCard` rebuild frequency
- Drift stream subscriptions triggering full list rebuilds
- `fl_chart` analytics rendering

Custom timeline markers for targeted profiling:
```dart
import 'dart:developer';

Timeline.startSync('DB_open');
// ... drift initialization
Timeline.finishSync();
```

### 1.5 Memory Profiler

**Confidence: MEDIUM**

DevTools → Memory tab. Primary concern for Masarify is:
- Chat message list growing unbounded (ChatMessages DB table)
- Large asset images (brand icons, 30+ Egyptian brands) held in memory
- `fl_chart` datasets for analytics — ensure they're computed lazily

Key metric: watch for sawtooth GC patterns during list scrolling (memory leak indicator).

### 1.6 Widget Rebuild Inspector

**Confidence: HIGH**

```dart
// Enable in debug builds to see rebuild counts
import 'package:flutter/rendering.dart';
debugProfileBuildsEnabled = true;
```

Or use DevTools → Flutter Inspector → "Highlight repaints" toggle.

For PERF-02 (smooth scrolling 500+ transactions): ensure `TransactionCard` uses `const` constructors wherever possible, and that Riverpod providers serving the list use `.select()` to avoid broadcasting unrelated state changes.

### 1.7 Database Query Performance (PERF-03)

**Confidence: HIGH — Drift-specific**

Drift streams re-emit on any table write. For heavy users (1000+ transactions):
- Use `watch()` with `.map()` to filter at the query level, not in Dart
- Add indexes on `(wallet_id, date)` and `(category_id)` for transaction lookups
- Use `Drift`'s `batchInsert` for bulk operations
- Check query plans with `EXPLAIN QUERY PLAN` via raw SQL in tests

```dart
// Index example in Drift table definition
@override
List<String> get customConstraints => ['CREATE INDEX IF NOT EXISTS idx_txn_date ON transactions(date DESC)'];
```

---

## 2. Google Play Billing

### 2.1 Current State: `in_app_purchase` vs RevenueCat

**Confidence: HIGH**

The project already has `in_app_purchase: ^3.2.0` in pubspec.yaml. The PROJECT.md decision is confirmed: **use Google Play Billing directly** via `in_app_purchase`, not RevenueCat.

**Comparison for this specific context:**

| Factor | `in_app_purchase` (direct) | `purchases_flutter` (RevenueCat) |
|--------|---------------------------|----------------------------------|
| Setup effort | Higher (more boilerplate) | Lower (~2x faster) |
| Server-side validation | Must build yourself | Included (free tier) |
| Subscription analytics | None built-in | Full dashboard (MRR, churn, trial conversions) |
| Cost | Free | Free up to $2,500/mo gross revenue |
| Billing Library version | Tracks Flutter plugin releases | Actively maintained, BL8 already supported |
| iOS parity | Yes (StoreKit 2 default in latest) | Yes |
| Offline-first risk | None (purchase validation is online by nature) | None |

**Decision rationale stands:** For a solo developer at launch, `in_app_purchase` is viable. The free tier ($0 until $2,500/mo revenue) makes RevenueCat compelling for a future migration, but adds a third-party dependency and external service to the trust model.

### 2.2 Critical: Play Billing Library Version

**Confidence: HIGH — Action Required**

Current `in_app_purchase: ^3.2.0` bundles Google Play Billing Library **6.x**. Google's mandatory migration schedule:

| Deadline | Requirement |
|----------|-------------|
| August 1, 2025 | New apps must use Billing Library 7+ |
| November 1, 2025 | Existing apps must use Billing Library 7+ |
| **February 2026** | **All apps must use Billing Library 8+** |

**Current status (March 2026):** Billing Library 8.3.0 is latest stable. The February 2026 deadline for BL8 has passed or is imminent — submitting a new app now requires BL8.

**Action:** Check the latest `in_app_purchase_android` version. There is an open Flutter issue (#171523) tracking BL8 support. As of this research, `in_app_purchase` may not yet bundle BL8 natively.

```bash
# Check current version status
flutter pub outdated
# Look for: in_app_purchase_android
```

If `in_app_purchase_android` does not yet support BL8, options are:
1. **Wait for the official Flutter plugin update** (lowest risk — monitor https://pub.dev/packages/in_app_purchase/changelog)
2. **Override the native dependency** in `android/app/build.gradle.kts`:
   ```kotlin
   dependencies {
       implementation("com.android.billingclient:billing:8.3.0")
   }
   ```
   (risky — may break the plugin's Kotlin/Java interface layer)
3. **Migrate to RevenueCat** (`purchases_flutter: ^8.x`) which already supports BL8

### 2.3 Subscription Implementation Architecture

**Confidence: HIGH**

The recommended implementation pattern for `in_app_purchase` with subscriptions:

```
App → InAppPurchase.instance.buyNonConsumable() → Purchase stream
     → PurchaseDetails.status
         ├── pending    → Show loading, don't grant entitlement
         ├── purchased  → [Validate] → Grant Pro access → completePurchase()
         ├── restored   → [Validate] → Grant Pro access → completePurchase()
         ├── error      → Show error message
         └── canceled   → No-op
```

**Server-side validation for Masarify:**

The `in_app_purchase` plugin does not expose the purchase signature directly for offline validation. For a client-only approach:
- Use `PurchaseDetails.verificationData.serverVerificationData` (base64 token)
- Send to Google Play Developer API for validation
- Requires a backend service account (Google Cloud Console)

**For initial launch (pragmatic approach):** Given offline-first architecture and Egyptian market (bandwidth-conscious), a lightweight approach:
1. Trust the purchase stream from Google Play (client-side)
2. Store the purchase token in `flutter_secure_storage` (already in pubspec)
3. Validate on app launch by calling Play Developer API (requires internet — graceful degradation if offline)
4. Implement proper server validation before scaling (can be a simple Cloud Function or Supabase Edge Function — not Firebase)

**Important — NEVER skip `completePurchase()`:** Failing to call `InAppPurchase.instance.completePurchase(purchase)` results in automatic refund after 3 days on Android.

### 2.4 Subscription Lifecycle States

**Confidence: HIGH**

Google Play subscriptions go through states that must be handled:

| State | How to Detect | App Action |
|-------|--------------|------------|
| Active | `purchaseStatus == purchased` + token valid | Grant Pro |
| Grace Period | Token valid, payment failed, 3-7 days grace | Grant Pro, show renewal warning |
| Account Hold | Payment failed, grace expired | Revoke Pro, show paywall |
| Paused | User-paused subscription | Revoke Pro |
| Cancelled | Cancelled but not expired | Grant until expiry date |
| Expired | Token validation returns expired | Revoke Pro |

For Masarify, the minimal implementation:
- Store `purchaseToken` + `expiryDate` in `flutter_secure_storage`
- On app launch: if token present and within expiry, grant Pro
- On purchase/restore: update stored token

### 2.5 Free Trial Implementation

**Confidence: HIGH**

For PAYWALL-04 (7-day free trial): configure the trial in Google Play Console under subscription product settings, not in code. The `in_app_purchase` plugin surfaces the trial offer automatically via `ProductDetails`.

```dart
// Offering a subscription with trial
final purchaseParam = PurchaseParam(
  productDetails: productDetails,
  // No special trial code needed — Play Console configures the offer
);
await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
```

The `SubscriptionOfferDetails` on Android exposes the trial period so you can display "7-day free trial" in the paywall UI.

### 2.6 Required Play Console Setup

**Confidence: HIGH**

Before any billing code works:
1. App must be published to Play Console (at minimum Internal Testing track)
2. Subscription products must be created in Play Console → Monetize → Products → Subscriptions
3. Tester accounts added to licence testing list (Play Console → Setup → Licence Testing)
4. Service account created for server-side validation (Google Cloud Console → IAM)

**Test purchases:** Real purchases cannot be tested without a published app. Use test accounts (licence testers) for sandbox purchases that auto-cancel after a few minutes.

---

## 3. Play Store Submission

### 3.1 Target API Level — Action Required

**Confidence: HIGH**

Current `build.gradle.kts` has `targetSdk = 34`. This is **non-compliant** for new app submissions as of August 2026.

| Timeline | Requirement | Status for Masarify |
|----------|-------------|---------------------|
| August 31, 2025 | New apps must target API 35 | **Non-compliant** (targetSdk=34) |
| August 31, 2026 | New apps must target API 36 | Upcoming |

**Action — update `android/app/build.gradle.kts`:**
```kotlin
defaultConfig {
    applicationId = "com.masarify.app"
    minSdk = 24
    targetSdk = 35      // Was 34 — required for new submission
    compileSdk = 35     // Match targetSdk
    // ...
}
```

**API 35 behavioral changes to audit for Masarify:**
- Edge-to-edge display is enforced by default on API 35+ (affects status bar / navigation bar insets)
- Predictive back gesture changes (may affect go_router back navigation)
- `SCHEDULE_EXACT_ALARM` permission behavior changes (already declared in manifest)
- `POST_NOTIFICATIONS` runtime permission required (already declared and handled via `flutter_local_notifications`)

### 3.2 Required Submission Assets

**Confidence: HIGH**

| Asset | Specification | Notes |
|-------|--------------|-------|
| App icon | 512×512 PNG, no alpha | Already handled by `flutter_launcher_icons` |
| Feature graphic | 1024×500 PNG/JPG | Required for store listing header |
| Screenshots | Min 2, max 8 per device type | Phone (16:9 or 9:16), 320-3840px |
| Short description | Max 80 chars | Appears in search results |
| Full description | Max 4000 chars | HTML-like formatting supported |
| Privacy policy URL | HTTPS, publicly accessible | **Mandatory** — see §3.3 |
| App category | Finance | Select in Play Console |

Screenshots must come from the actual app. Given ONBOARD-02 is in scope, take screenshots after onboarding polish is complete.

### 3.3 Privacy Policy Requirements

**Confidence: HIGH**

A privacy policy is **mandatory** for Masarify due to:
1. App requests `RECORD_AUDIO` permission (voice input)
2. App requests `ACCESS_FINE_LOCATION` permission
3. App uses `USE_BIOMETRIC` permission
4. App is categorized as Finance
5. Google Drive backup accesses `google_sign_in` (personal data)

Minimum content requirements:
- What data is collected (audio for voice transcription, location — if used, biometric identifiers)
- How data is stored (locally on-device, AES-256 encrypted backup to user's own Drive)
- Third-party services used (Google AI Studio/Gemini for voice, OpenRouter for AI chat)
- Data retention and deletion policy
- Contact information

**Finance-specific note:** Masarify is a **personal expense tracker**, NOT a personal loan app. The April 2025 Google Play policy changes for personal loans/credit apps (strict APR disclosure rules, prohibition on accessing contacts/photos) do not apply. However, accurately labeling the app category as "Finance > Personal Finance" (not "Finance > Money Transfer" or "Finance > Loans") is important.

### 3.4 Data Safety Section

**Confidence: HIGH**

All apps must complete the Data Safety form in Play Console. For Masarify:

| Data Type | Collected? | Shared? | Notes |
|-----------|-----------|---------|-------|
| Financial info (transactions) | Yes | No | Stored on-device only |
| Audio files | Yes (ephemeral) | Yes — Gemini API | Voice input only, not stored |
| Location | Optional | No | For context hints only |
| Name/email | No | No | Google Sign-In for Drive only (scoped) |
| App activity | No | No | |
| Device IDs | No | No | |

The form asks: "Is your app's data encrypted in transit?" → Yes (HTTPS for all API calls)
"Can users request data deletion?" → Yes (delete account / uninstall removes all local data)

**Hosting the privacy policy:** Use a simple static page. Options: GitHub Pages, Notion public page, or a dedicated domain. Must be HTTPS and permanently accessible.

### 3.5 App Signing — Play App Signing

**Confidence: HIGH**

The current `build.gradle.kts` already has a `signingConfigs.release` block reading from `key.properties`. The recommended flow for Play Store:

**Play App Signing (mandatory for AAB uploads):**
- You sign the AAB with your **upload key** (your local `key.properties` keystore)
- Google re-signs the final APKs with the **app signing key** (managed by Google)
- Users receive APKs signed by Google's app signing key

**Critical:** Store the upload keystore (`key.properties` + `.jks` file) securely. If lost, you cannot push updates. Options:
- Encrypted backup to personal Google Drive (separate from app data)
- Password manager with file attachment (Bitwarden, 1Password)
- GitHub Actions secret (for CI/CD)

**Key generation (if not already done):**
```bash
keytool -genkey -v -keystore ~/masarify-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias masarify-upload
```

The upload key must be RSA, 2048 bits or larger. The existing build config looks correct — verify `key.properties` references the correct file path.

### 3.6 Content Rating

**Confidence: HIGH**

Process: Play Console → App content → Ratings → Start questionnaire (IARC-based)

For a personal finance tracker (Masarify), expected answers:
- Violence: None
- Sexual content: None
- Profanity: None
- Controlled substances: None
- Gambling/simulated gambling: None (no investment features, no betting)
- Dangerous activities: None

Expected rating: **Everyone (E)** across all rating systems (ESRB, PEGI, USK, etc.)

This is straightforward — do not skip this step. Apps without a content rating cannot be published.

### 3.7 Submission Format

**Confidence: HIGH**

AAB (Android App Bundle) is mandatory for new apps. APK-only submissions are no longer accepted for new apps on Google Play (as of August 2021, now universally enforced).

```bash
# Play Store submission
flutter build appbundle --release

# The output: build/app/outputs/bundle/release/app-release.aab
# Upload this file to Play Console → Internal Testing → Create new release
```

Start with **Internal Testing** track:
1. Upload AAB to Internal Testing
2. Add tester email addresses
3. Test billing with licence tester accounts
4. Graduate to Closed Testing → Open Testing → Production

### 3.8 Review Timeline

**Confidence: MEDIUM**

New apps (first-time submissions) take **3-7 business days** for initial review in 2026. Finance apps may trigger additional manual review. Do not plan a hard launch date without a 2-week buffer from first submission.

---

## 4. Flutter App Size

### 4.1 Baseline Measurement

**Confidence: HIGH**

Before optimizing, measure:
```bash
# Measure actual download size (what users download from Play Store)
flutter build appbundle --release
# Upload to Play Console → Internal Testing → Review bundle → "Explore bundle"
# Play Console shows per-ABI download size after splitting

# Local APK size estimate (build split APKs)
flutter build apk --release --split-per-abi
# Check: build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
du -sh build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Detailed size analysis
flutter build apk --analyze-size --target-platform android-arm64
# Generates: build/app/outputs/flutter-apk/app-release.apk-analysis.json
# Open in DevTools → App Size tool for treemap visualization
```

Target for Egyptian market (bandwidth-conscious, many users on 4G with data caps): **under 25MB download size** for arm64 APK.

### 4.2 Split APKs / AAB — Primary Optimization

**Confidence: HIGH**

Already implemented in `build-release.sh` (`--split-per-abi`). For Play Store, AAB handles this automatically — Google generates per-ABI, per-density, per-language APKs. Users download only what their device needs.

Expected size savings vs fat APK: **30-40% reduction** per user download.

The `arm64-v8a` APK covers 95%+ of Egyptian Android market (2020+ devices). Users on old 32-bit phones (`armeabi-v7a`) are diminishing.

### 4.3 Enable R8 + Resource Shrinking

**Confidence: MEDIUM** (known Flutter 3.29+ issues — test carefully)

Add to `android/app/build.gradle.kts` release block:

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true        // Enable R8 code shrinking
        isShrinkResources = true      // Remove unused resources
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

Create `android/app/proguard-rules.pro`:
```
# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Drift / SQLite
-keep class com.almworks.sqlite4java.** { *; }

# Google Play Billing
-keep class com.android.billingclient.** { *; }

# Google Sign-In (Drive Backup)
-keep class com.google.android.gms.** { *; }
-keep class com.google.api.** { *; }

# Keep annotation processors
-keepattributes *Annotation*
-keepattributes Signature
```

**Warning:** As of Flutter 3.29.3, `isMinifyEnabled = true` with Kotlin DSL causes "missing classes" issues for some plugin combinations. Test thoroughly — if the release build fails, disable and ship without R8 initially (size penalty ~15-20%).

Expected savings: **10-15% additional reduction** beyond tree shaking.

### 4.4 Dart Tree Shaking (Automatic)

**Confidence: HIGH**

Flutter automatically tree-shakes Dart code and icon fonts in release mode. No configuration needed. Specific to Masarify:

- **Phosphor Icons (`phosphor_flutter`):** Only icons referenced via `AppIcons.*` will be included. Icons are tree-shaken at font level. Ensure all icon references go through `AppIcons` (already enforced by conventions).
- **Material Icons:** Only referenced icons included. The `MaterialIcons-Regular.otf` font is tree-shaken from 1.6MB to ~10KB for typical apps.
- **Google Fonts (`google_fonts: ^6.2.1`):** The package fetches fonts at runtime by default. For offline-first: either bundle fonts manually in `assets/fonts/` (already done via `google_fonts` asset bundling) or ensure `GoogleFonts.config.allowRuntimeFetching = false` is set. Bundled fonts add to APK size but are required for offline-first. Plus Jakarta Sans covers Latin + Arabic subsets — consider subsetting to only needed Unicode ranges.

```dart
// In main() — critical for offline-first
void main() {
  GoogleFonts.config.allowRuntimeFetching = false; // Force bundled fonts
  runApp(const ProviderScope(child: MasarifyApp()));
}
```

### 4.5 Asset Optimization

**Confidence: HIGH**

```bash
# Audit current asset sizes
find assets/ -name "*.png" -o -name "*.jpg" | xargs ls -lh | sort -k5 -rh | head -20

# Compress PNG files losslessly (install pngcrush or oxipng)
find assets/ -name "*.png" -exec pngcrush -reduce -brute {} {}.crushed \;

# Convert large PNGs to WebP (Flutter supports WebP natively)
# WebP typically 25-34% smaller than PNG
```

For brand icons (30+ Egyptian brands in `assets/icons/`):
- Use SVG or WebP instead of PNG where possible
- Target max 48×48dp resolution for list icons (96×96px @2x)
- Consider using a font-based approach for frequently-used brand icons

For animation assets (`assets/animations/`):
- Lottie JSON files can be minified (remove whitespace)
- Check if Lottie animations are actually used (Lottie microinteractions deferred to v1.1 per PROJECT.md)
- Remove unused animation files before shipping

### 4.6 Deferred Components (Advanced — v1.1 Candidate)

**Confidence: LOW for initial launch**

Flutter's deferred components allow lazy-loading of Dart code. Requires Play Feature Delivery (Android Dynamic Delivery). Setup is complex and requires Play Console configuration. Not recommended for initial launch given the complexity vs. benefit tradeoff for an app that is already relatively small.

**Defer to v1.1** alongside Home Widget work.

### 4.7 Remove Unused Packages

**Confidence: HIGH**

Audit `pubspec.yaml` for packages whose features are disabled:

| Package | Status | Action |
|---------|--------|--------|
| `another_telephony: ^0.4.1` | SMS disabled (`kSmsEnabled=false`) | **Consider removing** — adds native library, may trigger Play Store SMS policy scrutiny even with `tools:node="remove"` in manifest |
| `geolocator: ^13.0.1` | Location usage unclear | Audit — if not used for core features, remove |
| `geocoding: ^3.0.0` | Location-dependent | Remove if `geolocator` removed |
| `rxdart: ^0.28.0` | Used for activity providers | Keep — core feature |

Removing `another_telephony` in particular reduces risk on the SMS policy scrutiny front and reduces APK size slightly.

### 4.8 Expected Size Budget

For Masarify arm64 APK on Play Store (after optimizations):

| Component | Estimated Size |
|-----------|---------------|
| Flutter engine | ~6 MB |
| Dart code (compiled) | ~3-4 MB |
| SQLite native lib | ~1.5 MB |
| Assets (fonts + icons + animations) | ~2-3 MB |
| Third-party native libs | ~2 MB |
| **Total (arm64 split APK)** | **~15-20 MB** |

This is within the Egyptian market target of <25 MB.

---

## 5. Summary: Actions for Current Milestone

| Priority | Action | Confidence | Section |
|----------|--------|------------|---------|
| CRITICAL | Update `targetSdk` and `compileSdk` to 35 in `build.gradle.kts` | HIGH | §3.1 |
| CRITICAL | Verify `in_app_purchase_android` supports Play Billing Library 8 | HIGH | §2.2 |
| HIGH | Run `--trace-startup` profile, optimize `main()` to hit 2s target | HIGH | §1.2 |
| HIGH | Write privacy policy (HTTPS URL required before submission) | HIGH | §3.3 |
| HIGH | Complete Data Safety section in Play Console | HIGH | §3.4 |
| HIGH | Set `GoogleFonts.config.allowRuntimeFetching = false` in `main()` | HIGH | §4.4 |
| HIGH | Complete IARC content rating questionnaire | HIGH | §3.6 |
| MEDIUM | Enable R8 + resource shrinking, test build stability | MEDIUM | §4.3 |
| MEDIUM | Audit and potentially remove `another_telephony` package | HIGH | §4.7 |
| MEDIUM | Run `flutter build apk --analyze-size` and review treemap | HIGH | §4.1 |
| LOW | Add Drift indexes for (wallet_id, date) on transactions | HIGH | §1.7 |
| LOW | Evaluate deferred components (defer to v1.1) | LOW | §4.6 |

---

_Sources consulted:_
- https://docs.flutter.dev/perf/ui-performance
- https://docs.flutter.dev/tools/devtools/performance
- https://developer.android.com/google/play/requirements/target-sdk
- https://developer.android.com/google/play/billing/migrate-gpblv8
- https://pub.dev/packages/in_app_purchase/changelog
- https://support.google.com/googleplay/android-developer/answer/11926878
- https://support.google.com/googleplay/android-developer/answer/10787469
- https://developer.android.com/google/play/billing/release-notes
- https://arslanapax.com/how-i-reduced-my-flutter-apk-aab-size-a-practical-step-by-step-guide-with-gradle-kts-samples/
- https://www.revenuecat.com/blog/engineering/google-play-billing-library-7-features-migration/
- https://www.revenuecat.com/blog/engineering/google-play-billing-v8/
