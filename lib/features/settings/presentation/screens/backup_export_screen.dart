import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../shared/providers/repository_providers.dart';
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

  // ── Export JSON ──────────────────────────────────────────────────────────

  Future<void> _exportJson() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = await ref.read(backupServiceProvider).exportToJson();
      if (!mounted) return;
      await Share.shareXFiles([XFile(path)]);
      if (mounted) {
        SnackHelper.showSuccess(context, context.l10n.backup_success);
      }
    } catch (e) {
      if (mounted) {
        SnackHelper.showError(context, e.toString());
      }
    } finally {
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
      if (mounted) {
        SnackHelper.showSuccess(context, context.l10n.backup_restore_success);
      }
    } on FormatException {
      if (mounted) {
        SnackHelper.showError(context, context.l10n.backup_error_invalid);
      }
    } catch (e) {
      if (mounted) {
        SnackHelper.showError(context, e.toString());
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
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
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
    final picked = await _pickMonth();
    if (picked == null || _busy) return;

    setState(() => _busy = true);
    try {
      final path =
          await ref.read(backupServiceProvider).exportTransactionsToCsv(
                year: picked.year,
                month: picked.month,
              );
      if (!mounted) return;
      await Share.shareXFiles([XFile(path)]);
      if (mounted) {
        SnackHelper.showSuccess(context, context.l10n.backup_success);
      }
    } catch (e) {
      if (mounted) {
        SnackHelper.showError(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Export PDF ──────────────────────────────────────────────────────────

  Future<void> _exportPdf() async {
    final picked = await _pickMonth();
    if (picked == null || _busy) return;

    setState(() => _busy = true);
    try {
      final path = await ref.read(pdfExportServiceProvider).generate(
            year: picked.year,
            month: picked.month,
          );
      if (!mounted) return;
      await Share.shareXFiles([XFile(path)]);
      if (mounted) {
        SnackHelper.showSuccess(context, context.l10n.backup_success);
      }
    } catch (e) {
      if (mounted) {
        SnackHelper.showError(context, e.toString());
      }
    } finally {
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
    final cs = Theme.of(context).colorScheme;

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
          const Divider(
            indent: AppSizes.screenHPadding,
            endIndent: AppSizes.screenHPadding,
          ),
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
    final cs = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return ListTile(
      leading: Container(
        width: AppSizes.colorSwatchSize,
        height: AppSizes.colorSwatchSize,
        decoration: BoxDecoration(
          color: (enabled ? iconColor : cs.outline).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        ),
        child: Icon(
          icon,
          size: AppSizes.iconSm,
          color: enabled ? iconColor : cs.outline,
        ),
      ),
      title: Text(
        label,
        style: TextStyle(color: enabled ? null : cs.outline),
      ),
      subtitle: Text(subtitle),
      trailing: enabled
          ? Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? AppIcons.chevronLeft
                  : AppIcons.chevronRight,
            )
          : null,
      onTap: onTap,
    );
  }
}
