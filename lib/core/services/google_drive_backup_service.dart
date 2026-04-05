import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

/// Metadata for a backup file stored on Google Drive.
class DriveBackupInfo {
  const DriveBackupInfo({
    required this.fileId,
    required this.name,
    required this.modifiedTime,
    required this.sizeBytes,
  });

  final String fileId;
  final String name;
  final DateTime modifiedTime;
  final int sizeBytes;
}

/// Google Drive backup service using the `appDataFolder` scope.
///
/// Backups are AES-256-SIC (CTR mode) encrypted before upload. The encryption key
/// is generated once and stored in [FlutterSecureStorage].
class GoogleDriveBackupService {
  GoogleDriveBackupService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const _keyStorageKey = 'drive_backup_aes_key';
  static const _legacyIvStorageKey = 'drive_backup_aes_iv';
  static const _backupPrefix = 'masarify_backup_';
  static const _backupSuffix = '.enc';

  /// C-7 fix: key file stored in Drive appDataFolder for recovery after reinstall.
  static const _driveKeyFileName = 'masarify_encryption_key.dat';

  final _googleSignIn = GoogleSignIn(
    scopes: [drive.DriveApi.driveAppdataScope],
    serverClientId:
        '287070145777-kopeobabr0fvd0pirdb7tq3nus6o2clf.apps.googleusercontent.com',
  );

  // ── Auth ──────────────────────────────────────────────────────────────

  /// Attempts interactive Google Sign-In. Rethrows on failure so callers
  /// can surface a meaningful error message; returns `null` only when the
  /// user explicitly cancels the account picker.
  Future<GoogleSignInAccount?> signIn() async {
    try {
      return await _googleSignIn.signIn();
    } catch (e) {
      dev.log('Google Sign-In failed: $e', name: 'DriveBackup');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  bool get isSignedIn => _googleSignIn.currentUser != null;

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  Future<GoogleSignInAccount?> signInSilently() async {
    return _googleSignIn.signInSilently();
  }

  // ── Drive API ─────────────────────────────────────────────────────────

  Future<drive.DriveApi> _getDriveApi() async {
    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) {
      throw StateError('Not signed in to Google');
    }
    return drive.DriveApi(httpClient);
  }

  // ── Key Sync (C-7 fix) ───────────────────────────────────────────────

  /// Upload encryption key to Drive appDataFolder so it survives reinstall.
  /// Uses create-or-update: finds existing key file and overwrites, or creates new.
  Future<void> _syncKeyToDrive(drive.DriveApi driveApi) async {
    final key = await _getOrCreateKey();
    final keyBytes = Uint8List.fromList(key.bytes);

    // Check if key file already exists.
    final existing = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_driveKeyFileName'",
      $fields: 'files(id)',
    );

    final media = drive.Media(Stream.value(keyBytes), keyBytes.length);

    final existingId = existing.files?.firstOrNull?.id;
    if (existingId != null) {
      // Update existing key file.
      await driveApi.files.update(
        drive.File(),
        existingId,
        uploadMedia: media,
      );
    } else {
      // Create new key file.
      final file = drive.File()
        ..name = _driveKeyFileName
        ..parents = ['appDataFolder'];
      await driveApi.files.create(file, uploadMedia: media);
    }
    dev.log('Encryption key synced to Drive', name: 'DriveBackup');
  }

  /// Restore encryption key from Drive appDataFolder (after reinstall).
  /// Returns true if key was restored, false if no key found on Drive.
  Future<bool> restoreKeyFromDrive() async {
    try {
      final driveApi = await _getDriveApi();
      final result = await driveApi.files.list(
        spaces: 'appDataFolder',
        q: "name = '$_driveKeyFileName'",
        $fields: 'files(id)',
      );

      final keyFileId = result.files?.firstOrNull?.id;
      if (keyFileId == null) return false;

      final media = await driveApi.files.get(
        keyFileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final chunks = <List<int>>[];
      await for (final chunk in media.stream) {
        chunks.add(chunk);
      }
      final bytes = chunks.expand((c) => c).toList();
      if (bytes.length != 32) return false; // AES-256 key must be 32 bytes

      final key = enc.Key(Uint8List.fromList(bytes));
      await _secureStorage.write(key: _keyStorageKey, value: key.base64);
      dev.log('Encryption key restored from Drive', name: 'DriveBackup');
      return true;
    } catch (e) {
      dev.log('Key restore failed: $e', name: 'DriveBackup');
      return false;
    }
  }

  // ── Upload ────────────────────────────────────────────────────────────

  /// Encrypt and upload [jsonData] to Google Drive appDataFolder.
  /// Also syncs the encryption key to Drive for recovery after reinstall (C-7).
  /// Returns the file ID.
  Future<String> uploadBackup(String jsonData) async {
    final driveApi = await _getDriveApi();

    // C-7: sync encryption key to Drive alongside backup.
    await _syncKeyToDrive(driveApi);

    // Encrypt
    final encrypted = await _encrypt(jsonData);

    // Create file metadata
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final fileName = '$_backupPrefix$timestamp$_backupSuffix';

    final file = drive.File()
      ..name = fileName
      ..parents = ['appDataFolder'];

    final media = drive.Media(
      Stream.value(encrypted),
      encrypted.length,
    );

    final result = await driveApi.files.create(
      file,
      uploadMedia: media,
    );

    final id = result.id;
    if (id == null) {
      throw StateError('Drive API did not return a file ID after create');
    }

    dev.log(
      'Backup uploaded: $id (${encrypted.length} bytes)',
      name: 'DriveBackup',
    );

    return id;
  }

  // ── List ──────────────────────────────────────────────────────────────

  /// List all backup files in the appDataFolder.
  Future<List<DriveBackupInfo>> listBackups() async {
    final driveApi = await _getDriveApi();

    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name contains '$_backupPrefix'",
      orderBy: 'modifiedTime desc',
      $fields: 'files(id, name, modifiedTime, size)',
    );

    return (fileList.files ?? []).where((f) => f.id != null).map((f) {
      return DriveBackupInfo(
        fileId: f.id!,
        name: f.name ?? 'Unknown',
        modifiedTime: f.modifiedTime ?? DateTime.now(),
        sizeBytes: int.tryParse(f.size ?? '0') ?? 0,
      );
    }).toList();
  }

