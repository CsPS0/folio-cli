import 'dart:io';
import 'dart:convert';
import 'package:folio_cli/api/client.dart';
import 'package:folio_cli/utils/chart_generator.dart';
import 'package:folio_cli/utils/ics_exporter.dart';
import 'package:interact/interact.dart';

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
  String _currentBgAnsi = '';
  String _currentFgAnsi = '';

      void _applyTheme(String? theme) {
    if (theme == 'light') {
      _currentBgAnsi = '';
      _currentFgAnsi = '\x1B[38;2;5;26;22m';
      
      final primaryColor = (String text) => '\x1B[38;2;68;210;168m$text\x1B[0m';
      final secondaryColor = (String text) => '\x1B[38;2;5;26;22m$text\x1B[0m';
      
      Theme.defaultTheme = Theme.defaultTheme.copyWith(
        activeItemStyle: primaryColor,
        valueStyle: primaryColor,
        messageStyle: secondaryColor,
        hintStyle: secondaryColor,
        defaultStyle: secondaryColor,
        inputPrefix: '\x1B[38;2;68;210;168m? \x1B[0m',
        inputSuffix: '\x1B[38;2;5;26;22m\u203A \x1B[0m',
        successPrefix: '\x1B[38;2;68;210;168m\u2714 \x1B[0m',
        successSuffix: '\x1B[38;2;5;26;22m\u00B7 \x1B[0m',
        activeItemPrefix: '\x1B[38;2;68;210;168m\u276F \x1B[0m',
      );
    } else {
      _currentBgAnsi = '';
      _currentFgAnsi = '\x1B[38;2;241;253;251m';
      
      final primaryColor = (String text) => '\x1B[38;2;68;210;168m$text\x1B[0m';
      final secondaryColor = (String text) => '\x1B[38;2;241;253;251m$text\x1B[0m';
      
      Theme.defaultTheme = Theme.defaultTheme.copyWith(
        activeItemStyle: primaryColor,
        valueStyle: primaryColor,
        messageStyle: secondaryColor,
        hintStyle: secondaryColor,
        defaultStyle: secondaryColor,
        inputPrefix: '\x1B[38;2;68;210;168m? \x1B[0m',
        inputSuffix: '\x1B[38;2;241;253;251m\u203A \x1B[0m',
        successPrefix: '\x1B[38;2;68;210;168m\u2714 \x1B[0m',
        successSuffix: '\x1B[38;2;241;253;251m\u00B7 \x1B[0m',
        activeItemPrefix: '\x1B[38;2;68;210;168m\u276F \x1B[0m',
      );
    }
  }



  void _clearScreen() {
    stdout.write('\x1B[0m$_currentBgAnsi$_currentFgAnsi\x1B[2J\x1B[3J\x1B[H');
  }

  KretaClient? _client;
  String? studentUid;

  File _getAuthFile() {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return File('$home/.folio_auth.json');
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
            studentUid = studentData['Uid']?.toString();
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

  Future<void> runInteractive() async {
    print('==============================');
    print('    Folio CLI (Kréta API)     ');
    print('==============================\n');

    print('Keresem a mentett bejelentkezést...');
    if (await _tryAutoLogin()) {
      print('Sikeres automatikus bejelentkezés!\n');
      await _mainMenu();
      return;
    }

    print('\x1B[38;5;208m=============================================================');
    print(' FIGYELEM! Kérjük, kapcsold ki a Folio/Firka kiegészítőt');
    print(' a böngésződben a bejelentkezés idejére, mert jelenleg');
    print(' problémák vannak a bejelentkezési felülettel!');
    print('=============================================================\x1B[0m\n');

    await _performLoginFlow();
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
    await _mainMenu();
  }

  Future<void> _mainMenu() async {
    _clearScreen();
    while (true) {
      final action = Select(
        prompt: 'Folio',
        options: [
          'Tanulói adatlap',
          'Legutóbbi jegyek',
          'Órarend (Ezen a héten)',
          'Mulasztások',
          'Tantárgyi átlagok',
          'Számonkérések',
          'Házi feladatok',
          'Üzenetek',
          'Keresés',
          'Naptár exportálása (.ics)',
          'Adatok exportálása (CSV)',
          'Beállítások',
          'Kilépés'
        ],
      ).interact();

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
          await _exportCalendar();
          _clearScreen();
          break;
        case 10:
          _clearScreen();
          await _exportToCsv();
          _clearScreen();
          break;
        case 11:
          _clearScreen();
          await _showSettings();
          _clearScreen();
          break;
        case 12:
          print('Viszlát!');
          exit(0);
      }
    }
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Hétfő';
      case 2: return 'Kedd';
      case 3: return 'Szerda';
      case 4: return 'Csütörtök';
      case 5: return 'Péntek';
      case 6: return 'Szombat';
      case 7: return 'Vasárnap';
      default: return '';
    }
  }

  int _parseLessonNumber(dynamic oraszam) {
    if (oraszam == null) return 99;
    final numStr = oraszam.toString().replaceAll(RegExp(r'[^0-9]'), '');
    if (numStr.isEmpty) return 99;
    return int.parse(numStr);
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
