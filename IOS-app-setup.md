# Masarify iOS Setup Guide

Complete guide for deploying Masarify to a physical iPhone via wireless debugging from a MacBook.

---

## Prerequisites

### MacBook Software

| Tool | Version | Install |
|------|---------|---------|
| Xcode | 15+ | App Store |
| Xcode Command Line Tools | Latest | `xcode-select --install` |
| Flutter SDK | 3.22+ | `brew install flutter` or [flutter.dev](https://flutter.dev) |
| CocoaPods | Latest | `sudo gem install cocoapods` |

After installing, verify:
```bash
flutter doctor
# Ensure [✓] Flutter, [✓] Xcode, [✓] iOS toolchain
```

### Apple Developer Account

- **Free Apple ID** works for personal device testing (apps expire after 7 days, limited to 3 apps)
- **Apple Developer Program** ($99/year) required for TestFlight/App Store and longer-lived provisioning

---

## Step 1: Clone & Restore Dependencies

```bash
git clone https://github.com/Montivagant/masarify-plus.git
cd masarify-plus

# CRITICAL: Regenerate iOS config (replaces Windows paths in Generated.xcconfig)
flutter clean
flutter pub get
```

This regenerates `ios/Flutter/Generated.xcconfig` with correct macOS paths. The Windows-origin file contains backslashes (`C:\src\flutter`) that will break Xcode.

---

## Step 2: Create the `.env` File

The `.env` file is gitignored. Create it at the project root:

```bash
cat > .env << 'EOF'
OPENROUTER_API_KEY=<your-openrouter-key>
GOOGLE_AI_API_KEY=<your-google-ai-key>
EOF
```

These keys are injected at build time via `--dart-define-from-file=.env` and power the AI chat feature.

---

## Step 3: Configure Code Signing in Xcode

```bash
open ios/Runner.xcworkspace   # MUST open .xcworkspace, NOT .xcodeproj
```

In Xcode:

1. Select **Runner** in the project navigator (blue icon, top-left)
2. Select the **Runner** target (under TARGETS)
3. Go to **Signing & Capabilities** tab
4. Check **"Automatically manage signing"**
5. Select your **Team** from the dropdown (your Apple ID or organization)
6. Bundle Identifier should be `com.masarify.app`
   - If it conflicts with another developer's registration, change to something unique like `com.yourname.masarify`

### Current iOS Project Configuration

| Setting | Value | Location |
|---------|-------|----------|
| Bundle ID | `com.masarify.app` | project.pbxproj |
| iOS Deployment Target | 13.0 | project.pbxproj |
| Swift Version | 5.0 | project.pbxproj |
| Bitcode | Disabled | project.pbxproj |
| DEVELOPMENT_TEAM | **Not set** | Must set in Xcode |

---

## Step 4: Enable Developer Mode on iPhone

**iOS 16+** requires Developer Mode:

1. **Settings > Privacy & Security > Developer Mode**
2. Toggle **ON**
3. iPhone will restart
4. Confirm when prompted after restart

---

## Step 5: Pair iPhone for Wireless Debugging

### First-time pairing (USB required once):

1. Connect iPhone to MacBook via USB-C/Lightning cable
2. **Trust This Computer** on the iPhone when prompted
3. In Xcode: **Window > Devices and Simulators**
4. Select your iPhone in the left panel
5. Check **"Connect via network"** checkbox
6. Wait for the network globe icon to appear next to the device
7. Disconnect USB cable

### Verify wireless connection:

```bash
flutter devices
# Should show your iPhone listed with (wireless) or network indicator
```

---

## Step 6: Build & Install

### Debug build (faster, hot reload):
```bash
flutter run --dart-define-from-file=.env
```

### Release build (optimized, no debug banner):
```bash
flutter run --release --dart-define-from-file=.env
```

### If multiple devices are connected:
```bash
# List devices
flutter devices

# Target specific device
flutter run --release --dart-define-from-file=.env -d <device-id>
```

---

## Step 7: Trust the Developer on iPhone

On first install, iOS blocks the app until you trust the developer certificate:

1. **Settings > General > VPN & Device Management**
2. Tap your **Developer App** certificate
3. Tap **"Trust"**
4. Open Masarify from the home screen

---

## Google Sign-In Setup (Required for Google Drive Backup)

The project uses `google_sign_in` for Google Drive backup. iOS requires a separate OAuth client:

### Create iOS OAuth Client

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (or create one)
3. **Add app > iOS**
4. Bundle ID: `com.masarify.app` (must match Xcode)
5. Download **`GoogleService-Info.plist`**
6. In Xcode: drag the file into `Runner/Runner/` group
   - Check **"Copy items if needed"**
   - Check **Runner** in target membership

### Add URL Scheme

From the downloaded `GoogleService-Info.plist`, find the `REVERSED_CLIENT_ID` value and add it as a URL scheme:

1. In Xcode: Runner target > **Info** tab
2. Expand **URL Types**
3. Click **+**
4. Paste the `REVERSED_CLIENT_ID` value into **URL Schemes**

Without this setup, Google Sign-In will fail at runtime but the rest of the app works normally.

---

## Existing iOS Configuration (Already Set Up)

These are already configured in the project and require no changes:

### Info.plist Permissions

| Permission | Key | Description |
|-----------|-----|-------------|
| Microphone | `NSMicrophoneUsageDescription` | Voice transaction input |
| Speech Recognition | `NSSpeechRecognitionUsageDescription` | Voice-to-text processing |
| Location (In Use) | `NSLocationWhenInUseUsageDescription` | Transaction location tagging |
| Face ID | `NSFaceIDUsageDescription` | Biometric app lock |

### App Icons
Complete icon set in `ios/Runner/Assets.xcassets/AppIcon.appiconset/` — all 16 required sizes present.

### Launch Screen
Configured via `ios/Runner/Base.lproj/LaunchScreen.storyboard`.

### Plugins (27 iOS-compatible)
All registered automatically via `GeneratedPluginRegistrant.m`. No manual native code needed.

---

## Troubleshooting

### "No provisioning profile"
- Open Xcode > Runner target > Signing & Capabilities
- Ensure a Team is selected and "Automatically manage signing" is checked
- Xcode downloads/creates profiles automatically

### "Untrusted Developer" on iPhone
- Settings > General > VPN & Device Management > Trust your certificate

### Build fails with "module not found"
```bash
cd ios
pod install --repo-update
cd ..
flutter run --dart-define-from-file=.env
```

### "No devices found" for wireless debugging
- Ensure iPhone and MacBook are on the **same Wi-Fi network**
- Re-pair: connect USB, check "Connect via network" in Xcode Devices window
- Restart Xcode if the device disappears

### CocoaPods version conflict
```bash
sudo gem install cocoapods
cd ios
pod deintegrate
pod install
cd ..
```

### Minimum deployment target warnings
If a pod requires iOS 14+, edit `ios/Podfile` (auto-generated after first build):
```ruby
platform :ios, '14.0'   # Bump from 13.0 if needed
```
Then run `cd ios && pod install && cd ..`

### Free Apple ID limitations
- Apps expire after **7 days** (must reinstall)
- Max **3 apps** installed simultaneously
- No push notification entitlements
- No TestFlight distribution

### `.env` not injected (AI chat returns errors)
Verify the build command includes the flag:
```bash
flutter run --dart-define-from-file=.env
```
Not just `flutter run`.

---

## Quick Reference

```bash
# Full setup from scratch on a new MacBook
git clone https://github.com/Montivagant/masarify-plus.git
cd masarify-plus
flutter clean && flutter pub get

# Create .env with API keys
cat > .env << 'EOF'
OPENROUTER_API_KEY=<key>
GOOGLE_AI_API_KEY=<key>
EOF

# Open Xcode to configure signing (one-time)
open ios/Runner.xcworkspace
# → Runner target → Signing & Capabilities → Set Team

# Run on iPhone (wireless)
flutter run --release --dart-define-from-file=.env

# Trust developer on iPhone: Settings > General > VPN & Device Management
```

---

## Project iOS File Inventory

```
ios/
├── Runner.xcworkspace/          ← OPEN THIS (not .xcodeproj)
├── Runner.xcodeproj/
│   └── project.pbxproj          ← Build settings, signing config
├── Runner/
│   ├── AppDelegate.swift        ← Standard Flutter (no custom code)
│   ├── Info.plist               ← Permissions, app metadata
│   ├── Runner-Bridging-Header.h ← Plugin bridge (auto)
│   ├── Assets.xcassets/         ← App icons, launch image
│   └── Base.lproj/             ← Storyboards (launch, main)
├── Flutter/
│   ├── Generated.xcconfig       ← Auto-generated (DO NOT EDIT)
│   ├── Debug.xcconfig
│   ├── Release.xcconfig
│   └── AppFrameworkInfo.plist
└── Podfile                      ← Auto-generated on first build
```
