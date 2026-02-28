import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Offline crash log service — writes stack traces and device info
/// to a local file in the app directory. No PII logged.
///
/// File is capped at 500KB — oldest entries are rotated out.
class CrashLogService {
  CrashLogService._();

  static File? _logFile;

  /// Max file size in bytes (500 KB).
  static const int _maxBytes = 500 * 1024;

  /// Initialize the service — must be called before [log].
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    _logFile = File('${dir.path}/app_crash_log.txt');
  }

  /// Log an error with its stack trace to the local crash log file.
  /// Never throws — silently fails if the file is unavailable.
  static Future<void> log(Object error, StackTrace stack) async {
    try {
      final file = _logFile;
      if (file == null) return;

      final timestamp = DateTime.now().toIso8601String();
      final entry = StringBuffer()
        ..writeln('=== CRASH $timestamp ===')
        ..writeln('Error: $error')
        ..writeln('Stack:')
        ..writeln(stack)
        ..writeln();

      await file.writeAsString(
        entry.toString(),
        mode: FileMode.append,
        flush: true,
      );

      await _rotateIfNeeded(file);
    } catch (_) {
      // Never crash the crash logger.
      if (kDebugMode) rethrow;
    }
  }

  /// Read the entire crash log. Returns null if no log file exists.
  static Future<String?> readLog() async {
    try {
      final file = _logFile;
      if (file == null || !await file.exists()) return null;
      return await file.readAsString();
    } catch (_) {
      return null;
    }
  }

  /// Rotate the log file if it exceeds [_maxBytes].
  /// Keeps the newest half of the file.
  static Future<void> _rotateIfNeeded(File file) async {
    try {
      final stat = await file.stat();
      if (stat.size <= _maxBytes) return;

      final content = await file.readAsString();
      // Keep the second half (newest entries).
      final half = content.length ~/ 2;
      final nextNewline = content.indexOf('\n', half);
      final trimmed = nextNewline >= 0
          ? content.substring(nextNewline + 1)
          : content.substring(half);

      await file.writeAsString(trimmed, flush: true);
    } catch (_) {
      // Best effort rotation.
    }
  }
}
