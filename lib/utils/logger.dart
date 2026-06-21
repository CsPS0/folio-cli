import 'dart:io';

/// Lightweight debug logger for Folio CLI.
///
/// Activated via `--debug` flag or `FOLIO_DEBUG=1` environment variable.
/// Outputs to stderr so it doesn't interfere with normal stdout output.
class FolioLogger {
  static bool _enabled = false;

  /// Initialize the logger. Call once at app startup.
  static void init({bool enabled = false}) {
    _enabled = enabled || Platform.environment['FOLIO_DEBUG'] == '1';
    if (_enabled) {
      stderr.writeln('[DEBUG] Folio debug logging enabled.');
    }
  }

  /// Whether debug logging is currently enabled.
  static bool get isEnabled => _enabled;

  /// Log a debug message to stderr (only when debug mode is active).
  static void debug(String message) {
    if (_enabled) {
      stderr.writeln('[DEBUG] $message');
    }
  }

  /// Log a warning message to stderr (only when debug mode is active).
  static void warn(String message) {
    if (_enabled) {
      stderr.writeln('[WARN] $message');
    }
  }

  /// Log an error with optional exception details (only when debug mode is active).
  static void error(String message, [Object? error]) {
    if (_enabled) {
      stderr.writeln('[ERROR] $message');
      if (error != null) {
        stderr.writeln('[ERROR] Details: $error');
      }
    }
  }
}
