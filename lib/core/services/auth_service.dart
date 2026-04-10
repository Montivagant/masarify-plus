import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Handles PIN hashing / verification and biometric authentication.
///
/// H3 fix: PIN is now stored as PBKDF2-HMAC-SHA256 with random salt.
/// Previously SHA-256 without salt — 6-digit PIN brutable in <1 second.
/// Backward compatible: migrates unsalted hashes on first successful verify.
class AuthService {
  AuthService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
  })  : _secure = secureStorage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication();

  final FlutterSecureStorage _secure;
  final LocalAuthentication _localAuth;

  static const _pinHashKey = 'masarify_pin_hash';
  static const _pinSaltKey = 'masarify_pin_salt';
  // H3: legacy key for migration detection
  static const _iterations = 100000;
  static const _keyLength = 32; // 256 bits
  static const _failedAttemptsKey = 'masarify_pin_failed_attempts';
  static const _lockoutUntilKey = 'masarify_pin_lockout_until';

  // ── PIN ─────────────────────────────────────────────────────────────────

  /// Hash and store a 6-digit PIN with random salt.
  /// IM-37 fix: PBKDF2 runs in an isolate to avoid blocking the UI.
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = await Isolate.run(
      () => _hashPinPbkdf2(pin, salt),
    );
    await _secure.write(key: _pinSaltKey, value: base64Encode(salt));
    await _secure.write(key: _pinHashKey, value: hash);
  }

  /// Returns `true` if the supplied PIN matches the stored hash.
  /// Handles migration from unsalted SHA-256 to salted PBKDF2.
  Future<bool> verifyPin(String pin) async {
    final storedHash = await _secure.read(key: _pinHashKey);
    if (storedHash == null) return false;

    final storedSalt = await _secure.read(key: _pinSaltKey);

    if (storedSalt == null) {
      // Legacy unsalted hash — verify with old method, then migrate
      final legacyHash = _hashPinLegacy(pin);
      if (storedHash == legacyHash) {
        // Migrate to salted hash on successful verify
        await setPin(pin);
        return true;
      }
      return false;
    }

    // IM-37 fix: PBKDF2 in isolate to avoid blocking UI
    final salt = base64Decode(storedSalt);
    final computedHash = await Isolate.run(
      () => _hashPinPbkdf2(pin, salt),
    );
    return storedHash == computedHash;
  }

  /// Remove the stored PIN hash and salt.
  Future<void> removePin() async {
    await _secure.delete(key: _pinHashKey);
    await _secure.delete(key: _pinSaltKey);
  }

  // ── Lockout persistence ─────────────────────────────────────────────────

  /// Read the persisted failed-attempt count.
  Future<int> getFailedAttempts() async {
    final val = await _secure.read(key: _failedAttemptsKey);
    return val != null ? int.tryParse(val) ?? 0 : 0;
  }

  /// Persist the failed-attempt count.
  Future<void> setFailedAttempts(int count) async {
    await _secure.write(key: _failedAttemptsKey, value: count.toString());
  }

  /// Read the persisted lockout-until timestamp (ms since epoch).
  Future<DateTime?> getLockoutUntil() async {
    final val = await _secure.read(key: _lockoutUntilKey);
    if (val == null) return null;
    final ms = int.tryParse(val);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Persist a lockout-until timestamp.
  Future<void> setLockoutUntil(DateTime until) async {
    await _secure.write(
      key: _lockoutUntilKey,
      value: until.millisecondsSinceEpoch.toString(),
    );
  }

  /// Clear all lockout state (on successful unlock or PIN removal).
  Future<void> clearLockout() async {
    await _secure.delete(key: _failedAttemptsKey);
    await _secure.delete(key: _lockoutUntilKey);
  }

  // ── Biometric ───────────────────────────────────────────────────────────

  /// Check if the device supports biometric authentication.
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } on PlatformException {
      return false;
    }
  }

  /// Prompt for biometric authentication.
  /// Returns `true` on success, `false` on failure or cancellation.
  Future<bool> authenticateWithBiometric({
    required String localizedReason,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException {
      return false;
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Generate 16 bytes of cryptographically secure random salt.
  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );
  }

  /// PBKDF2-HMAC-SHA256 key derivation.
  /// IM-37 fix: static so it can be called from Isolate.run().
  static String _hashPinPbkdf2(String pin, Uint8List salt) {
    final pinBytes = utf8.encode(pin);
    // PBKDF2 implementation using dart:crypto HMAC
    final hmacKey = Hmac(sha256, pinBytes);
    final numBlocks = (_keyLength / 32).ceil();
    final result = BytesBuilder();

    for (var i = 1; i <= numBlocks; i++) {
      // U1 = PRF(password, salt || INT_32_BE(i))
      final saltPlusIndex = BytesBuilder()
        ..add(salt)
        ..add([
          (i >> 24) & 0xFF,
          (i >> 16) & 0xFF,
          (i >> 8) & 0xFF,
          i & 0xFF,
        ]);
      var u = hmacKey.convert(saltPlusIndex.toBytes()).bytes;
      final xorResult = Uint8List.fromList(u);

      for (var j = 1; j < _iterations; j++) {
        u = hmacKey.convert(u).bytes;
        for (var k = 0; k < xorResult.length; k++) {
          xorResult[k] ^= u[k];
        }
      }
      result.add(xorResult);
    }

    return base64Encode(result.toBytes().sublist(0, _keyLength));
  }

  /// Legacy SHA-256 hash (for migration from unsalted storage).
  String _hashPinLegacy(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}
