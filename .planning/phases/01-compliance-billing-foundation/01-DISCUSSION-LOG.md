# Phase 1: Compliance & Billing Foundation - Discussion Log (Assumptions Mode)

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions captured in CONTEXT.md — this log preserves the analysis.

**Date:** 2026-03-27
**Phase:** 01-compliance-billing-foundation
**Mode:** assumptions
**Areas analyzed:** SDK & Edge-to-Edge, Permission Cleanup, Package Dependencies, Billing Library, Trial & Subscription Storage, Settings Cleanup

## Assumptions Presented

### SDK & Edge-to-Edge
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| targetSdk is 34, must bump to 35+ | Confident | `build.gradle.kts` line 36 |
| compileSdk already 36 via Flutter | Confident | `FlutterExtension.kt` line 23 |
| Edge-to-edge enforced at API 35 — nav bar needs testing | Confident | Research STACK.md section 3.1 |

### Permission Cleanup
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| SCHEDULE_EXACT_ALARM declared but unused | Confident | `notification_service.dart` line 129: inexactAllowWhileIdle |
| Location permissions actively used — keep | Confident | `location_service.dart`, `add_transaction_screen.dart` |
| SMS permissions already removed via tools:node="remove" | Confident | `AndroidManifest.xml` |

### Package Dependencies
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| another_telephony removable — 3 import sites | Confident | grep found 3 files |
| geolocator/geocoding actively used — keep | Confident | LocationService active code |
| GoogleFonts.allowRuntimeFetching not set | Confident | grep returned zero matches |

### Billing Library
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| in_app_purchase_android 0.4.0+8 likely bundles BL6, not BL8 | Likely | pubspec.lock, research STACK.md |
| Migration may be needed | Likely | BL8 deadline February 2026 |

### Trial & Subscription Storage
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| _trialDays = 14, should be 7 | Confident | `subscription_service.dart` line 28 |
| ensureTrialStarted() called in main() on every launch | Confident | `main.dart` line 81 |
| No subscription_records table in Drift | Confident | `app_database.dart` — 13 tables, none for subscriptions |

### Settings Cleanup
| Assumption | Confidence | Evidence |
|------------|-----------|----------|
| SMS section hidden by kSmsEnabled=false | Confident | `settings_screen.dart` lines 721-731 |
| another_telephony import will break compilation | Confident | `settings_screen.dart` line 3 |
| Dead code notification_transaction_parser.dart exists | Confident | `lib/core/services/` |

## Corrections Made

No corrections — all assumptions confirmed.

### Product Decision
- **Trial duration:** User confirmed **7 days** (not 14). Fix `_trialDays = 14` → `_trialDays = 7`.

## Needs External Research

1. Play Billing Library version bundled by `in_app_purchase_android: 0.4.0+10`
2. Edge-to-edge behavior on API 35+ with Impeller disabled (Skia)
3. `flutter_local_notifications` transitive SCHEDULE_EXACT_ALARM declaration
4. `another_telephony` native library footprint in APK after removal
