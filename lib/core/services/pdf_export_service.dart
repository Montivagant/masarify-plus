import '../../data/services/pdf_export_service.dart';

/// Abstract interface for PDF report generation.
///
/// Concrete implementation: [PdfExportServiceImpl] in `data/services/`.
abstract class IPdfExportService {
  /// Generate a PDF report for the given [year]/[month] and return
  /// the file path of the generated PDF.
  Future<String> generate({
    required int year,
    required int month,
    required PdfLabels labels,
    String? locale,
  });
}
