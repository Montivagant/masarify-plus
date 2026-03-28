/// [Phase 4 stub] — Full implementation in Phase 4 Task 4.3.
///
/// Handles local database backup and CSV/PDF export.
/// All data stays on-device — Rule #1: 100% offline-first.
///
/// Planned features:
///   • Export to JSON (full backup)
///   • Import from JSON (restore)
///   • Export transactions to CSV
///   • Export reports to PDF
///   • Share via share_plus
abstract class BackupService {
  /// Exports the full database to a JSON file in the app's documents directory.
  /// Returns the file path on success.
  Future<String> exportToJson();

  /// Restores the database from a JSON backup file at [filePath].
  Future<void> importFromJson(String filePath);

  /// Exports transactions for the given month/year to CSV.
  /// Returns the file path on success.
  /// If [headers] is provided, uses them as CSV column headers (localized).
  Future<String> exportTransactionsToCsv({
    required int year,
    required int month,
    List<String>? headers,
  });
}
