import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../data/services/pdf_export_service.dart';
import '../../../../shared/providers/repository_providers.dart';
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

  /// Delete temp export file after sharing to avoid leaking financial data.
  void _deleteTempFile(String? path) {
    if (path == null) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {
      // Best-effort cleanup — don't crash if delete fails
    }
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
    final picked = await _pickMonth();
    if (picked == null || _busy) return;

    setState(() => _busy = true);
    String? path;
    try {
      path = await ref.read(backupServiceProvider).exportTransactionsToCsv(
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
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
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenHPadding),
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
        tintColor: (enabled ? iconColor : cs.outline).withValues(alpha: AppSizes.opacityLight2),
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
              Directionality.of(context) == TextDirection.rtl
                  ? AppIcons.chevronLeft
                  : AppIcons.chevronRight,
            )
          : null,
      onTap: onTap,
    );
  }
}
