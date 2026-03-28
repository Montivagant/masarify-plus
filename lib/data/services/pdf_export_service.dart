import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/constants/app_sizes.dart';
import '../../core/utils/money_formatter.dart';
import '../database/app_database.dart';

/// Localized labels for PDF report generation.
class PdfLabels {
  const PdfLabels({
    required this.reportTitle,
    required this.topCategories,
    required this.transactions,
    required this.income,
    required this.expense,
    required this.net,
    required this.categoryHeaders,
    required this.txHeaders,
    required this.pageLabel,
    required this.ofLabel,
    this.unknownCategory = 'Unknown',
  });

  final String reportTitle;
  final String topCategories;
  final String transactions;
  final String income;
  final String expense;
  final String net;
  final List<String> categoryHeaders;
  final List<String> txHeaders;
  final String pageLabel;
  final String ofLabel;
  final String unknownCategory;
}

/// Generates a monthly financial summary PDF.
///
/// - Header: "Masarify Monthly Report — [Month Year]"
/// - Income / Expense / Net totals
/// - Top 5 categories table
/// - Transaction list table
class PdfExportService {
  PdfExportService(this._db);

  final AppDatabase _db;

  // M-14 fix: cache Arabic font to avoid reloading on every export.
  static pw.Font? _cachedArabicFont;

  /// Load Arabic-capable font from bundled assets.
  /// Returns null if the font file is not bundled yet (graceful fallback).
  /// TODO(M-14): Download NotoSansArabic-Regular.ttf from Google Fonts and
  /// place at assets/fonts/NotoSansArabic-Regular.ttf for Arabic PDF support.
  static Future<pw.Font?> _loadArabicFont() async {
    if (_cachedArabicFont != null) return _cachedArabicFont;
    try {
      final data = await rootBundle.load(
        'assets/fonts/NotoSansArabic-Regular.ttf',
      );
      _cachedArabicFont = pw.Font.ttf(data);
      return _cachedArabicFont;
    } catch (_) {
      // Font file not bundled — Arabic glyphs will render as boxes.
      return null;
    }
  }

  Future<String> generate({
    required int year,
    required int month,
    required PdfLabels labels,
    String? locale,
  }) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    final monthLabel = DateFormat.yMMMM(locale).format(start);
    final isArabic = locale == 'ar';

    // M-14 fix: load Arabic font if needed.
    pw.ThemeData? pdfTheme;
    if (isArabic) {
      final arabicFont = await _loadArabicFont();
      if (arabicFont != null) {
        pdfTheme = pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicFont,
        );
      }
    }

    // Query data.
    final txs = await (_db.select(_db.transactions)
          ..where(
            (t) =>
                t.transactionDate.isBiggerOrEqualValue(start) &
                t.transactionDate.isSmallerThanValue(end),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.transactionDate)]))
        .get();

    final categories = await _db.select(_db.categories).get();
    final wallets = await _db.select(_db.wallets).get();

    final catMap = {for (final c in categories) c.id: c.name};
    final walletMap = {for (final w in wallets) w.id: w.name};

    // Compute totals.
    var totalIncome = 0;
    var totalExpense = 0;
    final categorySpend = <int, int>{};

    for (final tx in txs) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      } else if (tx.type == 'expense') {
        totalExpense += tx.amount;
        categorySpend[tx.categoryId] =
            (categorySpend[tx.categoryId] ?? 0) + tx.amount;
      }
    }

    final net = totalIncome - totalExpense;

    // Top 5 categories.
    final topCategories = categorySpend.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = topCategories.take(5).toList();

    // Build PDF.
    // M-14 fix: apply Arabic theme if available.
    final pdf = pw.Document(theme: pdfTheme);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        // M-14 fix: RTL text direction for Arabic locale.
        textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
        margin: const pw.EdgeInsets.all(AppSizes.pdfMargin),
        build: (context) => [
          // Header
          pw.Center(
            child: pw.Text(
              labels.reportTitle,
              style: pw.TextStyle(
                fontSize: AppSizes.pdfTitleFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Center(
            child: pw.Text(
              monthLabel,
              style: const pw.TextStyle(fontSize: AppSizes.pdfSubtitleFontSize),
            ),
          ),
          pw.SizedBox(height: AppSizes.lg),

          // Summary
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _summaryColumn(
                labels.income,
                MoneyFormatter.format(totalIncome),
              ),
              _summaryColumn(
                labels.expense,
                MoneyFormatter.format(totalExpense),
              ),
              _summaryColumn(
                labels.net,
                MoneyFormatter.format(net.abs()),
              ),
            ],
          ),
          pw.SizedBox(height: AppSizes.lg),

          // Top 5 categories
          if (top5.isNotEmpty) ...[
            pw.Text(
              labels.topCategories,
              style: pw.TextStyle(
                fontSize: AppSizes.pdfSubtitleFontSize,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: AppSizes.sm),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellPadding: const pw.EdgeInsets.all(AppSizes.pdfCellPadding),
              headers: labels.categoryHeaders,
              data: top5.map((e) {
                return [
                  catMap[e.key] ?? labels.unknownCategory,
                  MoneyFormatter.format(e.value),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: AppSizes.lg),
          ],

          // Transaction table
          pw.Text(
            labels.transactions,
            style: pw.TextStyle(
              fontSize: AppSizes.pdfSubtitleFontSize,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: AppSizes.sm),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey200,
            ),
            cellPadding: const pw.EdgeInsets.all(AppSizes.pdfCellPaddingSm),
            cellStyle: const pw.TextStyle(fontSize: AppSizes.pdfSmallFontSize),
            headers: labels.txHeaders,
            data: txs.map((tx) {
              return [
                DateFormat('MM/dd', locale).format(tx.transactionDate),
                tx.title,
                MoneyFormatter.format(tx.amount),
                tx.type,
                catMap[tx.categoryId] ?? '',
                walletMap[tx.walletId] ?? '',
              ];
            }).toList(),
          ),
        ],
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${labels.pageLabel} ${context.pageNumber} ${labels.ofLabel} ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: AppSizes.pdfSmallFontSize,
              color: PdfColors.grey,
            ),
          ),
        ),
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/masarify_report_${year}_${month.toString().padLeft(2, '0')}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  pw.Widget _summaryColumn(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: AppSizes.pdfBodyFontSize,
            color: PdfColors.grey700,
          ),
        ),
        pw.SizedBox(height: AppSizes.xs),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: AppSizes.pdfSummaryFontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
