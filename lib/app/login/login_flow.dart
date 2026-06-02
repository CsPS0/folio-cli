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

}
