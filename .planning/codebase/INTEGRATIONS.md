# Masarify — Integrations & External APIs

## AI & LLM Services

### 1. OpenRouter (Chat Completions)
**File:** `lib/core/services/ai/openrouter_service.dart`

**Configuration:**
```dart
// AiConfig in lib/core/config/ai_config.dart
static const String openRouterBaseUrl = 'https://openrouter.ai/api/v1';
static const int apiTimeoutSeconds = 15;
static String get openRouterApiKey => Env.openRouterApiKey;  // --dart-define=...
```

**Endpoint:** POST `/chat/completions`

**Models (Priority Order):**
1. `google/gemini-2.0-flash-001` — Paid, highest quality
2. `google/gemma-3-27b-it:free` — Free alternative
3. `qwen/qwen3-4b:free` — Last resort

**Request Pattern:**
```dart
final response = await http.post(
  Uri.parse('${baseUrl}/chat/completions'),
  headers: {
    'Authorization': 'Bearer $apiKey',
    'Content-Type': 'application/json',
    'HTTP-Referer': 'https://masarify.app',
  },
  body: jsonEncode({
    'model': 'google/gemini-2.0-flash-001',
    'messages': [
      {'role': 'system', 'content': systemPrompt},
      {'role': 'user', 'content': userMessage},
    ],
    'response_format': {'type': 'json_object'},
    'temperature': 0.2,
    'max_tokens': 1024,
    'provider': {'zdr': true},  // Zero Data Retention (not for :free models)
  }),
);
```

**Usage in App:**
- `AiChatService` (conversational finance advisor)
- SMS enrichment (payment type, merchant inference)
- Budget suggestions (spending patterns analysis)

---

### 2. Google AI / Gemini REST API
**File:** `lib/core/services/ai/gemini_audio_service.dart`

**Configuration:**
```dart
static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';
static const String geminiAudioModel = 'gemini-2.5-flash';
static const int geminiAudioTimeoutSeconds = 90;  // Longer for audio upload
static String get googleAiApiKey => Env.googleAiApiKey;  // --dart-define=...
```

**Endpoint:** POST `/{geminiAudioModel}:generateContent`

**Request Pattern (Audio Transcription + Parsing):**
```dart
final base64Audio = base64Encode(wavBytes);
final body = jsonEncode({
  'system_instruction': {
    'parts': [{'text': systemPrompt}],
  },
  'contents': [
    {
      'parts': [
        {'text': 'Transcribe audio and parse transactions. Return JSON only.'},
        {
          'inline_data': {
            'mime_type': 'audio/wav',
            'data': base64Audio,  // base64-encoded WAV
          },
        },
      ],
    },
  ],
});
```

**Output:** JSON with transaction array
```json
{
  "transactions": [
    {
      "type": "expense",
      "amount": 150,
      "category": "Food",
      "title": "Coffee",
      "wallet": "Cash"
    }
  ]
}
```

**Voice Input Flow:**
1. `VoiceInputSheet` → records WAV (16kHz mono) via `record` package
2. Routes to `GeminiAudioService.parseAudio()`
3. Returns `List<VoiceTransactionDraft>` → `VoiceConfirmScreen` for review
4. User taps "Save" → creates transactions via `CreateTransactionAction` (AI Chat executor)

---

## Authentication & Cloud Services

### 3. Google Sign-In + Drive API
**Files:**
- `lib/core/services/google_drive_backup_service.dart`
- `lib/core/config/env.dart` (server client ID)

**OAuth 2.0 Configuration:**
```dart
final _googleSignIn = GoogleSignIn(
  scopes: [drive.DriveApi.driveAppdataScope],
  serverClientId: '287070145777-kopeobabr0fvd0pirdb7tq3nus6o2clf.apps.googleusercontent.com',
);
```

**Scope:** `https://www.googleapis.com/auth/drive.appdata` (isolated, read/write own app folder only)

**Drive API Endpoints:**
- `POST /upload/drive/v3/files?uploadType=multipart` — Upload encrypted backup
- `GET /drive/v3/files` — List backup files (filter by `appDataFolder='appDataFolder'`)
- `GET /drive/v3/files/{fileId}?alt=media` — Download backup

**Backup Encryption:**
```dart
// AES-256-SIC (CTR mode)
final key = enc.Key.fromSecureRandom(32);  // 256 bits
final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.sic));
final encrypted = encrypter.encrypt(dbJson, iv: iv);

// Key stored in FlutterSecureStorage (encrypted per platform)
await _secureStorage.write(key: _keyStorageKey, value: base64Key);
```

