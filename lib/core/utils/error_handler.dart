/// Centralized error type hierarchy for Masarify.
/// Use these sealed classes to categorize errors uniformly.
sealed class AppError {
  const AppError(this.message, {this.code});
  final String message;
  final String? code;
}

class DatabaseError extends AppError {
  const DatabaseError(super.message, {super.code});
}

class ValidationError extends AppError {
  const ValidationError(super.message, {super.code});
}

class PermissionError extends AppError {
  const PermissionError(super.message, {super.code});
}

class ParsingError extends AppError {
  const ParsingError(super.message, {super.code});
}

class FileError extends AppError {
  const FileError(super.message, {super.code});
}

class NetworkError extends AppError {
  const NetworkError(super.message, {super.code});
}
