# Play Store Launch Pitfalls — Masarify

_Research date: 2026-03-27_
_Context: Flutter finance app, Egypt market, AI voice + chat, offline SQLite, subscription monetization_

---

## 1. Play Store Rejection Reasons

### 1.1 Financial Services Policy Compliance

**Pitfall:** Google classifies personal finance apps under its "Financial Services" policy, which requires explicit disclosure that the app does NOT provide regulated financial advice, investment recommendations, or banking services. Apps that imply otherwise — even through marketing copy — trigger review or rejection.

**Warning signs:**
- App description or onboarding calls itself an "AI Financial Advisor" without a disclaimer
- AI chat responses that sound like investment or tax advice
- Screenshots showing projections framed as guarantees
- Store listing copy: "smart financial advice", "tells you how to save" without qualification

**Prevention strategy:**
- Add a clear disclaimer on the Play Store listing and inside the app: "Masarify does not provide regulated financial, investment, or tax advice. All AI suggestions are for personal budgeting guidance only."
- In the AI chat system prompt, explicitly instruct the model to decline investment/tax questions and redirect to a professional
- Use phrasing like "AI spending insights" and "AI budgeting assistant" instead of "financial advisor" in the store listing
- Add disclaimer text on the onboarding page that introduces the AI feature

**Phase:** STORE-02 (Privacy policy) + STORE-01 (store listing copy audit)

---

### 1.2 Data Safety Section Requirements

**Pitfall:** Google's Data Safety section is mandatory and subject to enforcement. Mismatches between declared data practices and actual app behavior are a primary rejection trigger for finance apps — they receive heightened scrutiny. Incomplete or inconsistent declarations cause rejections weeks after initial submission.

**Warning signs:**
- Declaring "no data collected" when the app uses Gemini API (voice audio is transmitted)
- Not declaring audio data collection when voice input is active
- Not disclosing that data is shared with third parties (Google AI Studio, OpenRouter)
- Backup feature (Google Drive) not declared as optional data sharing

**What Masarify actually collects and shares:**
- **Audio data** — sent to Google AI Studio (Gemini) for voice input. Must be declared as "collected" and "shared with third parties" even if not stored.
- **App activity / financial data** — stored locally only via Drift/SQLite. Declare as "collected, not shared, encrypted in transit N/A".
- **Google Drive backup** — user-initiated, optional. Declare as "user-controlled data sharing".
- **AI chat messages** — sent to OpenRouter. Must be declared.
- **No account/identity data** — this is a plus; declare explicitly.

**Prevention strategy:**
- Map every network call: `GeminiAudioService` (voice), `AiChatService` (chat), backup service (Google Drive)
- In Data Safety: mark audio as "collected for app functionality, not retained by app after processing"
- Declare "Financial info" as "collected and stored on device only, not shared"
- Emphasize data deletion: user can delete all data via uninstall (no server-side storage)
- Review Google's Data Safety guidance: data "shared" = sent to any third party including AI APIs

**Phase:** STORE-02 (Privacy policy + Data Safety mapping)

---

### 1.3 Permissions Audit

**Pitfall:** Overly broad permissions — especially those on Google's "dangerous permissions" list — trigger manual review for finance apps. Play Store policy prohibits requesting permissions not directly needed for declared app functionality.

**Permissions Masarify likely requests and their risk level:**

| Permission | Risk | Status | Action |
|---|---|---|---|
| `RECORD_AUDIO` | Medium | Required for voice input | Justify in store listing — "Voice transaction input requires microphone" |
| `INTERNET` | Low | Required for AI features | Always acceptable |
| `RECEIVE_BOOT_COMPLETED` | Medium | For scheduled notifications | Acceptable with justification; must explain in privacy policy |
| `POST_NOTIFICATIONS` | Low | Android 13+ notification permission | Standard |
| `SCHEDULE_EXACT_ALARM` | High | Daily recap notification | May require exact alarm permission declaration in Android 12+; use `setExactAndAllowWhileIdle` or inexact alarm |
| SMS permissions | Critical | **Already removed via `tools:node="remove"`** | Confirmed safe |
| `READ_CONTACTS` | High | Not needed | Confirm not present |
| `ACCESS_FINE_LOCATION` | High | Not needed | Confirm not present |

