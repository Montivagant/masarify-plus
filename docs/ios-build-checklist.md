# Masarify — iOS Build Checklist (MacBook)

Follow these steps in order after pulling the latest code from git.

---

## Prerequisites

- [ ] macOS with **Xcode 15+** installed (Mac App Store)
- [ ] Xcode Command Line Tools: `xcode-select --install`
- [ ] **Flutter SDK** installed: https://docs.flutter.dev/get-started/install/macos
- [ ] `flutter doctor` shows no iOS errors
- [ ] **CocoaPods** installed: `sudo gem install cocoapods` (or `brew install cocoapods`)
- [ ] **Apple Developer account** (free for device testing, $99/year for App Store)

---

## Step 1: Clone & Setup

```bash
git clone <repo-url> && cd Masarify-Plus
# OR if already cloned:
git pull origin main

flutter pub get
cd ios && pod install && cd ..
```

> If `pod install` fails:
> - Version conflicts: `pod install --repo-update`
> - M-series Mac: `arch -x86_64 pod install`
> - Cache issues: `rm -rf ios/Pods ios/Podfile.lock && pod install`

---

## Step 2: Open in Xcode

```bash
open ios/Runner.xcworkspace
```

**IMPORTANT:** Open `.xcworkspace` (NOT `.xcodeproj`)

---

## Step 3: Configure Signing

1. Select **Runner** target in the left sidebar
2. Go to **Signing & Capabilities** tab
3. Check **"Automatically manage signing"**
4. Set **Team** to your Apple Developer account
5. Verify Bundle Identifier shows: `com.masarify.app`
6. If provisioning profile error → Xcode usually auto-resolves with auto-signing

---

## Step 4: Verify Deployment Target

In the **General** tab, verify **Minimum Deployments: iOS 13.0**

---

## Step 5: Verify Info.plist Permissions

In Xcode, expand Runner > Runner > Info.plist. Confirm these keys exist:

| Key | Purpose |
|-----|---------|
| `NSMicrophoneUsageDescription` | Voice input |
| `NSSpeechRecognitionUsageDescription` | Voice recognition |
| `NSLocationWhenInUseUsageDescription` | Location tagging |
| `NSFaceIDUsageDescription` | Biometric lock |

---

## Step 6: Launch Screen (Optional Polish)

The current LaunchImage files are blank placeholders. Options:
- **Option A:** Replace `ios/Runner/Assets.xcassets/LaunchImage.imageset/` PNG files with real assets
- **Option B:** Edit `LaunchScreen.storyboard` in Xcode to match app branding (Apple preferred)

---

## Step 7: Test on Simulator

```bash
flutter run
```

Verify:
- [ ] App launches without `MissingPluginException`
- [ ] Settings screen does **NOT** show SMS/Notification parser toggles
- [ ] Voice input works (microphone permission prompt appears)
- [ ] Biometric prompt appears (Settings > Security > Biometric)
- [ ] Glass effects (BackdropFilter) render correctly (Impeller works on iOS)
- [ ] Test in **Arabic** (RTL) — switch language in Settings
- [ ] Test in **English**

---

## Step 8: Test on Physical iPhone

### Wireless Debugging Setup
1. Connect iPhone via **USB** first
2. In Xcode: Window > Devices and Simulators
3. Select your iPhone, check **"Connect via network"**
4. Disconnect USB — device should remain visible

### First Run
```bash
flutter run -d <device-id>
# Find device ID with: flutter devices
```

On iPhone: **Settings > General > VPN & Device Management > Trust** your developer certificate

### Test Checklist
- [ ] All simulator checks above pass on real device
- [ ] Location tagging works with real GPS
- [ ] Voice input records and parses correctly
- [ ] App performs smoothly (no jank on glass effects)
- [ ] Notifications schedule and fire correctly

---

## Step 9: Release Build

```bash
flutter build ios --release
```

The `.app` bundle will be in `build/ios/iphoneos/`

---

## Step 10: App Store Submission (When Ready)

1. In Xcode: **Product > Archive**
2. In Organizer: **Distribute App > App Store Connect**
3. Upload to App Store Connect
4. Fill in App Store listing (screenshots, description, etc.)
5. Submit for review

---

## iOS vs Android Feature Differences

| Feature | Android | iOS |
|---------|---------|-----|
| SMS inbox parsing | Yes | No (iOS restriction) |
| Notification listener | Yes | No (iOS restriction) |
| Voice input (Gemini) | Yes | Yes |
| AI chat (OpenRouter) | Yes | Yes |
| Biometrics | Fingerprint | Face ID / Touch ID |
| Local notifications | Yes | Yes |
| Impeller renderer | Disabled | Enabled (works correctly) |

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Module not found` errors | `cd ios && pod install --repo-update && cd ..` |
| Signing errors | Delete derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*` |
| `MissingPluginException` | Run `flutter clean && flutter pub get && cd ios && pod install` |
| Simulator won't boot | `xcrun simctl shutdown all && xcrun simctl erase all` |
| M-series pod issues | `arch -x86_64 pod install` |
| Build hangs | Check free disk space (Xcode needs ~20GB) |

---

## API Keys

The app needs two API keys configured at build time (or in `lib/core/config/env.dart`):

```bash
# Option 1: Build-time injection
flutter run --dart-define=OPENROUTER_API_KEY=sk-or-v1-... --dart-define=GOOGLE_AI_API_KEY=AIzaSy...

# Option 2: env.dart already has keys committed (check if present)
```
