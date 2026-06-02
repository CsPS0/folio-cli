part of '../cli_app.dart';

extension FolioCliAppSettingsView on FolioCliApp {
  Future<void> _showSettings() async {
      while (true) {
        final action = Select(
          prompt: 'Beállítások',
          options: [
            'Profilváltás',
            'Új fiók hozzáadása',
            'Háttér-értesítések beállítása',
            'Főmenü testreszabása',
            'Naptár exportálása (.ics)',
            'Adatok exportálása (CSV)',
            'Összes mentett adat törlése (Kijelentkezés)', 
            'Vissza'
          ],
        ).interact();
  
        if (action == 7) return;
  
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
          if (!Platform.isWindows) {
            print('Az értesítések jelenleg csak Windows rendszeren támogatottak.\n');
            continue;
          }
  
          final enable = Confirm(
            prompt: 'Szeretnéd bekapcsolni az óránkénti háttér-ellenőrzést és értesítéseket?',
            defaultValue: true,
          ).interact();
  
          _setupDaemon(enable);
        } else if (action == 3) {
          _clearScreen();
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
          
          final stateFile = AppState.instance.stateFile;
          List<dynamic> hiddenItems = [];
          Map<String, dynamic> state = {};
          if (stateFile.existsSync()) {
            try {
              state = jsonDecode(stateFile.readAsStringSync());
              if (state['hiddenMenuItems'] != null) {
                hiddenItems = state['hiddenMenuItems'];
              }
            } catch (_) {}
          }
          
          final defaults = List.generate(allOptions.length, (i) => !hiddenItems.contains(i));
          
          print('\n\x1B[38;5;208mHasználd a SPACE-t a ki/bekapcsoláshoz, majd nyomj ENTER-t a mentéshez!\x1B[0m\n');
          final selection = MultiSelect(
            prompt: 'Válaszd ki a látható menüpontokat',
            options: allOptions,
            defaults: defaults,
          ).interact();
          
          final newHiddenItems = [];
          for (int i = 0; i < allOptions.length; i++) {
            if (!selection.contains(i)) {
              newHiddenItems.add(i);
            }
          }
          
          state['hiddenMenuItems'] = newHiddenItems;
          stateFile.writeAsStringSync(jsonEncode(state));
          
          print('\nFőmenü sikeresen testreszabva!');
          Input(prompt: 'Nyomj Enter-t a folytatáshoz...').interact();
          _clearScreen();
          
        } else if (action == 4) {
          _clearScreen();
          await _exportCalendar();
          _clearScreen();
        } else if (action == 5) {
          _clearScreen();
          await _exportToCsv();
          _clearScreen();
        } else if (action == 6) {
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
        
        final vbsPath = '${AppState.instance.configDir}\\daemon.vbs';
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

}
