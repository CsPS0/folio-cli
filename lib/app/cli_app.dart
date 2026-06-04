import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:args/args.dart';
import 'package:dart_console/dart_console.dart';
import 'package:http/http.dart' as http;
import 'package:interact/interact.dart';
import 'package:folio_cli/api/client.dart';
import 'package:folio_cli/utils/chart_generator.dart';
import 'package:folio_cli/utils/ics_exporter.dart';
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
      dynamic data = jsonDecode(content);
      
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
    } catch (e) {
      // Ignore
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
   |  _| (_) | | | (_) |
   |_|  \___/|_|_|\___/ CLI v1.0.0
    ''');
    print('\x1B[0m');
  }

  Future<void> runInteractive() async {
    AppState.instance.migrateOldFiles();
    _showBanner();

    print('Keresem a mentett bejelentkezést...');
    if (await _tryAutoLogin()) {
      print('Sikeres automatikus bejelentkezés!\n');
      await _checkForUpdates();
      await _mainMenu();
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
      // NOTE: Replace YOUR_USERNAME with the actual GitHub username where the repo is hosted
      final res = await http.get(
        Uri.parse('https://api.github.com/repos/YOUR_USERNAME/folio-cli/releases/latest'),
      ).timeout(Duration(seconds: 2));
      
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final latestVersion = data['tag_name'] as String?;
        // Assuming current version is v1.0.0
        if (latestVersion != null && latestVersion != 'v1.0.0' && latestVersion.startsWith('v')) {
          print('\x1B[33m\n[!] Új verzió elérhető: $latestVersion (Jelenlegi: v1.0.0)');
          print('[!] Ha Scoop-on keresztül telepítetted, futtasd a következő parancsot:');
          print('    scoop update folio-cli\x1B[0m\n');
        }
      }
    } catch (_) {
      // Ignore network errors so it doesn't interrupt the app
    }
  }

  Future<void> runWithCredentials(String instituteCode, String username, String password) async {
    _client = KretaClient(instituteCode: instituteCode);
    print('Bejelentkezés CLI paraméterekkel...');
    bool success = await _client!.login(username, password);
    if (!success) {
      print('Sikertelen bejelentkezés.');
      exit(1);
    }
    print('Sikeres bejelentkezés!\n');
    await _checkForUpdates();
    await _mainMenu();
  }

  Future<void> _mainMenu() async {
    _clearScreen();
    while (true) {
      final stateFile = AppState.instance.stateFile;
      List<dynamic> hiddenItems = [];
      if (stateFile.existsSync()) {
        try {
          final state = jsonDecode(stateFile.readAsStringSync());
          if (state['hiddenMenuItems'] != null) {
            hiddenItems = state['hiddenMenuItems'];
          }
        } catch (_) {}
      }

      final allOptions = [
        'Tanulói adatlap',
        'Legutóbbi jegyek',
        'Órarend (Ezen a héten)',
        'Mulasztások',
        'Tantárgyi átlagok',
        'Számonkérések',
        'Házi feladatok',
        'Üzenetek',
        'Keresés'
      ];

      List<String> displayOptions = [];
      List<int> actionIds = [];

      for (int i = 0; i < allOptions.length; i++) {
        if (!hiddenItems.contains(i)) {
          displayOptions.add(allOptions[i]);
          actionIds.add(i);
        }
      }

      displayOptions.add('Beállítások');
      actionIds.add(9);
      displayOptions.add('Kilépés');
      actionIds.add(10);

      final selection = Select(
        prompt: 'Folio',
        options: displayOptions,
      ).interact();

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
          print('Viszlát!');
          exit(0);
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
}
