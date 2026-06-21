import 'dart:io';
import 'dart:convert';

import 'package:folio_cli/app/theme.dart';
import 'package:folio_cli/utils/win32_console.dart';

/// A UTF-8 aware text input replacement for the `interact` package's `Input`.
///
/// The `interact` package uses `dart_console`'s `readKey()` which reads
/// stdin byte-by-byte via `stdin.readByteSync()` and converts each byte
/// to a character via `String.fromCharCode()`. This breaks multi-byte
/// UTF-8 characters (e.g. Hungarian: á, é, ő, ú, ű, ó, ü) because each
/// byte is treated as a separate Latin-1 character.
///
/// Additionally, `dart_console`'s `disableRawMode()` on Windows has a bug
/// where it uses bitwise AND (`&`) instead of OR (`|`) for console mode
/// flags, leaving the console with echo and line mode disabled. This class
/// explicitly restores echo and line mode before reading.
///
/// This class uses `stdin.readLineSync(encoding: utf8)` which correctly
/// handles multi-byte UTF-8 sequences.
class Utf8Input {
  final String prompt;
  final String? defaultValue;

  Utf8Input({required this.prompt, this.defaultValue});

  String interact() {
    final prefix = FolioTheme.primary;
    final reset = FolioTheme.reset;
    final hint = defaultValue != null ? ' \x1B[90m($defaultValue)\x1B[0m' : '';

    // Restore terminal to normal mode before reading.
    // dart_console's disableRawMode() has a bug on Windows that leaves
    // echo and line mode OFF, so we must explicitly re-enable them.
    try {
      if (stdin.hasTerminal) {
        stdin.echoMode = true;
        stdin.lineMode = true;
      }
    } catch (_) {}
    
    // Explicitly restore standard Windows console mode via FFI if needed.
    forceRestoreConsoleMode();

    stdout.write('$prefix? $reset$prompt$hint \x1B[36m›\x1B[0m ');

    final line = stdin.readLineSync(encoding: utf8) ?? '';
    final result = line.trim();

    if (result.isEmpty && defaultValue != null) {
      return defaultValue!;
    }

    return result;
  }
}