  // ── Download ──────────────────────────────────────────────────────────

  /// Download and decrypt a backup file. Returns the JSON string.
  /// C-7: attempts key restoration from Drive if local key is missing (reinstall).
  Future<String> downloadBackup(String fileId) async {
    final driveApi = await _getDriveApi();

    // C-7: if no local key, try restoring from Drive before decryption.
    final localKey = await _secureStorage.read(key: _keyStorageKey);
    if (localKey == null) {
      final restored = await restoreKeyFromDrive();
      if (!restored) {
        throw StateError(
          'Encryption key not found locally or on Drive. '
          'Cannot decrypt this backup.',
        );
      }
    }

    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final chunks = <List<int>>[];
    await for (final chunk in media.stream) {
      chunks.add(chunk);
    }
    final bytes = chunks.expand((c) => c).toList();

    return _decrypt(Uint8List.fromList(bytes));
  }

  // ── Encryption ────────────────────────────────────────────────────────

  Future<enc.Key> _getOrCreateKey() async {
    final stored = await _secureStorage.read(key: _keyStorageKey);
    if (stored != null) {
      return enc.Key.fromBase64(stored);
    }
    final key = enc.Key.fromSecureRandom(32); // AES-256
    await _secureStorage.write(
      key: _keyStorageKey,
      value: key.base64,
    );
    return key;
  }

  /// Compute HMAC-SHA256 for Encrypt-then-MAC integrity verification.
  List<int> _computeHmac(enc.Key key, List<int> data) {
    final hmac = Hmac(sha256, key.bytes);
    return hmac.convert(data).bytes;
  }

  /// Encrypt with fresh IV + HMAC-SHA256 integrity tag.
  /// Format: IV (16) || ciphertext || HMAC-SHA256(key, IV || ciphertext) (32)
  Future<Uint8List> _encrypt(String plaintext) async {
    final key = await _getOrCreateKey();
    final iv = enc.IV.fromSecureRandom(16); // Fresh IV every time
    final encrypter = enc.Encrypter(enc.AES(key));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);
    final ivAndCipher = [...iv.bytes, ...encrypted.bytes];
    final hmac = _computeHmac(key, ivAndCipher);
    return Uint8List.fromList([...ivAndCipher, ...hmac]);
  }

  /// Decrypt ciphertext. Supports 3 formats (newest → oldest):
  /// 1. IV (16) + ciphertext + HMAC (32) — current format
  /// 2. IV (16) + ciphertext — pre-HMAC format
  /// 3. Ciphertext only + legacy stored IV — original format
  Future<String> _decrypt(Uint8List cipherBytes) async {
    final key = await _getOrCreateKey();
    final encrypter = enc.Encrypter(enc.AES(key));

    // Format 1: IV + ciphertext + HMAC (min 64 bytes: 16 IV + 16 cipher + 32 HMAC)
    if (cipherBytes.length >= 64) {
      final hmacStart = cipherBytes.length - 32;
      final ivAndCipher = cipherBytes.sublist(0, hmacStart);
      final storedHmac = cipherBytes.sublist(hmacStart);
      final computedHmac = _computeHmac(key, ivAndCipher);

      if (_constantTimeEquals(storedHmac, Uint8List.fromList(computedHmac))) {
        final iv = enc.IV(ivAndCipher.sublist(0, 16));
        final encrypted = enc.Encrypted(ivAndCipher.sublist(16));
        return encrypter.decrypt(encrypted, iv: iv);
      }
      // HMAC mismatch — likely a pre-HMAC backup, try format 2
      dev.log(
        'HMAC verification failed, trying format 2 (no HMAC)',
        name: 'DriveBackup',
      );
    }

    // Format 2: IV (16) + ciphertext, no HMAC (min 32 bytes)
    if (cipherBytes.length >= 32) {
      try {
        final iv = enc.IV(cipherBytes.sublist(0, 16));
        final encrypted = enc.Encrypted(cipherBytes.sublist(16));
        return encrypter.decrypt(encrypted, iv: iv);
      } on ArgumentError catch (e) {
        dev.log(
          'Format-2 decrypt failed, trying legacy: $e',
          name: 'DriveBackup',
        );
      } on StateError catch (e) {
        dev.log(
          'Format-2 decrypt failed, trying legacy: $e',
          name: 'DriveBackup',
        );
      }
    }

    // Format 3: Legacy — IV stored in secure storage
    final legacyIvBase64 = await _secureStorage.read(key: _legacyIvStorageKey);
    if (legacyIvBase64 != null) {
      final iv = enc.IV.fromBase64(legacyIvBase64);
      final encrypted = enc.Encrypted(cipherBytes);
      return encrypter.decrypt(encrypted, iv: iv);
    }

    throw StateError('Cannot decrypt: no IV found (legacy or prepended)');
  }

  /// Constant-time comparison to prevent timing side-channel attacks on HMAC.
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
