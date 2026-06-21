import 'dart:ffi';
import 'dart:io';

// Windows kernel32.dll bindings
typedef _SetConsoleOutputCPNative = Int32 Function(Uint32 codePage);
typedef _SetConsoleOutputCPDart = int Function(int codePage);
typedef _SetConsoleCPNative = Int32 Function(Uint32 codePage);
typedef _SetConsoleCPDart = int Function(int codePage);

// Win32 console mode bindings
typedef _GetStdHandleNative = Pointer<Void> Function(Int32 nStdHandle);
typedef _GetStdHandleDart = Pointer<Void> Function(int nStdHandle);
typedef _SetConsoleModeNative = Int32 Function(Pointer<Void> hConsoleHandle, Uint32 dwMode);
typedef _SetConsoleModeDart = int Function(Pointer<Void> hConsoleHandle, int dwMode);

/// Sets the Windows console input and output code page to UTF-8 (65001)
/// using direct Win32 API calls via FFI.
///
/// This is the only reliable way to enable UTF-8 output for a compiled
/// Dart executable on Windows. The commonly used `chcp 65001` approach
/// only affects the child cmd.exe process, not the current process.
///
/// On non-Windows platforms, this is a no-op.
void enableUtf8Console() {
  if (!Platform.isWindows) return;

  try {
    final kernel32 = DynamicLibrary.open('kernel32.dll');

    final setConsoleOutputCP = kernel32
        .lookupFunction<_SetConsoleOutputCPNative, _SetConsoleOutputCPDart>(
            'SetConsoleOutputCP');
    final setConsoleCP = kernel32
        .lookupFunction<_SetConsoleCPNative, _SetConsoleCPDart>('SetConsoleCP');

    setConsoleOutputCP(65001); // UTF-8 output
    setConsoleCP(65001); // UTF-8 input
  } catch (_) {
    // Silently ignore if FFI fails (e.g. sandboxed environment)
  }
}

/// Forcefully restores standard cooked console mode on Windows (echo, line input, etc.)
/// using direct Win32 API SetConsoleMode call.
///
/// This is a failsafe for when dart_console / interact package leaves the console in raw mode
/// and Dart's standard `stdin.echoMode = true` throws an exception or fails to restore echo.
void forceRestoreConsoleMode() {
  if (!Platform.isWindows) return;

  try {
    final kernel32 = DynamicLibrary.open('kernel32.dll');
    final getStdHandle = kernel32
        .lookupFunction<_GetStdHandleNative, _GetStdHandleDart>('GetStdHandle');
    final setConsoleMode = kernel32
        .lookupFunction<_SetConsoleModeNative, _SetConsoleModeDart>('SetConsoleMode');

    final hStdIn = getStdHandle(-10); // STD_INPUT_HANDLE (0xFFFFFFF6)
    if (hStdIn.address != 0 && hStdIn.address != -1) {
      // Standard cooked console mode input flags:
      // ENABLE_PROCESSED_INPUT (0x0001) | ENABLE_LINE_INPUT (0x0002) | ENABLE_ECHO_INPUT (0x0004)
      // | ENABLE_INSERT_MODE (0x0020) | ENABLE_QUICK_EDIT_MODE (0x0040) | ENABLE_EXTENDED_FLAGS (0x0080)
      // We do NOT include ENABLE_VIRTUAL_TERMINAL_INPUT (0x0200) because it overrides standard Backspace (0x08)
      // with DEL (0x7F) and breaks standard line editing/deletion in readLineSync().
      final cookedMode = 0x0001 | 0x0002 | 0x0004 | 0x0020 | 0x0040 | 0x0080;
      setConsoleMode(hStdIn, cookedMode);
    }
  } catch (_) {
    // Silently ignore if FFI fails
  }
}