**Usage:** Backup/restore entire database (13 tables) with crash logs.

---

## Notifications & Scheduling

### 4. Local Notifications + Timezone Scheduler
**File:** `lib/core/services/notification_service.dart`

**Configuration:**
```dart
static const recapNotificationId = 99999;  // Daily spending recap

// Initialized in main.dart
await NotificationService.initialize();
```

**Android Channel:**
```dart
const AndroidInitializationSettings('@mipmap/ic_launcher');
AndroidNotificationDetails(
  'masarify_default',
  'Masarify',
  channelDescription: 'Masarify notifications',
  importance: Importance.high,
)
```

**Daily Scheduling:**
```dart
NotificationService.scheduleDaily(
  id: 99999,
  title: 'How was your spending today?',
  body: 'Tap to tell me — I\'ll log it for you',
  hour: 20,
  minute: 0,
  payload: 'recap',  // Deep link marker
);
```

**Tap Handler (main.dart):**
```dart
NotificationService.onNotificationTap = (payload) {
  if (payload == 'recap') {
    appRouter.go('${AppRoutes.chat}?mode=recap');  // Opens ChatScreen in recap mode
  }
};
```

**Recurring Bill Notifications:** Scheduled at v4 when bill/recurring rule is added (ID = ruleId + 100000).

---

## SMS & Device Integration

### 5. SMS Inbox Parsing (Feature-Flagged)
**File:** `lib/core/services/sms_parser_service.dart`

**Configuration:** `kSmsEnabled = false` (Hidden in AI-first pivot, preserved for Pro re-enablement)

**Library:** `another_telephony: ^0.4.1`

**Permissions (AndroidManifest.xml, removed via tools:node="remove"):**
```xml
<uses-permission android:name="android.permission.READ_SMS" />
```

**Local Regex Parsing Only:**
```dart
// Example: Detects "123 EGP" or "500 جنيه"
final regex = RegExp(r'(\d+)\s*EGP|جنيه');
final matches = regex.allMatches(smsBody);
```

**No Cloud Processing:** SMS text stays local. AI enrichment deferred to user action via OpenRouter.

**Deduplication:** Semantic fingerprint service (v8 migration) prevents duplicate parsing.

---

## In-App Purchases & Monetization

### 6. Google Play Billing / iOS StoreKit
**File:** `lib/core/services/subscription_service.dart`

**Configuration:**
```dart
static const bool kMonetizationEnabled = true;
static const String productIdMonthly = 'masarify_pro_monthly';
```

**IAP Products:**
- `masarify_pro_monthly` (59-79 EGP/month)
- 7-day free trial managed via `in_app_purchase`

**Flow:**
1. User taps "Upgrade to Pro" on Paywall screen
2. Calls `SubscriptionService.buyProduct(productId)`
3. Google Play/iOS handles payment UI
4. Receives `PurchaseDetails` with receipt/token
5. Validates receipt (server-side in production)
6. Sets `sharedPreferences['pro_status'] = true`
7. UI rebuilds via `proStatusStream` (Riverpod listener)

**Paywall Screen:** `lib/features/monetization/presentation/screens/paywall_screen.dart`

---

## Database & Local Storage

### 7. Drift ORM + SQLite
**File:** `lib/data/database/app_database.dart`

**Schema Version:** 13

**Migration Example (v4: Bills → RecurringRules):**
```dart
if (from < 4) {
  // Add columns to recurring_rules
  await m.addColumn(recurringRules, recurringRules.isPaid);
  await m.addColumn(recurringRules, recurringRules.paidAt);

  // Migrate bills rows
  final billRows = await customSelect('SELECT * FROM bills').get();
  for (final row in billRows) {
    await customStatement(
      'INSERT INTO recurring_rules (...) VALUES (...)',
      [/* row data */],
    );
  }

  // Drop old table
  await customStatement('DROP TABLE IF EXISTS bills');
}
```

**Index Strategy:**
- Transactions: `idx_transactions_date DESC` (fast "all txns" queries)
- Transfers: `idx_transfers_date DESC`
- Budgets: `idx_budgets_year_month` (monthly budget lookups)
- Recurring: `idx_recurring_rules_due` (scheduler queries)
- Category Mappings: `idx_category_mappings_pattern` (ML learning)

