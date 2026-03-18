import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/google_drive_backup_service.dart';

/// Singleton Google Drive backup service.
final googleDriveBackupProvider = Provider<GoogleDriveBackupService>(
  (ref) => GoogleDriveBackupService(),
);
