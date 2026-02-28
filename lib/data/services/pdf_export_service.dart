import 'dart:io';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/money_formatter.dart';
import '../database/app_database.dart';

/// Generates a monthly financial summary PDF.
///
/// - Header: "Masarify Monthly Report — [Month Year]"
/// - Income / Expense / Net totals
/// - Top 5 categories table
/// - Transaction list table
class PdfExportService {
  PdfExportService(this._db);

  final AppDatabase _db;

  Future<String> generate({required int year, required int month}) async {
    final start = DateTime(year, month);
    final end = DateTime(year, month + 1);
    final monthLabel = DateFormat.yMMMM().format(start);

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
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Center(
            child: pw.Text(
              'Masarify Monthly Report',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Center(
            child: pw.Text(
              monthLabel,
              style: const pw.TextStyle(fontSize: 14),
            ),
          ),
          pw.SizedBox(height: 24),

          // Summary
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _summaryColumn('Income', MoneyFormatter.format(totalIncome)),
              _summaryColumn('Expense', MoneyFormatter.format(totalExpense)),
              _summaryColumn('Net', MoneyFormatter.format(net)),
            ],
          ),
          pw.SizedBox(height: 24),

          // Top 5 categories
          if (top5.isNotEmpty) ...[
            pw.Text(
              'Top Categories',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey200,
              ),
              cellPadding: const pw.EdgeInsets.all(6),
              headers: ['Category', 'Amount'],
              data: top5.map((e) {
                return [
                  catMap[e.key] ?? 'Unknown',
                  MoneyFormatter.format(e.value),
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 24),
          ],

          // Transaction table
          pw.Text(
            'Transactions',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey200,
            ),
            cellPadding: const pw.EdgeInsets.all(4),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headers: ['Date', 'Title', 'Amount', 'Type', 'Category', 'Wallet'],
            data: txs.map((tx) {
              return [
                DateFormat('MM/dd').format(tx.transactionDate),
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
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
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
          style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }
}
