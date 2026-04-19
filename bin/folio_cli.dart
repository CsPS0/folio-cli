import 'dart:io';
import 'package:folio_cli/api/client.dart';
import 'package:interact/interact.dart';

void main() async {
  print('==============================');
  print('    Folio CLI (Kréta API)     ');
  print('==============================\n');

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
    instituteCode = Input(prompt: 'Intézmény kódja (pl. intezmeny123)').interact();
  }

  final client = KretaClient(instituteCode: instituteCode);
  
  final authMethod = Select(
    prompt: 'Válassz bejelentkezési módszert',
    options: ['Webes bejelentkezés (Böngészőn keresztül)', 'CLI Automatikus bejelentkezés (Kísérleti, ajánlott)'],
  ).interact();

  bool success = false;
  if (authMethod == 0) {
    print('\nKérlek nyisd meg az alábbi linket a böngésződben (Ctrl+Kattintás):');
    print('https://idp.e-kreta.hu/connect/authorize?prompt=login&nonce=wylCrqT4oN6PPgQn2yQB0euKei9nJeZ6_ffJ-VpSKZU&response_type=code&code_challenge_method=S256&scope=openid%20email%20offline_access%20kreta-ellenorzo-webapi.public%20kreta-eugyintezes-webapi.public%20kreta-fileservice-webapi.public%20kreta-mobile-global-webapi.public%20kreta-dkt-webapi.public%20kreta-ier-webapi.public&code_challenge=HByZRRnPGb-Ko_wTI7ibIba1HQ6lor0ws4bcgReuYSQ&redirect_uri=https://mobil.e-kreta.hu/ellenorzo-student/prod/oauthredirect&client_id=kreta-ellenorzo-student-mobile-ios&state=folio_student_mobile');
    print('\nJelentkezz be, majd amikor egy "Nem található" vagy "mobil.e-kreta.hu" kezdetű oldalra dob,');
    print('MÁSOLD KI A TELJES CÍMET A CÍMSORBÓL és illeszd be ide!');
    
    stdout.write('\nIde másold a linket: ');
    try {
      stdin.echoMode = true;
      stdin.lineMode = true;
    } catch (_) {}
    String pastedUrl = '';
    while (pastedUrl.isEmpty) {
      pastedUrl = stdin.readLineSync()?.trim() ?? '';
    }
    
    print('\nBelépés folyamatban a kóddal...');
    success = await client.webLogin(pastedUrl);
  } else {
    final username = Input(prompt: 'Felhasználónév (oktatási azonosító)').interact();
    final password = Password(prompt: 'Jelszó (születési dátum vagy megadott jelszó)').interact();

    if (username.isEmpty || password.isEmpty) {
      print('Hiba: Minden mezőt ki kell tölteni!');
      return;
    }

    print('\nBelépés folyamatban...');
    success = await client.login(username, password);
  }

  if (!success) {
    print('Sikertelen bejelentkezés.');
    return;
  }

  print('Sikeres bejelentkezés!\n');

  while (true) {
    final action = Select(
      prompt: 'Főmenü',
      options: ['Tanulói adatlap', 'Legutóbbi jegyek', 'Kilépés'],
    ).interact();

    if (action == 2) {
      print('Viszlát!');
      exit(0);
    } else if (action == 0) {
      await showStudentData(client);
    } else if (action == 1) {
      await showGrades(client);
    }
  }
}

Future<void> showStudentData(KretaClient client) async {
  print('\n--- Tanulói adatlap lekérdezése ---');
  final data = await client.getStudentData();
  if (data != null) {
    final name = data['Nev'] ?? 'Ismeretlen';
    final institution = data['IntezmenyNev'] ?? 'Ismeretlen intézmény';
    print('Név: $name');
    print('Intézmény: $institution');
  } else {
    print('Nem sikerült lekérdezni az adatokat.');
  }
  print('');
}

Future<void> showGrades(KretaClient client) async {
  print('\n--- Jegyek lekérdezése ---');
  final grades = await client.getGrades();
  if (grades != null) {
    if (grades.isEmpty) {
      print('Nincsenek elérhető jegyek.');
    } else {
      // Rendezzük a jegyeket rögzítés dátuma alapján csökkenő sorrendbe (legújabb legelöl)
      grades.sort((a, b) {
        final dateA = DateTime.tryParse(a['KeszitesDatuma'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['KeszitesDatuma'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA); // Csökkenő
      });

      for (var grade in grades.take(10)) { // Csak az utolsó 10
        final subject = grade['Tantargy']?['Nev'] ?? 'Ismeretlen tárgy';
        final val = grade['SzamErtek'] ?? grade['SzovegesErtek'];
        // Dátum formázása
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