**Warning signs:**
- `SCHEDULE_EXACT_ALARM` — Android 12+ requires this permission be declared and apps must justify why exact timing is needed. Use-exact-alarm policy enforced more strictly since 2024.
- Any SMS/contacts/location permissions silently included via transitive dependencies

**Prevention strategy:**
- Run `./gradlew dependencies` and audit merged AndroidManifest before submission
- Replace `setExact` with `setExactAndAllowWhileIdle` for daily recap; or switch to `WorkManager` which does not require exact alarm permission
- Add `<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" tools:node="remove"/>` if exact timing is not critical for recap notifications
- Audit transitive permission additions: check `build/outputs/merged_manifests/` in the AAB build

**Phase:** STORE-03 (release build prep) + PERF-01 (startup/notification audit)

---

### 1.4 AI/ML Disclosure Requirements

**Pitfall:** Google's policy (and increasingly consumer protection law globally) requires disclosure when AI-generated content could be mistaken for human/official advice. Finance apps with AI features face stricter scrutiny.

**Warning signs:**
- AI chat responses presented without any "AI-generated" label
- Voice parsing results presented as fact without showing the user what was interpreted
- AI-suggested category names or budget amounts with no indication they are model outputs

**Prevention strategy:**
- Label AI messages in the chat UI distinctly (already done via `MessageBubble` — ensure this is clear in screenshots)
- Voice confirm screen (already exists) correctly shows parsed data for user review before saving — this is the right pattern
- Add "AI-powered" or "Suggested by AI" micro-labels on insight cards generated by background AI services
- In the store listing, describe AI features accurately: "uses AI to parse your voice transactions" not "AI automatically tracks all your spending"
- Privacy policy must mention: which AI models are used, what data is sent, data retention by the AI provider (Google AI Studio / OpenRouter ZDR policies)

**Phase:** STORE-01 (listing), STORE-02 (privacy policy)

---

### 1.5 Subscription Transparency Requirements

**Pitfall:** Google has strict policies for apps with subscriptions. The most common rejection cause is an unclear paywall — specifically, not showing subscription price, duration, and trial terms before the user commits.

**Google's specific requirements:**
1. Price must be shown before purchase confirmation — cannot be revealed only inside the Google Play billing dialog
2. Trial terms (7-day free trial) must be shown in-app before purchase, not just in the Play billing sheet
3. The app must allow users to cancel subscription management via the system (i.e., link or instructions to `play.google.com/store/account/subscriptions`)
4. Apps that lock users out of previously accessible (non-paywalled) content when they cancel — without a grace period — will be flagged

**Warning signs:**
- Paywall screen shows "Pro" but not the price until Google's billing sheet opens
- Trial message says "Free trial" without specifying duration
- Settings > Subscription has no cancel/manage link

**Prevention strategy:**
- Paywall UI (PAYWALL-03) must show: "59 EGP/month — 7 days free, then billed monthly — Cancel anytime" before the purchase button
- Add "Manage subscription" button that opens: `https://play.google.com/store/account/subscriptions?sku=masarify_pro_monthly&package=com.masarify.app`
- Store listing subscription section must list the trial and price (Google auto-populates some but verify in Console)
- On cancel, do not immediately revoke access — respect the remainder of the paid period (Google enforces this)

**Phase:** PAYWALL-03 (UI), STORE-03 (submission checklist)

---

## 2. Performance Pitfalls

### 2.1 Jank in Transaction List Views

**Pitfall:** Transaction lists with 500+ items cause visible jank on mid-range Android devices (Snapdragon 4xx series, common in Egypt) when using standard `ListView.builder` with complex item widgets containing `BackdropFilter` or heavy `BoxDecoration`.

