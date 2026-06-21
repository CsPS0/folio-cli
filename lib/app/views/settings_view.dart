part of '../cli_app.dart';

extension FolioCliAppSettingsView on FolioCliApp {
  Future<void> _showSettings() async {
      int _lastSettingsMenuIndex = 0;
      while (true) {
        _clearScreen();
        _showMainMenuBanner();
        final layout = [
          {'type': 'separator', 'label': '------------------'},
          {'type': 'action', 'id': 0, 'label': 'Profilváltás'},
          {'type': 'action', 'id': 1, 'label': 'Új fiók hozzáadása'},
          {'type': 'action', 'id': 6, 'label': 'Összes mentett adat törlése (Kijelentkezés)'},
          {'type': 'separator', 'label': '------------------'},
          {'type': 'action', 'id': 3, 'label': 'Főmenü testreszabása'},
          {'type': 'action', 'id': -2, 'label': 'Tanár/Tantárgy átnevezése (Aliasok)'},
          {'type': 'action', 'id': -4, 'label': 'Színséma / Téma választása'},
          {'type': 'action', 'id': -5, 'label': 'Főmenü ASCII Banner ki/be'},
          {'type': 'separator', 'label': '------------------'},
          {'type': 'action', 'id': 4, 'label': 'Naptár exportálása (.ics)'},
          {'type': 'action', 'id': 5, 'label': 'Adatok exportálása (CSV)'},
          {'type': 'action', 'id': -3, 'label': 'Git-alapú Jegy-történet (Export & Git)'},
          {'type': 'separator', 'label': '------------------'},
          {'type': 'action', 'id': 2, 'label': 'Háttér-értesítések beállítása'},
          {'type': 'action', 'id': -6, 'label': 'Speciális'},
          {'type': 'separator', 'label': '------------------'},
          {'type': 'action', 'id': 7, 'label': 'Vissza'},
        ];

        List<String> options = [];
        List<int> actionIds = [];
        List<int> unselectable = [];

        for (int i = 0; i < layout.length; i++) {
          final item = layout[i];
          options.add(item['label'] as String);
          if (item['type'] == 'separator') {
            actionIds.add(-1);
            unselectable.add(i);
          } else {
            actionIds.add(item['id'] as int);
          }
        }

        if (_lastSettingsMenuIndex >= options.length) {
          _lastSettingsMenuIndex = 0;
        }

        final selection = CustomMenu(
          prompt: 'Beállítások',
          options: options,
          unselectableIndices: unselectable,
          initialIndex: _lastSettingsMenuIndex,
        ).interact();
  
        _lastSettingsMenuIndex = selection;
  
        final action = actionIds[selection];

        if (action == 7) return;
        
        if (action == 6) {
          final confirm = Confirm(prompt: 'Biztosan törölni szeretnéd az összes mentett adatot?', defaultValue: false).interact();
          if (!confirm) continue;
        }
  
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
          final customizableOptions = [
            {'id': 10, 'label': 'Folio Wrapped (Év végi összefoglaló)'},
            {'id': 0, 'label': 'Tanulói adatlap'},
            {'id': 2, 'label': 'Órarend'},
            {'id': 1, 'label': 'Legutóbbi jegyek'},
            {'id': 4, 'label': 'Tantárgyi átlagok'},
            {'id': 3, 'label': 'Mulasztások'},
            {'id': 5, 'label': 'Számonkérések'},
            {'id': 6, 'label': 'Házi feladatok'},
            {'id': 7, 'label': 'Üzenetek'},
            {'id': 8, 'label': 'Keresés'},
            {'id': -2, 'label': 'Dashboard (Élő nézet)'},
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
            } catch (e) {
              FolioLogger.debug('Failed to parse settings state file: $e');
            }
          }
          
          final optionLabels = customizableOptions.map((e) => e['label'] as String).toList();
          final defaults = customizableOptions.map((e) => !hiddenItems.contains(e['id'])).toList();
          
          print('\n\x1B[38;5;208mHasználd a SPACE-t a ki/bekapcsoláshoz, majd nyomj ENTER-t a mentéshez!\x1B[0m\n');
          final selection = MultiSelect(
            prompt: 'Válaszd ki a látható menüpontokat',
            options: optionLabels,
            defaults: defaults,
          ).interact();
          
          final newHiddenItems = [];
          for (int i = 0; i < customizableOptions.length; i++) {
            if (!selection.contains(i)) {
              newHiddenItems.add(customizableOptions[i]['id']);
            }
          }
          
          state['hiddenMenuItems'] = newHiddenItems;
          stateFile.writeAsStringSync(jsonEncode(state));
          
          print('\nFőmenü sikeresen testreszabva!');
          Utf8Input(prompt: 'Nyomj Enter-t a folytatáshoz...').interact();
          _clearScreen();
          
        } else if (action == 4) {
          _clearScreen();
          await _exportCalendar();
          _clearScreen();
        } else if (action == 5) {
          _clearScreen();
          await _exportToCsv();
          _clearScreen();
        } else if (action == -2) {
          _clearScreen();
          await _manageAliases();
          _clearScreen();
        } else if (action == -3) {
          _clearScreen();
          await _exportToGit();
          _clearScreen();
        } else if (action == -4) {
          _clearScreen();
          print('\n--- Színséma / Téma választása ---');
          final themes = ['Classic Blue (Cian)', 'Neon Matrix (Zöld)', 'Midnight Pink (Rózsaszín/Lila)', 'Classic Amber (Narancs)'];
          final themeValues = ['blue', 'green', 'pink', 'orange'];
          
          final currentIdx = themeValues.indexOf(AppState.instance.theme);
          final choice = Select(
            prompt: 'Válassz egy témát (Jelenlegi: ${themes[currentIdx >= 0 ? currentIdx : 0]}):',
            options: [...themes, 'Mégse'],
          ).interact();
          
          if (choice < themes.length) {
            AppState.instance.setTheme(themeValues[choice]);
            FolioTheme.configureInteractTheme();
            print('\nTéma sikeresen átállítva!');
            _pause();
          }
          _clearScreen();
        } else if (action == -5) {
          final currentVal = AppState.instance.showAsciiBanner;
          final newVal = Confirm(
            prompt: 'Szeretnéd megjeleníteni az ASCII Art bannert a főmenüben?',
            defaultValue: currentVal,
          ).interact();
          AppState.instance.setShowAsciiBanner(newVal);
          print('\nASCII Art banner sikeresen ${newVal ? "BEKAPCSOLVA" : "KIKAPCSOLVA"}!');
          _pause();
          _clearScreen();
        } else if (action == -6) {
          _clearScreen();
          await _showSpecialSettings();
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

  Future<void> _showSpecialSettings() async {
    while (true) {
      _clearScreen();
      _showMainMenuBanner();
      print('\n--- Speciális Beállítások ---');
      print('Jelenlegi verzió: \x1B[1;36m$appVersion\x1B[0m\n');

      final layout = [
        {'type': 'action', 'id': 0, 'label': 'Frissítések keresése'},
        {'type': 'action', 'id': 1, 'label': 'Vissza'},
      ];

      List<String> options = [];
      List<int> actionIds = [];
      List<int> unselectable = [];

      for (int i = 0; i < layout.length; i++) {
        final item = layout[i];
        options.add(item['label'] as String);
        if (item['type'] == 'separator') {
          actionIds.add(-1);
          unselectable.add(i);
        } else {
          actionIds.add(item['id'] as int);
        }
      }

      final selection = CustomMenu(
        prompt: 'Speciális',
        options: options,
        unselectableIndices: unselectable,
        initialIndex: 0,
      ).interact();

      final action = actionIds[selection];

      if (action == 1) return;

      if (action == 0) {
        _clearScreen();
        _showMainMenuBanner();
        print('\n--- Frissítések Keresése ---');
        print('Keresés a GitHub kiadások között...');
        
        try {
          final res = await http.get(
            Uri.parse('https://api.github.com/repos/CsPS0/folio-cli/releases/latest'),
          ).timeout(Duration(seconds: 4));
          
          if (res.statusCode == 200) {
            final data = jsonDecode(res.body);
            final latestVersion = data['tag_name'] as String?;
            final currentVersion = appVersion;
            
            if (latestVersion != null && latestVersion != currentVersion && latestVersion.startsWith('v')) {
              print('\x1B[33m\n[!] Új Folio CLI verzió érhető el: $latestVersion (Jelenlegi: $currentVersion)\x1B[0m\n');
              print('Frissítési parancsok:');
              print('  - Windows (Scoop):     \x1B[1;36mscoop update folio-cli\x1B[0m');
              print('  - Linux (APT):         \x1B[1;36msudo apt update && sudo apt install folio-cli\x1B[0m');
              print('  - macOS (Homebrew):    \x1B[1;36mbrew upgrade folio-cli\x1B[0m');
              print('  - Manuális szkript:    \x1B[1;36mcurl -fsSL https://raw.githubusercontent.com/CsPS0/folio-cli/main/install.sh | bash\x1B[0m\n');
            } else {
              print('\n\x1B[32m[✓] A legfrissebb verziót használod (Verzió: $currentVersion)\x1B[0m\n');
            }
          } else {
            print('\nHiba: Nem sikerült lekérdezni a verzióinformációkat a GitHubról (Szerver válaszkód: ${res.statusCode}).');
          }
        } catch (e) {
          print('\nHiba történt a frissítés ellenőrzése során: $e');
        }
        
        _pause();
      }
    }
  }

  Future<void> _manageAliases() async {
    while (true) {
      _clearScreen();
      _showMainMenuBanner();
      final aliases = AppState.instance.getAliases();
      List<String> options = [];
      List<String> keys = [];
      
      options.add('Új alias hozzáadása');
      keys.add('');

      for (var entry in aliases.entries) {
        options.add('${entry.key} -> ${entry.value}');
        keys.add(entry.key);
      }
      options.add('Vissza');

      final choice = Select(prompt: 'Tanár/Tantárgy átnevezése (Aliasok)', options: options).interact();
      
      if (choice == options.length - 1) return;

      if (choice == 0) {
        final original = Utf8Input(prompt: 'Eredeti név (pontosan!):').interact();
        if (original.isEmpty) continue;
        final alias = Utf8Input(prompt: 'Új név (Alias):').interact();
        if (alias.isNotEmpty) {
          AppState.instance.setAlias(original, alias);
        }
      } else {
        final keyToRemove = keys[choice];
        final confirm = Confirm(prompt: 'Törölni szeretnéd az aliast: $keyToRemove?', defaultValue: false).interact();
        if (confirm) {
          AppState.instance.removeAlias(keyToRemove);
        }
      }
    }
  }
}
