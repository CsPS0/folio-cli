import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:interact/interact.dart';
import 'package:folio_cli/api/client.dart';
import 'package:folio_cli/models/models.dart';
import 'package:folio_cli/utils/chart_generator.dart';
import 'package:folio_cli/utils/ics_exporter.dart';
import 'package:folio_cli/utils/encryption.dart';
import 'package:folio_cli/app/components/custom_menu.dart';
import 'package:folio_cli/app/components/utf8_input.dart';
import 'package:folio_cli/app/theme.dart';
import 'package:folio_cli/utils/logger.dart';
import 'package:folio_cli/utils/win32_console.dart';
import 'package:folio_cli/version.dart';
import 'package:path/path.dart' as p;
import 'state/app_state.dart';

part 'login/auth_manager.dart';
part 'login/login_flow.dart';
part 'daemon/daemon_logic.dart';

part 'views/settings_view.dart';
part 'views/student_data_view.dart';
part 'views/grades_view.dart';
part 'views/timetable_view.dart';
part 'views/absences_view.dart';
part 'views/homework_messages_view.dart';
part 'views/export_view.dart';
part 'views/dashboard_view.dart';
part 'views/wrapped_view.dart';

class FolioCliApp {
  Future<bool> _ensureClientReady() async {
    if (_client == null) {
      print('Hiba: Kliens nincs inicializálva. Próbálj újra bejelentkezni!');
      return false;
    }
    return true;
  }

  void _clearScreen() {
    stdout.write('\x1B[2J\x1B[3J\x1B[H');
  }

  KretaClient? _client;
  String? studentUid;

  File _getAuthFile() {
    return AppState.instance.authFile;
  }

  Future<bool> _tryAutoLogin() async {
    final authFile = _getAuthFile();
    if (!authFile.existsSync()) return false;

    try {
      final content = await authFile.readAsString();
      dynamic data;
      // Handle plain-text vs encrypted
      if (content.trim().startsWith('{')) {
        data = jsonDecode(content);
        // We let auth_manager.dart handle the actual encryption/migration upon first successful login/save.
      } else {
        final decrypted = EncryptionUtil.decrypt(content);
        data = jsonDecode(decrypted);
      }
      
      Map<String, dynamic>? activeProfile;

      if (data is Map<String, dynamic>) {
        if (data.containsKey('profiles')) {
          final profiles = data['profiles'] as List;
          final idx = data['activeProfileIndex'] ?? 0;
          if (profiles.isNotEmpty && idx >= 0 && idx < profiles.length) {
            activeProfile = profiles[idx];
          }
        } else if (data.containsKey('accessToken')) {
          activeProfile = data;
        }
      }

      if (activeProfile != null) {
        final instituteCode = activeProfile['instituteCode'];
        final accessToken = activeProfile['accessToken'];
        final refreshToken = activeProfile['refreshToken'];

        if (instituteCode != null && accessToken != null) {
          _client = KretaClient(instituteCode: instituteCode);
          _client!.accessToken = accessToken;
          _client!.refreshToken = refreshToken;
          _client!.onTokenRefreshed = () async {
            await _saveAuth();
          };

          var studentData = await _client!.getStudentData(silent: true);
          
          if (studentData == null && refreshToken != null) {
            // Token might be expired, let's try to refresh
            if (await _client!.refreshAccessToken()) {
              studentData = await _client!.getStudentData();
              if (studentData != null) {
                // Save the new tokens silently
                await _saveAuth();
              }
            }
          }

          if (studentData != null) {
            studentUid = studentData.uid;
            return true;
          }
        }
      }
    } on FormatException catch (_) {
      print('\x1B[1;31mA titkosítási kulcs érvénytelen (valószínűleg megváltozott a számítógép neve). Kérlek, jelentkezz be újra!\x1B[0m\n');
      if (authFile.existsSync()) authFile.deleteSync();
      return false;
    } catch (e) {
      // Ignore other errors like network timeouts on refresh
    }
    
    return false;
  }

  Future<void> runDaemon() async {
    if (!await _tryAutoLogin()) {
      return;
    }
    await _checkNewItems();
  }

  void _showBanner() {
    print('\x1B[36m');
    print(r'''
    _____     _ _       
   |  ___|__ | (_) ___  
   | |_ / _ \| | |/ _ \ 
   |  _| (_) | | | (_) |'''
    '\n   |_|  \\___/|_|_|\\___/ CLI $appVersion\n');
    print('\x1B[0m');
  }

