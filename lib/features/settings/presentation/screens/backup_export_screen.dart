import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/services/google_drive_backup_service.dart';
import '../../../../data/services/pdf_export_service.dart';
import '../../../../shared/providers/connectivity_provider.dart';
import '../../../../shared/providers/google_drive_provider.dart';
import '../../../../shared/providers/preferences_provider.dart';
import '../../../../shared/providers/repository_providers.dart';
import '../../../../shared/providers/subscription_provider.dart';
import '../../../../shared/widgets/cards/glass_card.dart';
import '../../../../shared/widgets/cards/glass_section.dart';
import '../../../../shared/widgets/feedback/snack_helper.dart';
import '../../../../shared/widgets/navigation/app_app_bar.dart';

/// Backup & Export screen with 4 action tiles:
///   1. Export JSON backup → share
///   2. Restore from JSON backup
///   3. Export CSV (monthly)
///   4. Export PDF report (monthly)
class BackupExportScreen extends ConsumerStatefulWidget {
  const BackupExportScreen({super.key});

  @override
  ConsumerState<BackupExportScreen> createState() => _BackupExportScreenState();
}

class _BackupExportScreenState extends ConsumerState<BackupExportScreen> {
  bool _busy = false;
  bool _driveSignedIn = false;
  String? _driveEmail;
  String? _lastBackupDate;

  @override
  void initState() {
    super.initState();
    _checkDriveStatus();
  }

  Future<void> _checkDriveStatus() async {
    try {
      final driveService = ref.read(googleDriveBackupProvider);
      final account = await driveService.signInSilently();
      if (!mounted) return;
      final prefs = await ref.read(preferencesFutureProvider.future);
      setState(() {
        _driveSignedIn = account != null;
        _driveEmail = account?.email;
        _lastBackupDate = prefs.lastBackupDate;
      });
    } catch (e) {
      dev.log('Drive silent sign-in failed: $e', name: 'BackupScreen');
      if (!mounted) return;
      try {
        final prefs = await ref.read(preferencesFutureProvider.future);
        if (mounted) setState(() => _lastBackupDate = prefs.lastBackupDate);
      } catch (_) {} // Best-effort cleanup — failure is non-critical.
    }
  }

