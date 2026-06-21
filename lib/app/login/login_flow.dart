part of '../cli_app.dart';

extension FolioCliAppLoginFlow on FolioCliApp {
  Future<void> _performLoginFlow() async {
      final hasCodeChoice = Select(
        prompt: 'Tudod az intézmény kódját?',
        options: ['Igen, tudom a kódját', 'Nem, keresés név alapján'],
      ).interact();
  
      String instituteCode = '';
  
      if (hasCodeChoice == 1) {
        while (instituteCode.isEmpty) {
          final query = Utf8Input(prompt: 'Keresés az iskola neve alapján (min 3 karakter)').interact();
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
                options: options,
              ).interact();
              
              if (choice < keys.length) {
                instituteCode = keys[choice];
                print('Kiválasztott intézménykód: $instituteCode\n');
              }
            }
          }
        }
      } else {
        instituteCode = Utf8Input(prompt: 'Intézmény kódja (pl. bmszc-neumann)').interact();
      }
  
      _client = KretaClient(instituteCode: instituteCode);
      _client!.onTokenRefreshed = () async {
        await _saveAuth();
      };
      
      final authMethod = Select(
        prompt: 'Válassz bejelentkezési módszert',
        options: ['CLI Automatikus bejelentkezés (Ajánlott)', 'Webes bejelentkezés (Böngészőn keresztül)'],
      ).interact();

      bool success = false;

      if (authMethod == 1) {
        final url = 'https://idp.e-kreta.hu/connect/authorize?prompt=login&nonce=wylCrqT4oN6PPgQn2yQB0euKei9nJeZ6_ffJ-VpSKZU&response_type=code&code_challenge_method=S256&scope=openid%20email%20offline_access%20kreta-ellenorzo-webapi.public%20kreta-eugyintezes-webapi.public%20kreta-fileservice-webapi.public%20kreta-mobile-global-webapi.public%20kreta-dkt-webapi.public%20kreta-ier-webapi.public&code_challenge=HByZRRnPGb-Ko_wTI7ibIba1HQ6lor0ws4bcgReuYSQ&redirect_uri=https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect&client_id=kreta-ellenorzo-student-mobile-ios&state=folio_student_mobile&acr_values=institute_code:${_client!.instituteCode}';
        
        print('\nHa a böngésző nem nyílna meg automatikusan, nyisd meg az alábbi linket (Ctrl+Kattintás):');
        print(url);
        
        print('\nMegnyitom a böngészőt a bejelentkezéshez...');
        try {
          if (Platform.isWindows) {
            Process.run('explorer', [url]);
          } else if (Platform.isLinux) {
            Process.run('xdg-open', [url]);
          } else if (Platform.isMacOS) {
            Process.run('open', [url]);
          }
        } catch (e) {
          print('\nNem sikerült automatikusan megnyitni a böngészőt. Kérlek másold be ezt a linket:');
          print(url);
        }
        
        print('\nJelentkezz be, majd amikor egy "Nem található" vagy "mobil.e-kreta.hu" kezdetű oldalra dob,');
        print('KERESD MEG A CÍMSORBAN A "code=" RÉSZT, ÉS MÁSOLD KI CSAK AZ UTÁNA LÉVŐ KÓDOT!');
        print('(Például: 14EC942D... a következő & jelig)');
        
        String pastedCode = '';
        while (pastedCode.isEmpty) {
          if (Platform.isWindows) {
            pastedCode = Utf8Input(prompt: 'Ide másold be a kódot (vagy a teljes linket)').interact().trim();
          } else {
            stdout.write('Ide másold be a kódot (vagy a teljes linket): ');
            pastedCode = stdin.readLineSync()?.trim() ?? '';
          }
          
          if (pastedCode.isEmpty || pastedCode == 'P') {
            pastedCode = '';
          }
        }
        
        print('\nBelépés folyamatban a kóddal...');
        if (pastedCode.startsWith('http')) {
          success = await _client!.webLogin(pastedCode);
        } else {
          // Construct a dummy URL with the code so webLogin can parse it normally
          success = await _client!.webLogin('https://mobil.e-kreta.hu/oauthredirect?code=$pastedCode');
        }
      } else {
        final username = Utf8Input(prompt: 'Felhasználónév (oktatási azonosító)').interact();
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

}