**Foreign Key Enforcement:**
```dart
beforeOpen: (details) async {
  await customStatement('PRAGMA foreign_keys = ON');
}
```

---

## Device & System Services

### 8. Biometric Authentication
**Library:** `local_auth: ^2.3.0`

**Usage:** App lock / session unlock (optional)

---

### 9. Secure Storage
**Library:** `flutter_secure_storage: ^9.2.2`

**Uses:**
- Drive backup encryption key
- Biometric credentials cache

**Platform Implementation:**
- Android: Android Keystore
- iOS: Keychain

---

### 10. Connectivity Detection
**Library:** `connectivity_plus: ^7.0.0`

**Usage:**
- Offline banner on dashboard
- Defer AI API calls until reconnected
- Auto-sync on reconnection via `OfflineSyncService`

---

## Data Export & Sharing

### 11. CSV & PDF Export
**Libraries:**
- `csv: ^6.0.0` — transaction export
- `pdf: ^3.11.1` — report generation
- `file_picker: ^8.1.2` — import backup
- `share_plus: ^10.0.0` — iOS/Android share sheet

**CSV Export Example:**
```dart
final csv = const ListToCsvConverter().convert([
  ['Date', 'Category', 'Amount', 'Wallet'],
  for (final txn in transactions) [
    txn.transactionDate.format(),
    txn.category.name,
    MoneyFormatter.format(txn.amount),
    txn.wallet.name,
  ],
]);
```

---

## Configuration & Environment

### 12. Environment Variables
**File:** `lib/core/config/env.dart` (gitignored)

**Build-Time Injection:**
```bash
flutter run --dart-define=OPENROUTER_API_KEY=sk-or-... \
            --dart-define=GOOGLE_AI_API_KEY=AIzaSy...
```

**Fallback:** Empty strings if not provided (API calls will fail gracefully with 401).

---

## Architecture Patterns

### Request Flow (Example: Voice Transaction)
```
VoiceInputSheet (UI)
    ↓
GeminiAudioService (REST call)
    ↓ (base64 WAV → Gemini 2.5 Flash)
VoiceTransactionDraft (JSON parsed)
    ↓
VoiceConfirmScreen (user review)
    ↓ (user taps "Save")
ChatActionExecutor.executeAction(CreateTransactionAction)
    ↓
TransactionRepository.create()
    ↓
TransactionDao.insert()
    ↓ (Drift query)
SQLite (local persistence)
```

### Provider Chain (Example: Chat Advice)
```
UI (ChatScreen) observes
    ↓
chatMessagesProvider (Riverpod FutureProvider)
    ↓
AiChatService.chat() (OpenRouter API)
    ↓
FinancialContext (wallet, category, budget state injected)
    ↓
System prompt (locale-aware, includes user's financial snapshot)
    ↓ (http request)
OpenRouter (best model in fallback chain)
    ↓
OpenRouterResponse (token usage tracked)
```

---

## Error Handling & Resilience

### API Timeout & Retry
```dart
// OpenRouter: 15s timeout
await http.post(...).timeout(const Duration(seconds: 15));

// Gemini Audio: 90s timeout (larger payloads)
const int geminiAudioTimeoutSeconds = 90;
```

### Fallback Chain (SMS Enrichment)
```dart
// If Gemini Flash rate-limited, try free models
const List<String> fallbackChain = [
  'google/gemini-2.0-flash-001',    // Paid
  'google/gemma-3-27b-it:free',     // Free
  'qwen/qwen3-4b:free',              // Last resort
];
```

### Graceful Degradation
- **No OpenRouter key:** SMS enrichment disabled, local regex only
- **Offline:** Transactions still saveable (offline-first), sync on reconnect
- **Audio API down:** Fall back to manual voice confirm screen

---

## Summary Table

| Service | Protocol | Auth | Timeout | Offline? |
|---------|----------|------|---------|----------|
| OpenRouter (Chat) | HTTPS REST | Bearer Token | 15s | No |
| Gemini Audio | HTTPS REST | API Key | 90s | No |
| Google Drive | HTTPS REST | OAuth 2.0 | 30s | No |
| Local Notifications | Native API | Local | N/A | Yes |
| SQLite (Drift) | Local IPC | N/A | N/A | Yes |
| SMS (local regex) | Native API | Android permission | N/A | Yes |
| In-App Purchase | Native API | OAuth 2.0 | 30s | Cached |