**Warning signs:**
- `TransactionCard` uses glassmorphism (BackdropFilter) — each BackdropFilter forces a new compositing layer and a full raster op
- `TransactionListSection` groups by date — recalculating groups on every rebuild is expensive
- Using `AnimatedList` or `ListView` without `itemExtent` forces Flutter to measure every item height
- Showing wallet name badges on every card (P5 Phase 3) adds widget subtree depth

**Prevention strategy:**
- Use `itemExtent` on `ListView.builder` if all cards are the same height — eliminates layout passes
- If heights vary, use `prototypeItem` parameter instead (Flutter 3.x)
- Avoid `BackdropFilter` per card — use it only on the navbar and sheet backgrounds. Use solid color cards with subtle shadow for transaction items (preserves the glass aesthetic at list scroll speed)
- Memoize date group calculations: compute in the provider/repository layer, cache with `ref.watch` — not inside `build()`
- Use `RepaintBoundary` around `TransactionCard` to isolate repaints
- Profile with `flutter run --profile` and DevTools' "Track Widget Rebuilds" before and after optimization

**Phase:** PERF-02 (smooth scrolling requirement)

---

### 2.2 Memory Leaks with Drift Streams

**Pitfall:** Drift returns `Stream<T>` from DAO queries. If these streams are subscribed to manually (not via Riverpod's `StreamProvider`), they leak if `.cancel()` is never called. Riverpod `StreamProvider` handles this automatically, but manual `StreamSubscription` in widgets or services does not.

**Warning signs:**
- Any `stream.listen(...)` call in a widget's `initState` without a corresponding `cancel()` in `dispose()`
- `BackgroundAiProvider` or `ActivityProvider` subscribing to multiple Drift streams in a service class without a clear lifecycle
- `CategorizationLearningService`, `RecurringPatternDetector` — if these hold stream references, they may outlive their providers

**Prevention strategy:**
- Audit all `stream.listen()` calls: `grep -r "\.listen(" lib/` — every one needs a matching cancel
- Prefer Riverpod `StreamProvider` for all Drift queries — lifecycle is managed automatically
- For services that must subscribe to streams (e.g., `BackgroundAiProvider`), use `ref.onDispose(() => subscription.cancel())` within the provider
- Run `flutter run --profile`, then in DevTools Memory tab: check for growing heap during long usage sessions (open 3-4 screens, go back, repeat 10 times — heap should not grow unboundedly)

**Phase:** PERF-03 (database optimization) + pre-launch audit

---

### 2.3 Startup Time Killers

**Pitfall:** Cold start time above 2 seconds on mid-range devices (Masarify's PERF-01 requirement) is almost always caused by doing too much on the main thread during initialization.

**Common causes in this codebase:**
- Drift database initialization is synchronous-looking but runs the migration chain — on first install with 13 schema versions, migration runs sequentially
- `NotificationService` initialization (flutter_local_notifications setup) on startup
- `CategorizationLearningService` pre-loading category mappings at boot
- Riverpod providers eagerly initialized at `ProviderScope` creation if overridden
- Large `brand_registry.dart` constant map loaded into memory at startup

**Warning signs:**
- `main.dart` awaiting multiple service initializations before `runApp()`
- `app_database.dart` running all migrations in series (expected, but should be benchmarked)
- Providers that query the database in their initialization path being used at screen 0

**Prevention strategy:**
- Move non-critical initializations after first frame: use `WidgetsBinding.instance.addPostFrameCallback` to defer `NotificationService.init()` and `CategorizationLearningService` prefetch
- Profile with `flutter run --trace-startup` — outputs a startup trace JSON showing exactly where time is spent
- Lazy-load `brand_registry` map: use `late final` so it's not allocated until first access
- Keep `main()` to: `WidgetsFlutterBinding.ensureInitialized()`, DB init, timezone init, `runApp()` — nothing else
- On subsequent launches, Drift only needs to open the existing database (fast) — migration only runs once per version bump

**Phase:** PERF-01 (startup requirement)

---

### 2.4 BackdropFilter / Glassmorphism Performance

**Pitfall:** `BackdropFilter` with `ImageFilter.blur` is one of the most expensive Flutter widgets. It forces compositing and a full GPU raster pass for the blurred region on every frame. On Android devices without a dedicated GPU (low-end Snapdragon 4xx), this causes sustained jank during scroll and animation.

**Masarify specifics:**
- The floating nav bar uses `BackdropFilter` (sigma 20) — this runs every frame
- The 3-tier glass system (Background/Card/Inset) means multiple simultaneous BackdropFilters on the dashboard
- Impeller already disabled due to grey overlay bug — this means Masarify is on the Skia renderer, which handles BackdropFilter differently (sometimes better on mid-range, sometimes worse)

**Warning signs:**
- Dashboard with 3+ glassmorphic cards visible simultaneously drops to 45fps on low-end devices
- Scrolling through transaction list while nav bar blur is active causes CPU spikes
- `GlassConfig.deviceFallback` exists — is it actually being checked and respected?

**Prevention strategy:**
- Verify `GlassConfig` device capability check is working: test on a low-end device (2GB RAM, Snapdragon 4xx) before submission
- For the nav bar BackdropFilter (constant, always active): this is unavoidable — but ensure sigma is as low as visually acceptable (20 is high; 12 may be imperceptible to users)
- For transaction list cards: use the Inset tier (sigma 8) or eliminate BackdropFilter entirely for list items — use solid semi-transparent colors with `Color.withOpacity()` instead
- Use `RepaintBoundary` above the nav bar's `BackdropFilter` to prevent list scroll from triggering nav bar re-raster
- The `GlassConfig.deviceFallback` must disable or reduce blur on devices with `physicalSizeInches < 5` or `totalRamMb < 3000`

**Phase:** PERF-02 (smooth scrolling), PERF-01 (startup)

---

## 3. Subscription Pitfalls

### 3.1 Google Play Billing Edge Cases

**Pitfall:** `in_app_purchase` (which wraps Google Play Billing Library) has several edge cases that are not obvious from the basic purchase flow. Mishandling them leads to users being charged without receiving Pro access, or retaining Pro access after refund.

**Key edge cases:**

**Cancellation:**
- User cancels → subscription remains active until period end → `PurchaseStatus.purchased` still returns `true`
- App must NOT revoke access immediately on cancellation — only at expiry
- Detection: `purchaseDetails.status == PurchaseStatus.purchased` is insufficient; check `expiryDate` from the billing response

**Grace period:**
- If payment fails (insufficient funds, expired card), Google gives a 3-7 day grace period
- During grace: `purchaseDetails.status` may still show `purchased` but the `autoRenewing` flag is `false`
- App must grant access during grace period (Google policy) — do not lock user out

**Refund:**
- User requests refund via Google Play → Google sends a `SUBSCRIPTION_REVOKED` notification via RTDN (Real-Time Developer Notifications) if server-side verification is set up
- Without a server, the app cannot know about refunds until next purchase state poll
- Client-only apps must poll `queryPurchases()` on each app launch to detect refunded/revoked subscriptions

**Restoration:**
- `restorePurchases()` must be called on new device install or after reinstall
- Users frequently complain about "losing" Pro after reinstall if restore is not surfaced in Settings

**Prevention strategy:**
- Implement purchase state persistence locally in Drift (store: productId, purchaseToken, expiryDate, status)
- On app launch, always call `queryPurchases()` and reconcile with local state
- Surface "Restore Purchase" prominently in Settings > Subscription
- Do not gate features purely on a boolean flag — store expiry timestamp and check it
- For the launch MVP: accept that refund detection requires polling; server-side RTDN is v1.1

**Phase:** PAYWALL-01, PAYWALL-02

---

### 3.2 Subscription Verification — Client-Only Risks

**Pitfall:** Verifying subscriptions entirely client-side (no server) means the purchase token is never validated against Google's servers. This creates two risks: (1) fake purchase receipts, and (2) inability to detect refunds/revocations in real-time.

**Risk assessment for Masarify:**
- Finance tracker with local-only data — unlike cloud sync apps, there is nothing to "steal" by faking a Pro subscription
- The risk is revenue loss from fake receipts, not data exposure
- At Egyptian market scale (launch cohort likely <1000 users), this is acceptable for v1.0

**Warning signs:**
- Purchase token accepted without verifying `packageName` matches `com.masarify.app`
- Not checking `purchaseToken` is non-null and non-empty before granting access
- Storing `isPro = true` in SharedPreferences without binding it to a purchase token (trivially bypassed by anyone with root or ADB)

**Prevention strategy:**
- Store subscription state in Drift (encrypted field) tied to the purchase token, not just a boolean
- At minimum, validate on-device: `packageName == "com.masarify.app"`, product ID is one of the declared SKUs, and purchase state is `purchased` not `pending`
- Plan for v1.1: backend endpoint that calls `Google Play Developer API: purchases.subscriptions.get` to verify token server-side
- Do not log purchase tokens to console or crash reports

**Phase:** PAYWALL-02

---

### 3.3 Free Trial Abuse Prevention

**Pitfall:** Google Play enforces that free trials are per Google account, not per device. A user can get a second trial by creating a new Google account. This is a platform-level limitation that cannot be prevented without server-side tracking.

**Additional edge cases:**
- User starts trial → cancels before trial ends → re-subscribes → gets another trial (Google allows this in some configurations depending on SKU setup)
- User uses trial on one device → installs on new device → trial still active (handled correctly by `queryPurchases()`)

**SKU configuration to prevent abuse (in Google Play Console):**
- Set trial eligibility to "New subscribers only" — prevents re-trials after cancellation
- Keep trial at 7 days (as planned) — shorter trials are harder to abuse
- Monitor Console's "Subscription cohort" report for abnormal trial-to-paid conversion

**Prevention strategy:**
- Accept platform limitations for v1.0
- In Play Console when creating the subscription product: explicitly set "Introductory price / free trial: eligible for new subscribers only"
- Surface the trial terms honestly to avoid support requests: "7-day free trial for new subscribers"
- For v1.1: track device+account hash server-side to detect multi-account abuse

**Phase:** PAYWALL-04 (free trial implementation)

---

### 3.4 Price Changes and Grandfather Pricing

**Pitfall:** When Masarify raises prices (e.g., from 59 EGP/mo to 79 EGP/mo), Google requires notifying existing subscribers and giving them a 30-day acknowledgment period before the new price takes effect. Apps that silently change prices or fail to handle the `PRICE_CHANGE_CONFIRMATION` flow will have subscribers churning.

**Google's price change flow:**
1. Publisher raises price in Play Console
2. Google notifies affected subscribers via email and in-app dialog
3. Subscriber must confirm via Play billing dialog or they are auto-cancelled at period end
4. App receives updated purchase state via `PurchasesUpdatedListener`

**Warning signs for launch:**
- Setting price at the lower end (59 EGP) with the expectation of raising it quickly creates churn risk
- Not having a Drift field for `acknowledgedAt` timestamp means the app cannot detect when a user has acknowledged a price change

**Prevention strategy:**
- Launch at the price you intend to keep for 6-12 months (79 EGP if that's the target, not 59 EGP)
- Grandfather pricing policy: keep existing subscribers at their locked price for at least 1 year after any increase — this builds trust
- Do not implement price changes in the first 3 months post-launch
- Subscribe to Play Developer Notifications to be alerted when Google sends price change confirmations to users

**Phase:** STORE-03 (product setup in Play Console)

---

## 4. Egyptian Market Pitfalls

### 4.1 Payment Method Availability

**Pitfall:** Google Play subscriptions require a payment method on file with Google. In Egypt, this is a significant friction point: many young users rely on Fawry, Vodafone Cash, or bank transfers — none of which are directly supported by Google Play billing. Only international Visa/Mastercard cards and Meeza (domestic debit) linked to Google Pay work reliably.

**Warning signs:**
- Target demographic (25-35 Egyptian professionals) may have bank accounts but not Google Play payment methods set up
- "Add payment method" failures on Google Play are the #1 reason for subscription drop-off in Egypt
- Users with Vodafone Cash or Orange Money (common in lower-income segments) cannot subscribe at all

**Market reality:**
- Egyptian Meeza cards (National Payment Council standard) now supported on Google Play — but many users do not know this
- Some Egyptian banks issue dual-currency cards that work; others issue EGP-only cards that do not work on Google Play (as of 2025)
- Students and younger users often do not have cards at all

**Prevention strategy:**
- In the paywall UI, add a brief "How to subscribe" help link explaining that Meeza cards and international bank cards work on Google Play
- Consider a "Gift Masarify Pro" feature (v1.1) using redemption codes for users who cannot pay via Play
- In the free tier, ensure enough value that non-paying users still become advocates
- Track conversion rate by country/region in Play Console — if Egypt conversion is below 1%, re-evaluate pricing or payment options

**Phase:** PAYWALL-03 (UI design)

---

### 4.2 Network Conditions

**Pitfall:** Egypt has variable mobile network quality, especially outside Cairo and Alexandria. Many users are on 4G that fluctuates to 3G or even 2G in transit. AI features (Gemini voice, OpenRouter chat) that assume fast connections will fail ungracefully.

**Warning signs:**
- Voice input fails with a timeout error and shows a generic error message (no guidance to retry)
- AI chat hangs indefinitely on slow connections with no loading indicator timeout
- Google Drive backup fails silently on flaky connections
- App shows "offline" banner but does not remember the last AI-generated insights from before going offline

**Network reality for Egypt:**
- Cairo: mostly reliable 4G/LTE, but metro/underground = dead zones
- Alexandria, Delta: patchy 4G
- Upper Egypt: predominantly 3G
- WiFi at home common, but public WiFi rare

**Prevention strategy:**
- Voice input: set a 15-second HTTP timeout on the Gemini API call; on timeout show "Connection too slow — try again on WiFi" not a generic error
- AI chat: implement a 20-second timeout with a user-readable message; cache the last 5 AI responses in Drift so they remain readable offline
- Google Drive backup: use resumable upload with retry; do not block the UI thread during backup
- The offline-first architecture (Drift) means core features always work — ensure the offline banner is prominent and non-alarming ("AI features need internet — your data is safe")
- Test with Android Studio's network throttling (200kbps) before submission

**Phase:** PERF-01, STORE-02 (privacy policy covers data handling on reconnect)

---

### 4.3 Device Diversity (Low-End Android)

**Pitfall:** Egypt's mid-range market is dominated by Samsung A-series (A04, A13, A14, A15), Xiaomi Redmi 10/12, and Tecno/Infinix budget devices. These run on Snapdragon 4xx/Helio G8x with 2-4GB RAM. Flutter apps that perform well on a Pixel 7 can jank or OOM-crash on these devices.

**Warning signs:**
- BackdropFilter (glassmorphism) running on Mali G57 GPU (Helio G85) causes sustained 30fps
- Drift queries with no indexes on large tables (1000+ transactions) take 200ms+ on ARM Cortex-A55 cores
- Image assets loaded at 3x density on a 1080p device waste significant RAM
- `brand_registry.dart` with 30+ brand entries loaded as Dart constants inflates the Dart heap

**Common low-end devices in Egypt to test on (or emulate):**
- Samsung Galaxy A14 (Helio G80, 4GB RAM) — highest-volume device
- Samsung Galaxy A04 (Helio P35, 3GB RAM)
- Xiaomi Redmi 12 (Helio G88, 4GB RAM)
- Tecno Spark 20 (Helio G85, 8GB RAM) — emerging mid-range

**Prevention strategy:**
- Test on an Android emulator configured for: 3GB RAM, arm64-v8a, 1080x2400, Helo G80 equivalent
- Implement `GlassConfig` fallback correctly: disable blur on devices with `totalRamMb < 3000`; use `Color.withOpacity(0.85)` with no BackdropFilter
- Add Drift database indexes: `CREATE INDEX IF NOT EXISTS idx_transactions_date ON transactions(date DESC)` and `idx_transactions_wallet ON transactions(wallet_id)`
- Use `flutter build appbundle --release` with `--split-per-abi` — ensure arm64-v8a and armeabi-v7a APKs are generated; low-end devices may still be 32-bit
- Audit image assets: use WebP format, provide only 1x and 2x (not 3x) for logos/brand icons
- Run `flutter build apk --analyze-size` to identify large assets or compiled code

**Phase:** PERF-01, PERF-02, PERF-03

---

### 4.4 Arabic RTL Edge Cases

**Pitfall:** Arabic RTL is not just about `Directionality` widgets. Several layout and logic issues are specific to RTL that do not appear in LTR testing.

**Common RTL bugs in Flutter finance apps:**

**Layout issues:**
- `Row` children appear left-to-right even in RTL context if `TextDirection.rtl` is not propagated
- `ListTile` leading/trailing icons swap — `leading` goes to the right in RTL, which is correct, but may look wrong if icons are directional (arrows)
- `Align(alignment: Alignment.centerRight)` stays right in RTL — you must use `AlignmentDirectional.centerEnd`
- `BoxDecoration` border-radius: `BorderRadius.only(topLeft: ...)` does not flip in RTL; use `BorderRadiusDirectional`

**Text issues:**
- Mixed Arabic/English text (e.g., "CIB → NBE") in RTL: the arrow direction is semantically wrong — in Arabic RTL, "CIB إلى NBE" should read right-to-left with the source on the right
- Currency formatting: Arabic uses ٪ and ١٢٣ (Hindi numerals) in formal text but Egyptian Arabic uses Western numerals — use `MoneyFormatter` that respects this
- Amount entry: number keyboard in RTL inserts from right; confirm cursor behavior in `AddTransactionScreen` amount field

**Date/time issues:**
- Gregorian calendar displayed in Arabic locale with Western or Eastern Arabic numerals — test both
- Date pickers in RTL: Flutter's `showDatePicker` respects locale, but custom date range pickers may not

**Brand icons and names:**
- Brand names are in English (CIB, NBE, Vodafone) even in Arabic UI — these should remain in LTR within an RTL sentence; use `bidi` isolation or explicit `TextDirection.ltr` for brand names

**Prevention strategy:**
- Use `AlignmentDirectional` and `EdgeInsetsDirectional` everywhere, never `Alignment.centerLeft/Right` or directional `EdgeInsets`
- Test every new screen by forcing `Localizations.override(context: context, locale: const Locale('ar'))` in a test
- Transfer display: replace arrow character `→` with `context.l10n.to` localization key so Arabic shows "إلى" correctly
- Run the app on an Arabic-locale device (or emulator set to Arabic) for every screen before each submission
- RTL-specific golden tests: add screenshot tests for the dashboard and transaction list in Arabic locale

**Phase:** STORE-04 (content rating + target audience) + STORE-01 (Arabic screenshots required)

---

## Summary Matrix

| Pitfall | Severity | Phase | Effort |
|---|---|---|---|
| Financial services disclaimer missing | High | STORE-01, STORE-02 | Low |
| Data Safety section incomplete | High | STORE-02 | Medium |
| Permissions audit (exact alarm) | Medium | STORE-03 | Low |
| AI disclosure labels | Medium | STORE-01 | Low |
| Subscription transparency UI | High | PAYWALL-03 | Medium |
| Transaction list jank | Medium | PERF-02 | Medium |
| Drift stream leaks | Medium | PERF-03 | Low |
| Startup time | Medium | PERF-01 | Medium |
| BackdropFilter on low-end | High | PERF-02 | Medium |
| Billing edge cases (cancel/refund/grace) | High | PAYWALL-02 | High |
| Client-only verification | Medium | PAYWALL-02 | Low |
| Free trial abuse | Low | PAYWALL-04 | Low |
| Price change strategy | Low | STORE-03 | Low |
| Egyptian payment method friction | High | PAYWALL-03 | Low |
| Network conditions (AI timeouts) | High | PERF-01 | Medium |
| Low-end device performance | High | PERF-01-03 | High |
| RTL layout bugs | Medium | All screens | Medium |

---

_This document is research-only. For implementation tasks, see PROJECT.md Active requirements (PERF-01-03, PAYWALL-01-04, STORE-01-04)._
