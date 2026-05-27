import 'dart:io';
import 'dart:convert';
import 'package:folio_cli/api/client.dart';
import 'package:folio_cli/utils/chart_generator.dart';
import 'package:folio_cli/utils/ics_exporter.dart';
import 'package:interact/interact.dart';

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

  Future<void> _saveAuth() async {
    if (_client?.accessToken == null) return;
    
    String profileName = 'Ismeretlen Profil';
    final studentData = await _client!.getStudentData();
    if (studentData != null) {
      profileName = studentData['Nev'] ?? 'Ismeretlen Profil';
    }

    final authFile = _getAuthFile();
    Map<String, dynamic> root = {'activeProfileIndex': 0, 'profiles': []};
    
    if (authFile.existsSync()) {
      try {
        final content = await authFile.readAsString();
        final data = jsonDecode(content);
        if (data is Map<String, dynamic>) {
          if (data.containsKey('profiles')) {
            root = data;
          } else if (data.containsKey('accessToken')) {
            root['profiles'].add({
              'name': 'Régi Profil',
              'instituteCode': data['instituteCode'],
              'accessToken': data['accessToken'],
              'refreshToken': data['refreshToken']
            });
          }
        }
      } catch (_) {}
    }

    List profiles = root['profiles'];
    
    int existingIdx = -1;
    for (int i = 0; i < profiles.length; i++) {
      if (profiles[i]['name'] == profileName && profiles[i]['instituteCode'] == _client!.instituteCode) {
        existingIdx = i;
        break;
      }
    }

    final newProfile = {
      'name': profileName,
      'instituteCode': _client!.instituteCode,
      'accessToken': _client!.accessToken,
      'refreshToken': _client!.refreshToken,
    };

    if (existingIdx != -1) {
      profiles[existingIdx] = newProfile;
      root['activeProfileIndex'] = existingIdx;
    } else {
      profiles.add(newProfile);
      root['activeProfileIndex'] = profiles.length - 1;
    }

    await authFile.writeAsString(jsonEncode(root));
  }

  Future<void> runDaemon() async {
    if (!await _tryAutoLogin()) {
      return;
    }
    await _checkNewItems();
  }

  Future<void> _checkNewItems() async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    final stateFile = File('$home/.folio_state.json');
    Map<String, dynamic> state = {};
    if (stateFile.existsSync()) {
      try {
        state = jsonDecode(stateFile.readAsStringSync());
      } catch (_) {}
    }

    final oldGradesCount = state['gradesCount'] ?? 0;
    
    final grades = await _client!.getGrades();
    if (grades != null) {
      if (grades.length > oldGradesCount && oldGradesCount > 0) {
        final newGradesCount = grades.length - oldGradesCount;
        _showWindowsToast('Folio (Kréta)', 'Kaptál $newGradesCount új jegyet!');
      }
      state['gradesCount'] = grades.length;
    }

    final oldHwCount = state['homeworkCount'] ?? 0;
    final homeworks = await _client!.getHomework(start: DateTime.now().subtract(Duration(days: 7)));
    if (homeworks != null) {
      if (homeworks.length > oldHwCount && oldHwCount > 0) {
        final newHwCount = homeworks.length - oldHwCount;
        _showWindowsToast('Folio (Kréta)', 'Kaptál $newHwCount új házi feladatot!');
      }
      state['homeworkCount'] = homeworks.length;
    }

    stateFile.writeAsStringSync(jsonEncode(state));
  }

  void _showWindowsToast(String title, String message) {
    if (!Platform.isWindows) return;
    
    final safeTitle = title.replaceAll("'", "''");
    final safeMessage = message.replaceAll("'", "''");
    
    final script = '''
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > \$null
\$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
\$texts = \$template.GetElementsByTagName("text")
\$texts[0].AppendChild(\$template.CreateTextNode('$safeTitle')) > \$null
\$texts[1].AppendChild(\$template.CreateTextNode('$safeMessage')) > \$null
\$toast = [Windows.UI.Notifications.ToastNotification]::new(\$template)
\$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("FolioCLI")
\$notifier.Show(\$toast)
''';
    
    Process.run('powershell', ['-Command', script]);
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

  Future<void> _performLoginFlow() async {
    final hasCodeChoice = Select(
      prompt: 'Tudod az intézmény kódját?',
      options: ['Igen, tudom a kódját', 'Nem, keresés név alapján'],
    ).interact();

    String instituteCode = '';

    if (hasCodeChoice == 1) {
      while (instituteCode.isEmpty) {
        final query = Input(prompt: 'Keresés az iskola neve alapján (min 3 karakter)').interact();
        if (query.length >= 3) {
          print('Keresés folyamatban...');
          final results = await KretaClient.searchSchools(query);
          
          if (results.isEmpty) {
            print('Nem található a keresésnek megfelelő iskola.');
          } else {
            final keys = results.keys.toList();
            final options = keys.map((k) => '${results[k]} (Kód: $k)').toList();
            options.add('Új keresés');
            
            final choice = Select(
              prompt: 'Válaszd ki a megfelelőt',
              options: ['Tanulói adatlap', 'Legutóbbi jegyek', 'Órarend (Ezen a héten)', 'Mulasztások', 'Tantárgyi átlagok', 'Számonkérések', 'Házi feladatok', 'Üzenetek', 'Keresés', 'Naptár exportálása (.ics)', 'Adatok exportálása (CSV)', 'Beállítások', 'Kilépés'],
            ).interact();
            
            if (choice < keys.length) {
              instituteCode = keys[choice];
              print('Kiválasztott intézménykód: $instituteCode\n');
            }
          }
        }
      }
    } else {
      instituteCode = Input(prompt: 'Intézmény kódja (pl. bmszc-neumann)').interact();
    }

    _client = KretaClient(instituteCode: instituteCode);
    
    final authMethod = Select(
      prompt: 'Válassz bejelentkezési módszert',
      options: ['Webes bejelentkezés (Böngészőn keresztül)', 'CLI Automatikus bejelentkezés (Kísérleti, ajánlott)'],
    ).interact();

    bool success = false;
    if (authMethod == 0) {
      print('\nKérlek nyisd meg az alábbi linket a böngésződben (Ctrl+Kattintás):');
      print('https://idp.e-kreta.hu/connect/authorize?prompt=login&nonce=wylCrqT4oN6PPgQn2yQB0euKei9nJeZ6_ffJ-VpSKZU&response_type=code&code_challenge_method=S256&scope=openid%20email%20offline_access%20kreta-ellenorzo-webapi.public%20kreta-eugyintezes-webapi.public%20kreta-fileservice-webapi.public%20kreta-mobile-global-webapi.public%20kreta-dkt-webapi.public%20kreta-ier-webapi.public&code_challenge=HByZRRnPGb-Ko_wTI7ibIba1HQ6lor0ws4bcgReuYSQ&redirect_uri=https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect&client_id=kreta-ellenorzo-student-mobile-ios&state=folio_student_mobile&acr_values=institute_code:${_client!.instituteCode}');
      print('\nJelentkezz be, majd amikor egy "Nem található" vagy "mobil.e-kreta.hu" kezdetű oldalra dob,');
      print('MÁSOLD KI A TELJES CÁMET A CÁMSORBÓL és illeszd be ide!\n');
      
      String pastedUrl = '';
      while (pastedUrl.isEmpty) {
        pastedUrl = Input(prompt: 'Ide másold a linket').interact().trim();
      }
      
      print('\nBelépés folyamatban a kóddal...');
      success = await _client!.webLogin(pastedUrl);
    } else {
      final username = Input(prompt: 'Felhasználónév (oktatási azonosító)').interact();
      final password = Password(prompt: 'Jelszó (születési dátum vagy megadott jelszó)').interact();

      if (username.isEmpty || password.isEmpty) {
        print('Hiba: Minden mezőt ki kell tölteni!');
        return;
      }

      print('\nBelépés folyamatban...');
      success = await _client!.login(username, password);
    }

    if (!success) {
      print('Sikertelen bejelentkezés.');
      return;
    }

    print('Sikeres bejelentkezés!\n');

    final remember = Confirm(
      prompt: 'Szeretnéd, hogy a rendszer megjegyezze a bejelentkezést?',
      defaultValue: true,
    ).interact();

    if (remember) {
      await _saveAuth();
      print('Bejelentkezés elmentve.\n');
      
      if (Platform.isWindows) {
        final enableDaemon = Confirm(
          prompt: 'Szeretnéd bekapcsolni az automatikus háttér-értesítéseket bejelentkezéskor/óránként? (Ezt később a beállításokban is módosíthatod)',
          defaultValue: false,
        ).interact();
        _setupDaemon(enableDaemon);
      }
    }

    await _mainMenu();
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

  void _setupDaemon(bool enable) {
    if (!Platform.isWindows) return;
    final taskName = "FolioCliDaemon";
    if (enable) {
      final exePath = Platform.resolvedExecutable;
      final scriptPath = Platform.script.toFilePath();
      
      String command;
      if (scriptPath.endsWith('.dart')) {
        command = '""$exePath"" run ""$scriptPath"" --daemon';
      } else {
        command = '""$exePath"" --daemon';
      }
      
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
      final vbsPath = '$home\\.folio_daemon.vbs';
      final vbsFile = File(vbsPath);
      
      vbsFile.writeAsStringSync('Set WshShell = CreateObject("WScript.Shell")\nWshShell.Run "$command", 0\nSet WshShell = Nothing');

      Process.runSync('schtasks', [
        '/Create', '/F',
        '/TN', taskName,
        '/TR', 'wscript.exe "$vbsPath"',
        '/SC', 'ONLOGON'
      ]);
      print('Értesítések BEKAPCSOLVA (Láthatatlan háttérfolyamat indításkor).\n');
    } else {
      Process.runSync('schtasks', [
        '/Delete', '/F',
        '/TN', taskName
      ]);
      print('Értesítések KIKAPCSOLVA.\n');
    }
  }

  Future<void> _exportToCsv() async {
    _clearScreen();
    print('\n--- Adatok exportálása (CSV) ---');
    print('Jegyek és mulasztások lekérése...');
    
    final grades = await _client!.getGrades();
    final absences = await _client!.getAbsences();
    
    if (grades != null && grades.isNotEmpty) {
      final csvFile = File('Folio_Jegyek.csv');
      String csvContent = 'Tantárgy;Érték;Dátum;Téma\n';
      for (var g in grades) {
        final t = g['Tantargy']?['Nev'] ?? '';
        final v = g['Ertek'] ?? '';
        final d = g['KeszitesDatuma']?.toString().split('T').first ?? '';
        final th = g['Tema'] ?? '';
        csvContent += '"$t";"$v";"$d";"$th"\n';
      }
      csvFile.writeAsBytesSync(const [239, 187, 191]); // UTF-8 BOM
      csvFile.writeAsStringSync(csvContent, mode: FileMode.append);
      print('Jegyek elmentve: Folio_Jegyek.csv');
    }
    
    if (absences != null && absences.isNotEmpty) {
      final csvFile = File('Folio_Mulasztasok.csv');
      String csvContent = 'Tantárgy;Dátum;Igazolt;Típus\n';
      for (var a in absences) {
        final t = a['Tantargy']?['Nev'] ?? '';
        final d = a['Datum']?.toString().split('T').first ?? '';
        final i = a['IgazolasAllapota'] == 'Igazolt' ? 'Igen' : 'Nem';
        final ty = a['Tipus']?['Nev'] ?? '';
        csvContent += '"$t";"$d";"$i";"$ty"\n';
      }
      csvFile.writeAsBytesSync(const [239, 187, 191]); // UTF-8 BOM
      csvFile.writeAsStringSync(csvContent, mode: FileMode.append);
      print('Mulasztások elmentve: Folio_Mulasztasok.csv');
    }
    
    print('');
    Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
  }

  Future<void> _globalSearch() async {
    _clearScreen();
    print('\n--- Globális Kereső ---');
    final query = Input(prompt: 'Keresendő kifejezés').interact().toLowerCase();
    if (query.isEmpty) return;
    
    print('Adatok lekérése a kereséshez...');
    final grades = await _client!.getGrades() ?? [];
    final hw = await _client!.getHomework() ?? [];
    final exams = await _client!.getExams() ?? [];
    
    _clearScreen();
    print('\n--- Keresési Eredmények: "$query" ---');
    
    bool foundAny = false;
    
    for (var g in grades) {
      final t = g['Tantargy']?['Nev']?.toString().toLowerCase() ?? '';
      final d = g['KeszitesDatuma']?.toString() ?? '';
      final th = g['Tema']?.toString().toLowerCase() ?? '';
      if (t.contains(query) || th.contains(query)) {
        foundAny = true;
        print('[Jegy] ${g['Tantargy']?['Nev']}: ${g['Ertek']} (${d.split('T').first}) - ${g['Tema'] ?? ''}');
      }
    }
    
    for (var h in hw) {
      final t = h['Tantargy']?['Nev']?.toString().toLowerCase() ?? '';
      final th = h['Szoveg']?.toString().toLowerCase() ?? '';
      if (t.contains(query) || th.contains(query)) {
        foundAny = true;
        print('[Házi] ${h['Tantargy']?['Nev']}: ${h['Szoveg']?.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('\n', ' ')}');
      }
    }
    
    for (var e in exams) {
      final t = e['Tantargy']?['Nev']?.toString().toLowerCase() ?? '';
      final th = e['Temaja']?.toString().toLowerCase() ?? '';
      if (t.contains(query) || th.contains(query)) {
        foundAny = true;
        print('[Dolgozat] ${e['Tantargy']?['Nev']}: $th (${e['Datum']?.toString().split('T').first})');
      }
    }
    
    if (!foundAny) {
      print('Nincs találat.');
    }
    
    print('');
    Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
  }

  Future<void> _exportCalendar() async {
    print('\n--- Naptár Exportálása ---');
    print('Adatok lekérése (E heti és jövő heti órarend, valamint vizsgák)...');
    
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfNextWeek = startOfWeek.add(Duration(days: 13));
    
    final timetable = await _client!.getTimetable(startOfWeek, endOfNextWeek) ?? [];
    final exams = await _client!.getExams() ?? [];
    
    if (timetable.isEmpty && exams.isEmpty) {
      print('Nincs exportálható adat (órarend és vizsgák üresek).\n');
      return;
    }
    final icsContent = IcsExporter.generate(timetable, exams);
    
    final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '.';
    final desktop = Directory('$home\\Desktop');
    final outDir = desktop.existsSync() ? desktop.path : home;
    
    final file = File('$outDir\\folio_naptar.ics');
    await file.writeAsString(icsContent);
    
    print('Sikeres exportálás! A naptár elmentve ide: ${file.path}\n');
  }

  Future<void> _showSettings() async {
    while (true) {
      final action = Select(
        prompt: 'Beállítások',
        options: [
          'Profilváltás',
          'Új fiók hozzáadása',
          'Téma beállítása',
          'Háttér-értesítések beállítása',
          'Összes mentett adat törlése (Kijelentkezés)', 
          'Vissza'
        ],
      ).interact();

      if (action == 5) return;

      if (action == 0) {
        final authFile = _getAuthFile();
        if (!authFile.existsSync()) {
          print('Nincsenek mentett profilok.\n');
          continue;
        }
        
        try {
          final data = jsonDecode(await authFile.readAsString());
          if (data['profiles'] == null || (data['profiles'] as List).isEmpty) {
            print('Nincsenek mentett profilok.\n');
            continue;
          }
          final profiles = data['profiles'] as List;
          final options = profiles.map((p) => '${p['name']} (${p['instituteCode']})').toList();
          options.add('Mégse');
          
          final choice = Select(
            prompt: 'Válassz profilt',
            options: options,
          ).interact();
          
          if (choice < profiles.length) {
            data['activeProfileIndex'] = choice;
            await authFile.writeAsString(jsonEncode(data));
            print('Profil sikeresen kiválasztva! Kérlek indítsd újra az alkalmazást.\n');
            exit(0);
          }
        } catch (_) {
          print('Hiba a profilok betöltésekor.\n');
        }
      } else if (action == 1) {
        print('\n--- Új fiók hozzáadása ---');
        await _performLoginFlow();
        return;
      } else if (action == 2) {
        _clearScreen();
        final themeAction = Select(
          prompt: 'Válassz témát',
          options: [
            'Sötét (Folio Alapértelmezett)',
            'Világos',
            'Vissza'
          ],
        ).interact();
        
        if (themeAction != 2) {
          final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
          final stateFile = File('$home/.folio_state.json');
          Map<String, dynamic> state = {};
          if (stateFile.existsSync()) {
            try {
              state = jsonDecode(stateFile.readAsStringSync());
            } catch (_) {}
          }
          state['theme'] = themeAction == 0 ? 'dark' : 'light';
          stateFile.writeAsStringSync(jsonEncode(state));
          
          _applyTheme(state['theme']);
          print('\nTéma sikeresen beállítva!');
          Input(prompt: 'Nyomj Enter-t a folytatáshoz...').interact();
        }
        continue;
      } else if (action == 3) {
        if (!Platform.isWindows) {
          print('Az értesítések jelenleg csak Windows rendszeren támogatottak.\n');
          continue;
        }

        final enable = Confirm(
          prompt: 'Szeretnéd bekapcsolni az óránkénti háttér-ellenőrzést és értesítéseket?',
          defaultValue: true,
        ).interact();

        _setupDaemon(enable);
      } else if (action == 4) {
        final confirm = Confirm(
          prompt: 'Biztosan törölni szeretnéd a mentett profilokat?',
          defaultValue: false,
        ).interact();

        if (confirm) {
          final authFile = _getAuthFile();
          if (authFile.existsSync()) {
            authFile.deleteSync();
            print('Mentett bejelentkezések törölve.\n');
            print('A módosítások érvénybe lépéséhez a program most kilép.');
            exit(0);
          } else {
            print('Nincs mentett bejelentkezés.\n');
          }
        }
      }
    }
  }

  Future<void> _showStudentData() async {
    while (true) {
      final action = Select(
        prompt: 'Tanulói adatlap',
        options: ['Adatok megtekintése', 'Vissza'],
      ).interact();

      if (action == 1) return;
      _clearScreen();
      print('\n--- Tanulói adatlap lekérdezése ---');
      final data = await _client!.getStudentData();
      if (data != null) {
        final name = data['Nev'] ?? 'Ismeretlen';
        final institution = data['IntezmenyNev'] ?? 'Ismeretlen intézmény';
        print('Név: $name');
        print('Intézmény: $institution');
        studentUid = data['Uid']?.toString();
      } else {
        print('Nem sikerült lekérdezni az adatokat.');
      }
      print('');
    }
  }

  Future<void> _showGrades() async {
    while (true) {
      final action = Select(
        prompt: 'Jegyek',
        options: ['Legutóbbi 10 jegy', 'Összes jegy', 'Vissza'],
      ).interact();

      if (action == 2) return;
      _clearScreen();
      print('\n--- Jegyek lekérdezése ---');
      final grades = await _client!.getGrades();
      if (grades != null) {
        if (grades.isEmpty) {
          print('Nincsenek elérhető jegyek.');
        } else {
          grades.sort((a, b) {
            final dateA = DateTime.tryParse(a['KeszitesDatuma'] ?? '') ?? DateTime(2000);
            final dateB = DateTime.tryParse(b['KeszitesDatuma'] ?? '') ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });

          final limit = action == 0 ? 10 : grades.length;
          for (var grade in grades.take(limit)) {
            final subject = grade['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
            final val = grade['SzamErtek'] ?? grade['SzovegesErtek'];
            final dateStr = grade['KeszitesDatuma']?.toString().split('T').first ?? '';
            final type = grade['Tipus']?['Nev'] ?? 'Értékelés';
            print('[$dateStr] $subject: $val ($type)');
          }
        }
      } else {
        print('Nem sikerült lekérdezni a jegyeket.');
      }
      print('');
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

  Future<void> _showTimetable() async {
    while (true) {
      final action = Select(
        prompt: 'Órarend',
        options: ['Ezen a héten', 'Következő héten', 'Vissza'],
      ).interact();

      if (action == 2) return;
      _clearScreen();
      print('\n--- Órarend ---');
      final now = DateTime.now();
      final offsetDays = action == 1 ? 7 : 0;
      final targetDate = now.add(Duration(days: offsetDays));
      final startOfWeek = targetDate.subtract(Duration(days: targetDate.weekday - 1));
      final endOfWeek = startOfWeek.add(Duration(days: 4));

      final timetable = await _client!.getTimetable(startOfWeek, endOfWeek);
      if (timetable != null) {
        if (timetable.isEmpty) {
          print('Nincsenek órák rögzítve erre a hétre.');
        } else {
          int minOra = 99;
          int maxOra = -1;
          int maxWeekday = 5;

          Map<int, Map<int, List<Map<String, dynamic>>>> matrix = {};

          for (var lesson in timetable) {
            final dateStr = lesson['Datum']?.toString().split('T').first ?? '';
            final dateObj = DateTime.tryParse(dateStr);
            if (dateObj == null) continue;

            final weekday = dateObj.weekday;
            if (weekday > maxWeekday) maxWeekday = weekday;
            if (weekday > 7) continue;

            final ora = _parseLessonNumber(lesson['Oraszam']);
            if (ora == 99) continue;

            if (ora < minOra) minOra = ora;
            if (ora > maxOra) maxOra = ora;

            matrix.putIfAbsent(ora, () => {});
            matrix[ora]!.putIfAbsent(weekday, () => []);
            // Cast the dynamic map to Map<String, dynamic>
            matrix[ora]![weekday]!.add(Map<String, dynamic>.from(lesson));
          }

          if (minOra > maxOra) {
            print('Nincs megjeleníthető óra (ismeretlen óraszámok).');
            continue;
          }

          final days = ['Hétfő', 'Kedd', 'Szerda', 'Csütörtök', 'Péntek', 'Szombat', 'Vasárnap'];
          int termWidth = stdout.hasTerminal ? stdout.terminalColumns : 120;
          int colWidth = (termWidth - 7 - maxWeekday) ~/ maxWeekday;
          if (colWidth > 28) colWidth = 28;
          if (colWidth < 12) colWidth = 12;

          String headerTop = '┌─────';
          String headerMid = '│ Óra ';
          String headerBot = '├─────';

          for (int w = 1; w <= maxWeekday; w++) {
            headerTop += '┬' + '─' * colWidth;
            headerMid += '│ ' + days[w - 1].padRight(colWidth - 1);
            headerBot += '┼' + '─' * colWidth;
          }
          headerTop += '┐';
          headerMid += '│';
          headerBot += '┤';

          print(headerTop);
          print(headerMid);
          print(headerBot);

          for (int ora = minOra; ora <= maxOra; ora++) {
            List<List<String>> dayLines = List.generate(maxWeekday + 1, (_) => []);
            int maxLines = 1;

            for (int w = 1; w <= maxWeekday; w++) {
              final lessons = matrix[ora]?[w] ?? [];
              if (lessons.isNotEmpty) {
                final lesson = lessons.first;
                String sub = lesson['Tantargy']?['Nev'] ?? '';
                String thm = lesson['Tema'] ?? '';
                
                List<String> cellLines = [];
                if (sub.isNotEmpty) {
                  cellLines.addAll(_wrapText(sub, colWidth - 2));
                }
                if (thm.isNotEmpty) {
                  cellLines.addAll(_wrapText('($thm)', colWidth - 2));
                }
                
                if (cellLines.isEmpty) cellLines = [''];
                dayLines[w] = cellLines;
                if (cellLines.length > maxLines) maxLines = cellLines.length;
              } else {
                dayLines[w] = [''];
              }
            }

            for (int lineIdx = 0; lineIdx < maxLines; lineIdx++) {
              String rowStr = (lineIdx == 0) ? '│ ${ora.toString().padLeft(2)}. │' : '│     │';
              
              for (int w = 1; w <= maxWeekday; w++) {
                String lineText = '';
                if (lineIdx < dayLines[w].length) {
                  lineText = dayLines[w][lineIdx];
                }
                rowStr += ' ' + lineText.padRight(colWidth - 1) + '│';
              }
              print(rowStr);
            }
            
            if (ora < maxOra) {
              String sep = '├─────';
              for (int w = 1; w <= maxWeekday; w++) {
                sep += '┼' + '─' * colWidth;
              }
              sep += '┤';
              print(sep);
            }
          }

          String footer = '└─────';
          for (int w = 1; w <= maxWeekday; w++) {
            footer += '┴' + '─' * colWidth;
          }
          footer += '┘';
          print(footer);
        }
      } else {
        print('Nem sikerült lekérdezni az órarendet.');
      }
      print('');
    }
  }

  Future<void> _showAbsences() async {
    while (true) {
      final action = Select(
        prompt: 'Mulasztások',
        options: ['Legutóbbi mulasztások megtekintése', 'Vissza'],
      ).interact();

      if (action == 1) return;
      _clearScreen();
      print('\n--- Mulasztások ---');
      final absences = await _client!.getAbsences();
      if (absences != null) {
        if (absences.isEmpty) {
          print('Nincsenek mulasztások.');
        } else {
          absences.sort((a, b) {
            final dateA = DateTime.tryParse(a['Datum'] ?? '') ?? DateTime(2000);
            final dateB = DateTime.tryParse(b['Datum'] ?? '') ?? DateTime(2000);
            return dateB.compareTo(dateA); // Legújabb elöl
          });

          for (var absence in absences.take(10)) {
            final dateStr = absence['Datum']?.toString().split('T').first ?? '';
            final subject = absence['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
            final status = absence['IgazolasAllapota'] ?? 'Ismeretlen';
            print('[$dateStr] $subject ($status)');
          }
        }
      } else {
        print('Nem sikerült lekérdezni a mulasztásokat.');
      }
      print('');
    }
  }

  Future<void> _showAverages() async {
    while (true) {
      final action = Select(
        prompt: 'Tantárgyi átlagok',
        options: ['Átlagok megtekintése', 'Vissza'],
      ).interact();

      if (action == 1) return;
      _clearScreen();
      print('\n--- Tantárgyi átlagok ---');
      print('Adatok lekérése...');
      
      final averages = await _client!.getAverages();
      if (averages != null) {
        if (averages.isEmpty) {
          print('Nincsenek átlagok.');
        } else {
          final Map<String, double> chartData = {};
          for (var avg in averages) {
            final subject = avg['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
            final valueStr = avg['Ertek']?.toString() ?? '0';
            final value = double.tryParse(valueStr.replaceAll(',', '.')) ?? 0.0;
            if (value > 0) {
              chartData[subject] = value;
            }
          }
          if (chartData.isNotEmpty) {
            print(ChartGenerator.generateBarChart(chartData));
          } else {
            for (var avg in averages) {
              final subject = avg['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
              final value = avg['Ertek']?.toString() ?? '-';
              print('$subject: $value');
            }
          }
        }
      } else {
        print('Nem sikerült lekérdezni az átlagokat.');
      }
      print('');
    }
  }

  Future<void> _showTargetAverageCalculator() async {
    _clearScreen();
    print('\n--- Célátlag Kalkulátor ---');
    final grades = await _client!.getGrades();
    if (grades == null || grades.isEmpty) {
      print('Nincsenek elérhető jegyek a számoláshoz.');
      Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
      return;
    }

    final Map<String, List<Map<String, double>>> subjectGrades = {};
    for (var grade in grades) {
      final tipus = grade['Tipus']?['Nev']?.toString().toLowerCase() ?? '';
      if (tipus.contains('vegi') || tipus.contains('felevevi') || tipus.contains('negyedevi')) continue;
      
      final subject = grade['Tantargy']?['Nev'];
      if (subject == null) continue;
      
      final numVal = grade['SzamErtek'];
      if (numVal == null || numVal == 0 || numVal > 5) continue;
      
      final weight = (grade['SulySzazalekErteke'] ?? 100).toDouble();
      
      subjectGrades.putIfAbsent(subject, () => []);
      subjectGrades[subject]!.add({'value': numVal is int ? numVal.toDouble() : double.parse(numVal.toString()), 'weight': weight});
    }

    if (subjectGrades.isEmpty) {
      print('Nincsenek számítható tantárgyak.');
      Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
      return;
    }

    final subjects = subjectGrades.keys.toList()..sort();
    final subjectIdx = Select(
      prompt: 'Melyik tantárgy célátlagát szeretnéd kiszámolni?',
      options: [...subjects, 'Vissza'],
    ).interact();

    if (subjectIdx == subjects.length) return;

    final subject = subjects[subjectIdx];
    final items = subjectGrades[subject]!;
    
    double sum = 0;
    double weightSum = 0;
    for (var item in items) {
      sum += item['value']! * item['weight']!;
      weightSum += item['weight']!;
    }
    
    final currentAvg = weightSum > 0 ? (sum / weightSum) : 0.0;
    print('\nKiválasztott tantárgy: $subject');
    print('Jelenlegi átlagod: ${currentAvg.toStringAsFixed(2)}');

    final targetStr = Input(
      prompt: 'Mi a megcélzott átlag? (pl. 4.5)',
      defaultValue: '4.5',
    ).interact();

    final target = double.tryParse(targetStr.replaceAll(',', '.')) ?? 0.0;
    if (target <= currentAvg) {
      print('Ezt az átlagot már elérted! Gratulálok!');
    } else if (target > 5.0) {
      print('5.0 feletti átlagot lehetetlen elérni.');
    } else {
      final requiredFives = (target * weightSum - sum) / (500 - target * 100);
      final intFives = requiredFives.ceil();
      print('\nCél: ${target.toStringAsFixed(2)}');
      print('Ehhez pontosan $intFives darab 100%-os ÖTÖSRE van szükséged.');
      
      if (target <= 4.0) {
        final requiredFours = (target * weightSum - sum) / (400 - target * 100);
        if (requiredFours > 0) {
          final intFours = requiredFours.ceil();
          print('Vagy $intFours darab 100%-os NÉGYESRE.');
        }
      }
    }
    
    print('');
    Input(prompt: 'Nyomj Enter-t a visszatéréshez...').interact();
  }

  Future<void> _showExams() async {
    while (true) {
      final action = Select(
        prompt: 'Számonkérések',
        options: ['Számonkérések megtekintése', 'Vissza'],
      ).interact();

      if (action == 1) return;
      _clearScreen();
      print('\n--- Számonkérések ---');
      final exams = await _client!.getExams();
      if (exams != null) {
        if (exams.isEmpty) {
          print('Nincsenek bejelentett számonkérések.');
        } else {
          exams.sort((a, b) {
            final dateA = DateTime.tryParse(a['Datum'] ?? '') ?? DateTime(2000);
            final dateB = DateTime.tryParse(b['Datum'] ?? '') ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });

          for (var exam in exams.take(10)) {
            final dateStr = exam['Datum']?.toString().split('T').first ?? '';
            final subject = exam['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
            final type = exam['Modja']?['Nev'] ?? 'Számonkérés';
            final theme = exam['Tema'] ?? '';
            print('[$dateStr] $subject - $type ${theme.isNotEmpty ? "($theme)" : ""}');
          }
          if (exams.length > 10) {
            print('  ... és még ${exams.length - 10} régebbi számonkérés.');
          }
        }
      } else {
        print('Nem sikerült lekérdezni a számonkéréseket.');
      }
      print('');
    }
  }

  Future<void> _showHomework() async {
    while (true) {
      final action = Select(
        prompt: 'Házi feladatok',
        options: ['Házi feladatok megtekintése', 'Vissza'],
      ).interact();

      if (action == 1) return;
      _clearScreen();
      print('\n--- Házi feladatok ---');
      final hw = await _client!.getHomework();
      if (hw != null) {
        if (hw.isEmpty) {
          print('Nincs megjeleníthető házi feladat.');
        } else {
          for (var item in hw) {
            final date = item['RogzitesIdopontja']?.toString().split('T').first ?? '';
            final subject = item['Tantargy'] is Map ? (item['Tantargy']['Nev'] ?? 'Ismeretlen tárgy') : (item['Tantargy'] ?? 'Ismeretlen tárgy');
            final text = item['Szoveg']?.toString().replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('\n', ' ') ?? '';
            
            print('[$date] $subject');
            print('  Feladat: $text');
            print('  Határidő: ${(item['HataridoDatuma'] ?? item['HataridoIdopontja'])?.toString().split('T').first ?? '?'}');
            print('---');
          }
        }
      } else {
        print('Nem sikerült lekérdezni a házi feladatokat.');
      }
      print('');
    }
  }

  Future<void> _showMessages() async {
    while (true) {
      final action = Select(
        prompt: 'Üzenetek',
        options: ['Beérkezett üzenetek megtekintése', 'Vissza'],
      ).interact();

      if (action == 1) return;
      _clearScreen();
      print('\n--- Üzenetek ---');
      final messages = await _client!.getMessages();
      if (messages != null) {
        if (messages.isEmpty) {
          print('Nincs beérkezett üzenet.');
        } else {
          messages.sort((a, b) {
            final dateA = DateTime.tryParse(a['uzenet']?['kuldesDatum'] ?? '') ?? DateTime(2000);
            final dateB = DateTime.tryParse(b['uzenet']?['kuldesDatum'] ?? '') ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });

          for (var msg in messages.take(15)) {
            final dateStr = msg['uzenet']?['kuldesDatum']?.toString().replaceAll('T', ' ').substring(0, 16) ?? '';
            final felado = msg['uzenet']?['feladoNev'] ?? 'Ismeretlen feladó';
            final targy = msg['uzenet']?['targy'] ?? 'Nincs tárgy';
            final isRead = msg['isElolvasva'] == true;
            
            String marker = isRead ? " " : "*";
            print('[$marker] $dateStr - $felado');
            print('    Tárgy: $targy');
          }
          if (messages.length > 15) {
            print('  ... és még ${messages.length - 15} régebbi üzenet.');
          }
        }
      } else {
        print('Nem sikerült lekérdezni az üzeneteket.');
      }
      print('');
    }
  }
}