  Future<void> _signInGoogle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final driveService = ref.read(googleDriveBackupProvider);
      final account = await driveService.signIn();
      if (!mounted) return;
      setState(() {
        _driveSignedIn = account != null;
        _driveEmail = account?.email;
      });
    } catch (e) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOutGoogle() async {
    final driveService = ref.read(googleDriveBackupProvider);
    await driveService.signOut();
    if (!mounted) return;
    final prefs = await ref.read(preferencesFutureProvider.future);
    await prefs.clearDrivePrefs();
    if (!mounted) return;
    setState(() {
      _driveSignedIn = false;
      _driveEmail = null;
      _lastBackupDate = null;
    });
  }

  Future<void> _backupToDrive() async {
    if (_busy) return;
    final isOnline = ref.read(isOnlineProvider).valueOrNull ?? false;
    if (!isOnline) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.backup_offline_error);
      }
      return;
    }

    setState(() => _busy = true);
    try {
      // Export JSON from backup service
      final backupPath = await ref.read(backupServiceProvider).exportToJson();
      final file = File(backupPath);
      final jsonData = await file.readAsString();

      // Upload to Drive
      final driveService = ref.read(googleDriveBackupProvider);
      // M-15 fix: capture file ID returned by uploadBackup.
      final fileId = await driveService.uploadBackup(jsonData);

      // Save backup date + file ID
      final now = DateTime.now().toIso8601String();
      final prefs = await ref.read(preferencesFutureProvider.future);
      await prefs.setLastBackupDate(now);
      await prefs.setDriveFileId(fileId); // M-15 fix: persist file ID

      // Clean up temp file
      try {
        if (file.existsSync()) file.deleteSync();
      } catch (_) {} // Best-effort cleanup — failure is non-critical.

      if (!mounted) return;
      setState(() => _lastBackupDate = now);
      SnackHelper.showSuccess(context, context.l10n.backup_drive_success);
    } catch (e) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.backup_drive_failed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restoreFromDrive() async {
    if (_busy) return;
    final isOnline = ref.read(isOnlineProvider).valueOrNull ?? false;
    if (!isOnline) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.backup_offline_error);
      }
      return;
    }

    setState(() => _busy = true);
    try {
      final driveService = ref.read(googleDriveBackupProvider);
      final backups = await driveService.listBackups();

      if (!mounted) return;
      if (backups.isEmpty) {
        SnackHelper.showInfo(context, context.l10n.backup_no_backups);
        setState(() => _busy = false);
        return;
      }

      // Show backup picker
      final selected = await _showBackupPicker(backups);
      if (selected == null || !mounted) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      // Confirm restore
      final confirmed = await _showRestoreConfirmation();
      if (!confirmed || !mounted) {
        if (mounted) setState(() => _busy = false);
        return;
      }

      // Download, decrypt, validate, and import
      Directory? tempDir;
      try {
        final jsonData = await driveService.downloadBackup(selected.fileId);

        // Validate JSON structure before import
        try {
          final parsed = jsonDecode(jsonData) as Map<String, dynamic>;
          if (parsed['tables'] == null) {
            throw const FormatException('Invalid backup: missing tables');
          }
        } on FormatException {
          if (mounted) {
            SnackHelper.showError(
              context,
              context.l10n.backup_error_invalid,
            );
          }
          return;
        }

        tempDir = await Directory.systemTemp.createTemp('masarify_restore');
        final tempFile = File('${tempDir.path}/restore.json');
        await tempFile.writeAsString(jsonData);

        await ref.read(backupServiceProvider).importFromJson(tempFile.path);
        // M-17 fix: reconcile subscription state after DB restore.
        await ref.read(subscriptionServiceProvider).restorePurchases();

        if (!mounted) return;
        SnackHelper.showSuccess(context, context.l10n.backup_restore_success);
      } finally {
        // Always clean up temp dir
        try {
          if (tempDir != null && tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
        } catch (_) {} // Best-effort cleanup — failure is non-critical.
      }
    } catch (e) {
      if (mounted) {
        final msg = e is FormatException
            ? context.l10n.backup_error_invalid
            : context.l10n.backup_drive_failed;
        SnackHelper.showError(context, msg);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<DriveBackupInfo?> _showBackupPicker(
    List<DriveBackupInfo> backups,
  ) async {
    return showModalBottomSheet<DriveBackupInfo>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Text(
                ctx.l10n.backup_restore_drive,
                style: ctx.textStyles.titleMedium,
              ),
            ),
            ...backups.take(10).map(
                  (b) => ListTile(
                    title: Text(
                      DateFormat.yMMMd(context.languageCode)
                          .add_Hm()
                          .format(b.modifiedTime),
                    ),
                    subtitle: Text(
                      '${(b.sizeBytes / 1024).toStringAsFixed(1)} KB',
                    ),
                    trailing: Icon(
                      context.isRtl
                          ? AppIcons.chevronLeft
                          : AppIcons.chevronRight,
                    ),
                    onTap: () => ctx.pop(b),
                  ),
                ),
            const SizedBox(height: AppSizes.sm),
          ],
        ),
      ),
    );
  }

  /// Delete temp export file after sharing to avoid leaking financial data.
  /// Delays 2s to give the receiving app time to finish reading on Android.
  void _deleteTempFile(String? path) {
    if (path == null) return;
    Future<void>.delayed(AppDurations.tempFileCleanupDelay, () {
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {
        // Best-effort cleanup — don't crash if delete fails
      }
    });
  }

  // ── Export JSON ──────────────────────────────────────────────────────────

  Future<void> _exportJson() async {
    if (_busy) return;
    setState(() => _busy = true);
    String? path;
    try {
      path = await ref.read(backupServiceProvider).exportToJson();
      if (!mounted) return;
      await Share.shareXFiles([XFile(path)]);
      if (mounted) {
        SnackHelper.showSuccess(context, context.l10n.backup_success);
      }
    } catch (e) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
    } finally {
      _deleteTempFile(path);
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Restore JSON ────────────────────────────────────────────────────────

  Future<void> _restoreJson() async {
    if (_busy) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    // R5-I6 fix: store file path in local variable defensively
    final filePath = result?.files.firstOrNull?.path;
    if (filePath == null) return;

    if (!mounted) return;
    final confirmed = await _showRestoreConfirmation();
    if (!confirmed) return;

    setState(() => _busy = true);
    try {
      await ref.read(backupServiceProvider).importFromJson(filePath);
      // M-17 fix: reconcile subscription state after DB restore.
      await ref.read(subscriptionServiceProvider).restorePurchases();
      if (mounted) {
        SnackHelper.showSuccess(context, context.l10n.backup_restore_success);
      }
    } on FormatException {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.backup_error_invalid);
      }
    } catch (e) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _showRestoreConfirmation() async {
    final l10n = context.l10n;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backup_confirm_restore_title),
        content: Text(l10n.backup_confirm_restore_body),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => ctx.pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: ctx.colors.error,
            ),
            child: Text(l10n.backup_restore),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Export CSV ──────────────────────────────────────────────────────────

  Future<void> _exportCsv() async {
    // M-12 fix: capture l10n before async gap for build_context_synchronously.
    final l10n = context.l10n;
    final picked = await _pickMonth();
    if (picked == null || _busy) return;

    setState(() => _busy = true);
    String? path;
    try {
      // M-12 fix: pass localized CSV column headers.
      path = await ref.read(backupServiceProvider).exportTransactionsToCsv(
        year: picked.year,
        month: picked.month,
        headers: [
          l10n.csv_header_date,
          l10n.csv_header_title,
          l10n.csv_header_amount,
          l10n.csv_header_currency,
          l10n.csv_header_type,
          l10n.csv_header_category,
          l10n.csv_header_account,
          l10n.csv_header_tags,
          l10n.csv_header_source,
          l10n.csv_header_location,
          l10n.csv_header_notes,
        ],
      );
      if (!mounted) return;
      await Share.shareXFiles([XFile(path)]);
      if (mounted) {
        SnackHelper.showSuccess(context, context.l10n.backup_success);
      }
    } catch (e) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
    } finally {
      _deleteTempFile(path);
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Export PDF ──────────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    final l10n = context.l10n;
    final langCode = context.languageCode;
    final picked = await _pickMonth();
    if (picked == null || _busy) return;

    setState(() => _busy = true);
    String? path;
    try {
      path = await ref.read(pdfExportServiceProvider).generate(
            year: picked.year,
            month: picked.month,
            locale: langCode,
            labels: PdfLabels(
              reportTitle: l10n.pdf_report_title,
              topCategories: l10n.pdf_top_categories,
              transactions: l10n.pdf_transactions,
              income: l10n.pdf_income,
              expense: l10n.pdf_expense,
              net: l10n.pdf_net,
              categoryHeaders: [l10n.pdf_col_category, l10n.pdf_col_amount],
              txHeaders: [
                l10n.pdf_col_date,
                l10n.pdf_col_title,
                l10n.pdf_col_amount,
                l10n.pdf_col_type,
                l10n.pdf_col_category,
                l10n.pdf_col_wallet,
              ],
              pageLabel: l10n.pdf_page_label,
              ofLabel: l10n.pdf_of_label,
              unknownCategory: l10n.pdf_unknown_category,
            ),
          );
      if (!mounted) return;
      await Share.shareXFiles([XFile(path)]);
      if (mounted) {
        SnackHelper.showSuccess(context, context.l10n.backup_success);
      }
    } catch (e) {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.common_error_generic);
      }
    } finally {
      _deleteTempFile(path);
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Month picker ──────────────────────────────────────────────────────

  Future<DateTime?> _pickMonth() async {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
      helpText: context.l10n.backup_select_month,
      initialDatePickerMode: DatePickerMode.year,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = context.colors;

    return Scaffold(
      appBar: AppAppBar(title: l10n.backup_title),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSizes.bottomScrollPadding),
        children: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(AppSizes.md),
              child: LinearProgressIndicator(),
            ),
          const SizedBox(height: AppSizes.sm),

          // ── Cloud Backup ──────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
            child: GlassSection(
              header: l10n.backup_cloud_title,
              children: [
                if (!_driveSignedIn)
                  _ActionTile(
                    icon: AppIcons.backup,
                    label: l10n.backup_sign_in_google,
                    subtitle: l10n.backup_cloud_title,
                    iconColor: cs.primary,
                    onTap: _busy ? null : _signInGoogle,
                  )
                else ...[
                  ListTile(
                    leading: Icon(AppIcons.checkCircle, color: cs.primary),
                    title: Text(
                      _driveEmail ?? '',
                      style: context.textStyles.bodyMedium,
                    ),
                    subtitle: _lastBackupDate != null
                        ? Text(
                            l10n.backup_last_date(
                              DateFormat.yMMMd(context.languageCode)
                                  .add_Hm()
                                  .format(DateTime.parse(_lastBackupDate!)),
                            ),
                          )
                        : null,
                    trailing: TextButton(
                      onPressed: _busy ? null : _signOutGoogle,
                      child: Text(l10n.backup_sign_out),
                    ),
                  ),
                  _ActionTile(
                    icon: AppIcons.backup,
                    label: l10n.backup_now,
                    subtitle: l10n.backup_uploading,
                    iconColor: cs.primary,
                    onTap: _busy ? null : _backupToDrive,
                  ),
                  _ActionTile(
                    icon: AppIcons.import_,
                    label: l10n.backup_restore_drive,
                    subtitle: l10n.backup_downloading,
                    iconColor: cs.tertiary,
                    onTap: _busy ? null : _restoreFromDrive,
                  ),
                ],
              ],
            ),
          ),

          // ── Encryption warning ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.screenHPadding + AppSizes.md,
            ),
            child: Text(
              l10n.backup_encryption_warning,
              style: context.textStyles.bodySmall?.copyWith(
                color: cs.outline,
              ),
            ),
          ),

          // ── Local Backup ──────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
            child: GlassSection(
              header: l10n.backup_title,
              children: [
                _ActionTile(
                  icon: AppIcons.export_,
                  label: l10n.backup_export_json,
                  subtitle: l10n.backup_export_json_subtitle,
                  iconColor: cs.primary,
                  onTap: _busy ? null : _exportJson,
                ),
                _ActionTile(
                  icon: AppIcons.import_,
                  label: l10n.backup_restore,
                  subtitle: l10n.backup_restore_subtitle,
                  iconColor: cs.tertiary,
                  onTap: _busy ? null : _restoreJson,
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
            child: GlassSection(
              header: l10n.backup_export_csv,
              children: [
                _ActionTile(
                  icon: AppIcons.transactions,
                  label: l10n.backup_export_csv,
                  subtitle: l10n.backup_export_csv_subtitle,
                  iconColor: cs.secondary,
                  onTap: _busy ? null : _exportCsv,
                ),
                _ActionTile(
                  icon: AppIcons.analytics,
                  label: l10n.backup_export_pdf,
                  subtitle: l10n.backup_export_pdf_subtitle,
                  iconColor: cs.secondary,
                  onTap: _busy ? null : _exportPdf,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final enabled = onTap != null;

    return ListTile(
      leading: GlassCard(
        tier: GlassTier.inset,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        tintColor: (enabled ? iconColor : cs.outline)
            .withValues(alpha: AppSizes.opacityLight2),
        child: SizedBox(
          width: AppSizes.colorSwatchSize,
          height: AppSizes.colorSwatchSize,
          child: Icon(
            icon,
            size: AppSizes.iconSm,
            color: enabled ? iconColor : cs.outline,
          ),
        ),
      ),
      title: Text(
        label,
        style: context.textStyles.bodyLarge?.copyWith(
          color: enabled ? null : cs.outline,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: enabled
          ? Icon(
              context.isRtl ? AppIcons.chevronLeft : AppIcons.chevronRight,
            )
          : null,
      onTap: onTap,
    );
  }
}