  void _showMainMenuBanner() {
    if (!AppState.instance.showAsciiBanner) return;
    
    final color = FolioTheme.primary;
    print(color);
    print(r'''
███████╗ ██████╗ ██╗     ██╗ ██████╗ 
██╔════╝██╔═══██╗██║     ██║██╔═══██╗
█████╗  ██║   ██║██║     ██║██║   ██║
██╔══╝  ██║   ██║██║     ██║██║   ██║
██║     ╚██████╔╝███████╗██║╚██████╔╝
╚═╝      ╚═════╝ ╚══════╝╚═╝ ╚═════╝ ''');
    print(FolioTheme.reset);
  }

  Future<void> runInteractive({bool startInDashboard = false}) async {
    AppState.instance.migrateOldFiles();
    FolioTheme.configureInteractTheme();
    _showBanner();

    print('Keresem a mentett bejelentkezést...');
    if (await _tryAutoLogin()) {
      print('Sikeres automatikus bejelentkezés!\n');
      await _checkForUpdates();
      if (startInDashboard) {
        await _showDashboard();
      } else {
        await _mainMenu();
      }
      return;
    }

    print('\x1B[38;5;208m=============================================================');
    print(' FIGYELEM! Kérjük, kapcsold ki a Folio/Firka kiegészítőt');
    print(' a böngésződben a bejelentkezés idejére, mert jelenleg');
    print(' problémák vannak a bejelentkezési felülettel!');
    print('=============================================================\x1B[0m\n');

    await _performLoginFlow();
    await _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    try {
      final res = await http.get(
        Uri.parse('https://api.github.com/repos/CsPS0/folio-cli/releases/latest'),
      ).timeout(Duration(seconds: 2));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final latestVersion = data['tag_name'] as String?;
        final currentVersion = appVersion;
        
        if (latestVersion != null && latestVersion != currentVersion && latestVersion.startsWith('v')) {
          print('\x1B[33m\n=============================================================');
          print('[!] Új Folio CLI verzió érhető el: $latestVersion (Jelenlegi: $currentVersion)');
          print('Kérjük, frissíts a legújabb verzióra a következő parancsok egyikével:');
          print('  - Windows (Scoop):     scoop update folio-cli');
          print('  - Linux (APT):         sudo apt update && sudo apt install folio-cli');
          print('  - macOS (Homebrew):    brew upgrade folio-cli');
          print('  - Manuális szkript:    curl -fsSL https://raw.githubusercontent.com/CsPS0/folio-cli/main/install.sh | bash');
          print('=============================================================\x1B[0m\n');
        }
      }
    } catch (e) {
      FolioLogger.debug('Update check failed: $e');
    }
  }

  Future<void> runWithCredentials(String instituteCode, String username, String password, {bool startInDashboard = false}) async {
    AppState.instance.migrateOldFiles();
    FolioTheme.configureInteractTheme();
    _client = KretaClient(instituteCode: instituteCode);
    _client!.onTokenRefreshed = () async {
      await _saveAuth();
    };
    if (await _client!.login(username, password)) {
      await _saveAuth();
      await _checkForUpdates();
      if (startInDashboard) {
        await _showDashboard();
      } else {
        await _mainMenu();
      }
    } else {
      print('Bejelentkezés sikertelen!');
      exit(1);
    }
  }

  Future<void> _mainMenu() async {
    int _lastMainMenuIndex = 0;
    while (true) {
      _clearScreen();
      _showMainMenuBanner();
      final stateFile = AppState.instance.stateFile;
      List<dynamic> hiddenItems = [];
      if (stateFile.existsSync()) {
        try {
          final state = jsonDecode(stateFile.readAsStringSync());
          if (state['hiddenMenuItems'] != null) {
            hiddenItems = state['hiddenMenuItems'];
          }
        } catch (e) {
          FolioLogger.debug('Failed to parse state file: $e');
        }
      }

      final layout = [
        {'type': 'separator', 'label': '------------------'},
        {'type': 'action', 'id': 10, 'label': 'Folio Wrapped (Év végi összefoglaló)'},
        {'type': 'action', 'id': 0, 'label': 'Tanulói adatlap'},
        {'type': 'action', 'id': 2, 'label': 'Órarend'},
        {'type': 'separator', 'label': '------------------'},
        {'type': 'action', 'id': 1, 'label': 'Legutóbbi jegyek'},
        {'type': 'action', 'id': 4, 'label': 'Tantárgyi átlagok'},
        {'type': 'separator', 'label': '------------------'},
        {'type': 'action', 'id': 3, 'label': 'Mulasztások'},
        {'type': 'action', 'id': 5, 'label': 'Számonkérések'},
        {'type': 'action', 'id': 6, 'label': 'Házi feladatok'},
        {'type': 'action', 'id': 7, 'label': 'Üzenetek'},
        {'type': 'separator', 'label': '------------------'},
        {'type': 'action', 'id': 8, 'label': 'Keresés'},
        {'type': 'action', 'id': -2, 'label': 'Dashboard (Élő nézet)'},
        {'type': 'action', 'id': 9, 'label': 'Beállítások'},
        {'type': 'action', 'id': 100, 'label': 'Kilépés'},
      ];

      List<String> displayOptions = [];
      List<int> actionIds = [];

      for (var item in layout) {
        if (item['type'] == 'separator') {
          displayOptions.add(item['label'] as String);
          actionIds.add(-1);
        } else {
          final id = item['id'] as int;
          if (!hiddenItems.contains(id) || id == 9 || id == 100) {
            displayOptions.add(item['label'] as String);
            actionIds.add(id);
          }
        }
      }

      List<int> unselectable = [];
      for (int i = 0; i < displayOptions.length; i++) {
        if (displayOptions[i] == '------------------') {
          unselectable.add(i);
        }
      }

      final promptText = AppState.instance.isOffline ? 'Folio Főmenü \x1B[1;31m[OFFLINE MÓD]\x1B[0m' : 'Folio Főmenü';

      if (_lastMainMenuIndex >= displayOptions.length) {
        _lastMainMenuIndex = 0;
      }

      final selection = CustomMenu(
        prompt: promptText,
        options: displayOptions,
        unselectableIndices: unselectable,
        initialIndex: _lastMainMenuIndex,
      ).interact();

      _lastMainMenuIndex = selection;

      final action = actionIds[selection];

      switch (action) {
        case 0:
          _clearScreen();
          await _showStudentData();
          _clearScreen();
          break;
        case 1:
          _clearScreen();
          await _showGrades();
          _clearScreen();
          break;
        case 2:
          _clearScreen();
          await _showTimetable();
          _clearScreen();
          break;
        case 3:
          _clearScreen();
          await _showAbsences();
          _clearScreen();
          break;
        case 4:
          _clearScreen();
          await _showAverages();
          _clearScreen();
          break;
        case 5:
          _clearScreen();
          await _showExams();
          _clearScreen();
          break;
        case 6:
          _clearScreen();
          await _showHomework();
          _clearScreen();
          break;
        case 7:
          _clearScreen();
          await _showMessages();
          _clearScreen();
          break;
        case 8:
          _clearScreen();
          await _globalSearch();
          _clearScreen();
          break;
        case 9:
          _clearScreen();
          await _showSettings();
          _clearScreen();
          break;
        case 10:
          _clearScreen();
          await _showFolioWrapped();
          _clearScreen();
          break;
        case -2:
          _clearScreen();
          final List<String> args;
          final String exe;
          if (Platform.resolvedExecutable.endsWith('dart') || Platform.resolvedExecutable.endsWith('dart.exe')) {
            exe = Platform.resolvedExecutable;
            args = [Platform.script.toFilePath(), 'dash'];
          } else {
            exe = Platform.resolvedExecutable;
            args = ['dash'];
          }
          final process = await Process.start(
            exe,
            args,
            mode: ProcessStartMode.inheritStdio,
          );
          await process.exitCode;
          try {
            if (stdin.hasTerminal) {
              stdin.echoMode = true;
              stdin.lineMode = true;
            }
          } catch (_) {}
          forceRestoreConsoleMode();
          _clearScreen();
          break;
        case 100:
          final confirm = Confirm(
            prompt: 'Biztos ki akarsz lépni?',
            defaultValue: false,
          ).interact();
          if (confirm) {
            print('Viszlát!');
            exit(0);
          }
          break;
      }
    }
  }

  List<String> _wrapText(String text, int width) {
    if (text.isEmpty) return [''];
    List<String> lines = [];
    List<String> words = text.split(' ');
    String currentLine = '';

    for (String word in words) {
      if ((currentLine + word).length > width) {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine.trim());
          currentLine = '';
        }
        while (word.length > width) {
          lines.add(word.substring(0, width));
          word = word.substring(width);
        }
        currentLine = word + ' ';
      } else {
        currentLine += word + ' ';
      }
    }
    if (currentLine.trim().isNotEmpty) {
      lines.add(currentLine.trim());
    }
    return lines.isNotEmpty ? lines : [''];
  }

  void _pause([String message = 'Nyomj Enter-t a folytatáshoz...']) {
    print('\n\x1B[90m($message)\x1B[0m');
    stdin.readLineSync();
  }
}
